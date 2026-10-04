// SS-03, Gungnir — the machine, drawn over gungnir_space in its own frame. Three views of it:
//
// 1, the ring (Jupiter's frame, its radii): the accelerator, a thin black torus round the planet just over its cloud
//    tops, the breech a knot on it; its coils waking segment by segment from the breech round the whole planet, a white
//    head racing ahead of the ember; the ring glowing ember, whiter lap by lap; the needle a white-hot point racing round
//    it with a trail of fire; the release — a jagged muzzle flash off the breech, the needle a streak of light down the
//    line to the Earth, a ring of shock thrown off round the breech.
// 2, the track (km, at the needle: x out of the ring's plane, y out from Jupiter, z along the track): the hoops of the
//    ring, one every N6.x km, their coils, the spine they hang on, and the needle — a kilometre of black hexagonal hull,
//    its seams burning ember, four tail fins, a white-hot point — sliding into the breech and clamped there, then running
//    through the hoops: the coils ahead of it firing white, behind it cooling to ember, the hoops passing slow and then so
//    fast they smear into a tunnel of light streaks.
// 3, the flight (km, the needle at the origin running along +z): the needle, the asteroid belt's rocks whipping past it
//    in streaks, and in the air its plasma sheath — a bow shock off the point, the sheath streaming back along the hull,
//    a turbulent burning wake.
// Raymarched and lit like the rest of the film (the Sun as a key with soft self-shadow — gone while it runs through
// Jupiter's night side — the planet's light as a fill, a rim, inked outlines), in linear light, display space in and out.
//
// N0 = (tan half vertical fov, seconds, seed, view 1..3), N1 = (ring radius, ring thickness, the breech's angle, the
// needle's angle), N2 = (coils awake 0..1 round from the breech, the ring's glow, the needle's heat, laps done),
// N3 = (seconds since the release or < 0, seconds since the clamps shut or < 0, the trail's length in radians, sunlit),
// N4 = (the track's phase under the needle km, the hoop there, the hoops' smear km, the needle's place on the track km
// while loading), N5 = (the asteroid belt 0..1, how far through it km, the plasma 0..1, seconds since the entry or < 0),
// N6 = (km between hoops, spinning, loading, the flight's speed as a fraction of c). RingU/V/N = the ring's axes
// (Jupiter's frame). JupC/EarthC = the planet's centre (xyz) and radius (w) in the view's frame.

#include "star.glsl"

uniform vec3 CamPos;
uniform vec3 CamFwd;
uniform vec3 CamUp;
uniform vec3 CamRight;
uniform vec3 KeyDir;
uniform vec4 KeyCol;
uniform vec3 FillDir;
uniform vec4 FillCol;
uniform vec4 JupC;
uniform vec4 EarthC;
uniform vec3 RingU;
uniform vec3 RingV;
uniform vec3 RingN;
uniform vec4 N0;
uniform vec4 N1;
uniform vec4 N2;
uniform vec4 N3;
uniform vec4 N4;
uniform vec4 N5;
uniform vec4 N6;

#define M_HULL 1.0
#define M_FIN 2.0
#define M_HOOP 4.0
#define M_COIL 5.0
#define M_SPINE 6.0
#define M_CLAMP 7.0
#define M_ROCK 8.0
#define M_RING 9.0
#define M_BREECH 10.0

const vec3 EMBER = vec3(1.0, 0.3, 0.06);
const vec3 EMBER_HOT = vec3(1.0, 0.62, 0.3);
const vec3 WHITE_HOT = vec3(1.0, 0.94, 0.86);
const vec3 INK = vec3(0.02, 0.008, 0.01);
const float NEVER = 1e30;
const float HALF = 0.5;

float gPixel;
float gInk;
/** The ring view: how close (pixels) the ray passed to the ring's core, where round the ring, and how far along it. */
float gNearPx;
float gNearA;
float gNearT;
int gView;
float gHoop;
float gHeat;
float gBlur;

// ---------------------------------------------------------------- shapes

float sdBox(vec3 p, vec3 b) {
    vec3 q = abs(p) - b;
    return length(max(q, 0.0)) + min(max(q.x, max(q.y, q.z)), 0.0);
}

/** A hexagon of apothem r. */
float sdHex(vec2 p, float r) {
    const vec3 k = vec3(-0.866025404, 0.5, 0.577350269);
    p = abs(p);
    p -= 2.0 * min(dot(k.xy, p), 0.0) * k.xy;
    p -= vec2(clamp(p.x, -k.z * r, k.z * r), r);
    return length(p) * sign(p.y);
}

/** The needle's apothem along it (km): a long point in front, a waist, the tail. z from -0.5 (tail) to 0.5 (point). */
float needleR(float z) {
    float body = 0.018;
    if (z > 0.04) {
        float k = saturate((z - 0.04) / 0.46);
        return body * (1.0 - k) * (1.0 - 0.15 * k * (1.0 - k));
    }
    if (z < -0.42) {
        return mix(0.0135, body, saturate((z + 0.5) / 0.08));
    }
    return body * (1.0 - 0.06 * exp(-sqr((z + 0.1) / 0.05)));
}

/** The needle (km, its centre at the origin, its point along +z). */
vec2 needle(vec3 p) {
    float z = p.z;
    float r = needleR(clamp(z, -HALF, HALF));
    float d = sdHex(p.xy, r) * 0.9;
    d = max(d, abs(z) - HALF);
    vec2 res = vec2(d, M_HULL);
    // four tail fins on the hex's corners, swept: widest at the very tail
    float fz = z + HALF;
    if (fz < 0.26) {
        vec2 q = abs(p.xy);
        float span = mix(0.062, r * 0.9, smoothstep(0.0, 0.24, fz));
        float th = 0.0016;
        float plateA = max(q.y - th, q.x - span);
        float plateB = max(q.x - th, q.y - span);
        float fin = max(min(plateA, plateB), max(-fz, fz - 0.24)) * 0.85;
        if (fin < res.x) res = vec2(fin, M_FIN);
    }
    return res;
}

/** A hoop of the track (km, its centre at the origin, round the z axis), stretched along z by its motion blur. */
vec2 hoop(vec3 p) {
    float stretch = min(gBlur * 0.5, N6.x * 0.3);
    p.z = sign(p.z) * max(abs(p.z) - stretch, 0.0);
    float rr = length(p.xy);
    // the hoop: a flattened band, not a tube
    vec2 band = abs(vec2(rr - 0.07, p.z)) - vec2(0.0035, 0.009);
    vec2 res = vec2(length(max(band, 0.0)) + min(max(band.x, band.y), 0.0) - 0.0008, M_HOOP);
    // eight coil housings round it, set into the band, their faces slit where they burn
    float a = atan(p.y, p.x);
    float seg = TAU / 8.0;
    float ai = (floor(a / seg + 0.5)) * seg;
    vec2 cs = vec2(cos(ai), sin(ai));
    vec3 lp = vec3(dot(p.xy, cs) - 0.07, dot(p.xy, vec2(-cs.y, cs.x)), p.z);
    float coil = sdBox(lp, vec3(0.0065, 0.0075, 0.012)) - 0.0008;
    if (coil < res.x) res = vec2(coil, M_COIL);
    // the strut down to the spine
    float strut = sdBox(p - vec3(0.0, -0.09, 0.0), vec3(0.004, 0.018, 0.004));
    if (strut < res.x) res = vec2(strut, M_SPINE);
    return res;
}

/** The track at the needle: the hoops (the one in this cell), the spine under them, the breech's clamps. */
vec2 track(vec3 p) {
    float H = N6.x;
    float zq = p.z + N4.x;
    float cell = floor(zq / H + 0.5);
    gHoop = cell + N4.y;
    vec3 q = vec3(p.xy, zq - cell * H);
    vec2 res = hoop(q);
    // the spine the hoops hang on, running the whole way round
    vec2 sp = abs(p.xy - vec2(0.0, -0.11)) - vec2(0.012, 0.007);
    float spine = length(max(sp, 0.0)) + min(max(sp.x, sp.y), 0.0);
    if (spine < res.x) res = vec2(spine, M_SPINE);
    // at the breech: three heavy clamp rings round the needle, shutting on it
    if (N6.z > 0.5) {
        float shut = N3.y >= 0.0 ? 1.0 : 0.0;
        float ringR = mix(0.05, 0.026, shut);
        for (int i = -1; i <= 1; i++) {
            vec3 c = p - vec3(0.0, 0.0, float(i) * 0.3);
            vec2 cb = abs(vec2(length(c.xy) - ringR - 0.004, c.z)) - vec2(0.006, 0.012);
            float cl = length(max(cb, 0.0)) + min(max(cb.x, cb.y), 0.0) - 0.001;
            if (cl < res.x) res = vec2(cl, M_CLAMP);
        }
    }
    return res;
}

/** The asteroid belt round the needle's path, streaming past (km). */
vec2 rocks(vec3 p) {
    const float S = 2.4;
    vec3 q = p + vec3(0.0, 0.0, N5.y);
    vec3 cell = floor(q / S + 0.5);
    vec3 c = q - cell * S;
    float h = hash13(cell + gSeed * 13.0);
    vec2 far = vec2(S * 0.45, M_ROCK);
    if (h > 0.045 * N5.x) return far;
    vec3 off = (vec3(hash13(cell + 1.7), hash13(cell + 3.1), hash13(cell + 5.3)) - 0.5) * S * 0.55;
    // keep the needle's own path clear
    if (length(cell.xy * S + off.xy) < 0.45) return far;
    vec3 lp = c - off;
    float r = mix(0.05, 0.34, sqr(hash13(cell + 7.1)));
    lp.z = sign(lp.z) * max(abs(lp.z) - N6.w * r * 0.8, 0.0);
    float d = length(lp) - r;
    d += (vnoise3(lp / r * 2.3 + cell) - 0.5) * r * 0.5;
    return vec2(min(d * 0.7, S * 0.45), M_ROCK);
}

/** The ring round Jupiter, and the breech on it (Jupiter radii). */
vec2 ring(vec3 p, float thick) {
    vec3 q = vec3(dot(p, RingU), dot(p, RingN), dot(p, RingV));
    float R = N1.x;
    vec2 res = vec2(length(vec2(length(q.xz) - R, q.y)) - thick, M_RING);
    vec3 b = vec3(cos(N1.z), 0.0, sin(N1.z)) * R;
    vec3 er = vec3(cos(N1.z), 0.0, sin(N1.z));
    vec3 et = vec3(-sin(N1.z), 0.0, cos(N1.z));
    vec3 lp = vec3(dot(q - b, er), q.y, dot(q - b, et));
    float breech = sdBox(lp, vec3(0.006, 0.005, 0.018) + thick * 0.5);
    breech = min(breech, sdBox(lp - vec3(0.0, 0.0, 0.0), vec3(0.011, 0.0025, 0.006) + thick * 0.4));
    if (breech < res.x) res = vec2(breech, M_BREECH);
    return res;
}

vec2 scene(vec3 p) {
    if (gView == 1) {
        return ring(p, max(N1.y, 0.0));
    }
    if (gView == 2) {
        vec2 res = needle(p - vec3(0.0, 0.0, N4.w));
        vec2 tr = track(p);
        return tr.x < res.x ? tr : res;
    }
    vec2 res = needle(p);
    if (N5.x > 0.001) {
        vec2 rk = rocks(p);
        if (rk.x < res.x) res = rk;
    }
    return res;
}

// ---------------------------------------------------------------- marching

float gThick;

vec2 sceneR(vec3 p, float t) {
    if (gView == 1) {
        // a thin ring stays at least a pixel across (its light is scaled down to its true width, see below)
        return ring(p, max(N1.y, gPixel * t * 0.75));
    }
    return scene(p);
}

float inkAt(float px) {
    float w = max(1.0, OutSize.y / 640.0);
    return 1.0 - smoothstep(1.8 * w, 3.6 * w, px);
}

vec2 march(vec3 ro, vec3 rd, float tMax) {
    gInk = 0.0;
    gNearPx = NEVER;
    gNearA = 0.0;
    gNearT = NEVER;
    float t = 0.0;
    if (gView == 1) {
        vec2 hb = raySphere(ro, rd, vec3(0.0), N1.x + 0.08);
        if (hb.y <= 0.0) return vec2(-1.0, 0.0);
        t = max(hb.x, 0.0);
        tMax = min(tMax, hb.y);
    }
    float prevH = NEVER;
    float prevPx = NEVER;
    float prevT = t;
    float edgePx = NEVER;
    float edgeT = 0.0;
    float maxStep = gView == 2 ? N6.x * 0.3 : gView == 3 ? 0.9 : 1e9;
    gNearPx = NEVER;
    for (int i = 0; i < 160; i++) {
        vec2 h = sceneR(ro + rd * t, t);
        if (gView == 1) {
            vec3 pr = ro + rd * t;
            vec3 q = vec3(dot(pr, RingU), dot(pr, RingN), dot(pr, RingV));
            float core = length(vec2(length(q.xz) - N1.x, q.y)) / (gPixel * max(t, 1e-6));
            if (core < gNearPx) {
                gNearPx = core;
                gNearA = atan(q.z, q.x);
                gNearT = t;
            }
        }
        float px = h.x / (gPixel * max(t, 1e-6));
        if (h.x > prevH && prevPx < edgePx) {
            edgePx = prevPx;
            edgeT = prevT;
        }
        if (h.x < max(gPixel * t * 0.35, 1e-6)) {
            if (t - edgeT > t * 0.03 + 0.002) {
                gInk = inkAt(edgePx);
            }
            return vec2(t, h.y);
        }
        prevH = h.x;
        prevPx = px;
        prevT = t;
        t += min(h.x * 0.9, maxStep);
        if (t > tMax) break;
    }
    gInk = inkAt(min(edgePx, prevPx));
    return vec2(-1.0, 0.0);
}

vec3 normalAt(vec3 p, float t) {
    float h = max(gPixel * t * 0.5, 2e-6);
    vec2 e = vec2(1.0, -1.0) * h;
    return normalize(e.xyy * scene(p + e.xyy).x + e.yyx * scene(p + e.yyx).x
            + e.yxy * scene(p + e.yxy).x + e.xxx * scene(p + e.xxx).x);
}

float shadow(vec3 p, vec3 l) {
    float s = 1.0;
    float t = 0.002;
    for (int i = 0; i < 24; i++) {
        float h = scene(p + l * t).x;
        s = min(s, 12.0 * h / t);
        t += clamp(h, 0.002, 0.08);
        if (s < 0.01 || t > 1.5) break;
    }
    return smoothstep(0.0, 1.0, saturate(s));
}

// ---------------------------------------------------------------- how it looks

float ggx(float nh, float a) {
    float a2 = a * a;
    float d = nh * nh * (a2 - 1.0) + 1.0;
    return a2 / (PI * d * d);
}

vec3 specular(vec3 n, vec3 v, vec3 l, vec3 f0, float rough) {
    float nl = max(dot(n, l), 0.0);
    if (nl <= 0.0) return vec3(0.0);
    vec3 h = normalize(l + v);
    float nv = max(dot(n, v), 1e-3);
    float a = max(rough * rough, 0.004);
    vec3 F = f0 + (1.0 - f0) * pow(1.0 - max(dot(h, v), 0.0), 5.0);
    float k = sqr(a + 1.0) / 8.0;
    float G = nv / (nv * (1.0 - k) + k) * nl / (nl * (1.0 - k) + k);
    return F * ggx(max(dot(n, h), 0.0), a) * G / (4.0 * nv * nl + 1e-4) * nl;
}

/** What the polished black hull mirrors: the planet's light from one side, deep space from the other. */
vec3 environment(vec3 dir) {
    float toward = dot(dir, FillDir);
    vec3 col = FillCol.rgb * FillCol.a * smoothstep(-0.15, 0.7, toward) * 0.5;
    col += vec3(0.01, 0.012, 0.02);
    return col;
}

/** How brightly a hoop's coils burn: the wave that drives the needle — white just ahead of it, ember behind. */
vec3 coilLight(float zc) {
    float spin = N6.y;
    vec3 col = EMBER * 0.25;
    if (spin > 0.5) {
        float ahead = exp(-sqr((zc - 0.35) / 0.5));
        float behind = exp(-max(-zc, 0.0) / 2.5) * step(zc, 0.35);
        float heat = N2.z;
        col = EMBER * (0.3 + 0.9 * behind) + mix(EMBER_HOT, WHITE_HOT, heat * heat) * ahead * (1.6 + 3.5 * heat);
    }
    if (N6.z > 0.5 && N3.y >= 0.0) {
        col += WHITE_HOT * exp(-N3.y * 6.0) * 6.0 * exp(-abs(zc) / 0.5);
    }
    return col;
}

/** The needle's seams: down its six edges and in rings round it, ember, white where it burns. */
float seams(vec3 p) {
    float r = needleR(clamp(p.z, -HALF, HALF));
    float a = atan(p.y, p.x);
    float corner = abs(fract(a / (TAU / 6.0)) - 0.5) * (TAU / 6.0) * r;
    float edge = exp(-sqr(corner / 0.0005));
    float band = abs(fract(p.z / 0.1 + 0.5) - 0.5) * 0.1;
    float ringS = exp(-sqr(band / 0.0007)) * step(p.z, 0.3);
    return saturate(edge + ringS);
}

vec3 shadeNeedle(vec3 p, vec3 n, vec3 v, float id, vec3 key, vec3 keyCol, float sh) {
    float heat = gHeat;
    vec3 base = vec3(0.028, 0.026, 0.03);
    float rough = id == M_FIN ? 0.42 : 0.34;
    vec3 f0 = vec3(0.07, 0.068, 0.072);
    // panel lines stamped in the black, faintly
    float panel = abs(fract(p.z / 0.025) - 0.5);
    base *= 0.85 + 0.3 * step(0.47, panel);
    vec3 col = base * (keyCol * max(dot(n, key), 0.0) * sh + FillCol.rgb * FillCol.a * max(dot(n, FillDir), 0.0) * 0.5);
    col += specular(n, v, key, f0, rough) * keyCol * sh;
    col += specular(n, v, FillDir, f0, rough) * FillCol.rgb * FillCol.a * 0.5;
    vec3 r = reflect(-v, n);
    col += environment(r) * (f0 + (1.0 - f0) * pow(1.0 - max(dot(n, v), 0.0), 5.0)) * 0.45;
    // the coils it runs through light it as they fire
    if (gView == 2) {
        vec3 around = normalize(vec3(p.xy, 0.0) + 1e-6);
        float H = N6.x;
        float zq = p.z + N4.x;
        float near = zq - floor(zq / H + 0.5) * H;
        vec3 cl = coilLight(p.z - near) * exp(-sqr(near / 0.05));
        col += cl * (base * 3.0 + f0 * 0.4) * (0.35 + 0.65 * max(dot(n, around), 0.0));
    }
    // the seams burn ember, whiter as it heats; the point white-hot
    float s = id == M_FIN ? 0.0 : seams(p);
    float finEdge = id == M_FIN ? exp(-sqr((max(abs(p.x), abs(p.y)) - mix(0.062, 0.016, smoothstep(0.0, 0.24, p.z + HALF))) / 0.0015)) : 0.0;
    vec3 glowC = mix(EMBER, mix(EMBER_HOT, WHITE_HOT, saturate(heat - 0.5) * 2.0), saturate(heat * 1.3));
    col += glowC * (s + finEdge) * (0.45 + 5.0 * heat);
    float tip = smoothstep(0.18, 0.5, p.z);
    col += blackbody(0.3 + 0.9 * heat * tip) * tip * heat * heat * 9.0;
    // skin hot all over at the release and in the air
    col += blackbody(0.2 + 0.5 * heat) * saturate(heat - 0.75) * 1.6;
    return col;
}

vec3 shade(vec3 p, vec3 rd, float id, float t) {
    vec3 n = normalAt(p, t);
    vec3 v = -rd;
    vec3 key = normalize(KeyDir);
    vec3 keyCol = KeyCol.rgb * KeyCol.a;
    float sh = gView == 1 ? 1.0 : shadow(p + n * max(gPixel * t, 0.0004), key);
    if (id == M_HULL || id == M_FIN) {
        vec3 np = gView == 2 ? p - vec3(0.0, 0.0, N4.w) : p;
        return shadeNeedle(np, n, v, id, key, keyCol, sh);
    }
    if (id == M_ROCK) {
        vec3 albedo = vec3(0.2, 0.16, 0.13) * (0.6 + 0.8 * vnoise3(p * 30.0));
        float wrap = saturate((dot(n, key) + 0.35) / 1.35);
        vec3 col = albedo * (keyCol * 1.4 * wrap * sh + vec3(0.05, 0.055, 0.07));
        // lit by the needle's heat as they pass it
        col += EMBER * albedo * 4.0 * gHeat * exp(-length(p.xy) / 0.4);
        return col;
    }
    if (id == M_RING || id == M_BREECH) {
        return vec3(0.02) * keyCol * max(dot(n, key), 0.0) + specular(n, v, key, vec3(0.3), 0.3) * keyCol;
    }
    // the track: dark metal hoops, spine and clamps; the coils burning
    float H = N6.x;
    float zq = p.z + N4.x;
    float zc = floor(zq / H + 0.5) * H - N4.x;
    vec3 albedo = id == M_CLAMP ? vec3(0.022, 0.02, 0.02) : vec3(0.014, 0.014, 0.017);
    // plates riveted round the hoops, darker seams between them
    float plates = step(0.08, abs(fract(atan(p.y, p.x) / TAU * 48.0) - 0.5) * 2.0);
    albedo *= 0.7 + 0.3 * plates;
    float rough = 0.32;
    vec3 f0 = vec3(0.16, 0.15, 0.15);
    vec3 col = albedo * (keyCol * max(dot(n, key), 0.0) * sh + FillCol.rgb * FillCol.a * max(dot(n, FillDir), 0.0) * 0.15 + 0.003);
    col += specular(n, v, key, f0, rough) * keyCol * sh * 0.6;
    col += environment(reflect(-v, n)) * 0.08;
    // the coil windings showing through slits in the hoop's inner face, a dull ember at rest
    if (id == M_HOOP) {
        float inner = saturate(-dot(n, normalize(vec3(p.xy, 0.0))));
        float slits = step(0.7, fract(atan(p.y, p.x) / TAU * 96.0)) * step(abs(p.z - zc), 0.006);
        col += coilLight(zc) * slits * inner * 0.9;
    }
    if (id == M_COIL || id == M_HOOP) {
        vec3 cl = coilLight(zc);
        // the coils burn through slits in their housings' inner faces; the hoop's band carries a thin line of it
        float face;
        if (id == M_COIL) {
            float inward = saturate(-dot(n, normalize(vec3(p.xy, 0.0))));
            float slit = step(0.55, fract((p.z - zc) / 0.004));
            face = inward * (0.35 + 0.65 * slit);
        } else {
            face = exp(-sqr(abs(p.z - zc) / 0.0015)) * 0.6;
        }
        float flicker = 0.85 + 0.15 * sin(gTime * 90.0 + hash11(gHoop) * 40.0);
        col += cl * face * flicker;
    }
    if (id == M_CLAMP) {
        float ang = atan(p.y, p.x) / TAU * 12.0;
        col += EMBER * 0.7 * exp(-sqr((fract(ang) - 0.5) / 0.04));
        if (N3.y >= 0.0) {
            col += WHITE_HOT * exp(-N3.y * 8.0) * 4.0;
        }
    }
    // the needle's heat lighting the track round it
    col += blackbody(0.4 + 0.5 * gHeat) * albedo * 8.0 * gHeat * exp(-length(p - vec3(0.0, 0.0, N4.w)) / 0.08);
    return col;
}

// ---------------------------------------------------------------- the light over it

/** The streaks the coils leave at speed: eight lines of light running the length of the track, a tunnel round us. */
vec3 tunnel(vec3 ro, vec3 rd, float tLimit) {
    float speed = saturate(gBlur / (N6.x * 0.8) - 0.3);
    if (speed <= 0.001) return vec3(0.0);
    vec3 col = vec3(0.0);
    for (int i = 0; i < 16; i++) {
        float a = float(i / 2) * TAU / 8.0 + (float(i - (i / 2) * 2) - 0.5) * 0.05;
        vec3 at = vec3(cos(a) * 0.066, sin(a) * 0.066, 0.0);
        float tRay;
        float d = raySegmentDist(ro, rd, at + vec3(0.0, 0.0, -6.0), at + vec3(0.0, 0.0, 80.0), tRay);
        if (tRay > tLimit) continue;
        float w = max(0.0012, tRay * gPixel * 0.8);
        vec3 p = ro + rd * tRay;
        vec3 c = coilLight(p.z) * vec3(1.0, 0.8, 0.7);
        col += c * (exp(-d / w) * 0.25 + exp(-d / (w * 6.0)) * 0.035) * exp(-max(p.z, 0.0) / 30.0);
    }
    return col * speed;
}

/** The needle a white-hot point on the ring, its trail of fire round the ring behind it (the ring view). */
vec3 needleOnRing(vec3 ro, vec3 rd, float tLimit, float tJup) {
    if (N6.y < 0.5 && N3.x < 0.0) return vec3(0.0);
    vec3 col = vec3(0.0);
    float R = N1.x;
    float heat = N2.z;
    if (N3.x < 0.0) {
        float a = N1.w;
        vec3 p = (RingU * cos(a) + RingV * sin(a)) * R;
        float tp;
        float d = rayPointDist(ro, rd, p, tp);
        // (it rides on the ring itself: the ring's own hit must not hide it)
        float limit = min(tLimit + 0.08, tJup);
        if (tp < limit) {
            float x = d / max(tp, 1e-6) / gPixel;
            vec3 hot = mix(EMBER_HOT, WHITE_HOT, 0.4 + 0.6 * heat);
            col += hot * (exp(-sqr(x / (2.5 + 3.0 * heat))) * (6.0 + 14.0 * heat) + exp(-x / (14.0 + 20.0 * heat)) * 1.2);
            // an anamorphic streak through it
            vec3 dir = normalize(p - ro);
            vec3 off = rd - dir * dot(rd, dir);
            vec2 sq = vec2(dot(off, CamRight), dot(off, CamUp)) / gPixel;
            col += hot * exp(-abs(sq.y) / 1.2) * exp(-abs(sq.x) / (60.0 + 140.0 * heat)) * (0.6 + heat);
        }
        // the trail: a ribbon of fire along the ring behind it, where the ray passed close to the ring
        if (gNearPx < 40.0 && gNearT < limit) {
            float behind = mod(a - gNearA, TAU);
            float trail = N3.z;
            float along = exp(-behind / max(trail * 0.35, 1e-3)) * step(behind, trail);
            float width = 1.5 + 4.0 * heat;
            col += mix(EMBER, mix(EMBER_HOT, WHITE_HOT, heat), along) * along
                    * (exp(-sqr(gNearPx / width)) * (3.0 + 6.0 * heat) + exp(-gNearPx / (width * 5.0)) * 0.6);
        }
    }
    return col;
}

/** The ring lit: coils waking from the breech, the ring's glow, and where its surface was hit, its light at that spot. */
vec3 ringLight(vec3 p, float thickTrue, float thickDrawn) {
    vec3 q = vec3(dot(p, RingU), dot(p, RingN), dot(p, RingV));
    float a = atan(q.z, q.x);
    float fromBreech = mod(a - N1.z, TAU);
    float awake = N2.x * TAU;
    float lit = step(fromBreech, awake);
    // segments, and the white head racing ahead of the ember
    float seg = step(0.3, fract(fromBreech * 180.0 / PI));
    float head = exp(-sqr((fromBreech - awake) / 0.05)) * step(0.001, N2.x) * (1.0 - step(0.999, N2.x));
    vec3 col = EMBER * lit * (0.6 + 0.4 * seg) * 1.2 + WHITE_HOT * head * 12.0;
    col += blackbody(0.3 + 0.7 * N2.y) * N2.y * (0.8 + 4.0 * N2.y);
    // the breech's own lights
    col *= thickTrue / max(thickDrawn, 1e-6);
    return col;
}

/** The release: a jagged muzzle flash off the breech, the needle a streak down the line, a shock ring round the breech. */
vec3 releaseLight(vec3 ro, vec3 rd, vec2 screen, float tJup) {
    float s = N3.x;
    if (s < 0.0 || gView != 1) return vec3(0.0);
    vec3 col = vec3(0.0);
    vec3 b = (RingU * cos(N1.z) + RingV * sin(N1.z)) * N1.x;
    vec3 fly = RingU;
    // the streak: from the breech out along the line, white-hot, fading
    float len = 0.02 + s * 300.0;
    float tr;
    float d = raySegmentDist(ro, rd, b, b + fly * len, tr);
    float w = max(0.0006, tr * gPixel * 0.8);
    float fadeS = exp(-s * 3.0);
    col += (WHITE_HOT * exp(-d / w) * 8.0 + EMBER_HOT * exp(-d / (w * 8.0)) * 1.5) * fadeS;
    // the muzzle flash: a white core, jagged rays
    float tb;
    float db = rayPointDist(ro, rd, b, tb);
    if (tb < tJup) {
        vec3 bd = normalize(b - ro);
        vec3 off = rd - bd * dot(rd, bd);
        vec2 q = vec2(dot(off, CamRight), dot(off, CamUp)) / gPixel;
        float r = length(q);
        float ang = atan(q.y, q.x);
        float k = floor(ang / TAU * 22.0);
        float rayLen = (40.0 + 160.0 * hash11(k + gSeed * 7.0)) * (0.4 + 0.6 * exp(-s * 1.5));
        float wedge = exp(-sqr((fract(ang / TAU * 22.0) - 0.5) / 0.08));
        float rays = wedge * exp(-r / rayLen) * step(0.4, hash11(k * 3.3 + 1.0));
        float flash = exp(-s * 5.0);
        col += (WHITE_HOT * (exp(-r / 6.0) * 30.0 + rays * 4.0) + EMBER_HOT * exp(-r / 60.0) * 2.0) * flash;
        // the shock ring thrown off round the breech, across the line of flight
        float tp = rayPlane(ro, rd, b, fly);
        if (tp > 0.0 && tp < tJup) {
            float rr = length(ro + rd * tp - b);
            float front = 0.01 + s * 0.35;
            float ring = exp(-sqr((rr - front) / (0.004 + s * 0.03))) * exp(-s * 1.8);
            col += mix(WHITE_HOT, EMBER, saturate(s * 1.5)) * ring * 6.0;
        }
    }
    return col;
}

/** Its plasma in the air: the bow shock off the point, the sheath streaming back along the hull, the burning wake. */
vec3 plasmaLight(vec3 ro, vec3 rd, float tLimit) {
    float k = N5.z;
    if (k < 0.001 || gView != 3) return vec3(0.0);
    // bounded by a cylinder round the needle, from ahead of the point to far behind the tail
    vec2 o = ro.xy;
    vec2 d2 = rd.xy;
    float a = dot(d2, d2);
    float bb = dot(o, d2);
    float c = dot(o, o) - 0.3 * 0.3;
    float h = bb * bb - a * c;
    if (h < 0.0 || a < 1e-8) return vec3(0.0);
    h = sqrt(h);
    float t0 = max((-bb - h) / a, 0.0);
    float t1 = min((-bb + h) / a, tLimit);
    if (t1 <= t0) return vec3(0.0);
    vec3 col = vec3(0.0);
    const int STEPS = 28;
    float dt = (t1 - t0) / float(STEPS);
    float jitter = hash12(gl_FragCoord.xy + gTime);
    for (int i = 0; i < STEPS; i++) {
        vec3 p = ro + rd * (t0 + dt * (float(i) + jitter));
        float z = p.z;
        if (z > 0.6 || z < -3.0) continue;
        float r = length(p.xy);
        float nr = needleR(clamp(z, -HALF, HALF));
        // the bow shock: a paraboloid shell just off the point, opening back
        float tipz = HALF + 0.014;
        float shellR = sqrt(max(tipz - z, 0.0) * 0.016);
        float shell = exp(-sqr((r - shellR) / 0.004)) * step(z, tipz) * smoothstep(-0.9, 0.35, z);
        // the sheath hugging the hull, streaming back in threads
        float threads = 0.6 + 0.8 * vnoise3(vec3(atan(p.y, p.x) * 6.0, r * 300.0, z * 8.0 + gTime * 60.0));
        float sheath = exp(-max(r - nr, 0.0) / 0.005) * step(-HALF - 0.02, z) * step(z, HALF) * threads;
        // the wake behind the tail, widening, turbulent
        float wz = -HALF - z;
        float wakeR = 0.02 + max(wz, 0.0) * 0.07;
        float churn = vnoise3(vec3(p.xy * 35.0, z * 5.0 + gTime * 40.0));
        float wake = step(0.0, wz) * exp(-sqr(r / wakeR)) * exp(-wz / 1.1) * (0.3 + 1.2 * churn);
        vec3 hot = mix(vec3(1.0, 0.5, 0.55), WHITE_HOT, smoothstep(0.0, 0.5, z));
        col += (WHITE_HOT * shell * 8.0 + hot * sheath * 3.0 + mix(vec3(1.0, 0.35, 0.2), vec3(0.75, 0.3, 1.0), saturate(wz / 2.0)) * wake * 2.5) * dt;
    }
    return col * k * 7.0;
}

void main() {
    gTime = N0.y;
    gSeed = N0.z;
    gView = int(N0.w + 0.5);
    float tanFov = N0.x;
    gPixel = 2.0 * tanFov / OutSize.y;
    gPix = gPixel;
    gHeat = N2.z;
    gBlur = N4.z;
    vec2 ndc = texCoord * 2.0 - 1.0;
    vec2 screen = vec2(ndc.x * OutSize.x / OutSize.y, ndc.y);
    vec3 rd = normalize(CamFwd + (CamRight * screen.x + CamUp * screen.y) * tanFov);
    vec3 bg = texture(DiffuseSampler, texCoord).rgb;
    if (gView < 1) {
        fragColor = vec4(bg, 1.0);
        return;
    }
    vec3 bgLin = -log(max(1.0 - min(pow(bg, vec3(2.2)), vec3(0.999)), 1e-4)) / 1.1;
    vec3 ro = CamPos;

    // Jupiter hides the ring behind it (the ring view)
    float tJup = NEVER;
    if (gView == 1) {
        vec2 hj = raySphere(ro, rd, vec3(0.0), 1.0);
        if (hj.x > 0.0) tJup = hj.x;
    }
    float tMax = gView == 1 ? tJup : gView == 2 ? 60.0 : 40.0;
    vec2 hit = march(ro, rd, tMax);
    float tHit = hit.x > 0.0 ? hit.x : NEVER;
    vec3 col = bgLin;
    float ink = gInk;
    if (hit.x > 0.0) {
        vec3 p = ro + rd * hit.x;
        if (gView == 1) {
            // a sub-pixel ring: its colour laid over the planet by how much of the pixel it covers
            float drawn = max(N1.y, gPixel * hit.x * 0.75);
            float cover = saturate(N1.y / drawn);
            vec3 surf = shade(p, rd, hit.y, hit.x);
            col = mix(col, surf, cover * (hit.y == M_BREECH ? 1.0 : 0.95)) + ringLight(p, N1.y, drawn) * (hit.y == M_BREECH ? 0.3 : 1.0);
            if (hit.y == M_BREECH) {
                col += EMBER * 0.6 * (0.3 + N2.x) + WHITE_HOT * 2.0 * step(0.5, fract(gTime * 1.5)) * N2.x;
            }
        } else {
            col = shade(p, rd, hit.y, hit.x);
            // far down the track, the hoops fade into the planet's glare
            if (gView == 2) {
                col = mix(col, bgLin, smoothstep(12.0, 45.0, hit.x));
            }
        }
    }
    float footprint = gPixel * (hit.x > 0.0 ? hit.x : 1.0);
    if (gView != 1) {
        col = mix(col, INK, ink * (1.0 - smoothstep(0.0015, 0.006, footprint)) * 0.85);
    }
    float sky = hit.x > 0.0 ? 0.0 : 1.0;

    vec3 light = vec3(0.0);
    if (gView == 1) {
        light += needleOnRing(ro, rd, tHit, tJup) + releaseLight(ro, rd, screen, tJup);
    } else if (gView == 2) {
        light += tunnel(ro, rd, tHit);
        // the needle's own glow at speed, a halo round its hot point
        float tp;
        float d = rayPointDist(ro, rd, vec3(0.0, 0.0, N4.w + HALF), tp);
        if (tp < tHit + 0.05) {
            light += blackbody(0.5 + 0.6 * gHeat) * pointGlow(d / max(tp, 1e-6), gPixel, 3.0 + 10.0 * gHeat) * gHeat * gHeat * 3.0;
        }
    } else {
        light += plasmaLight(ro, rd, tHit);
        float tp;
        float d = rayPointDist(ro, rd, vec3(0.0, 0.0, HALF), tp);
        if (tp < tHit + 0.05) {
            float glow = gHeat * gHeat + N5.z * 2.0;
            light += blackbody(0.5 + 0.6 * gHeat) * pointGlow(d / max(tp, 1e-6), gPixel, 3.0 + 12.0 * glow) * glow * 2.0;
        }
    }
    col += light;

    col = 1.0 - exp(-col * 1.1);
    col = pow(col, vec3(1.0 / 2.2));
    fragColor = vec4(col, saturate(sky + lum(light) * 0.5));
}
