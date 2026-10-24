// SS-05 · the W-Engine — its look-dev pass (tools/preview: TesseractEngineScenarios). Not part of the film: placeholder
// backdrops for each beat and the engine from tess_engine.glsl, composited the way the notes recommend.
//
// V0 = (tan half vertical fov, seconds, mode, lod)
//      mode 0 the bulk (a galaxy floor below, lit from it), 1 over the Earth (sunlit), 2 the sky from the ground,
//      3 the drop seen from the ground by the square, 4 studio (dark, stars)
// V1 = (1 = draw with engineFar instead of trace + shade + glow, -, -, the floor's / ground's y)
// V2 = (how much the dark hull blocks the sky's light (sky modes), daylight 0..1, the Earth's radius, its centre y)
// KeyDir = toward the light (engine-local), KeyCol = its colour and strength. Everything engine-local. Display out.

#include "star.glsl"

uniform vec3 CamPos;
uniform vec3 CamFwd;
uniform vec3 CamUp;
uniform vec3 CamRight;
uniform vec3 KeyDir;
uniform vec4 KeyCol;
uniform vec4 V0;
uniform vec4 V1;
uniform vec4 V2;
uniform sampler2D MilkyTop;
uniform sampler2D EarthDay;

#include "tess_engine.glsl"

/** The bulk's floor: our universe as a sheet of galaxies, glowing, the haze of the far ones between. */
vec3 galaxyFloor(vec3 ro, vec3 rd, float pix, out float tHit) {
    tHit = 1e9;
    if (rd.y >= -1e-4) return vec3(0.0);
    float t = (V1.w - ro.y) / rd.y;
    if (t <= 0.0) return vec3(0.0);
    tHit = t;
    vec3 q = ro + rd * t;
    vec2 xz = q.xz;
    float slant = max(-rd.y, 0.04);
    float fpx = pix * t / slant;
    vec3 col = vec3(0.35, 0.42, 0.7) * 0.018 * (0.4 + fbm2(xz * 0.9)) + vec3(0.6, 0.5, 0.45) * 0.008;
    for (int layer = 0; layer < 2; layer++) {
        float cell = layer == 0 ? 0.16 : 0.07;
        vec2 id = floor(xz / cell);
        vec2 f = xz / cell - id;
        float h = hash12(id + 7.0 + float(layer) * 13.0);
        if (h > 0.55) continue;
        vec2 c = 0.3 + 0.4 * hash22(id + 3.1);
        float r = (layer == 0 ? 0.25 : 0.18) * (0.4 + 0.6 * hash12(id + 9.4));
        vec2 uv = (f - c) / r;
        if (dot(uv, uv) >= 1.0) continue;
        uv = rot(h * 40.0) * uv;
        float lod = log2(max(fpx / (2.0 * r * cell) * 2048.0, 1e-3));
        vec3 g = toLinear(textureLod(MilkyTop, uv * 0.5 + 0.5, lod).rgb);
        g *= mix(vec3(1.0, 0.82, 0.66), vec3(0.72, 0.84, 1.0), hash12(id + 1.7)) * (0.5 + 0.9 * hash12(id + 2.2));
        col += g * (layer == 0 ? 1.4 : 0.8);
    }
    return col * exp(-t * 0.04);
}

/** A placeholder Earth: the day map, lit by the key, an atmosphere round its limb. */
vec3 earth(vec3 ro, vec3 rd, float pix, out float tHit) {
    tHit = 1e9;
    vec3 c = vec3(0.0, V2.w, 0.0);
    float R = V2.z;
    vec2 hs = raySphere(ro, rd, c, R);
    vec3 col = vec3(0.0);
    float tp;
    float d = rayPointDist(ro, rd, c, tp);
    if (hs.x > 0.0) {
        tHit = hs.x;
        vec3 n = normalize(ro + rd * hs.x - c);
        vec3 tex = toLinear(textureLod(EarthDay, sphereUV(vec3(n.x, n.z, -n.y)), 0.0).rgb);
        float nl = dot(n, KeyDir);
        col = tex * KeyCol.rgb * KeyCol.a * max(nl, 0.0) * 0.8 + tex * 0.002;
        float limb = 1.0 - max(dot(n, -rd), 0.0);
        col += vec3(0.25, 0.5, 1.0) * limb * limb * smoothstep(-0.2, 0.4, nl) * KeyCol.a * 0.25;
    } else if (tp > 0.0) {
        float x = (d - R) / (R * 0.025);
        col += vec3(0.3, 0.55, 1.0) * exp(-x) * 0.25 * KeyCol.a * step(0.0, x);
    }
    return col;
}

/** The sky from the ground: day (blue, the Sun) fading to night (stars); returns its inscattered light, with what
 *  lies in space and how much of its light gets through. */
vec3 groundSky(vec3 rd, float pix, out float trans, out vec3 space) {
    float up = max(rd.y, 0.0);
    float day = V2.y;
    vec3 zen = vec3(0.07, 0.2, 0.55);
    vec3 hor = vec3(0.45, 0.6, 0.82);
    vec3 sky = mix(hor, zen, sqrt(up)) * day * 1.2;
    float mu = max(dot(rd, KeyDir), 0.0);
    sky += vec3(1.0, 0.9, 0.7) * (pow(mu, 8.0) * 0.25 + pow(mu, 600.0) * 30.0) * day;
    trans = exp(-0.12 / max(rd.y, 0.03));
    space = starField(rd, pix, 1.0) * (1.0 - day * 0.97);
    return sky;
}

/** The square and the land round it (mode 3): its 8 x 8 cells, bracketed, under the key. */
vec3 ground(vec3 ro, vec3 rd, float pix, out float tHit) {
    tHit = 1e9;
    if (rd.y >= -1e-5) return vec3(0.0);
    float t = (V1.w - ro.y) / rd.y;
    if (t <= 0.0) return vec3(0.0);
    tHit = t;
    vec3 q = ro + rd * t;
    float fpx = pix * t / max(-rd.y, 0.05);
    vec3 alb = mix(vec3(0.09, 0.16, 0.05), vec3(0.13, 0.12, 0.09), vnoise2(q.xz * 40.0));
    vec3 col = alb * KeyCol.rgb * KeyCol.a * max(KeyDir.y, 0.0) * 0.8 + alb * 0.05 * V2.y + alb * 0.01;
    if (max(abs(q.x), abs(q.z)) < 1.0) {
        vec2 g = abs(fract(q.xz * 4.0 + 0.5) - 0.5) / 4.0;
        float ln = engLine(min(g.x, g.y), 0.002, fpx);
        col += prism7(engWorldHue(q)) * ln * 0.6;
    }
    return col * exp(-t * 0.08) + vec3(0.4, 0.55, 0.8) * V2.y * 0.2 * (1.0 - exp(-t * 0.08));
}

void main() {
    float tanFov = V0.x;
    float pix = 2.0 * tanFov / OutSize.y;
    gPix = pix;
    gTime = V0.y;
    gSeed = 0.37;
    vec2 ndc = texCoord * 2.0 - 1.0;
    vec2 sc = vec2(ndc.x * OutSize.x / OutSize.y, ndc.y);
    vec3 rd = normalize(CamFwd + (CamRight * sc.x + CamUp * sc.y) * tanFov);
    vec3 ro = CamPos;
    int mode = int(V0.z + 0.5);
    vec3 keyCol = KeyCol.rgb * KeyCol.a;
    float tScene = 1e9;
    vec3 bg;
    float trans = 1.0;
    vec3 inscatter = vec3(0.0);
    vec3 space = vec3(0.0);
    bool skyMode = mode == 2 || mode == 3;
    if (mode == 0) {
        bg = galaxyFloor(ro, rd, pix, tScene) + deepField(rd, pix) * 0.12 + vec3(0.004, 0.005, 0.009);
    } else if (mode == 1) {
        bg = starField(rd, pix, 0.8) + deepField(rd, pix) * 0.25;
        float te;
        vec3 e = earth(ro, rd, pix, te);
        bg = te < 1e8 ? e : bg + e;
        tScene = te;
    } else if (skyMode) {
        inscatter = groundSky(rd, pix, trans, space);
        bg = inscatter + space * trans;
        float tg;
        vec3 gcol = ground(ro, rd, pix, tg);
        if (tg < 1e8) {
            bg = gcol;
            tScene = tg;
            trans = 1.0;
        }
    } else {
        bg = starField(rd, pix, 0.7) + vec3(0.006, 0.006, 0.01) * (0.6 + 0.4 * rd.y);
    }
    vec3 col;
    gEngDebug = int(V1.y + 0.5);
    if (skyMode) engineHaze(vec3(0.16, 0.25, 0.42) * V2.y + vec3(0.004, 0.005, 0.01), 0.22);
    if (V1.x > 0.5) {
        engineKey(KeyDir, keyCol);
        vec4 far = engineFar(ro, rd, tScene, pix);
        if (skyMode && tScene > 1e8) {
            // as tess_sky composites it: the air between dims its light toward the horizon
            float air = exp(-0.1 / max(rd.y, 0.02));
            col = bg * (1.0 - far.a * air * V2.x) + far.rgb * air;
        } else {
            col = bg * (1.0 - far.a) + far.rgb;
        }
    } else {
        EngHit h = engineTrace(ro, rd, tScene, V0.w);
        col = h.t > 0.0 ? engineShade(h, ro, rd, KeyDir, keyCol, pix) : bg;
        col += engineGlow(ro, rd, h.t > 0.0 ? h.t : tScene, pix);
    }
    col = max(col, vec3(0.0));
    if (col.r != col.r || col.g != col.g || col.b != col.b) col = vec3(1.0, 0.0, 1.0);
    col = 1.0 - exp(-col * 1.1);
    col = pow(col, vec3(1.0 / 2.2));
    fragColor = vec4(col, 1.0);
}
