// SS-05, Tesseract — the universe its film is shot in, and the one beyond it. The pull-back from the land: the Earth and
// the Moon (Earth radii), the Sun and the planets (AU), the whole Milky Way (thousands of light years), the galaxies and
// the cosmic web (millions) — the web flattening into one sheet, our universe a floor; the membrane between universes,
// a film of every colour the camera rises through; the bulk beyond it: violet dark, a lattice of light receding, other
// universes far off as tilted sheets of galaxies; the W-Engine hanging over the galaxy floor (tess_engine.glsl), its scan
// lines locking onto the Milky Way; the floor sagging into a wormhole funnel — Flamm's paraboloid, its embedding grid
// drawn on it in the spectrum, the galaxies sliding down its walls and stretching into streaks — the throat at the bottom
// opening onto the Earth (the bulk carried through the throat onto the Earth's frame by a similarity, so what is seen
// through it is the real Earth from the mouth); and out of the mouth over the Earth, the engine hanging over the planet,
// the mouth closing behind, then down under it to the target.
//
// T0 = (tan half vertical fov, seconds, seed, cover), T1 = (frame 0 Earth / 1 Solar / 2 Galaxy / 3 Bulk, the Earth shown,
// cloud dissolve, Moon radius ER), T2 = (Sun radius AU, the web flattened 0..1, the membrane's height Mly, the target's
// glow), T3 = (throat radius, fold reach, depth (Mly), throat open), T4 = (ER per Mly through the throat, the mouth's
// radius ER, the engine shown, locked on), T5 = (the dive, streaming, the web's half-thickness, -). Floor axes: BulkX,
// GalaxyN, BulkZ (local x y z); FloorRel = the galactic centre from the camera (Mly); MouthRel = the mouth (frame 0, ER) or
// the throat's centre (frame 3, Mly) from the camera; MapX/Y/Z = the Earth frame's images of the floor's axes; MouthE =
// the mouth, Earth-centred. EngC = the engine's core from the camera (frame units), w its frame units per engine unit;
// EngX/Y/Z its axes.

// a zero the compiler cannot see through: loop bounds built on it are not unrolled (unrolled, the first draw took 15 s)
int gZero = 0;
#define LOOP_ZERO gZero
#include "star.glsl"

uniform sampler2D EarthDay;
uniform sampler2D EarthAux;
uniform sampler2D MoonColor;
uniform sampler2D MilkyWay;
uniform sampler2D MilkyTop;
uniform sampler2D Planets;
uniform sampler2D Rings;
uniform vec3 CamFwd;
uniform vec3 CamUp;
uniform vec3 CamRight;
uniform vec3 EarthRel;
uniform vec3 MoonRel;
uniform vec3 EarthX;
uniform vec3 EarthY;
uniform vec3 EarthZ;
uniform vec3 SunDir;
uniform vec3 SiteN;
uniform vec3 SunRelS;
uniform vec4 Planet[8];
uniform vec3 Ecliptic;
uniform vec3 SaturnPole;
uniform vec3 GalaxyN;
uniform vec3 ToCentre;
uniform vec3 CentreRel;
uniform vec3 SunRelG;
uniform vec3 FloorRel;
uniform vec3 BulkX;
uniform vec3 BulkZ;
uniform vec3 MapX;
uniform vec3 MapY;
uniform vec3 MapZ;
uniform vec3 MouthE;
uniform vec3 MouthRel;
uniform vec4 EngC;
uniform vec3 EngX;
uniform vec3 EngY;
uniform vec3 EngZ;
uniform vec4 T0;
uniform vec4 T1;
uniform vec4 T2;
uniform vec4 T3;
uniform vec4 T4;
uniform vec4 T5;
uniform vec4 T6;

#include "space.glsl"
#include "tess_engine.glsl"

// the embedding grid fades in just before the funnel (seconds)
#define FUNNEL_GRID_IN 10.3

vec3 texAxes(vec3 v) {
    return vec3(dot(v, EarthX), dot(v, EarthY), dot(v, EarthZ));
}

/** The target seen from space: a white point with a rainbow halo turning round it, brighter as the camera comes down. */
vec3 groundGlow(vec3 n) {
    vec3 site = texAxes(SiteN);
    vec3 d = n - site;
    float near = length(d);
    vec3 east, north;
    tangents(site, east, north);
    float ang = atan(dot(d, north), dot(d, east));
    vec3 ring = prism7(ang / TAU + gTime * 0.3);
    // a marker for seeing it from orbit: it fades as the camera comes down to it (close up it would fill the frame)
    float high = smoothstep(0.002, 0.03, length(EarthRel) - 1.0);
    return (vec3(1.0) * exp(-near / 0.00015) * 3.0 + ring * exp(-sqr((near - 0.0012) / 0.0005)) * 1.4
            + ring * exp(-near / 0.006) * 0.15) * (0.25 + 0.75 * T2.w) * high;
}

vec3 airGlow(vec3 p) {
    return vec3(0.0);
}

// ---------------------------------------------------------------- the Earth's side

/** The Earth (and from the main camera the Moon) from ro (Earth-centred ER) along rd over what lies behind it. */
vec3 earthView(vec3 ro, vec3 rd, vec3 back, bool moon, out float tNear) {
    bool big = resolvable(-ro, 1.0);
    vec2 he = big ? raySphere(ro, rd, vec3(0.0), 1.0) : vec2(-1.0);
    vec3 moonC = MoonRel - EarthRel - ro;
    vec2 hm = moon && resolvable(moonC, T1.w) ? raySphere(vec3(0.0), rd, moonC, T1.w) : vec2(-1.0);
    float tEarth = he.x > 0.0 ? he.x : NEVER;
    float tMoon = hm.x > 0.0 ? hm.x : NEVER;
    vec3 near = back;
    if (tMoon < tEarth) {
        near = moonBody(rd * tMoon, moonC, T1.w, rd, tMoon);
    } else if (tEarth < NEVER) {
        near = earthSurface(ro + rd * tEarth, rd, tEarth);
    }
    if (big) {
        vec3 through;
        vec3 air = atmosphere(ro, rd, min(tEarth, tMoon), through);
        near = near * through + air;
    } else {
        // too far to trace: the pale blue dot
        near += vec3(0.55, 0.75, 1.0) * pointGlow(length(rd - normalize(-ro)), gPixel, 1.2) * 1.4;
    }
    tNear = min(tEarth, tMoon);
    return near;
}

// ---------------------------------------------------------------- the bulk (Mly, floor-local: x BulkX, y up, z BulkZ)

vec3 toFloor(vec3 v) {
    return vec3(dot(v, BulkX), dot(v, GalaxyN), dot(v, BulkZ));
}

/**
 * The Milky Way lying on the floor at its centre, from above: its true radius (0.06 Mly) on the way out; seen from the
 * bulk it is drawn as the one thing there, big under the engine (R grows as the camera rises through the membrane).
 */
vec3 milkyWayOnFloor(vec2 q, float foot, float R) {
    vec2 ey = normalize(vec2(dot(ToCentre, BulkX), dot(ToCentre, BulkZ)));
    vec2 ex = vec2(-ey.y, ey.x);
    vec2 uv = vec2(dot(q, ex), dot(q, ey)) / (2.0 * R) + 0.5;
    vec3 col = vec3(0.0);
    if (uv.x > 0.0 && uv.y > 0.0 && uv.x < 1.0 && uv.y < 1.0) {
        float lod = log2(max(foot / (2.0 * R) * 2048.0, 1e-3));
        col = toLinear(textureLod(MilkyTop, vec2(uv.x, 1.0 - uv.y), lod).rgb) * 0.9;
    }
    // ours, marked: a warm point that never drops below a pixel
    col += vec3(1.0, 0.86, 0.62) * exp(-sqr(length(q) / max(foot * 1.2, 1e-4))) * 1.4 * smoothstep(R * 0.1, R * 0.5, foot);
    return col;
}

// ---------------------------------------------------------------- the funnel

float gRs = 0.0;
float gR1 = 0.0;
float gD = 0.0;

/** The sheet's height at radius r: flat beyond the fold, Flamm's paraboloid within it down to the throat, softly joined. */
float sheetY(float r) {
    float f = -gD + 2.0 * sqrt(gRs * max(r - gRs, 0.0));
    return smin(f, 0.0, 0.08 * gR1 + 1e-3);
}

/** Length along the sheet from the fold's edge in to radius r (Flamm's paraboloid, closed form). */
float sheetLen(float r) {
    float a = max(r, gRs + 1e-4);
    float b = max(gR1, gRs + 1e-4);
    float fa = sqrt(a * (a - gRs)) + gRs * log(sqrt(a) + sqrt(a - gRs));
    float fb = sqrt(b * (b - gRs)) + gRs * log(sqrt(b) + sqrt(b - gRs));
    return max(fb - fa, 0.0);
}

struct Sheet {
    float t;       // along the ray (Mly), < 0: no hit
    vec2 q;        // where on the floor it was before the fold
    float foot;    // the footprint there
    float portal;  // 1: the throat's disc
    vec3 p;        // floor-local hit
    float depth;   // how far down the funnel, 0..1
};

/** The floor (and the funnel and the throat's disc in it) along a floor-local ray. */
Sheet sheetTrace(vec3 ro, vec3 rd) {
    Sheet s;
    s.t = -1.0;
    s.q = vec2(0.0);
    s.foot = 1.0;
    s.portal = 0.0;
    s.p = vec3(0.0);
    s.depth = 0.0;
    float tHit = -1.0;
    if (gD > 1e-3) {
        // the fold's region: inside a cylinder round the throat, between its bottom and the floor
        float R = gR1 * 1.2 + 1.0;
        vec2 cyl = rayCylinderY(ro, rd, vec3(0.0), R);
        float ty0 = abs(rd.y) > 1e-6 ? (0.5 - ro.y) / rd.y : (ro.y < 0.5 ? -NEVER : NEVER);
        float ty1 = abs(rd.y) > 1e-6 ? (-gD - 0.5 - ro.y) / rd.y : (ro.y > -gD - 0.5 ? NEVER : -NEVER);
        float tA = max(max(cyl.x, min(ty0, ty1)), 0.0);
        float tB = min(cyl.y, max(ty0, ty1));
        if (cyl.y > 0.0 && tB > tA) {
            int steps = 56 + gZero;
            float dt = (tB - tA) / float(steps);
            float tPrev = tA;
            vec3 p0 = ro + rd * tA;
            float fPrev = p0.y - sheetY(length(p0.xz));
            for (int i = 1; i <= steps; i++) {
                float t = tA + dt * float(i);
                vec3 p = ro + rd * t;
                float f = p.y - sheetY(length(p.xz));
                if (f < 0.0 && fPrev >= 0.0) {
                    float a = tPrev;
                    float b = t;
                    for (int k = 0; k < 8 + gZero; k++) {
                        float m = 0.5 * (a + b);
                        vec3 pm = ro + rd * m;
                        if (pm.y - sheetY(length(pm.xz)) < 0.0) {
                            b = m;
                        } else {
                            a = m;
                        }
                    }
                    tHit = 0.5 * (a + b);
                    break;
                }
                tPrev = t;
                fPrev = f;
            }
            if (tHit < 0.0 && rd.y < 0.0) {
                // through the region without touching it: the flat floor beyond
                float t = -ro.y / rd.y;
                vec3 p = ro + rd * t;
                if (t > 0.0 && length(p.xz) >= R) tHit = t;
            }
        } else if (rd.y < 0.0 && ro.y > 0.0) {
            tHit = -ro.y / rd.y;
        }
    } else if (abs(rd.y) > 1e-6) {
        float t = -ro.y / rd.y;
        if (t > 0.0) tHit = t;
    }
    if (tHit <= 0.0) return s;
    vec3 p = ro + rd * tHit;
    float r = length(p.xz);
    float phi = atan(p.z, p.x);
    s.t = tHit;
    s.p = p;
    float slant = max(abs(rd.y), 0.06);
    float foot = gPixel * tHit / slant;
    if (gD > 1e-3 && r < gRs * 1.0005 && p.y < -gD + 0.6) {
        s.portal = 1.0;
        s.q = p.xz;
        s.foot = foot;
        s.depth = 1.0;
        return s;
    }
    if (gD > 1e-3 && r < gR1) {
        // the sheet was pulled in: what was at radius r0 has slid down the funnel to here
        float len = sheetLen(r);
        float r0 = gR1 - len;
        float twist = 0.9 * sqr(len / max(gR1, 1e-3));
        float phi0 = phi + twist;
        float rr0 = abs(r0);
        s.q = rr0 * vec2(cos(phi0), sin(phi0));
        s.foot = foot * max(rr0 / max(r, 1e-3), 1.0) / max(sqrt(r / max(r - gRs, 1e-3)), 1.0);
        s.depth = saturate(-p.y / max(gD, 1e-3));
    } else {
        s.q = p.xz;
        s.foot = foot;
    }
    return s;
}

/** The embedding grid drawn on the sheet: rings of what was its radius, spokes round the throat, in the spectrum. */
vec3 embeddingGrid(vec2 q, float foot, float amount) {
    if (amount < 0.001) return vec3(0.0);
    float r0 = length(q);
    float phi = atan(q.y, q.x);
    gAA = foot * 1.2;
    float ring = abs(r0 - 4.0 * floor(r0 / 4.0 + 0.5));
    float spokeA = TAU / 24.0;
    float spoke = abs(phi - spokeA * floor(phi / spokeA + 0.5)) * r0;
    float w = 0.03 + foot * 0.2;
    float lines = max(line(ring, w), line(spoke, w) * smoothstep(1.0, 3.0, r0));
    // out across the floor, fading into the distance
    float fade = 1.0 - smoothstep(60.0, 150.0, r0);
    // plain white, a touch cooler far out, as an embedding diagram is drawn
    vec3 hue = mix(vec3(0.95, 0.96, 1.0), vec3(0.62, 0.68, 0.8), smoothstep(10.0, 50.0, r0));
    return hue * lines * fade * amount * 0.45;
}

// ---------------------------------------------------------------- the engine

// What the frame being drawn tells the engine: whether it is seen at all, its light, where the scene stops it, and the
// throat's / mouth's plane beyond which it is seen only through the disc (gClipN zero: no plane).
bool gEngineOn = false;
vec3 gKeyDir = vec3(0.0, 1.0, 0.0);
vec3 gKeyCol = vec3(0.0);
float gEngLimit = NEVER;
vec3 gClipC = vec3(0.0);
vec3 gClipN = vec3(0.0);
bool gThrough = false;

/** The engine along a ray from the camera (rd, frame units) over `back`; tOut = its t or NEVER. */
vec3 engineAlong(vec3 rd, vec3 back, out float tOut) {
    tOut = NEVER;
    if (!gEngineOn || T4.z < 0.5) return back;
    vec3 lro = vec3(dot(-EngC.xyz, EngX), dot(-EngC.xyz, EngY), dot(-EngC.xyz, EngZ)) / EngC.w;
    vec3 lrd = vec3(dot(rd, EngX), dot(rd, EngY), dot(rd, EngZ));
    vec2 bound = raySphere(lro, lrd, vec3(0.0), 2.1);
    if (bound.y <= 0.0) return back;
    float tMax = min(gEngLimit / EngC.w, bound.y);
    vec3 lkey = normalize(vec3(dot(gKeyDir, EngX), dot(gKeyDir, EngY), dot(gKeyDir, EngZ)));
    EngHit h = engineTrace(lro, lrd, tMax, engineLod(lro, gPixel));
    vec3 col = back;
    float tEnd = tMax;
    if (h.t > 0.0) {
        float tPass = h.t * EngC.w;
        // the part on the far side of the throat / the mouth is seen only through it
        if (dot(rd * tPass - gClipC, gClipN) > 0.0 && !gThrough) return back;
        col = engineShade(h, lro, lrd, lkey, gKeyCol, gPixel);
        tOut = tPass;
        tEnd = h.t;
    }
    return col + engineGlow(lro, lrd, tEnd, gPixel);
}

/** The engine's scan lines locked onto the floor: from round its underside down to the rim of the fold. */
vec3 lockLines(vec3 rd, float tLimit) {
    float on = T4.w;
    if (on < 0.001 || T4.z < 0.5) return vec3(0.0);
    vec3 col = vec3(0.0);
    int n = 24 + gZero;
    for (int i = 0; i < n; i++) {
        float a = float(i) / float(n) * TAU + gTime * 0.12;
        vec3 top = EngC.xyz + (EngX * cos(a) + EngZ * sin(a)) * 0.95 * EngC.w - EngY * 1.05 * EngC.w;
        vec3 bot = FloorRel + (BulkX * cos(a) + BulkZ * sin(a)) * gR1 * 0.92 - GalaxyN * 0.4;
        float tRay;
        float d = raySegmentDist(vec3(0.0), rd, top, bot, tRay);
        if (tRay <= 0.0 || tRay > tLimit) continue;
        float width = max(gPixel * tRay * 0.9, 0.012);
        // pulses running down to the floor
        vec3 seg = bot - top;
        float s = saturate(dot(rd * tRay - top, seg) / dot(seg, seg));
        float pulse = exp(-sqr((fract(s * 3.0 - gTime * 1.6 + float(i) * 0.37) - 0.5) / 0.05));
        col += prism7(float(i) / float(n) + gTime * 0.05) * (exp(-sqr(d / width)) * (0.9 + 2.2 * pulse)
                + exp(-d / (width * 8.0)) * 0.08);
    }
    return col * on;
}

/** A disc's rim seen as an Einstein ring: a thin white ring of lensed starlight, a fainter second one, a soft halo. */
vec3 einsteinRing(float r, float R, float ang, float pixR) {
    float x = (r - R * 1.04) / max(R * 0.012, pixR);
    float x2 = (r - R * 1.11) / max(R * 0.008, pixR);
    // the stars behind it smeared into arcs round it
    float arcs = 0.75 + 0.25 * vnoise2(vec2(ang * 40.0, gTime * 0.2));
    vec3 white = vec3(0.95, 0.97, 1.0);
    return white * (exp(-x * x) * 1.8 * arcs + exp(-x2 * x2) * 0.35 + exp(-abs(r - R) / (R * 0.12)) * 0.18);
}

// ---------------------------------------------------------------- the frames
// Every heavy piece below is drawn from ONE place (main): the driver inlines a function at every call, and on this card
// it compiles at the first draw, so a second call site is seconds of freeze the first time the film plays.

/** Frame 2: the Milky Way, the camera backing out of it. */
vec3 galaxyFrame(vec3 rd, vec3 stars, vec3 deep) {
    float h = abs(dot(-CentreRel, GalaxyN));
    float outside = smoothstep(0.6, 4.0, h);
    vec3 col = panorama(rd) * 0.8 * (1.0 - outside) + stars * (0.45 * (1.0 - outside) + 0.12) + deep * outside;
    float cover;
    float tDisc;
    vec3 mw = galaxyDisc(rd, CentreRel, GalaxyN, ToCentre, 60.0, MilkyTop, gPixel, NEVER, cover, tDisc);
    float tb;
    float db = rayPointDist(vec3(0.0), rd, CentreRel, tb);
    float bulge = tb > 0.0 ? exp(-sqr(db / 4.5)) : 0.0;
    col = col * (1.0 - cover * 0.85 * outside) + (mw * 0.62 + vec3(1.0, 0.82, 0.55) * bulge * 0.22) * outside;
    col += vec3(1.0, 0.9, 0.75) * pointGlow(length(rd - normalize(SunRelG)), gPixel, 1.3) * 3.0;
    return col;
}

/** Frames 0 and 1, behind the Earth: the Milky Way from inside it, the stars, the Sun and the planets. */
vec3 solarBack(vec3 rd, vec3 stars) {
    vec3 col = panorama(rd) * 0.8 + stars * 0.5;
    float tSolid = NEVER;
    vec3 solid = vec3(0.0);
    vec2 hs = resolvable(SunRelS, T2.x) ? raySphere(vec3(0.0), rd, SunRelS, T2.x) : vec2(-1.0);
    if (hs.x > 0.0) {
        tSolid = hs.x;
        solid = sunBody(rd * hs.x, SunRelS, T2.x, rd, hs.x);
    }
    for (int i = 0; i < 8 + gZero; i++) {
        if (i == 2) continue;
        vec3 c = Planet[i].xyz;
        float R = Planet[i].w;
        vec2 h = resolvable(c, R) ? raySphere(vec3(0.0), rd, c, R) : vec2(-1.0);
        if (h.x > 0.0 && h.x < tSolid) {
            tSolid = h.x;
            solid = planetBody(i, rd * h.x, c, R, rd, h.x);
        } else if (h.x <= 0.0 && T1.x > 0.5) {
            float lit = 0.5 + 0.5 * dot(normalize(c - SunRelS), normalize(-c));
            col += vec3(1.0, 0.95, 0.85) * pointGlow(length(rd - normalize(c)), gPixel, 1.1) * (0.5 + lit) * 0.9;
        }
    }
    if (tSolid < NEVER) {
        col = solid;
    }
    if (length(SunRelS) < 200.0) {
        col += sunGlare(rd, SunRelS, T2.x);
    } else {
        col += vec3(1.0, 0.95, 0.85) * pointGlow(length(rd - normalize(SunRelS)), gPixel, 1.4) * 2.0;
    }
    return col;
}

// where a ray from the bulk's camera met the throat's disc (floor-local): the Earth is drawn there
bool gPortal = false;
vec3 gPortalP = vec3(0.0);

/**
 * The bulk along a floor-local ray: empty space — the stars, the far galaxies faint, as round the SS-01 gun — over a
 * floor that is nothing but its spacetime grid (no web, no galaxies on it: the user), the Milky Way lying at its middle;
 * as the floor folds, the same grid carried down the funnel; the throat's disc left dark (the Earth goes there). The grid
 * shows from the bulk's side only, as the camera rises through the membrane. `cam`: the bulk camera's own ray (frame 3);
 * otherwise one carried up the throat from the mouth over the Earth.
 */
vec3 bulkView(vec3 ro, vec3 rl, vec3 rd, vec3 stars, vec3 deep, bool cam, out float tScene) {
    float shear = T2.z;
    bool above = ro.y > shear || !cam || T5.w > 0.5;
    // from the bulk: the grid, the Milky Way drawn big (the one thing on the floor), the space round it plainer
    float big = above ? T6.x : 0.0;
    vec3 col = stars * mix(0.24, 0.5, big) + deep * mix(1.0, 0.3, big);
    tScene = NEVER;
    Sheet s = sheetTrace(ro, rl);
    if (s.t > 0.0) {
        float r = length(s.p.xz);
        if (s.portal > 0.5) {
            // the throat: shut, a pinch of dark; open, the Earth through it (drawn in main)
            tScene = s.t;
            gPortal = true;
            gPortalP = s.p;
            col = vec3(0.0);
        } else {
            if (big > 0.5) {
                tScene = s.t;
            }
            col += embeddingGrid(s.q, s.foot, big);
            // the Milky Way, lying at the middle (carried down the funnel with the floor as it folds)
            float mwR = mix(0.06, 5.0, big);
            if (length(s.q) < mwR * 1.05) {
                col += milkyWayOnFloor(s.q, s.foot, mwR);
            }
            // the scan sweeping in across the floor as the engine locks on (the machine's, so in its colours)
            if (T4.w > 0.001) {
                float r0 = length(s.q);
                float scanR = mix(gR1 * 1.3, 0.0, fract(gTime * 0.45));
                col += prism7(r0 * 0.02 + gTime * 0.1) * exp(-sqr((r0 - scanR) / (0.4 + s.foot))) * 1.4 * T4.w;
            }
        }
        // the Einstein ring round the throat
        if (gD > 1e-3) {
            col += einsteinRing(r, gRs, atan(s.p.z, s.p.x), s.foot) * T3.w * (s.portal > 0.5 ? 0.6 : 1.0);
        }
    }
    // (the membrane between universes is felt, not drawn: a shiver of the lens as the camera crosses — TesseractFx)
    return col;
}

void main() {
    // (not x * 0.0: this driver folds that to a visible 0 and unrolls everything)
    gZero = int(step(1e30, abs(T0.z)));
    gTime = T0.y;
    gSeed = T0.z;
    float tanFov = T0.x;
    gPixel = 2.0 * tanFov / OutSize.y;
    gPix = gPixel;
    gRs = T3.x;
    gR1 = T3.y;
    gD = T3.z;
    vec2 ndc = texCoord * 2.0 - 1.0;
    vec2 screen = vec2(ndc.x * OutSize.x / OutSize.y, ndc.y);
    vec3 rd = normalize(CamFwd + (CamRight * screen.x + CamUp * screen.y) * tanFov);
    float frame = T1.x;

    // the stars and the deep field, once whatever the frame
    vec3 stars = starField(rd, gPixel, 1.0);
    vec3 deep = frame > 1.5 ? deepField(rd, gPixel) : vec3(0.0);

    // what this frame needs: the bulk (frame 3's own ray, or frame 0's carried up through the mouth) and the Earth
    // (frames 0-1's own ray, or frame 3's carried down through the throat) — each drawn once below
    vec3 col = vec3(0.0);
    bool wantBulk = false;
    bool camBulk = false;
    vec3 bro = vec3(0.0);
    vec3 brd = vec3(0.0, 1.0, 0.0);
    bool wantEarth = false;
    vec3 ero = -EarthRel;
    vec3 erd = rd;
    bool through = false;
    float tEarthQ = NEVER;
    vec3 ring = vec3(0.0);
    float mouthR = T4.y;
    if (frame < 1.5) {
        col = solarBack(rd, stars);
        wantEarth = true;
        if (frame < 0.5) {
            vec2 he = raySphere(-EarthRel, rd, vec3(0.0), 1.0);
            tEarthQ = he.x > 0.0 ? he.x : NEVER;
            float tm = mouthR > 1e-4 ? rayPlane(vec3(0.0), rd, MouthRel, MapY) : -1.0;
            if (tm > 0.0 && tm < tEarthQ) {
                vec3 q = rd * tm - MouthRel;
                float r = length(q);
                ring = einsteinRing(r, mouthR, atan(dot(q, MapZ), dot(q, MapX)), gPixel * tm);
                if (r < mouthR) {
                    // looking up through the mouth: the bulk, up the funnel, carried back by the similarity
                    through = true;
                    wantBulk = true;
                    wantEarth = false;
                    bro = vec3(dot(q, MapX), dot(q, MapY), dot(q, MapZ)) / T4.x + vec3(0.0, -gD + 0.02, 0.0);
                    brd = vec3(dot(rd, MapX), dot(rd, MapY), dot(rd, MapZ));
                }
            }
        }
    } else if (frame < 2.5) {
        col = galaxyFrame(rd, stars, deep);
    } else {
        wantBulk = true;
        camBulk = true;
        bro = toFloor(-FloorRel);
        brd = toFloor(rd);
    }

    // the bulk
    float tScene = NEVER;
    if (wantBulk) {
        col = bulkView(bro, brd, rd, stars, deep, camBulk, tScene);
        if (camBulk && gPortal) {
            // through the throat: the real Earth, from the mouth over it
            vec3 off = gPortalP - vec3(0.0, -gD, 0.0);
            ero = MouthE + (MapX * off.x + MapY * off.y + MapZ * off.z) * T4.x;
            erd = MapX * brd.x + MapY * brd.y + MapZ * brd.z;
            wantEarth = true;
        }
    }

    // the Earth
    if (wantEarth) {
        float tE0;
        vec3 back = camBulk ? panorama(erd) * 0.8 : col;
        vec3 earth = earthView(ero, erd, back, !camBulk, tE0);
        if (camBulk) {
            col += earth * T3.w * (1.0 - smoothstep(gRs * 0.92, gRs, length(gPortalP.xz)));
        } else {
            col = earth;
        }
    }
    col += ring;

    // the engine: over the Earth lit by the Sun, beyond the mouth only through it; in the bulk lit from the floor,
    // only from the bulk's side, beyond the throat's disc only through it
    if (frame < 0.5) {
        gEngineOn = true;
        gKeyDir = SunDir;
        gKeyCol = vec3(1.0, 0.96, 0.9) * 2.4;
        gEngLimit = tEarthQ < NEVER ? tEarthQ : 1e6;
        gClipC = MouthRel;
        gClipN = mouthR > 1e-4 ? MapY : vec3(0.0);
        gThrough = through;
    } else if (frame > 2.5) {
        gEngineOn = bro.y > T2.z || T5.w > 0.5;
        gKeyDir = -GalaxyN + BulkX * 0.18 + BulkZ * 0.12;
        gKeyCol = vec3(0.78, 0.82, 1.0) * 1.1;
        gEngLimit = gPortal ? 1e30 : tScene;
        gClipC = FloorRel - GalaxyN * gD;
        gClipN = gD > 1e-3 ? -GalaxyN : vec3(0.0);
        gThrough = gPortal;
    }
    float tE;
    col = engineAlong(rd, col, tE);
    if (frame > 2.5 && gEngineOn) {
        col += lockLines(rd, min(gEngLimit, tE));
    }

    // streaming out: the stars drawn back into the heading in every colour as the decades go by
    if (T5.y > 0.001) {
        // plain starlight streaks (the user: "make those rainbow tunnel line just generic one")
        col += warpField(rd, CamFwd, -gTime * 7.0, 1.4, gPixel, vec3(0.82, 0.88, 1.0), vec3(1.0, 0.95, 0.86)) * 0.8 * T5.y;
    }

    col = 1.0 - exp(-col * 1.1);
    col = pow(col, vec3(1.0 / 2.2));

    // up out of the world: cloud streaming past as the view opens
    float dis = T1.z;
    float cover0 = T0.w;
    float fog = sin(saturate(dis) * PI) * (1.0 - step(0.999, dis)) * step(frame, 0.5);
    float mask = 1.0;
    vec3 outCol = col;
    if (cover0 < 0.999 || fog > 0.001) {
        vec3 world = texture(DiffuseSampler, texCoord).rgb;
        float r = length(screen);
        float an = atan(screen.y, screen.x);
        float wisps = fbm2(vec2(an * 2.5, log(r + 0.03) * 2.2 - dis * 7.0) + gSeed);
        mask = smoothstep(wisps - 0.12, wisps + 0.12, cover0 * 1.35 - 0.2);
        outCol = mix(world, col, mask);
        float cloud = smoothstep(0.35, 0.8, vnoise2(screen * 2.2 + vec2(0.0, -dis * 5.0) + wisps) * 0.6 + wisps * 0.4);
        outCol = mix(outCol, vec3(0.92, 0.94, 1.0), fog * (0.35 + 0.65 * cloud) * 0.95);
    }
    fragColor = vec4(outCol, 1.0 - mask);
}
