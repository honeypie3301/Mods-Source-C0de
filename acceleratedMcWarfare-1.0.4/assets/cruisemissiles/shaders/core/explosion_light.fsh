#version 150
uniform float DhDepthReversed;
bool cmDhSurface(float depth){return DhDepthReversed>.5 ? depth>.0000001 : depth<.9999995;}

uniform sampler2D DiffuseSampler;
uniform sampler2D DepthSampler;
uniform sampler2D DhDepthSampler;

uniform mat4 InvViewProjMat;
uniform mat4 ViewProjMat;
uniform mat4 DhInvViewProjMat;
uniform mat4 DhViewProjMat;
uniform mat4 InvProjMat;
uniform mat4 ViewToWorldMat;
uniform vec3 LightPos;
uniform vec3 LightColor;
uniform vec3 LightAxis;
uniform vec3 LightPrevPos;
uniform float Intensity;
uniform float SkyIntensity;
uniform float FlashIntensity;
uniform float Radius;
uniform float SkyRadius;
uniform float AirBurst;
uniform float PointSource;
uniform float LightCount;
uniform float HasDhDepth;
uniform float HasDhMatrix;
uniform float DhOnly;
uniform float SamNight;
uniform float SamPos[12];
uniform float SamPrev[12];
uniform float SamCol[12];
uniform float SamAxis[12];
uniform float SamIntRadius[8];
uniform float SamSpark[8];
// Minecraft uploads a float uniform with count=4 as a vec4, not a scalar array.
uniform vec4 SamMotorScale;

in vec2 texCoord;

out vec4 fragColor;

float distToCapsule(vec3 p, vec3 a, vec3 b) {
    vec3 ab = b - a;
    float ab2 = max(dot(ab, ab), 1e-6);
    float t = clamp(dot(p - a, ab) / ab2, 0.0, 1.0);
    return length(p - (a + ab * t));
}

// Min distance from ray (origin 0, dir rd) to segment a→b — world-locked spark (no camera swim)
float raySegmentDist(vec3 rd, vec3 a, vec3 b) {
    vec3 u = b - a;
    vec3 v = rd;
    vec3 w = a;
    float uu = max(dot(u, u), 1e-8);
    float vv = max(dot(v, v), 1e-8);
    float uv = dot(u, v);
    float wu = dot(w, u);
    float wv = dot(w, v);
    float D = uu * vv - uv * uv;
    float tSeg;
    float tRay;
    if (D < 1e-8) {
        tSeg = clamp(-wu / uu, 0.0, 1.0);
        tRay = max(dot(a + u * tSeg, v) / vv, 0.0);
    } else {
        tSeg = clamp((uv * wv - vv * wu) / D, 0.0, 1.0);
        tRay = max((uu * wv - uv * wu) / D, 0.0);
    }
    vec3 pSeg = a + u * tSeg;
    vec3 pRay = v * tRay;
    return length(pSeg - pRay);
}

vec3 samVec3(float arr[12], int i) {
    int o = i * 3;
    return vec3(arr[o], arr[o + 1], arr[o + 2]);
}

float depthOcclusionAt(vec3 samplePos, mat4 viewProj, mat4 invViewProj,
                       sampler2D depthSampler, float worldBias, bool distant) {
    vec4 projected = viewProj * vec4(samplePos, 1.0);
    if (projected.w <= 1e-5) return 0.0;
    vec3 ndc = projected.xyz / projected.w;
    vec2 uv = ndc.xy * 0.5 + 0.5;
    if (uv.x <= 0.002 || uv.x >= 0.998 || uv.y <= 0.002 || uv.y >= 0.998) return 0.0;
    float expectedDepth = ndc.z * 0.5 + 0.5;
    if (expectedDepth <= 0.0 || expectedDepth >= 1.0) return 0.0;
    float sceneDepth = texture(depthSampler, uv).r;
    if (distant ? !cmDhSurface(sceneDepth) : sceneDepth>=0.99999) return 0.0;

    // Depth is highly non-linear: a fixed depth-buffer epsilon at 500-1000
    // blocks can hide an entire house. Reconstruct the visible sample and
    // compare camera-relative distances in actual blocks instead.
    vec4 sceneH = invViewProj * vec4(uv * 2.0 - 1.0,
            sceneDepth * 2.0 - 1.0, 1.0);
    vec3 scenePos = sceneH.xyz / max(abs(sceneH.w), 1e-6);
    float expectedDistance = length(samplePos);
    float sceneDistance = length(scenePos);
    return sceneDistance + worldBias < expectedDistance ? 1.0 : 0.0;
}

// Approximate light-to-surface visibility using both Minecraft and DH depth.
// A multi-sample ray gives stable house/wall shadows without a second
// world render or a cubemap shadow pass for every explosion.
float explosionVisibility(vec3 surfacePos, vec3 emitterPos) {
    vec3 segment = emitterPos - surfacePos;
    float segmentLength = length(segment);
    if (segmentLength < 2.0) return 1.0;
    float blocked = 0.0;
    // 24 samples are dense enough not to step over a 4-6 block village house
    // on the long rays seen in the tactical test recordings.
    for (int i = 0; i < 24; i++) {
        float t = 0.07 + (float(i) + 0.5) * (0.86 / 24.0);
        vec3 samplePos = surfacePos + segment * t;
        float hit = depthOcclusionAt(samplePos, ViewProjMat, InvViewProjMat,
                DepthSampler, 0.55, false);
        if (HasDhDepth > 0.5 && HasDhMatrix > 0.5) {
            hit = max(hit, depthOcclusionAt(samplePos, DhViewProjMat, DhInvViewProjMat,
                    DhDepthSampler, 1.35, true));
        }
        blocked += hit;
    }
    // One or two samples may be a thin wall, so they must already make a
    // readable shadow. Never make it pitch black: the huge fireball produces
    // a broad penumbra and the illuminated ground supplies bounced light.
    return 1.0 - smoothstep(0.35, 2.8, blocked) * 0.88;
}

void main() {
    vec4 scene = texture(DiffuseSampler, texCoord);
    float depth = texture(DepthSampler, texCoord).r;
    float dhDepth = HasDhDepth > 0.5 ? texture(DhDepthSampler, texCoord).r : 1.0;
    bool vanSky = depth >= 0.99999;
    // Only real DH geometry behind sky-depth. Do NOT color-guess:
    // dark night sky has low skyLikeness and was misclassified as terrain →
    // launch pad wash flooded the whole sky and killed the nozzle spark.
    bool dhHit = HasDhDepth > 0.5 && cmDhSurface(dhDepth);
    bool lodSurface = vanSky && dhHit;
    bool isSky = vanSky && !lodSurface;

    if (DhOnly > 0.5 && !lodSurface) {
        fragColor = scene;
        return;
    }

    float surfaceDepth = lodSurface ? dhDepth : depth;
    vec4 clip = vec4(
        texCoord.x * 2.0 - 1.0,
        texCoord.y * 2.0 - 1.0,
        surfaceDepth * 2.0 - 1.0,
        1.0
    );
    vec4 worldH = (lodSurface && HasDhMatrix > 0.5)
        ? (DhInvViewProjMat * clip) : (InvViewProjMat * clip);
    vec3 camRel = worldH.xyz / max(worldH.w, 1e-6);

    float luma = dot(scene.rgb, vec3(0.2126, 0.7152, 0.0722));
    float nightGap = clamp(1.25 - luma * 1.2, 0.2, 1.0);
    vec3 add = vec3(0.0);

    int count = int(LightCount + 0.5);

    // --- SAM batch: soft ground wash + tiny world-space nozzle spark ---
    if (count > 0) {
        // Ray in the SAME space as camRel / SamPos (camera-relative world).
        // Using InvProj+ViewToWorld drifted under view-bob and made the spark swim.
        vec4 nearH = InvViewProjMat * vec4(clip.xy, -1.0, 1.0);
        vec4 farH = InvViewProjMat * vec4(clip.xy, 1.0, 1.0);
        vec3 nearP = nearH.xyz / max(nearH.w, 1e-6);
        vec3 farP = farH.xyz / max(farH.w, 1e-6);
        vec3 rayDir = normalize(farP - nearP);

        for (int i = 0; i < 4; i++) {
            if (i >= count) {
                break;
            }
            vec3 pos = samVec3(SamPos, i);
            vec3 prev = samVec3(SamPrev, i);
            vec3 col = samVec3(SamCol, i);
            vec3 axis = samVec3(SamAxis, i);
            float inten = SamIntRadius[i * 2];
            float rad = max(SamIntRadius[i * 2 + 1], 4.0);
            float sparkInt = SamSpark[i * 2];
            float sparkLen = max(SamSpark[i * 2 + 1], 0.4);

            // Soft pad wash (terrain only) — backup «зенитной ракетой в2»
            if (!isSky && inten >= 0.01) {
                vec3 jetEnd = pos + normalize(axis) * sparkLen;
                float d = distToCapsule(camRel, pos, jetEnd);
                float core = 1.0 / (1.0 + (d / (rad * 0.55)) * (d / (rad * 0.55)));
                float mid = 1.0 / (1.0 + (d / rad) * (d / rad));
                float skirt = 1.0 / (1.0 + (d / (rad * 1.85)) * (d / (rad * 1.85)));
                // A rational falloff never reaches zero. Without this boundary
                // every terrain pixel received launch color and the view became
                // one flat yellow/grey layer.
                float finiteRange = 1.0 - smoothstep(rad * 1.15, rad * 2.05, d);
                float fall = max(core * 0.55, max(mid * 0.70, skirt * 0.28)) * finiteRange;
                float lit = inten * fall * nightGap;
                vec3 surfaceNormal = normalize(cross(dFdx(camRel), dFdy(camRel)));
                if (dot(surfaceNormal, -rayDir) < 0.0) surfaceNormal = -surfaceNormal;
                vec3 toEmitter = normalize(mix(pos, jetEnd, 0.45) - camRel);
                float facing = 0.22 + 0.78 * max(dot(surfaceNormal, toEmitter), 0.0);
                // Retain terrain texture and hue instead of laying a flat white wash over it.
                vec3 daylight = (scene.rgb * 1.8 + vec3(0.055)) * col * lit * facing;
                // One smooth distance law for terrain, vehicles and walls.
                // No launch-age boundary: low flight keeps lighting nearby geometry.
                float nightFall = 1.0 / pow(1.0 + d * d / (rad * rad), 2.0);
                vec3 nightColor = mix(vec3(1.0, 0.59, 0.27), vec3(1.0, 0.87, 0.66), nightFall);
                vec3 nightLight = (scene.rgb * 1.7 + vec3(0.095)) * nightColor
                                * inten * nightFall * facing;
                add += mix(daylight, nightLight, SamNight);
            }

            // Tiny elongated nozzle spark — world-locked in camera-relative space
            if (sparkInt >= 0.01) {
                float axLen = length(axis);
                vec3 ex = axLen > 1e-4 ? axis / axLen : vec3(0.0, -1.0, 0.0);
                float surfaceT = isSky ? 1e8 : max(dot(camRel, rayDir), 0.0);
                float hot = 0.0;
                float rim = 0.0;
                float haze = 0.0;
                // Overlapping depth-tested cross sections of a widening jet.
                // The same ray test works against sky AND terrain backgrounds.
                for (int j = 0; j < 16; j++) {
                    float u = float(j) / 15.0;
                    vec3 centre = pos + ex * (sparkLen * u);
                    float rayT = dot(centre, rayDir);
                    if (rayT <= 0.0) continue;
                    vec3 closest = rayDir * min(rayT, surfaceT);
                    float d = length(closest - centre);
                    float width = 0.18 * max(1.0, SamMotorScale[i]) + 0.095 * sparkLen * u;
                    float tail = 1.0 - smoothstep(0.65, 1.0, u);
                    // Jet width softens its silhouette, not scene occlusion.
                    // Letting width extend depth made the core bleed through the missile.
                    float visible = isSky ? 1.0 : 1.0 - smoothstep(surfaceT, surfaceT + 0.03, rayT);
                    float body = exp(-d * d / (width * width));
                    float edge = exp(-d * d / (width * width * 2.8));
                    hot = max(hot, body * tail * visible);
                    rim = max(rim, edge * tail * visible);
                    // Local atmospheric scattering: finite, occluded, also visible
                    // against sky. This is a nearby halo, not a uniform sky flash.
                    float hazeRadius = 2.0 + width * 3.5;
                    float fog = exp(-d * d / (hazeRadius * hazeRadius));
                    float fogVisible = isSky ? 1.0 : 1.0 - smoothstep(surfaceT, surfaceT + hazeRadius, rayT);
                    haze = max(haze, fog * fogVisible * (1.0 - smoothstep(hazeRadius, hazeRadius * 2.0, d)));
                }
                float nearFade = smoothstep(0.6, 2.5, length(pos));
                add += vec3(1.0, 0.98, 0.91) * hot * sparkInt * 2.8 * nearFade;
                add += vec3(1.0, 0.47, 0.12) * max(rim - hot * 0.75, 0.0) * sparkInt * 0.85 * nearFade;
                add += vec3(1.0, 0.59, 0.23) * haze * sparkInt * nightGap * 0.12 * nearFade * (1.0 - SamNight);
                // Soft distant optical bloom, bounded in world units: it still shrinks far away.
                vec3 bloomAt = pos + ex * sparkLen * 0.35;
                float bloomDistance = length(bloomAt);
                float bloomT = dot(bloomAt, rayDir);
                float bloomVisible = isSky ? 1.0 : 1.0 - smoothstep(surfaceT, surfaceT + 0.03, bloomT);
                if (bloomT > 0.0) {
                    float radius = min(8.0, 1.5 + bloomDistance * 0.006);
                    float d = length(rayDir * bloomT - bloomAt) / radius;
                    float bloom = exp(-d*d*1.6) + 0.15*exp(-d*d*0.4);
                    float gain = smoothstep(100.0, 350.0, bloomDistance) * sparkInt * bloomVisible;
                    add += vec3(1.0, 0.91, 0.68) * bloom * gain * mix(0.18, 0.65, SamNight);
                }
            }
            if (SamNight > 0.001 && DhOnly < 0.5 && inten > 0.001) {
                // Integrate illuminated air along the view ray, clipped at the
                // first scene surface. The glow has real world size and parallax.
                vec3 centre = pos + axis * sparkLen * 0.45;
                float fogRadius = rad * 0.48;
                float along = dot(centre, rayDir);
                float perpendicular2 = max(dot(centre, centre) - along * along, 0.0);
                float bound2 = 9.0 * fogRadius * fogRadius;
                if (perpendicular2 < bound2) {
                    float halfSpan = sqrt(bound2 - perpendicular2);
                    float startT = max(along - halfSpan, 0.0);
                    float endT = along + halfSpan;
                    if (!isSky) endT = min(endT, max(dot(camRel, rayDir), 0.0));
                    float stepLength = max(endT - startT, 0.0) / 12.0;
                    float opticalDepth = 0.0;
                    for (int sampleIndex = 0; sampleIndex < 12; sampleIndex++) {
                        vec3 p = rayDir * (startT + (float(sampleIndex) + 0.5) * stepLength);
                        float r2 = dot(p - centre, p - centre) / (fogRadius * fogRadius);
                        opticalDepth += exp(-r2 * 1.4) * stepLength / fogRadius;
                    }
                    float scattering = (1.0 - exp(-opticalDepth * 0.22)) * inten * SamNight * 0.25;
                    add += vec3(1.0, 0.64, 0.34) * scattering;
                }
            }
        }
        fragColor = vec4(scene.rgb + add, scene.a);
        return;
    }

    // --- Legacy single-light path (explosions / old callers) ---
    // Build the ray in exactly the same camera-relative world space as
    // LightPos and camRel.  InvProj + Camera.rotation omitted Minecraft's
    // view-bob transform, so a world-fixed blast appeared to sway with the
    // player's camera animation.
    vec4 explosionNearH = InvViewProjMat * vec4(clip.xy, -1.0, 1.0);
    vec4 explosionFarH = InvViewProjMat * vec4(clip.xy, 1.0, 1.0);
    vec3 explosionNear = explosionNearH.xyz / max(abs(explosionNearH.w), 1e-6);
    vec3 explosionFar = explosionFarH.xyz / max(abs(explosionFarH.w), 1e-6);
    vec3 rayDir = normalize(explosionFar - explosionNear);

    float lightDist = max(length(LightPos), 1.0);
    float farT = smoothstep(35.0, 360.0, lightDist);

    vec3 toLight = LightPos / lightDist;
    float align = max(dot(rayDir, toLight), 0.0);

    // Compact flash. The old low exponents painted a very large disc even though
    // the actual light radius was correct.
    float corePow = mix(125.0, 720.0, farT);
    float bloomPow = mix(30.0, 115.0, farT);
    float washPow = mix(13.0, 44.0, farT);
    float yieldAngularScale = clamp(Radius / 90.75, 0.55, 1.85);
    float perspectiveScale = max(1.0, pow(lightDist / max(Radius * 3.0, 1.0), 1.45));
    corePow = corePow * perspectiveScale / yieldAngularScale;
    bloomPow = bloomPow * perspectiveScale / yieldAngularScale;
    washPow = washPow * perspectiveScale / yieldAngularScale;

    float sparkCore = pow(align, corePow);
    float sparkBloom = pow(align, bloomPow);
    float sparkWash = pow(align, washPow);

    float coreGain = mix(2.65, 5.1, farT);
    float bloomGain = mix(1.25, 2.3, farT);
    float washGain = mix(0.28, 0.58, farT);

    float glareMask = isSky ? 1.0 : 0.0;
    float flashDistance = 1.0 / (1.0 + pow(lightDist / max(Radius * 2.15, 1.0), 1.70));

    if (PointSource > 0.5 && FlashIntensity > 0.01
            && (isSky || length(camRel) + 0.35 >= lightDist)) {
        // Compact white glare at the actual moving part, with surface occlusion.
        bool flame = PointSource > 1.5;
        float angularSize = flame ? max(0.00045, 0.42 / max(lightDist, 1.0))
                                  : max(0.00028, 0.24 / max(lightDist, 1.0));
        float alignment = max(0.0, 1.0 - dot(rayDir, normalize(LightPos)));
        float core = exp(-alignment / (angularSize * angularSize));
        float halo = exp(-alignment / (angularSize * angularSize * 5.0));
        if(flame) {
            float outer = exp(-alignment / (angularSize * angularSize * 14.0));
            add += vec3(1.0, 0.91, 0.60) * FlashIntensity * core * 2.2;
            add += LightColor * FlashIntensity * (halo * .85 + outer * .18);
        } else add += LightColor * FlashIntensity * (core * 1.4 + halo * 0.16);
    }
    if (PointSource < 0.5 && glareMask > 0.01 && FlashIntensity > 0.01) {
        add += vec3(1.0, 0.86, 0.48) * (FlashIntensity * flashDistance * sparkCore * coreGain * 1.45 * nightGap * glareMask);
        add += vec3(1.0, 0.56, 0.12) * (FlashIntensity * flashDistance * sparkBloom * bloomGain * nightGap * glareMask);
        add += LightColor * (FlashIntensity * flashDistance * sparkWash * washGain * 0.34 * nightGap * glareMask);
        float glare = sparkCore * coreGain + sparkBloom * bloomGain;
        add += vec3(1.0, 0.66, 0.22) * (FlashIntensity * flashDistance * glare * glare * 0.16 * nightGap * glareMask);
    }

    if (SkyIntensity > 0.01) {
        // This is a finite atmospheric volume at the explosion, not a tint on
        // the infinitely distant sky.  Clamp the ray segment to the first
        // visible vanilla/DH surface, so buildings and terrain hide the volume
        // behind them while air in front of those surfaces can still glow.
        vec3 glowCenter = LightPos
                + vec3(0.0, mix(SkyRadius * 0.16, 0.0, AirBurst), 0.0);
        // SkyRadius is the soft scattering scale. Trace farther than that so
        // the Gaussian tail is effectively dark before the ray bound ends.
        float glowSigma = max(SkyRadius, 1.0);
        float glowRadius = glowSigma * 2.7;
        float centerAlongRay = dot(glowCenter, rayDir);
        float centerPerpendicularSq = max(
            dot(glowCenter, glowCenter) - centerAlongRay * centerAlongRay,
            0.0
        );
        float radiusSq = glowRadius * glowRadius;

        if (centerPerpendicularSq < radiusSq && centerAlongRay > 0.0) {
            float halfChord = sqrt(max(radiusSq - centerPerpendicularSq, 0.0));
            float segmentStart = max(centerAlongRay - halfChord, 0.0);
            float segmentEnd = centerAlongRay + halfChord;
            float surfaceDistance = isSky
                    ? 100000000.0
                    : max(dot(camRel, rayDir), 0.0);
            segmentEnd = min(segmentEnd, surfaceDistance);

            // Do not cut the sphere at glowCenter.y.  Its centre is raised for
            // a ground burst, and that old hard plane removed the whole lower
            // part of the glow, leaving a dark horizontal stripe.  Actual
            // ground/buildings already clip the volume through surfaceDistance
            // (using vanilla or DH depth), which is the physically useful mask.
            float segmentLength = max(segmentEnd - segmentStart, 0.0);
            float radial = exp(-centerPerpendicularSq / (glowSigma * glowSigma));
            float opticalDepth = 1.0 - exp(-segmentLength / max(glowSigma * 0.90, 0.001));
            float localGlow = radial * opticalDepth;
            add += LightColor * (SkyIntensity * localGlow * nightGap * mix(0.48, 0.88, farT));
            float warmCore = exp(-centerPerpendicularSq /
                    max(glowSigma * glowSigma * 0.20, 1.0));
            add += LightColor * (SkyIntensity * warmCore * opticalDepth * nightGap * 0.34);
            add += vec3(1.0, 0.85, 0.48)
                    * (SkyIntensity * localGlow * localGlow * 0.22 * nightGap);
        }
    }

    if (!isSky && Intensity > 0.01 && (!lodSurface || HasDhMatrix > 0.5)) {
        // Capsule terrain wash (prev→curr) for single-light callers
        vec3 prev = length(LightPrevPos) > 0.01 ? LightPrevPos : LightPos;
        float d = distToCapsule(camRel, prev, LightPos);
        float rad = max(Radius, 4.0);
        float finiteRange = 1.0 - smoothstep(rad * 1.10, rad * 2.15, d);
        // Preserve the exact broad, bright explosion curve from the reference
        // backup. Direction and occlusion are applied afterwards and do not
        // change its radius, colour or centre brightness.
        float atten = (1.0 / (1.0 + (d / rad) * (d / rad))) * finiteRange;
        if (PointSource > 0.5) atten = pow(max(0.0, 1.0-d/rad), 2.0);
        vec3 surfaceNormal = normalize(cross(dFdx(camRel), dFdy(camRel)));
        if (dot(surfaceNormal, -rayDir) < 0.0) surfaceNormal = -surfaceNormal;
        // A ground detonation is a large rising fireball, not a point lamp 0.6
        // blocks above the soil. Aim surface lighting/shadow rays at the centre
        // of that volume so horizontal ground receives the reference brightness.
        vec3 effectiveLightPos = LightPos
                + vec3(0.0, mix(rad * 0.24, 0.0, AirBurst), 0.0);
        if(PointSource > 0.5) effectiveLightPos = LightPos + vec3(0.0, 0.10, 0.0);
        vec3 towardLight = normalize(effectiveLightPos - camRel);
        // Binary-soft visibility of a side, rather than Lambert dimming. A side
        // that can see the large flash keeps the backup's full light intensity.
        float facing = smoothstep(-0.045, 0.14, dot(surfaceNormal, towardLight));
        if(PointSource > 0.5) facing = max(0.0, dot(surfaceNormal, towardLight));
        float visibility = 0.0;
        // Shadow tracing is the expensive part. Do it only where the finite
        // explosion light can contribute a visible amount.
        if (atten > 0.002 && facing > 0.001) {
            visibility = explosionVisibility(camRel + surfaceNormal * 0.35, effectiveLightPos);
        }
        float lit = Intensity * atten * nightGap * facing * visibility;
        add += LightColor * lit;
        if(PointSource < 0.5) {
        add += vec3(1.0, 0.97, 0.88) * (lit * atten * atten * 0.50);

        // Original large hot centre from the backup, now only masked by the
        // receiving side and line-of-sight to the blast.
        float hotRadius = max(rad * 0.30, 5.0);
        float hot = 1.0 / (1.0 + (d / hotRadius) * (d / hotRadius));
        hot *= hot * finiteRange;
        add += vec3(1.0, 0.82, 0.42)
                * (Intensity * hot * nightGap * facing * visibility * 1.35);
        add += vec3(1.0, 0.48, 0.10)
                * (Intensity * atten * nightGap * facing * visibility * 0.34);

        // Very weak indirect orange bounce for back-facing walls. This is not
        // direct light through the building; it prevents the unlit side from
        // becoming a pasted-on black cutout against the blazing ground.
        float bounce = (1.0 - facing) * Intensity * atten * nightGap * 0.075;
        add += vec3(0.82, 0.32, 0.055) * bounce;
        }
    }

    fragColor = vec4(scene.rgb + add, scene.a);
}
