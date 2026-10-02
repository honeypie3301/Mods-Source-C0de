// The Shooting Star — the gun. SS-01 hangs in the dark just past the Milky Way's rim, some 32 units long in its own
// frame, its muzzle down -Z along the laser toward the Sun inside the galaxy. A railgun the size of a world: an
// octagonal barrel between two machined rails, seventeen accelerator coils (every fourth a heavy clamped housing), a
// lattice spine over and under it, six focusing prongs round the muzzle, a hexagonal receiver carrying the bridge and
// two capacitor banks, a gold-wrapped reactor in a ring and a cage, four slatted radiators in an X, thrusters at the
// back. Raymarched and lit physically: the galaxy's heart as the key light with soft self-shadows, the disc as a broad
// fill, ambient occlusion, a traced bounce for reflections (the gun in its own polished metal, the galaxy in all of it),
// and the gun's own lights — the tiny charge, the muzzle flash, the beam — lighting it too.
//
// CamPos/Fwd/Up/Right = the camera in the gun's frame. GunX/Y/Z = the gun's axes in the shared ones (the sky is drawn
// in those, matching star_space). CentreRel, SunRelG = the galactic centre and the Sun from the gun (thousands of
// light years). S0 = (tan half vertical fov, seconds, seed, implosion 0..1), S1 = (charge 0..1 — its first half a red
// wave down the coils breech to muzzle, its second arcs and motes falling into the tiny point — seconds since the shot
// or < 0, reveal 0..1, awake 0..1). Alpha out marks what the star_rays pass may cast shafts from: 1 sky and light, 0 the gun.

#include "star.glsl"

uniform sampler2D MilkyTop;
uniform vec3 CamPos;
uniform vec3 CamFwd;
uniform vec3 CamUp;
uniform vec3 CamRight;
uniform vec3 GunX;
uniform vec3 GunY;
uniform vec3 GunZ;
uniform vec3 CentreRel;
uniform vec3 SunRelG;
uniform vec3 GalaxyN;
uniform vec3 ToCentre;
uniform vec4 S0;
uniform vec4 S1;

#define M_HULL 1.0
#define M_METAL 2.0
#define M_DARK 3.0
#define M_RAD 4.0
#define M_GOLD 5.0
#define M_LENS 6.0
#define M_BRIDGE 7.0
#define M_NAV 8.0
#define M_COIL 10.0

const int COILS = 17;
const float COIL_Z0 = -14.5;
const float COIL_STEP = 1.05;
/** Where the tiny charge gathers: between the prongs, in front of the emitter. */
const float CHARGE_Z = -17.4;
const float MUZZLE_Z = -19.2;

float gPixel;
float gCharge;
float gFired;
float gRecoil;
float gAwake;
float gFlash;
/** Secondary rays (shadows, occlusion, reflections) see the gun without its small greebles: same big shapes, less work. */
bool gLite = false;
float gWave;     // how far the charge's wave has run down the barrel, 0 at the breech .. 1 at the muzzle
float gImplode;  // everything sucked into the point before the shot
vec3 gKey;       // toward the galaxy's heart, in the gun's frame
vec3 gDisc;      // toward the bulk of the disc below it
vec3 gCentreW;   // the galactic centre from the gun, shared axes

// ---------------------------------------------------------------- frames

vec3 toShared(vec3 v) {
    return GunX * v.x + GunY * v.y + GunZ * v.z;
}

vec3 toGun(vec3 v) {
    return vec3(dot(v, GunX), dot(v, GunY), dot(v, GunZ));
}

// ---------------------------------------------------------------- shapes

float sdBox(vec3 p, vec3 b) {
    vec3 q = abs(p) - b;
    return length(max(q, 0.0)) + min(max(q.x, max(q.y, q.z)), 0.0);
}

float sdRBox(vec3 p, vec3 b, float r) {
    vec3 q = abs(p) - b + r;
    return length(max(q, 0.0)) + min(max(q.x, max(q.y, q.z)), 0.0) - r;
}

float sdOct(vec2 p, float r) {
    const vec3 k = vec3(-0.9238795325, 0.3826834323, 0.4142135623);
    p = abs(p);
    p -= 2.0 * min(dot(vec2(k.x, k.y), p), 0.0) * vec2(k.x, k.y);
    p -= 2.0 * min(dot(vec2(-k.x, k.y), p), 0.0) * vec2(-k.x, k.y);
    p -= vec2(clamp(p.x, -k.z * r, k.z * r), r);
    return length(p) * sign(p.y);
}

float sdHex(vec2 p, float r) {
    const vec3 k = vec3(-0.866025404, 0.5, 0.577350269);
    p = abs(p);
    p -= 2.0 * min(dot(k.xy, p), 0.0) * k.xy;
    p -= vec2(clamp(p.x, -k.z * r, k.z * r), r);
    return length(p) * sign(p.y);
}

float sdCylZ(vec3 p, float r, float h) {
    vec2 d = vec2(length(p.xy) - r, abs(p.z) - h);
    return min(max(d.x, d.y), 0.0) + length(max(d, 0.0));
}

float sdTorusZ(vec3 p, float R, float r) {
    return length(vec2(length(p.xy) - R, p.z)) - r;
}

vec2 opU(vec2 a, vec2 b) {
    return a.x < b.x ? a : b;
}

/** p.xy folded into the sector of `count` round the z axis that holds it, turned to lie along +x. */
vec2 sector(vec2 p, float count, float offset, out float id) {
    float step1 = TAU / count;
    id = floor((atan(p.y, p.x) - offset) / step1 + 0.5);
    return rot(id * step1 + offset) * p;
}

// ---------------------------------------------------------------- the gun

/** p.xy folded onto the diagonal of its quadrant, lying along +x: the same as sector(p, 4, PI/4) for symmetric shapes. */
vec2 foldDiagonal(vec2 p) {
    vec2 q = abs(p);
    return vec2(q.x + q.y, abs(q.x - q.y)) * 0.70710678;
}

/** One accelerator coil k (0 at the muzzle): an octagonal ring on four spokes; every fourth a clamped heavy housing. */
vec2 coil(vec3 p, float k) {
    vec3 cp = vec3(p.xy, p.z - (COIL_Z0 + k * COIL_STEP));
    if (abs(cp.z) > 0.9) return vec2(abs(cp.z) - 0.4, 0.0);
    float heavy = mod(k, 4.0) < 0.5 ? 1.0 : 0.0;
    float outer = mix(1.38, 1.62, heavy);
    float th = mix(0.11, 0.24, heavy);
    float ring = max(max(sdOct(cp.xy, outer), -sdOct(cp.xy, 1.0)), abs(cp.z) - th) - 0.02;
    vec2 res = vec2(ring, M_COIL + k);
    vec2 diag = foldDiagonal(cp.xy);
    if (!gLite) {
        float spoke = sdBox(vec3(diag.x - 0.98, diag.y, cp.z), vec3(0.14, 0.07, th * 0.6));
        res = opU(res, vec2(spoke, M_METAL));
    }
    if (heavy > 0.5) {
        // eight clamps: four on the axes, four on the diagonals (folded by symmetry, no angles needed)
        vec2 ax = abs(cp.xy);
        ax = ax.x > ax.y ? ax : ax.yx;
        float clamp8 = min(sdRBox(vec3(ax.x - outer - 0.08, ax.y, cp.z), vec3(0.16, 0.2, th + 0.07), 0.03),
                sdRBox(vec3(diag.x - outer - 0.08, diag.y, cp.z), vec3(0.16, 0.2, th + 0.07), 0.03));
        if (!gLite) {
            clamp8 = min(clamp8, min(sdCylZ(vec3(ax.x - outer - 0.1, ax.y, cp.z), 0.07, th + 0.16),
                    sdCylZ(vec3(diag.x - outer - 0.1, diag.y, cp.z), 0.07, th + 0.16)));
        }
        res = opU(res, vec2(clamp8, M_METAL));
    }
    return res;
}

vec2 barrel(vec3 p) {
    vec2 res = vec2(1e5, 0.0);
    // the octagonal core, chamfered at its ends
    float core = max(sdOct(p.xy, 0.66), abs(p.z + 6.3) - 9.6) - 0.02;
    res = opU(res, vec2(core, M_HULL));
    // twin rails, machined, a groove down their backs
    vec3 q = vec3(p.x, abs(p.y), p.z);
    float rail = sdRBox(q - vec3(0.0, 0.8, -6.55), vec3(0.3, 0.16, 9.95), 0.035);
    if (!gLite) {
        rail = max(rail, -sdBox(q - vec3(0.0, 0.97, -6.55), vec3(0.055, 0.045, 9.8)));
    }
    res = opU(res, vec2(rail, M_METAL));
    vec3 s = vec3(abs(p.x), p.y, p.z);
    float r = length(p.xy);
    if (!gLite && r < 1.7) {
        // insulator blocks down the flanks between the coils
        float zc = mod(p.z - COIL_Z0 + COIL_STEP * 0.5, COIL_STEP) - COIL_STEP * 0.5;
        float block = sdRBox(vec3(s.x - 0.7, s.y, abs(zc) - 0.36), vec3(0.08, 0.36, 0.13), 0.02);
        block = max(block, abs(p.z + 6.1) - 9.3);
        res = opU(res, vec2(block, M_DARK));
        // conduits along the flanks, threaded through the heavy housings
        vec2 c = vec2(s.x - 1.5, abs(p.y) - 0.52);
        float conduit = max(length(c) - 0.075, abs(p.z + 5.8) - 9.2);
        res = opU(res, vec2(conduit, M_DARK));
    } else if (!gLite) {
        res.x = min(res.x, r - 1.62);
    }
    // the coils (nothing of them lies inside r 0.84 or outside r 1.95): the nearest two, since the heavy housings
    // reach past their neighbours' cells
    if (r > 0.78 && r < 2.0) {
        float kf = (p.z - COIL_Z0) / COIL_STEP;
        float k0 = clamp(floor(kf + 0.5), 0.0, float(COILS - 1));
        res = opU(res, coil(p, k0));
        // the neighbour can only be nearer where its heavy housing (0.31 half thick) comes within reach
        float k1 = clamp(k0 + (kf > k0 ? 1.0 : -1.0), 0.0, float(COILS - 1));
        float reach = abs(p.z - (COIL_Z0 + k1 * COIL_STEP)) - 0.32;
        if (!gLite && k1 != k0 && reach < res.x) {
            res = opU(res, coil(p, k1));
        }
    } else {
        res.x = min(res.x, r < 0.78 ? 0.82 - r : r - 1.97);
    }
    // the lattice spine over and under the coils (nothing of it below |y| 1.36): two chords and an apex, a V of
    // diagonals in every bay
    if (abs(p.y) < 1.3) {
        return vec2(min(res.x, 1.34 - abs(p.y)), res.x < 1.34 - abs(p.y) ? res.y : 0.0);
    }
    vec3 t = vec3(abs(p.x), abs(p.y), p.z);
    float span = abs(p.z + 6.1) - 9.1;
    float chord = min(length(t.xy - vec2(0.55, 1.95)), length(vec2(p.x, t.y - 2.55))) - 0.07;
    float cz = mod(p.z - COIL_Z0 + COIL_STEP * 0.5, COIL_STEP) - COIL_STEP * 0.5;
    float diag = sdCapsule(vec3(t.x, t.y, abs(cz)), vec3(0.0, 2.55, 0.0), vec3(0.55, 1.95, COIL_STEP * 0.5), 0.042);
    float truss = min(chord, diag);
    if (!gLite) {
        float cross1 = sdCapsule(vec3(t.x, t.y, cz), vec3(0.0, 1.95, 0.0), vec3(0.55, 1.95, 0.0), 0.04);
        float post = sdBox(vec3(t.x - 0.55, t.y - 1.66, cz), vec3(0.05, 0.3, 0.05));
        truss = min(truss, min(cross1, post));
    }
    truss = max(truss, span);
    res = opU(res, vec2(truss, M_DARK));
    return res;
}

vec2 muzzle(vec3 p) {
    vec2 res = vec2(1e5, 0.0);
    // a heavy vented collar
    float collar = max(max(sdOct(p.xy, 1.55), -sdOct(p.xy, 0.62)), abs(p.z + 16.1) - 0.45) - 0.03;
    float id;
    // one angle for all its radial details: each is laid out in (radius, arc length) round its own sector
    float ang = atan(p.y, p.x);
    float rad = length(p.xy);
    if (!gLite) {
        float a16 = ang - floor(ang / (TAU / 16.0) + 0.5) * (TAU / 16.0);
        vec2 vp = vec2(rad, rad * a16);
        float vents = sdBox(vec3(vp.x - 1.5, vp.y, p.z + 16.1), vec3(0.22, 0.09, 0.3));
        collar = max(collar, -vents);
        // its face stepped down into the throat in three rings, radial fins between them
        collar = max(collar, -max(sdOct(p.xy, 1.3), -(p.z + 16.45)));
        float step1 = max(max(sdOct(p.xy, 1.3), -sdOct(p.xy, 0.62)), abs(p.z + 16.35) - 0.1) - 0.015;
        float a24 = ang - floor(ang / (TAU / 24.0) + 0.5) * (TAU / 24.0);
        vec2 fp = vec2(rad, rad * a24);
        float fins = max(sdBox(vec3(fp.x - 0.95, fp.y, p.z + 16.48), vec3(0.32, 0.018, 0.06)), -p.z - 16.6);
        res = opU(res, vec2(min(step1, fins), M_DARK));
        // the emitter, sunk in the collar's throat
        res = opU(res, vec2(sdCylZ(p - vec3(0.0, 0.0, -15.75), 0.6, 0.05), M_LENS));
    }
    res = opU(res, vec2(collar, M_HULL));
    // six focusing prongs, drawing in toward the tips
    float a6 = ang - PI / 6.0 - floor((ang - PI / 6.0) / (TAU / 6.0) + 0.5) * (TAU / 6.0);
    vec2 pp = rad * vec2(cos(a6), sin(a6));
    float along = saturate((-p.z - 16.4) / 2.8);
    float rr = mix(1.08, 0.66, along * along);
    float w = mix(0.17, 0.07, along);
    float prong = sdRBox(vec3(pp.x - rr, pp.y, p.z + 17.8), vec3(w, mix(0.13, 0.05, along), 1.4), 0.025) * 0.8;
    res = opU(res, vec2(prong, M_METAL));
    // and a thin ring held at their tips, where the charge is focused
    res = opU(res, vec2(sdTorusZ(p - vec3(0.0, 0.0, MUZZLE_Z + 0.1), 0.7, 0.05), M_METAL));
    return res;
}

vec2 body(vec3 p) {
    vec2 res = vec2(1e5, 0.0);
    // the flange where the barrel meets the receiver
    float flange = max(max(sdOct(p.xy, 1.5), -sdOct(p.xy, 0.5)), abs(p.z - 3.35) - 0.2) - 0.02;
    res = opU(res, vec2(flange, M_METAL));
    // the receiver: a hexagonal block, a raised band round it
    float hex = max(sdHex(p.xy, 1.9), abs(p.z - 5.75) - 2.4) - 0.08;
    float band = max(sdHex(p.xy, 2.0), abs(p.z - 6.9) - 0.18) - 0.02;
    if (!gLite) {
        hex = max(hex, -max(sdHex(p.xy, 1.86), abs(p.z - 4.6) - 0.03));
    }
    res = opU(res, vec2(min(hex, band), M_HULL));
    // the bridge on its back, two masts
    float bridge = sdRBox(p - vec3(0.0, 2.3, 5.1), vec3(0.72, 0.48, 1.35), 0.14);
    res = opU(res, vec2(bridge, M_BRIDGE));
    if (!gLite) {
        float masts = min(sdCapsule(p, vec3(0.35, 2.7, 4.4), vec3(0.35, 4.1, 4.4), 0.03),
                sdCapsule(p, vec3(-0.4, 2.7, 5.9), vec3(-0.4, 3.5, 5.9), 0.025));
        res = opU(res, vec2(masts, M_DARK));
    }
    // capacitor banks on both flanks: three ribbed cylinders each, in a frame
    vec3 c = vec3(abs(p.x) - 2.55, p.y - clamp(floor(p.y / 0.74 + 0.5), -1.0, 1.0) * 0.74, p.z - 5.6);
    float cap = sdCylZ(c, 0.3, 2.05);
    if (!gLite) {
        float rib = sdCylZ(vec3(c.xy, mod(c.z + 0.18, 0.36) - 0.18), 0.335, 0.045);
        cap = min(cap, max(rib, abs(c.z) - 1.9));
        float frame1 = sdBox(vec3(abs(p.x) - 2.3, p.y, abs(p.z - 5.6) - 2.1), vec3(0.42, 1.15, 0.07));
        res = opU(res, vec2(frame1, M_DARK));
    }
    res = opU(res, vec2(cap, M_METAL));
    // the reactor: a gold-wrapped core in a ring, in a cage of six struts
    vec3 r = p - vec3(0.0, 0.0, 10.0);
    res = opU(res, vec2(length(r) - 1.05, M_GOLD));
    res = opU(res, vec2(sdTorusZ(r, 1.75, 0.42), M_METAL));
    float id;
    vec2 sp = sector(p.xy, 6.0, 0.0, id);
    float strut = max(length(vec2(sp.x - 2.35, sp.y)) - 0.1, abs(p.z - 10.0) - 1.85);
    float arm = sdCapsule(vec3(sp, p.z), vec3(1.2, 0.0, 10.0), vec3(2.35, 0.0, 10.0), 0.06);
    res = opU(res, vec2(min(strut, arm), M_DARK));
    // the back plate, four thrusters in it
    float plate = max(sdOct(p.xy, 2.2), abs(p.z - 12.0) - 0.22) - 0.04;
    res = opU(res, vec2(plate, M_HULL));
    if (!gLite) {
        vec3 n = vec3(abs(p.xy) - vec2(1.3), p.z);
        float bell = sdRoundCone(n, vec3(0.0, 0.0, 12.2), vec3(0.0, 0.0, 12.85), 0.22, 0.4);
        bell = max(bell, -sdCylZ(n - vec3(0.0, 0.0, 12.95), 0.33, 0.28));
        res = opU(res, vec2(bell, M_DARK));
    }
    return res;
}

/** Four slatted radiators in an X: a frame, thin slats with gaps between (the galaxy's light comes through), struts. */
vec2 radiators(vec3 p) {
    vec2 rp = foldDiagonal(p.xy);
    vec3 q = vec3(rp.x - 5.15, rp.y, p.z - 8.1);
    float outer = sdBox(q, vec3(2.5, 0.05, 3.5));
    float frame1 = max(outer, -sdBox(q, vec3(2.36, 1.0, 3.36)));
    float zc = mod(q.z + 0.25, 0.5) - 0.25;
    float slat = max(sdBox(vec3(q.x, q.y, zc), vec3(2.4, 0.025, 0.17)), abs(q.z) - 3.4);
    float spine = sdBox(q, vec3(0.06, 0.06, 3.45));
    vec2 res = vec2(min(frame1, spine), M_DARK);
    res = opU(res, vec2(slat, M_RAD));
    float strut = min(sdCapsule(vec3(rp, p.z), vec3(1.7, 0.0, 6.2), vec3(2.8, 0.0, 6.2), 0.07),
            sdCapsule(vec3(rp, p.z), vec3(2.0, 0.0, 10.0), vec3(2.8, 0.0, 10.0), 0.07));
    res = opU(res, vec2(strut, M_DARK));
    // running lights at the outer corners
    if (!gLite) {
        vec3 nav = vec3(rp.x - 7.68, rp.y, abs(p.z - 8.1) - 3.5);
        res = opU(res, vec2(length(nav) - 0.1, M_NAV + 0.01));
    }
    return res;
}

/** The gun: distance and material. */
vec2 gun(vec3 p) {
    p.z -= gRecoil;
    float bound = sdBox(p - vec3(0.0, 0.0, -3.1), vec3(7.9, 7.9, 16.3));
    if (bound > 1.0) return vec2(bound, 0.0);
    vec2 res = vec2(1e5, 0.0);
    float b = sdBox(p - vec3(0.0, 0.0, -6.2), vec3(2.8, 2.8, 9.9));
    res = opU(res, b > 0.6 ? vec2(b, 0.0) : barrel(p));
    b = sdBox(p - vec3(0.0, 0.0, -17.45), vec3(1.7, 1.7, 1.9));
    res = opU(res, b > 0.6 ? vec2(b, 0.0) : muzzle(p));
    b = sdBox(p - vec3(0.0, 0.3, 8.1), vec3(3.2, 4.3, 5.0));
    res = opU(res, b > 0.6 ? vec2(b, 0.0) : body(p));
    float r = length(p.xy);
    b = max(max(2.2 - r, r - 7.9), abs(p.z - 8.1) - 3.7);
    res = opU(res, b > 0.6 ? vec2(b, 0.0) : radiators(p));
    return res;
}

float gunDist(vec3 p) {
    return gun(p).x;
}

vec3 gunNormal(vec3 p) {
    const vec2 e = vec2(0.0012, -0.0012);
    return normalize(e.xyy * gunDist(p + e.xyy) + e.yyx * gunDist(p + e.yyx) + e.yxy * gunDist(p + e.yxy)
            + e.xxx * gunDist(p + e.xxx));
}

vec2 boxHit(vec3 ro, vec3 rd, vec3 lo, vec3 hi) {
    vec3 inv = 1.0 / rd;
    vec3 t0 = (lo - ro) * inv;
    vec3 t1 = (hi - ro) * inv;
    vec3 tmin = min(t0, t1);
    vec3 tmax = max(t0, t1);
    return vec2(max(max(tmin.x, tmin.y), tmin.z), min(min(tmax.x, tmax.y), tmax.z));
}

/** March to the gun; (t, material), material 0 on a miss. */
vec2 march(vec3 ro, vec3 rd, int steps, float tMax) {
    vec2 box = boxHit(ro, rd, vec3(-7.9, -7.9, -19.5 + gRecoil), vec3(7.9, 7.9, 13.3 + gRecoil));
    if (box.y < max(box.x, 0.0)) return vec2(-1.0, 0.0);
    float t = max(box.x, 0.0);
    float end = min(box.y, tMax);
    // over-relaxed sphere tracing (Keinert et al. 2014): longer strides, stepping back when a stride overshoots
    float omega = 1.35;
    float stride = 0.0;
    float before = 0.0;
    for (int i = 0; i < 180; i++) {
        if (i >= steps) break;
        vec2 h = gun(ro + rd * t);
        float radius = h.x * 0.92;
        bool overshot = omega > 1.0 && radius + before < stride;
        if (overshot) {
            stride -= omega * stride;
            omega = 1.0;
        } else {
            if (h.x < max(gPixel * t * (gLite ? 1.5 : 0.45), 0.0008)) return vec2(t, h.y);
            stride = radius * omega;
        }
        before = radius;
        t += stride;
        if (t > end) break;
    }
    return vec2(-1.0, 0.0);
}

vec2 marchLite(vec3 ro, vec3 rd) {
    gLite = true;
    vec2 h = march(ro, rd, 36, 18.0);
    gLite = false;
    return h;
}

/** Soft shadow toward a direction (improved penumbra estimate), against the gun without its greebles. */
float shadowDir(vec3 p, vec3 l, float k) {
    // nothing past the gun's box can shade it
    float out_ = boxHit(p, l, vec3(-7.9, -7.9, -19.5 + gRecoil), vec3(7.9, 7.9, 13.3 + gRecoil)).y;
    gLite = true;
    float s = 1.0;
    float t = 0.03;
    float ph = 1e10;
    for (int i = 0; i < 36; i++) {
        float h = gunDist(p + l * t);
        float y = h * h / (2.0 * ph);
        float d = sqrt(max(h * h - y * y, 0.0));
        s = min(s, k * d / max(t - y, 1e-4));
        ph = h;
        t += clamp(h, 0.03, 0.9);
        if (s < 0.005 || t > out_) break;
    }
    gLite = false;
    return smoothstep(0.0, 1.0, saturate(s));
}

/** Hard-ish shadow toward a point light. */
float shadowTo(vec3 p, vec3 light) {
    gLite = true;
    vec3 l = light - p;
    float far = length(l);
    l /= far;
    float s = 1.0;
    float t = 0.04;
    for (int i = 0; i < 32; i++) {
        float h = gunDist(p + l * t);
        s = min(s, 14.0 * h / t);
        t += clamp(h, 0.04, 0.8);
        if (s < 0.01 || t > far - 0.1) break;
    }
    gLite = false;
    return saturate(s);
}

float occlusion(vec3 p, vec3 n) {
    gLite = true;
    float o = 0.0;
    float w = 1.0;
    for (int i = 1; i <= 5; i++) {
        float d = 0.06 * float(i) * float(i) * 0.5 + 0.02;
        o += (d - gunDist(p + n * d)) * w;
        w *= 0.75;
    }
    gLite = false;
    return saturate(1.0 - o * 2.2);
}

// ---------------------------------------------------------------- what lies round it

/** The Milky Way beside the gun, seen in direction `w` (shared axes); `blur` widens the lookup for rough reflections. */
vec3 galaxy(vec3 w, float blur, out float cover) {
    float tHit;
    vec3 mw = galaxyDisc(w, CentreRel, GalaxyN, ToCentre, 60.0, MilkyTop, gPixel * blur, 1e9, cover, tHit);
    float tb;
    float db = rayPointDist(vec3(0.0), w, CentreRel, tb);
    float bulge = tb > 0.0 ? exp(-sqr(db / (5.0 + blur * 0.02))) : 0.0;
    return mw * 0.7 + vec3(1.0, 0.82, 0.55) * bulge * 0.18;
}

vec3 backdrop(vec3 rd) {
    vec3 w = toShared(rd);
    vec3 col = starField(w, gPixel, 0.9) + deepField(w, gPixel) * 0.5;
    float cover;
    vec3 mw = galaxy(w, 1.0, cover);
    col = col * (1.0 - cover * 0.85) + mw;
    // the target, inside it: the Sun, a single star on the line of fire, ringed in red
    vec3 sun = normalize(SunRelG);
    float ds = length(w - sun);
    col += vec3(1.0, 0.9, 0.75) * pointGlow(ds, gPixel, 1.2) * 2.5;
    float ring = abs(ds - gPixel * 9.0) / gPixel;
    col += LASER * saturate(1.2 - ring) * step(0.5, fract(atan(dot(w - sun, CamUp), dot(w - sun, CamRight)) / TAU * 4.0 + 0.125))
            * 1.5 * gAwake;
    return col;
}

/** What the metal sees in a direction: the galaxy (blurred with roughness) and the black. */
vec3 environment(vec3 dir, float rough) {
    float cover;
    return galaxy(toShared(dir), 1.0 + rough * 600.0, cover) * (1.0 - rough * 0.5) + vec3(0.004, 0.005, 0.008);
}

// ---------------------------------------------------------------- the look of it

/** Panel seams and the odd hatch, projected along the surface's main axis; id of the panel for its tint. */
float seams(vec3 p, vec3 n, out float panel) {
    vec3 a = abs(n);
    vec2 uv = a.x > a.y && a.x > a.z ? p.yz : a.y > a.z ? p.xz : p.xy;
    vec2 cell = vec2(0.64, 0.42);
    vec2 g = abs(fract(uv / cell) - 0.5) * cell;
    vec2 id = floor(uv / cell);
    panel = hash12(id + 7.0);
    float line = 1.0 - smoothstep(0.004, 0.009, min(g.x, g.y));
    float hatch = step(0.88, hash12(id)) * (1.0 - smoothstep(0.004, 0.009, abs(max(g.x - 0.12, g.y - 0.07))));
    return max(line, hatch * 0.8);
}

float ggx(float nh, float a) {
    float a2 = a * a;
    float d = nh * nh * (a2 - 1.0) + 1.0;
    return a2 / (PI * d * d);
}

float smithG(float nv, float nl, float a) {
    float k = sqr(a + 1.0) / 8.0;
    return nv / (nv * (1.0 - k) + k) * nl / (nl * (1.0 - k) + k);
}

vec3 fresnel(float c, vec3 f0) {
    return f0 + (1.0 - f0) * pow(1.0 - c, 5.0);
}

/** A light's share of a surface: diffuse and GGX specular. */
vec3 brdf(vec3 n, vec3 v, vec3 l, vec3 albedo, vec3 f0, float rough, float metal) {
    float nl = max(dot(n, l), 0.0);
    if (nl <= 0.0) return vec3(0.0);
    vec3 h = normalize(l + v);
    float nv = max(dot(n, v), 1e-3);
    float nh = max(dot(n, h), 0.0);
    float a = max(rough * rough, 0.002);
    vec3 F = fresnel(max(dot(h, v), 0.0), f0);
    vec3 spec = F * ggx(nh, a) * smithG(nv, nl, a) / (4.0 * nv * nl + 1e-4);
    vec3 diff = albedo * (1.0 - metal) * (1.0 - F) / PI;
    return (diff + spec) * nl;
}

struct Surface {
    vec3 albedo;
    vec3 f0;
    float rough;
    float metal;
    vec3 emit;
};

/** How lit the barrel is at a z by the charge's wave (behind it lit, ahead of it dark), and its blazing front. */
vec2 waveAt(float z) {
    float front = mix(3.4, -16.4, gWave);
    float lit = smoothstep(front - 0.3, front + 0.6, z) * step(0.001, gWave);
    return vec2(lit, exp(-sqr((z - front) / 0.7)) * step(0.001, gWave) * step(gWave, 0.999));
}

Surface material(vec3 lp, vec3 n, float mat) {
    Surface s;
    s.albedo = vec3(0.05);
    s.f0 = vec3(0.04);
    s.rough = 0.5;
    s.metal = 0.0;
    s.emit = vec3(0.0);
    float panel;
    float seam = seams(lp, n, panel);
    // (in a reflection the grime is lost in the blur: a single octave does)
    float grime = gLite ? vnoise3(lp * 1.7) : fbm3(lp * 1.7);
    float boost = gFired >= 0.0 ? 4.0 * exp(-gFired * 3.0) : 0.0;
    vec2 wave = waveAt(lp.z);
    float drain = 1.0 - 0.8 * gImplode;
    if (mat == M_HULL) {
        // graphite armour, each plate a slightly different shade, scuffed toward its edges
        s.albedo = vec3(0.075, 0.078, 0.086) * (0.75 + 0.5 * panel) * (0.85 + 0.3 * grime);
        s.rough = 0.42 + 0.2 * panel;
        s.metal = 0.25;
        // red hazard bands just behind the muzzle collar and round the receiver's band
        float stripe = step(0.5, fract((lp.x + lp.y + lp.z) * 2.4));
        float zone = step(-15.62, lp.z) * step(lp.z, -15.2) + step(6.72, lp.z) * step(lp.z, 7.08);
        s.albedo = mix(s.albedo, mix(vec3(0.5, 0.03, 0.04), vec3(0.8, 0.75, 0.7), stripe * 0.0) * (0.8 + 0.2 * stripe), zone * stripe);
        // the barrel's seams are its circuitry: as the wave passes they light red, current pulsing down them
        float barrelCore = step(length(lp.xy), 0.72) * step(lp.z, 3.4) * step(-16.0, lp.z);
        float current = 0.5 + 0.5 * sin(lp.z * 5.0 + gTime * 40.0);
        s.emit += LASER * seam * barrelCore * (wave.x * (0.6 + 0.8 * current) * drain + wave.y * 5.0);
    } else if (mat == M_METAL) {
        // machined steel, brushed along the barrel
        float brushed = vnoise2(vec2(lp.z * 40.0, (lp.x + lp.y) * 1200.0));
        s.albedo = vec3(0.62, 0.63, 0.66);
        s.f0 = vec3(0.56, 0.57, 0.6) * (0.9 + 0.1 * brushed);
        s.rough = 0.16 + 0.12 * brushed + 0.1 * grime;
        s.metal = 1.0;
        // the rails' inner faces carry the current: a dull red while it is awake, blazing when it fires
        float inner = step(0.62, abs(lp.y)) * step(abs(lp.y), 0.68) * step(0.5, -sign(lp.y) * n.y);
        float pulse = fract(gTime * 2.5 + lp.z * 0.18);
        s.emit += LASER * inner * (0.08 * gAwake + (0.5 + 2.5 * exp(-pulse * 7.0)) * wave.x * drain + wave.y * 6.0 + 6.0 * boost);
        // the ring held at the prongs' tips, where the charge is focused
        float tipRing = step(lp.z, MUZZLE_Z + 0.3) * step(0.55, length(lp.xy)) * step(length(lp.xy), 0.85);
        s.emit += mix(LASER, LASER_HOT, gCharge * gCharge) * tipRing * smoothstep(0.4, 1.0, gCharge) * (2.0 + 2.0 * sin(gTime * 70.0)) * drain;
    } else if (mat == M_DARK) {
        s.albedo = vec3(0.022, 0.023, 0.026) * (0.8 + 0.4 * grime);
        s.rough = 0.55;
        s.metal = 0.5;
        s.f0 = vec3(0.08);
    } else if (mat == M_RAD) {
        // ceramic radiator slats, a heat pipe down each glowing faintly
        s.albedo = vec3(0.16, 0.155, 0.15) * (0.8 + 0.3 * grime);
        s.rough = 0.7;
        float pipe = 1.0 - smoothstep(0.015, 0.035, abs(fract((lp.z - 8.1) * 2.0 + 0.5) - 0.5) * 0.5);
        s.emit += blackbody(0.3 + 0.2 * gAwake) * pipe * (0.05 + 0.25 * gAwake) * (0.7 + 0.3 * sin(gTime * 1.3 + lp.z));
    } else if (mat == M_GOLD) {
        // crinkled gold foil
        float crinkle = fbm3(lp * 9.0);
        s.albedo = vec3(1.0, 0.72, 0.3);
        s.f0 = vec3(1.0, 0.71, 0.29) * (0.75 + 0.35 * crinkle);
        s.rough = 0.22 + 0.25 * crinkle;
        s.metal = 1.0;
    } else if (mat == M_LENS) {
        s.albedo = vec3(0.01);
        s.f0 = vec3(0.06);
        s.rough = 0.04;
        float r = length(lp.xy);
        s.emit += LASER * (0.05 * gAwake + 2.5 * gCharge * drain) * (0.4 + 0.6 * smoothstep(0.6, 0.0, r)) + LASER_HOT * boost * 4.0;
    } else if (mat == M_BRIDGE) {
        // the bridge: rows of lit windows, the scale of the thing
        s.albedo = vec3(0.09, 0.092, 0.1);
        s.rough = 0.35;
        s.metal = 0.3;
        vec2 wuv = abs(n.x) > 0.6 ? lp.zy : lp.xy;
        vec2 wc = vec2(wuv.x * 6.0, (wuv.y - 2.3) * 5.0);
        vec2 wid = floor(wc);
        vec2 wf = fract(wc) - 0.5;
        float row = step(abs(lp.y - 2.3), 0.3);
        float window = step(abs(wf.x), 0.32) * step(abs(wf.y), 0.18) * row * step(abs(n.y), 0.5);
        float lit = step(0.35, hash12(wid + 3.0));
        s.emit += mix(vec3(1.0, 0.72, 0.42), vec3(0.6, 0.85, 1.0), step(0.85, hash12(wid))) * window * lit * 1.4 * (0.3 + 0.7 * gAwake);
    } else if (mat >= M_NAV && mat < M_COIL) {
        // running lights: green to starboard (+x), red to port, all of them strobing white now and then
        float side = sign(lp.x);
        vec3 c = side > 0.0 ? vec3(0.2, 1.0, 0.4) : vec3(1.0, 0.1, 0.1);
        float strobe = step(0.94, fract(gTime * 0.9));
        s.emit += mix(c * (0.6 + 0.4 * step(0.4, fract(gTime * 0.7))), vec3(1.0), strobe) * 6.0;
        s.albedo = vec3(0.1);
    } else if (mat >= M_COIL) {
        float k = mat - M_COIL;
        s.albedo = vec3(0.3, 0.3, 0.32);
        s.f0 = vec3(0.45, 0.44, 0.46);
        s.rough = 0.24 + 0.1 * grime;
        s.metal = 1.0;
        // each inner rim holds a dim red while it is awake, and blazes for a moment after the shot, muzzle first
        // each inner rim holds a dim red while it is awake; the charge's wave lights them breech to muzzle, each
        // blazing white-hot as the front passes; the shot runs down them muzzle first
        float rim = 1.0 - smoothstep(0.0, 0.025, sdOct(lp.xy, 1.0) + 0.012);
        // a glowing groove round each face, halfway out
        float heavy = mod(k, 4.0) < 0.5 ? 1.0 : 0.0;
        float groove = (1.0 - smoothstep(0.012, 0.03, abs(sdOct(lp.xy, mix(1.19, 1.31, heavy)))))
                * smoothstep(0.85, 1.0, abs(n.z));
        float shotWave = gFired >= 0.0 ? exp(-sqr((gFired * 90.0 - k) / 2.0)) * 8.0 : 0.0;
        float hum = 0.8 + 0.2 * sin(gTime * 30.0 + k * 1.7);
        float lit = wave.x * hum * drain;
        s.emit += LASER * rim * (0.1 * gAwake + lit * 3.0 + wave.y * 10.0 + shotWave + boost * 2.0);
        s.emit += LASER * groove * (lit * 2.2 + wave.y * 8.0 + shotWave * 0.5);
        s.emit += LASER_HOT * (rim + groove) * wave.y * 4.0;
    }
    s.albedo *= 1.0 - seam * 0.5;
    s.rough = min(s.rough + seam * 0.3, 1.0);
    s.f0 = mix(vec3(0.04), s.f0, 1.0 - seam * 0.6);
    return s;
}

/** Everything that lights a surface point but the traced reflection. */
vec3 lighting(vec3 p, vec3 n, vec3 v, Surface s, float ao, bool full) {
    vec3 lp = p - vec3(0.0, 0.0, gRecoil);
    vec3 col = vec3(0.0);
    // the key: the galaxy's heart, soft self-shadowed
    float sh = full && dot(n, gKey) > 0.0 ? shadowDir(p + n * 0.01, gKey, 10.0) : 1.0;
    vec3 keyCol = vec3(1.0, 0.84, 0.64) * 3.6 * (1.0 - 0.75 * gImplode);
    col += brdf(n, v, gKey, s.albedo, s.f0, s.rough, s.metal) * keyCol * sh;
    // the fill: the whole disc spread out below and ahead, a broad pale light
    float wrap = saturate(dot(n, gDisc) * 0.5 + 0.5);
    col += s.albedo * (1.0 - s.metal * 0.6) * vec3(0.55, 0.62, 0.8) * wrap * wrap * 0.35 * ao * (1.0 - 0.75 * gImplode);
    // what little comes from the empty side
    col += s.albedo * vec3(0.012, 0.014, 0.022) * ao;
    // the gun's own lights: the tiny charge, then the flash and the beam at the muzzle
    vec3 mz = vec3(0.0, 0.0, CHARGE_Z + gRecoil);
    vec3 toM = mz - p;
    float dm = length(toM);
    vec3 lm = toM / dm;
    float power = smoothstep(0.45, 1.0, gCharge) * 7.0 * (1.0 - 0.7 * gImplode) + gFlash * 2600.0;
    if (power > 0.001) {
        float shm = full && gFlash > 0.01 ? shadowTo(p + n * 0.02, mz) : 1.0;
        vec3 lc = mix(LASER, vec3(1.0, 0.85, 0.82), saturate(gFlash * 3.0));
        col += brdf(n, v, lm, s.albedo, s.f0, max(s.rough, 0.15), s.metal) * lc * power / (dm * dm + 0.2) * shm;
    }
    if (gFired >= 0.0) {
        // the beam past the muzzle: a line of red light down -Z
        vec3 bp = vec3(0.0, 0.0, min(lp.z, MUZZLE_Z) + gRecoil);
        vec3 tb = bp - p;
        float db = length(tb);
        col += brdf(n, v, tb / db, s.albedo, s.f0, max(s.rough, 0.2), s.metal) * LASER * 30.0 / (db * db + 0.5);
    }
    return col * mix(1.0, ao, 0.35) + s.emit;
}

/** A surface point, shaded, with one traced bounce for its reflection. */
vec3 shade(vec3 p, vec3 rd, float mat) {
    vec3 n = gunNormal(p);
    vec3 lp = p - vec3(0.0, 0.0, gRecoil);
    Surface s = material(lp, n, mat);
    if (mat == M_GOLD) {
        n = normalize(n + (vec3(fbm3(lp * 14.0), fbm3(lp * 14.0 + 3.1), fbm3(lp * 14.0 + 7.3)) - 0.5) * 0.35);
    }
    vec3 v = -rd;
    float ao = occlusion(p, n);
    vec3 col = lighting(p, n, v, s, ao, true);
    // the reflection: traced against the gun itself, else the galaxy and the dark
    float nv = max(dot(n, v), 0.0);
    vec3 F = fresnel(nv, s.f0);
    vec3 r = reflect(rd, n);
    vec3 refl;
    // traced where a reflection can show — polished metal; rough or dull surfaces (a few percent of mirror) only see
    // the sky, which their blur makes indistinguishable from the gun's own dark
    float weight = max(F.r, max(F.g, F.b)) * (1.0 - s.rough * 0.85);
    vec2 h = s.rough < 0.55 && weight > 0.12 ? marchLite(p + n * 0.02, r) : vec2(-1.0, 0.0);
    if (h.x > 0.0) {
        vec3 q = p + n * 0.02 + r * h.x;
        gLite = true;
        vec3 qn = gunNormal(q);
        Surface qs = material(q - vec3(0.0, 0.0, gRecoil), qn, h.y);
        gLite = false;
        refl = lighting(q, qn, -r, qs, 1.0, false);
    } else {
        refl = environment(r, s.rough);
    }
    col += refl * F * (1.0 - s.rough * 0.85) * mix(0.5, 1.0, ao);
    return col;
}

// ---------------------------------------------------------------- its light

/**
 * The tiny red charge: a hard point between the prongs, shivering, a little red breath and a thin streak round it. In the
 * implosion it is squeezed to a pinprick, burning white.
 */
vec3 chargePoint(vec3 rd, float tLimit) {
    float amt = smoothstep(0.42, 0.6, gCharge);
    if (amt <= 0.001 || gFired >= 0.0) return vec3(0.0);
    vec3 c = vec3(0.0, 0.0, CHARGE_Z + gRecoil) - CamPos;
    float t = dot(c, rd);
    if (t <= 0.0 || t > tLimit + 0.6) return vec3(0.0);
    vec3 dir = normalize(c);
    vec3 off = rd - dir * dot(rd, dir);
    float d = length(off);
    float shiver = 0.8 + 0.2 * sin(gTime * 97.0) * sin(gTime * 61.0 + 1.0);
    float size = mix(0.6, 2.0, gCharge) * shiver * mix(1.0, 0.45, gImplode);
    float x = dot(off, CamRight);
    float y = dot(off, CamUp);
    float streak = exp(-abs(y) / (gPixel * 0.9)) * exp(-abs(x) / (0.02 + 0.1 * gCharge)) * (1.0 - gImplode);
    vec3 hot = mix(vec3(1.0, 0.8, 0.8), vec3(1.0), gImplode);
    return (hot * pointGlow(d, gPixel, size) * (3.0 + 4.0 * gImplode) + LASER * pointGlow(d, gPixel, size * 5.0) * 1.3
            * (1.0 - 0.6 * gImplode) + LASER * streak * 0.9) * amt;
}

/**
 * The coils seen through the air as the wave lights them: a soft corona round each ring's aperture, the one at the
 * wave's front blazing — a tunnel of red rings lighting one after another down the barrel.
 */
vec3 coronas(vec3 rd, float tLimit) {
    if (gWave <= 0.001 || gFired >= 0.0) return vec3(0.0);
    // only the coils whose planes the ray crosses within reach of the barrel (radius 3 round its axis)
    vec2 o = CamPos.xy;
    vec2 d2 = rd.xy;
    float a = dot(d2, d2);
    float b = dot(o, d2);
    float c = dot(o, o) - 9.0;
    float disc = b * b - a * c;
    if (disc <= 0.0 && c > 0.0) return vec3(0.0);
    float sq = sqrt(max(disc, 0.0));
    float t0 = a > 1e-8 ? max((-b - sq) / a, 0.0) : 0.0;
    float t1 = a > 1e-8 ? min((-b + sq) / a, tLimit) : tLimit;
    if (t1 <= t0) return vec3(0.0);
    float z0 = CamPos.z + rd.z * t0 - gRecoil;
    float z1 = CamPos.z + rd.z * t1 - gRecoil;
    float kLo = clamp(floor((min(z0, z1) - COIL_Z0) / COIL_STEP), 0.0, float(COILS - 1));
    float kHi = clamp(ceil((max(z0, z1) - COIL_Z0) / COIL_STEP), 0.0, float(COILS - 1));
    vec3 col = vec3(0.0);
    float drain = 1.0 - 0.85 * gImplode;
    for (int i = 0; i < COILS; i++) {
        float k = float(i);
        if (k < kLo || k > kHi) continue;
        float z = COIL_Z0 + k * COIL_STEP + gRecoil;
        float t = rayPlane(CamPos, rd, vec3(0.0, 0.0, z), vec3(0.0, 0.0, 1.0));
        if (t <= 0.0 || t > tLimit) continue;
        vec2 wave = waveAt(z - gRecoil);
        if (wave.x + wave.y < 0.01) continue;
        vec2 q = (CamPos + rd * t).xy;
        float d = sdOct(q, 1.0);
        // brighter where the ray crosses the ring's plane at a slant, as a thin sheet of glowing air is
        float slant = min(1.0 / max(abs(rd.z), 0.08), 5.0);
        float inside = exp(-max(-d, 0.0) / 0.12) * step(d, 0.0);
        float outside = exp(-max(d, 0.0) / 0.35) * step(0.0, d) * 0.4;
        col += (LASER * (wave.x * 0.18 * drain + wave.y * 0.9) + LASER_HOT * wave.y * 0.4) * (inside + outside) * slant;
    }
    return col;
}

/** Red arcs crackling from the six prongs into the point, struck afresh twenty-four times a second; they retract into it. */
vec3 arcs(vec3 rd, float tLimit) {
    float amt = smoothstep(0.5, 0.75, gCharge) * (1.0 - gImplode);
    if (amt <= 0.001 || gFired >= 0.0) return vec3(0.0);
    vec3 c = vec3(0.0, 0.0, CHARGE_Z + gRecoil);
    // they all lie within 1.6 of the point, and their glow within a little more
    float tc;
    float miss = rayPointDist(CamPos, rd, c, tc);
    if (miss > 1.6 + gPixel * tc * 40.0) return vec3(0.0);
    float strike = floor(gTime * 24.0);
    float core = 0.0;
    float halo = 0.0;
    for (int i = 0; i < 6; i++) {
        float fi = float(i);
        if (hash11(strike * 1.7 + fi * 3.1) < 0.3) continue;
        float a = (fi + 0.5) * TAU / 6.0;
        vec3 from = vec3(cos(a) * 0.82, sin(a) * 0.82, CHARGE_Z + (hash11(strike + fi * 5.0) - 0.5) * 1.8 + gRecoil);
        vec3 prev = from;
        for (int j = 1; j <= 4; j++) {
            float u = float(j) / 4.0;
            vec3 q = mix(from, c, u);
            if (j < 4) {
                q += (vec3(hash11(strike * 3.1 + fi * 7.0 + float(j)), hash11(strike * 5.3 + fi * 11.0 + float(j)),
                        hash11(strike * 2.2 + fi * 13.0 + float(j))) - 0.5) * 0.4 * (1.0 - u * 0.6);
            }
            float tRay;
            float d = raySegmentDist(CamPos, rd, prev, q, tRay);
            if (tRay < tLimit) {
                float w = max(gPixel * tRay, 0.002);
                core += saturate(1.0 - d / (w * 0.9));
                halo += exp(-d / (w * 6.0));
            }
            prev = q;
        }
    }
    return (vec3(1.0, 0.82, 0.84) * min(core, 1.5) * 2.0 + LASER * halo * 0.5) * amt;
}

/**
 * Motes of light spiralling in from the dark and falling into the point, faster as the charge climbs, each dragging a
 * short tail; in the implosion they all go at once. A ring of shock closes on the point as it does.
 */
vec3 inflow(vec3 rd, float tLimit) {
    // (they begin with the close shot of the muzzle: in the wave's shot they would only be blurs at the lens)
    float amt = smoothstep(0.5, 0.62, gCharge);
    if (amt <= 0.001 || gFired >= 0.0) return vec3(0.0);
    vec3 col = vec3(0.0);
    // they all fall from within 6.6 of the point
    float tc;
    float miss = rayPointDist(CamPos, rd, vec3(0.0, 0.0, CHARGE_Z + gRecoil), tc);
    bool near = miss < 6.8 + gPixel * tc * 6.0;
    for (int i = 0; i < 26; i++) {
        if (!near) break;
        float fi = float(i);
        float seed = hash11(fi * 1.37 + 0.5);
        float speed = (0.3 + 1.3 * gCharge) * (0.7 + 0.6 * hash11(fi * 2.1));
        float r0 = 4.5 + 2.0 * hash11(fi * 3.3);
        float turns = 5.0 + 3.0 * hash11(fi * 5.7);
        float spread = (hash11(fi * 9.1) - 0.5) * 4.0;
        for (int k = 0; k < 3; k++) {
            float life = fract(seed + gTime * speed - float(k) * 0.025);
            life = mix(life, 1.0, gImplode);
            float r = mix(r0, 0.03, life * life);
            float ang = seed * TAU + life * turns;
            float z = CHARGE_Z + spread * (1.0 - life) + gRecoil;
            vec3 rel = vec3(cos(ang) * r, sin(ang) * r, z) - CamPos;
            float t = dot(rel, rd);
            if (t <= 0.0 || t > tLimit) {
                if (k == 0) break;
                continue;
            }
            float d = length(rel - rd * t) / t;
            // (a mote's tail lies within a few pixels of its head: far from the head, skip the tail)
            if (k == 0 && d > gPixel * 40.0) break;
            float fade = k == 0 ? 1.0 : 0.45 / float(k);
            col += mix(LASER, vec3(1.0, 0.82, 0.82), life) * pointGlow(d, gPixel, mix(1.3, 2.4, life)) * (0.25 + life) * fade;
        }
    }
    col *= amt * (1.0 - smoothstep(0.7, 1.0, gImplode));
    // the implosion's ring, closing on the point square to the barrel
    if (gImplode > 0.001 && gImplode < 0.999) {
        float tr = rayPlane(CamPos, rd, vec3(0.0, 0.0, CHARGE_Z + gRecoil), vec3(0.0, 0.0, 1.0));
        if (tr > 0.0 && tr < tLimit) {
            float r = length((CamPos + rd * tr).xy);
            float R = mix(5.0, 0.0, gImplode);
            col += mix(LASER, vec3(1.0, 0.85, 0.85), gImplode) * exp(-sqr((r - R) / (0.04 + 0.1 * (1.0 - gImplode)))) * 2.5;
        }
    }
    return col;
}

/**
 * The muzzle flash: for a frame a white burst swallows everything round the muzzle, the gun black against it where it
 * stands in front; six spikes off the prongs and a streak across the lens; a shock disc thrown square to the barrel.
 */
vec3 flash(vec3 rd, float tLimit) {
    if (gFired < 0.0 || gFired > 0.5) return vec3(0.0);
    vec3 c = vec3(0.0, 0.0, CHARGE_Z - 0.4 + gRecoil) - CamPos;
    float dist = length(c);
    vec3 dir = c / dist;
    vec3 off = rd - dir * dot(rd, dir);
    float d = length(off);
    float lateral = d * dist;
    float x = dot(off, CamRight);
    float y = dot(off, CamUp);
    float hard = exp(-gFired * 70.0);
    float soft = exp(-gFired * 30.0);
    // the burst itself is hidden where the gun stands between it and the lens
    float seen = tLimit > dist - 1.2 ? 1.0 : 0.0;
    float burst = (exp(-lateral / (0.45 + gFired * 6.0)) * 40.0 * soft + exp(-lateral / 5.0) * 6.0 * hard) * seen
            + exp(-lateral / 14.0) * 3.0 * hard;
    float ang = atan(y, x);
    float spikes = pow(abs(cos(ang * 3.0 + 0.4)), 80.0) * exp(-d / (0.3 + gFired * 1.5)) * 8.0 * soft;
    float streak = exp(-abs(y) / (gPixel * 2.0)) * exp(-abs(x) / 1.2) * 10.0 * soft;
    vec3 col = vec3(1.0, 0.95, 0.93) * (burst + spikes) + mix(LASER, vec3(1.0, 0.7, 0.7), 0.25) * streak;
    // the shock disc
    float tr = rayPlane(vec3(0.0), rd, vec3(0.0, 0.0, MUZZLE_Z - 0.4 - gFired * 40.0 + gRecoil) - CamPos, vec3(0.0, 0.0, 1.0));
    if (tr > 0.0 && tr < tLimit) {
        float r = length((rd * tr + CamPos).xy);
        float R = 1.0 + gFired * 90.0;
        col += mix(vec3(1.0, 0.9, 0.9), LASER, saturate(gFired * 6.0)) * exp(-sqr((r - R) / (0.3 + gFired * 8.0))) * 4.0 * soft;
    }
    return col;
}

/** The shot: razor-straight, a white hairline in a thin red sheath down -Z from the muzzle into the galaxy. */
vec3 shot(vec3 rd, float tLimit) {
    if (gFired < 0.0) return vec3(0.0);
    vec3 a = vec3(0.0, 0.0, MUZZLE_Z + gRecoil) - CamPos;
    float reach = 9000.0 * saturate(gFired * 30.0);
    float tRay;
    float d = raySegmentDist(vec3(0.0), rd, a, a + vec3(0.0, 0.0, -reach), tRay);
    if (tRay > tLimit) return vec3(0.0);
    float w = max(gPixel * tRay, 0.004);
    float core = saturate(1.0 - d / (w * 1.1)) * saturate(0.35 / w + 0.4);
    float body = saturate(1.0 - d / 0.2);
    float sheath = exp(-d / (w * 2.4)) * 0.9 + exp(-d / 0.5) * 0.25;
    return vec3(1.0, 0.92, 0.92) * (core * 5.0 + body * 4.0) + LASER * (sheath * 4.0 + body * 2.0);
}

// ---------------------------------------------------------------- main

void main() {
    gTime = S0.y;
    gSeed = S0.z;
    float tanFov = S0.x;
    gPixel = 2.0 * tanFov / OutSize.y;
    gPix = gPixel;
    gCharge = S1.x;
    gFired = S1.y;
    gAwake = S1.w;
    gWave = saturate(gCharge * 2.0);
    gImplode = S0.w;
    gRecoil = gFired >= 0.0 ? 1.4 * (1.0 - exp(-gFired * 14.0)) * exp(-gFired * 0.8) : 0.0;
    gFlash = gFired >= 0.0 ? exp(-gFired * 28.0) : 0.0;
    gCentreW = CentreRel;
    gKey = normalize(toGun(normalize(CentreRel)));
    gDisc = normalize(toGun(-GalaxyN) + gKey * 0.6);
    vec2 ndc = texCoord * 2.0 - 1.0;
    vec2 screen = vec2(ndc.x * OutSize.x / OutSize.y, ndc.y);
    vec3 rd = normalize(CamFwd + (CamRight * screen.x + CamUp * screen.y) * tanFov);

    vec2 hit = march(CamPos, rd, 170, 1e9);
    float tHit = hit.x > 0.0 ? hit.x : 1e9;
    vec3 col;
    float sky = 1.0;
    if (hit.x > 0.0) {
        col = shade(CamPos + rd * hit.x, rd, hit.y);
        sky = 0.0;
    } else {
        col = backdrop(rd) * (1.0 - 0.85 * gImplode);
    }
    // out of the flight's white it comes: dark against the galaxy first, then lit
    if (hit.x > 0.0) {
        col *= mix(0.12, 1.0, S1.z);
    }
    vec3 light = coronas(rd, tHit) + chargePoint(rd, tHit) + arcs(rd, tHit) + inflow(rd, tHit) + flash(rd, tHit)
            + shot(rd, tHit);
    col += light;

    col = 1.0 - exp(-col * 1.15);
    col = pow(col, vec3(1.0 / 2.2));
    fragColor = vec4(col, saturate(sky + lum(light) * 0.5));
}
