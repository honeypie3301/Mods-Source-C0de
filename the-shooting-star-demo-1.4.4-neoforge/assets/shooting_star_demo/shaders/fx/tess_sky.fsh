// SS-05, Tesseract — the sky over the square, as everyone sees it. A wormhole's mouth opens high over the target: a disc
// thousands of kilometres across ringed by an Einstein ring in the spectrum, the sky round it bent, and through it the
// funnel seen from its throat — the rainbow embedding grid of another universe's floor rising away, its galaxies
// streaking. Out of it comes the W-Engine (tess_engine.glsl, engineFar): a Kardashev III machine of tesseracts so big
// its frames run from horizon to horizon, its beams seen through the air. The sky dims under it (in the shader: the
// world's clock is never touched). Then it folds through the fourth dimension and falls, shrinking, onto the square —
// where the cage it became takes over (tess_world). Camera-relative world space, blocks.
//
// S0 = (seconds, the sky dimmed 0..1, the engine shown, the mouth's flash), MouthC = the mouth's middle from the camera,
// its radius (it faces straight down). EngC = the engine's core from the camera, w = blocks per engine unit; EngX/Y/Z =
// its axes. KeyDir/KeyCol = the light on it.

#include "star.glsl"

uniform sampler2D MilkyTop;
uniform vec4 S0;
uniform vec4 MouthC;
uniform vec4 EngC;
uniform vec3 EngX;
uniform vec3 EngY;
uniform vec3 EngZ;
uniform vec3 KeyDir;
uniform vec3 KeyCol;

#include "tess_engine.glsl"

const float NEVER_T = 1e30;

/** Looking up the funnel from its throat: the grid of the other universe's floor rising away, in the spectrum. */
vec3 throatView(vec2 q, float R) {
    float r = length(q) / R;
    float ang = atan(q.y, q.x);
    // depth up the funnel: the rim of the mouth is the throat, its middle the far end
    float depth = -log(max(r, 1e-3));
    float rings = abs(fract(depth * 2.2 - gTime * 0.35) - 0.5);
    float spokes = abs(fract(ang / TAU * 24.0) - 0.5) / max(r, 0.05);
    float w = 0.04 + 0.02 * depth;
    float grid = exp(-sqr(rings / w)) + exp(-sqr(spokes / 0.08)) * 0.7;
    vec3 col = vec3(0.01, 0.01, 0.016);
    col += vec3(0.9, 0.93, 1.0) * grid * exp(-depth * 0.35) * 0.7;
    // the galaxies of its walls, drawn out into streaks
    vec2 cell = vec2(floor(depth * 9.0), floor(ang / TAU * 140.0));
    float h = hash12(cell);
    if (h < 0.18) {
        float a0 = (cell.y + 0.5) / 140.0 * TAU;
        float da = abs(ang - a0) * 140.0 / TAU;
        col += mix(vec3(0.7, 0.8, 1.0), vec3(1.0, 0.85, 0.65), hash12(cell + 3.0)) * exp(-sqr(da / 0.12)) * 0.6
                * exp(-depth * 0.25);
    }
    // far up it, the white of the other side
    col += vec3(0.85, 0.8, 1.0) * exp(-r / 0.05) * 1.5;
    return col;
}

void main() {
    initPixel(texCoord);
    gTime = S0.x;
    gSeed = 0.37;
    vec3 rd = viewDir(texCoord);
    vec3 surf = scenePosAt(texCoord);
    bool sky = skyAt(texCoord);
    float sceneT = sky ? NEVER_T : length(surf);
    float up = smoothstep(-0.08, 0.35, rd.y);

    // ---- the mouth: the sky round it bent outward, the funnel through it, the ring at its rim
    vec3 base = sampleScene(texCoord);
    float R = MouthC.w;
    bool through = false;
    float tMouth = rd.y > 1e-4 ? MouthC.y / rd.y : -1.0;
    vec3 glow = vec3(0.0);
    if (R > 1.0 && tMouth > 0.0 && tMouth < sceneT) {
        vec3 q = rd * tMouth - MouthC.xyz;
        float r = length(q.xz);
        float ang = atan(q.z, q.x);
        if (r < R) {
            through = true;
            base = throatView(q.xz, R);
        } else if (sky && r < R * 1.8) {
            // the lens: the sky just outside it pushed outward
            vec3 p = rd * tMouth + vec3(q.x, 0.0, q.z) / max(r, 1.0) * R * 0.22 * sqr(R / r);
            vec3 s = project(p);
            if (s.z > 0.0) base = sampleScene(s.xy);
        }
        // the Einstein ring: a thin white ring of lensed starlight round it, a fainter second one, a soft halo
        float x = (r - R * 1.03) / max(R * 0.008, gPix * tMouth * 1.5);
        float x2 = (r - R * 1.09) / max(R * 0.006, gPix * tMouth * 1.5);
        float arcs = 0.75 + 0.25 * vnoise2(vec2(ang * 40.0, gTime * 0.2));
        glow += vec3(0.95, 0.97, 1.0) * (exp(-x * x) * 2.0 * arcs + exp(-x2 * x2) * 0.4 + exp(-abs(r - R) / (R * 0.1)) * 0.2)
                + vec3(1.0) * S0.w * exp(-abs(r - R) / (R * 0.4)) * 2.0;
    }

    // ---- the sky dimmed under it: cooled, darkened, the stars showing
    if (sky && S0.y > 0.001 && !through) {
        base = mix(base, base * vec3(0.32, 0.3, 0.48) + vec3(0.003, 0.002, 0.012), S0.y * (0.55 + 0.4 * up));
        glow += starField(rd, gPix, 0.6) * S0.y * up;
    }

    // ---- the engine, through the air
    if (S0.z > 0.5) {
        vec3 lro = vec3(dot(-EngC.xyz, EngX), dot(-EngC.xyz, EngY), dot(-EngC.xyz, EngZ)) / EngC.w;
        vec3 lrd = vec3(dot(rd, EngX), dot(rd, EngY), dot(rd, EngZ));
        vec2 bound = raySphere(lro, lrd, vec3(0.0), 2.1);
        if (bound.y > 0.0) {
            float tMax = min(sceneT / EngC.w, bound.y);
            // the part still on the far side of the mouth is seen only through it
            if (R > 1.0 && !through && tMouth > 0.0) tMax = min(tMax, tMouth / EngC.w);
            if (tMax > max(bound.x, 0.0)) {
                // its sunlight and rim; the dimmed sky behind it as the haze that sells its size
                engineKey(normalize(vec3(dot(KeyDir, EngX), dot(KeyDir, EngY), dot(KeyDir, EngZ))), KeyCol);
                engineHaze(base * 0.9, 0.2);
                vec4 far = engineFar(lro, lrd, tMax, gPix);
                // the air between: its light dims toward the horizon (what it hides is the sky's light, already there)
                float air = exp(-0.1 / max(rd.y, 0.02)) * (sky ? 1.0 : 0.85);
                base = base * (1.0 - far.a * air * 0.9) + far.rgb * air;
            }
        }
    }

    fragColor = vec4(base + glow, 1.0);
}
