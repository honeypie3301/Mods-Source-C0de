#version 150

// Kh-59M Tube-2A: day B&W cubes; dusk snow ramps in; night full static.
// SkyLight 1 = noon, 0 = midnight (world clock).

uniform sampler2D DiffuseSampler;
uniform vec2 OutSize;
uniform float Time;
uniform float SkyLight;
uniform float BlockLight;
uniform float Flash;

in vec2 texCoord;
out vec4 fragColor;

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

float luma(vec3 c) {
    return dot(c, vec3(0.299, 0.587, 0.114));
}

float chromaY(vec3 c) {
    float y = luma(c);
    float chroma = max(c.r, max(c.g, c.b)) - min(c.r, min(c.g, c.b));
    return clamp(y + chroma * 0.35, 0.0, 1.0);
}

float sampleY(vec2 uv) {
    return chromaY(texture(DiffuseSampler, uv).rgb);
}

float softY(vec2 uv) {
    vec2 t = 1.0 / max(OutSize, vec2(1.0));
    return (
        sampleY(uv) * 2.0 +
        sampleY(uv + vec2(t.x, 0.0)) +
        sampleY(uv - vec2(t.x, 0.0)) +
        sampleY(uv + vec2(0.0, t.y)) +
        sampleY(uv - vec2(0.0, t.y)) +
        sampleY(uv + t * 0.7) +
        sampleY(uv - t * 0.7) +
        sampleY(uv + vec2(t.x, -t.y) * 0.7) +
        sampleY(uv + vec2(-t.x, t.y) * 0.7)
    ) / 10.0;
}

float edgeY(vec2 uv) {
    vec2 t = 1.0 / max(OutSize, vec2(1.0));
    float n = sampleY(uv + vec2(0.0, -t.y));
    float s = sampleY(uv + vec2(0.0, t.y));
    float e = sampleY(uv + vec2(t.x, 0.0));
    float w = sampleY(uv + vec2(-t.x, 0.0));
    float gx = e - w;
    float gy = n - s;
    return sqrt(gx * gx + gy * gy);
}

float fineEdgeY(vec2 uv) {
    vec2 t = 0.5 / max(OutSize, vec2(1.0));
    float n = sampleY(uv + vec2(0.0, -t.y));
    float s = sampleY(uv + vec2(0.0, t.y));
    float e = sampleY(uv + vec2(t.x, 0.0));
    float w = sampleY(uv + vec2(-t.x, 0.0));
    float gx = e - w;
    float gy = n - s;
    return sqrt(gx * gx + gy * gy);
}

void main() {
    vec2 uv = texCoord;

    float day = clamp(SkyLight, 0.0, 1.0);
    // Full snow below ~0.22; ramps in from ~0.65 (dusk). Noon stays clean.
    float nightAmt = 1.0 - smoothstep(0.20, 0.62, day);

    vec2 jitter = (vec2(
        hash(vec2(Time * 17.0, uv.y * 97.0)),
        hash(vec2(uv.x * 83.0, Time * 23.0))
    ) - 0.5) * (1.15 / max(OutSize, vec2(1.0)));
    vec2 sampleUv = uv + jitter * mix(0.35, 1.0, 1.0 - nightAmt * 0.5);

    vec3 rgb = texture(DiffuseSampler, sampleUv).rgb;
    float rawY = chromaY(rgb);
    float blurY = softY(sampleUv);
    float edge = edgeY(sampleUv);
    bool isSky = rawY > 0.70;

    float y = clamp(rawY * 1.12, 0.0, 1.0);
    y = (y - 0.5) * 1.32 + 0.5;
    y += (rawY - blurY) * 3.55;
    if (!isSky) {
        y += edge * 0.92 + fineEdgeY(sampleUv) * 0.36;
        y = min(y, 0.78);
        y = max(y, 0.11);
        if (rawY < 0.03) {
            y = max(y, 0.11);
        }
    } else {
        y = clamp(mix(0.52, 0.88, rawY), 0.0, 0.88);
    }
    float dayG = clamp(y, 0.0, 1.0);
    dayG += (hash(uv * OutSize + Time * 53.0) - 0.5) * mix(0.038, 0.012, nightAmt);

    float snowA = hash(uv * OutSize + Time * 61.0);
    float snowB = hash(uv * OutSize * 1.73 + Time * 29.0);
    float snowC = hash(floor(uv * OutSize * 0.45) + floor(Time * 22.0));
    float boil = mix(step(0.50, snowA), step(0.46, snowB), 0.5);
    boil = mix(boil, step(0.50, snowC), 0.30);
    float flicker = 0.78 + 0.22 * hash(vec2(Time * 17.0, floor(uv.y * OutSize.y)));
    float nightG = mix(0.02, 1.0, boil) * flicker;
    float emitter = smoothstep(0.58, 0.82, rawY);
    nightG = mix(nightG, clamp(0.50 + rawY * 0.60, 0.0, 1.0), emitter * (0.55 + 0.45 * blurY));

    float g = mix(dayG, nightG, nightAmt);

    float flash = clamp(Flash, 0.0, 1.0);
    g = mix(g, 1.0, flash * 0.90);

    float scan = 0.972 + 0.028 * sin(uv.y * OutSize.y * 3.14159 + Time * 8.0);
    g *= mix(scan, 0.988 + 0.012 * sin(uv.y * OutSize.y * 2.5 + Time * 5.0), 1.0 - nightAmt);

    float band = abs(fract(uv.y * 0.85 + Time * 0.07) - 0.5);
    g *= 1.0 - (1.0 - smoothstep(0.02, 0.06, band)) * mix(0.04, 0.12, nightAmt);

    vec2 vc = uv * 2.0 - 1.0;
    float vig = 1.0 - dot(vc, vc) * mix(0.16, 0.28, nightAmt);
    g *= clamp(vig, 0.58, 1.0);

    g = floor(clamp(g, 0.0, 1.0) * 255.0 + 0.5) / 255.0;
    fragColor = vec4(vec3(g), 1.0);
}
