#version 150
uniform float DhDepthReversed;
bool cmDhSurface(float depth){return DhDepthReversed>.5 ? depth>.0000001 : depth<.9999995;}

// Phase-1 WH FLIR — MUST match FlirHeatCodec.java
//
// CRITICAL: Minecraft smoke sprites are DARK. Vertex color (1,0.04,0.02) * tex≈0.3
// yields RGB≈(0.3,0.01,0.006). Absolute R>0.88 NEVER fires. Detect by RATIOS only.
// Temperature from G/R (texture-invariant). Display white from temp, NEVER from scene luma.

uniform sampler2D DiffuseSampler;
uniform sampler2D HeatSampler;
uniform sampler2D SceneDepthSampler;
uniform sampler2D DhDepthSampler;
uniform vec2 OutSize;
uniform float Time;
uniform float Thermal;
uniform float Degrade;
uniform float NoiseAmount;
uniform float HeatBoost;
uniform float Flash;
uniform float Exposure;
uniform vec2 FlashUv;
uniform float FlashRad;
uniform float MissileOnly;
uniform float ThermalMode;
uniform float HasHeatMask;
uniform float HasDhDepth;
uniform vec3 SkyColor;
uniform float ThermalLow;
uniform float ThermalHigh;
uniform float EnvironmentLow;
uniform float EnvironmentHigh;
uniform float LaunchSaturation;

in vec2 texCoord;
out vec4 fragColor;

float impulseSpread(vec2 uv, float lod) {
    vec2 stepSize=exp2(lod)/vec2(textureSize(HeatSampler,0));
    // Rotationally distributed overlapping taps: avoid the old 3x3 grid ghost.
    float result=textureLod(HeatSampler,uv,lod-.5).g*.28;
    for(int i=0;i<12;i++) {
        float angle=float(i)*2.39996323;
        float radius=sqrt((float(i)+.5)/12.0)*1.55;
        result+=textureLod(HeatSampler,uv+vec2(cos(angle),sin(angle))*stepSize*radius,lod-.5).g*.06;
    }
    return result;
}

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

float luma(vec3 c) {
    return dot(c, vec3(0.299, 0.587, 0.114));
}

float sampleLuma(vec2 uv) {
    return luma(texture(DiffuseSampler, uv).rgb);
}

float opticsEdge(vec2 uv) {
    vec2 px = 1.0 / max(OutSize, vec2(1.0));
    float l = sampleLuma(uv - vec2(px.x, 0.0));
    float r = sampleLuma(uv + vec2(px.x, 0.0));
    float d = sampleLuma(uv - vec2(0.0, px.y));
    float u = sampleLuma(uv + vec2(0.0, px.y));
    float gx = r - l;
    float gy = u - d;
    return sqrt(gx * gx + gy * gy);
}

vec3 sampleSoft(vec2 uv, float radiusPx) {
    vec2 texel = 1.0 / max(OutSize, vec2(1.0));
    if (radiusPx < 0.2) {
        return texture(DiffuseSampler, uv).rgb;
    }
    vec2 r = texel * radiusPx;
    vec3 a = texture(DiffuseSampler, uv).rgb * 0.40;
    a += texture(DiffuseSampler, uv + vec2(r.x, 0.0)).rgb * 0.15;
    a += texture(DiffuseSampler, uv - vec2(r.x, 0.0)).rgb * 0.15;
    a += texture(DiffuseSampler, uv + vec2(0.0, r.y)).rgb * 0.15;
    a += texture(DiffuseSampler, uv - vec2(0.0, r.y)).rgb * 0.15;
    return a;
}

// Ratio marker: works on dark smoke tex. Wood fails (G≈R).
float markerPresence(vec3 c) {
    float r = max(c.r, 0.001);
    float gOverR = c.g / r;
    float bOverR = c.b / r;
    float redFrac = (c.r - c.g) / r;
    if (c.r < 0.008) return 0.0; // dark debris sprites after vertex×tex
    if (c.g > c.r + 0.01) return 0.0; // grass
    // Wood/dirt: G rides with R (oak~0.75, acacia~0.53)
    if (gOverR > 0.40) return 0.0;
    if (bOverR > 0.45) return 0.0;
    if (redFrac < 0.55) return 0.0;
    return clamp((redFrac - 0.50) * 3.0, 0.0, 1.0);
}

// Hot tint G/R≈0.02 → temp1; cool G/R≈0.34 → temp0. Scale-invariant.
float markerTemp(vec3 c) {
    float gOverR = c.g / max(c.r, 0.001);
    return clamp(1.0 - (gOverR - 0.02) / 0.32, 0.0, 1.0);
}

float markerPresenceMax(vec2 uv, float px) {
    vec2 t = (1.0 / max(OutSize, vec2(1.0))) * px;
    float m = markerPresence(texture(DiffuseSampler, uv).rgb);
    m = max(m, markerPresence(texture(DiffuseSampler, uv + vec2(t.x, 0.0)).rgb));
    m = max(m, markerPresence(texture(DiffuseSampler, uv - vec2(t.x, 0.0)).rgb));
    m = max(m, markerPresence(texture(DiffuseSampler, uv + vec2(0.0, t.y)).rgb));
    m = max(m, markerPresence(texture(DiffuseSampler, uv - vec2(0.0, t.y)).rgb));
    return m;
}

void main() {
    vec2 uv = texCoord;
    if (Thermal > 0.5 && HasHeatMask > 0.5) {
        // HDR radiance is composed before detector/display processing.
        vec2 px = 1.0 / max(OutSize, vec2(1.0));
        float signal = texture(HeatSampler, uv).r;
        float surround = 0.0;
        for (int j=-1;j<=1;j++) for(int i=-1;i<=1;i++)
            surround += texture(HeatSampler, uv+vec2(i,j)*px).r;
        float sensed = signal*.88 + surround*(.12/9.0);
        // Three optical-scatter scales, driven by the impulse's HDR energy.
        // Ordinary hot smoke and fragments cannot create a persistent fog halo.
        float nearGlare=impulseSpread(uv,2.0);
        float middleGlare=impulseSpread(uv,4.0);
        float wideGlare=impulseSpread(uv,6.0);
        sensed+=nearGlare*.26+middleGlare*.38+wideGlare*.22;
        float level = log(1.0+max(sensed,0.0));
        float span = max(ThermalHigh-ThermalLow,0.3);
        float x = max(0.0,(level-ThermalLow)/span);
        // Shoulder retains gradients in hot clouds instead of clipping every
        // sample above a fixed temperature to the same white value.
        float g = 1.0-exp(-x*1.35);
        float signalLevel=log(1.+max(signal,0.));
        float environmentX=max(0.,(signalLevel-EnvironmentLow)/max(.18,EnvironmentHigh-EnvironmentLow));
        float environmentGray=1.-exp(-environmentX*.90);
        // Existing explosion exposure/impulse response is preserved in heated pixels.
        float protectedHeat=texture(HeatSampler,uv).a;
        float bareX=max(0.,(signalLevel-ThermalLow)/span);
        float glareDelta=g-(1.-exp(-bareX*1.35));
        g=mix(environmentGray+glareDelta,g,smoothstep(0.,.10,protectedHeat));
        // Vehicle pixels carry a negative identification channel. A wider detector
        // window preserves gradients in warm running gear without altering explosions.
        float vehicleMask=smoothstep(.20,.75,-texture(HeatSampler,uv).b)*(1.-smoothstep(0.,.10,protectedHeat));
        float vehicleX=max(0.,(signalLevel-EnvironmentLow)/max(.16,EnvironmentHigh-EnvironmentLow));
        float vehicleGray=1.-exp(-vehicleX*.90);
        g=mix(g,vehicleGray+glareDelta,vehicleMask);
        float detail = log(1.0+max(signal,0.0))-log(1.0+max(surround/9.0,0.0));
        // Mild local contrast overshoot gives the opposite-polarity contour.
        // It is display processing, not a cold physical ring around the blast.
        float localMean=0.0;
        vec2 detectorPx=1.0/vec2(textureSize(HeatSampler,0));
        for(int j=-1;j<=1;j++)for(int i=-1;i<=1;i++)
            localMean+=textureLod(HeatSampler,uv+vec2(i,j)*detectorPx*5.0,0.0).r/9.0;
        float edge=log(1.0+max(signal,0.0))-log(1.0+max(localMean,0.0));
        g+=clamp(edge/span,-.16,.12)*.48;
        // A saturated source loses internal detail and expands via optical scatter.
        // Invert only at the end, so BLACK HOT glare remains dark.
        float overload=smoothstep(2.2,4.2,x);
        g=mix(g,1.0,overload*.96);
        // Local body contrast enhancement, with source visibility/absorption preserved.
        // Does not tint terrain or expose entities hidden by walls or dense smoke.
        float body=texture(HeatSampler,uv).b;
        g=max(g,.82*body);
        g += (hash(uv*OutSize+vec2(Time*17.0))-0.5)*NoiseAmount*.06;
        g = clamp(g,0.01,0.995);
        g = mix(g,1.0,clamp(LaunchSaturation,0.0,1.0));
        if(ThermalMode>0.5)g=1.0-g;
        fragColor=vec4(vec3(g),1.0);
        return;
    }
    if (Thermal < -0.5) {
        vec4 tv = texture(DiffuseSampler, uv);
        float sceneDepth = texture(SceneDepthSampler, uv).r;
        float dhDepth = HasDhDepth > 0.5 ? texture(DhDepthSampler, uv).r : 1.0;
        float emptySky = step(0.9999995, sceneDepth) * (HasDhDepth>.5 && cmDhSurface(dhDepth)?0.:1.);
        float blackSky = 1.0 - smoothstep(0.02, 0.10, luma(tv.rgb));
        float missingSky = emptySky * max(1.0 - step(0.1, tv.a), blackSky);
        fragColor = vec4(mix(tv.rgb, SkyColor, missingSky), 1.0);
        return;
    }
    float d = clamp(Degrade, 0.0, 1.0);
    bool missileOnly = MissileOnly > 0.5;
    bool thermal = Thermal > 0.5;
    bool blackHot = ThermalMode > 0.5;

    vec4 raw = texture(DiffuseSampler, uv);
    if (thermal) {
        // Preserve real hot geometry inside this output pixel's source footprint.
        // This is heat-aware reduction, not a screen-space target marker or halo.
        ivec2 sourceSize = textureSize(DiffuseSampler, 0);
        float bestHeat = -1.0;
        vec4 strongest = raw;
        for (int iy = 0; iy < 2; ++iy) {
            for (int ix = 0; ix < 2; ++ix) {
                vec2 offset = (vec2(ix, iy) - vec2(0.5)) * 0.5 / max(OutSize, vec2(1.0));
                ivec2 pixel = clamp(ivec2((uv + offset) * vec2(sourceSize)), ivec2(0), sourceSize - 1);
                vec4 candidate = texelFetch(DiffuseSampler, pixel, 0);
                float strength = markerPresence(candidate.rgb);
                if (strength > bestHeat) {
                    bestHeat = strength;
                    strongest = candidate;
                }
            }
        }
        if (bestHeat > 0.2) raw = strongest;
    }
    // Minimal blur in thermal — chroma is fragile
    float blurPx = thermal ? mix(0.15, 0.45, d) : mix(0.35, 1.4, d * d);
    vec3 scene = sampleSoft(uv, blurPx);
    if (raw.a < 0.15) {
        scene = sampleSoft(uv, 2.5);
    }
    float y = clamp(luma(scene), 0.0, 1.0);
    float rawY = clamp(luma(raw.rgb), 0.0, 1.0);
    vec3 outc;

    if (thermal) {
        // Ambient radiance proxy: modest material/illumination variation, never
        // classify whole block types as white-hot. Depth separates sky from land.
        float depth = texture(SceneDepthSampler, uv).r;
        float dhDepth = HasDhDepth > 0.5 ? texture(DhDepthSampler, uv).r : 1.0;
        float sky = step(0.9999995, depth) * (HasDhDepth>.5 && cmDhSurface(dhDepth)?0.:1.);
        float vegetation = clamp(scene.g - 0.5 * (scene.r + scene.b), 0.0, 0.4);
        float water = clamp(scene.b - max(scene.r, scene.g), 0.0, 0.4);
        // Keep ordinary terrain below the palette midpoint: 50% gray barely
        // changes under inversion and made WH/BH terrain look identical.
        float ambient = 0.23 + 0.23 * sqrt(y) - vegetation * 0.09 - water * 0.12;
        float surfaceDetail = y - luma(sampleSoft(uv, 2.0));
        ambient = clamp(ambient + surfaceDetail * 0.18, 0.20, 0.46);
        ambient = mix(ambient, 0.13 + 0.045 * y, sky);

        float presence = markerPresence(raw.rgb);
        float heatWeight = smoothstep(0.05, 0.28, presence);
        float temperature = markerTemp(raw.rgb);
        // Sprite luminance contributes fine structure, not the absolute heat:
        // dark smoke textures must still represent a hot expanding gas cloud.
        float detail = smoothstep(0.015, 0.65, raw.r);
        float radiance = 0.38 + 0.58 * pow(temperature, 0.72);
        radiance += (detail - 0.5) * 0.12 * (1.0 - smoothstep(0.9, 0.99, temperature));
        float saturated = smoothstep(0.91, 0.985, temperature) * heatWeight;
        float g = mix(ambient, radiance, heatWeight);
        g = mix(g, 1.0, saturated);

        // Optical spread is derived ONLY from visible hot pixels. No projected
        // flash disk, so it cannot detach from the explosion or pass terrain.
        vec2 pixelSize = 1.0 / max(OutSize, vec2(1.0));
        float spread = 0.0;
        for (int iy = -1; iy <= 1; ++iy) {
            for (int ix = -1; ix <= 1; ++ix) {
                vec3 neighbor = texture(DiffuseSampler, uv + vec2(ix, iy) * pixelSize).rgb;
                spread += markerPresence(neighbor) * smoothstep(0.92, 0.995, markerTemp(neighbor));
            }
        }
        g += (1.0 - g) * spread / 9.0 * 0.32;
        // Weak wider PSF wing around saturated sources; never a projected disk.
        float wing = 0.0;
        for (int i = 0; i < 8; ++i) {
            float angle = float(i) * 0.785398;
            vec3 neighbor = texture(DiffuseSampler, uv + vec2(cos(angle), sin(angle)) * pixelSize * 3.0).rgb;
            wing += markerPresence(neighbor) * smoothstep(0.96, 0.995, markerTemp(neighbor));
        }
        g += (1.0 - g) * wing * 0.012;
        float grain = hash(uv * OutSize + vec2(Time * 29.0, Time * 17.0)) - 0.5;
        g += grain * NoiseAmount * 0.12 * (1.0 - saturated);
        g = clamp(g, 0.02, 1.0);
        // Apply palette last: identical radiance response for both polarities.
        g = mix(g,1.0,clamp(LaunchSaturation,0.0,1.0));
        if (blackHot) g = 1.0 - g;
        fragColor = vec4(vec3(g), 1.0);
        return;
    }
    if (missileOnly) {
        float g = mix(0.55, 0.95, smoothstep(0.02, 0.9, rawY));
        float a = clamp(max(raw.a, smoothstep(0.02, 0.12, rawY)), 0.0, 1.0);
        if (a < 0.02) {
            fragColor = vec4(0.0);
            return;
        }
        fragColor = vec4(vec3(g), a);
        return;
    }

    float softY = luma(sampleSoft(uv, 1.05));
    float widerY = luma(sampleSoft(uv, 2.15));
    float detail = rawY - widerY;
    float spike = max(rawY - softY, 0.0);
    float edge = opticsEdge(uv);
    float g = rawY + detail * 1.65 + edge * 0.30;
    g = mix(g, g - spike * 0.55, 0.35);
    g = (g - 0.5) * mix(1.18, 0.92, d) + 0.5;
    outc = mix(vec3(clamp(g, 0.0, 1.0)), vec3(0.78), d * 0.22);
    float scan = 0.988 + 0.012 * sin(uv.y * OutSize.y * 2.8 + Time * 6.0);
    outc *= scan;
    float n1 = hash(uv * OutSize + vec2(Time * 37.0, Time * 19.0));
    outc += vec3((n1 - 0.5) * NoiseAmount * 0.35);
    fragColor = vec4(clamp(outc, 0.0, 1.0), 1.0);
}

