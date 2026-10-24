// cc 1791554124311509400
// SS-05 · the W-Engine — a Kardashev III machine built as a hypercube (an INCLUDE-ONLY library: no main).
// The pose comes from TesseractEngine.java (pure Java). Design notes and the contract: notes/tess-engine.md.
//
// Include after common.glsl and star.glsl. It samples no textures (includers may still declare MilkyTop: unused). Engine-local space: the core at the origin, the outer frame's
// half-width 1 at rest, +Y away from the floor / the Earth (it drops along -Y). Rays are engine-local, rd normalized;
// pix = the angular size of a pixel (a footprint at distance t is pix * t). Eng[ENG_POSE] = TesseractEngine.pose().
//
//   EngHit h = engineTrace(ro, rd, tMax, lod);          // nearest solid (h.t < 0: none); lod 0 full .. 1 cheapest
//   vec3 col = h.t > 0.0 ? engineShade(h, ro, rd, keyDir, keyCol, pix) : background;
//   col += engineGlow(ro, rd, h.t > 0.0 ? h.t : tMax, pix);     // stars, core, fields, beacons, scan (additive)
//
//   engineKey(keyDir, keyCol);                          // engineFar's sunlight (call before it; default: none)
//   engineHaze(hazeCol, perUnit);                       // optional, any entry point: aerial depth inside the machine
//                                                       //   (parts blend toward hazeCol by 1 - exp(-t * perUnit)),
//                                                       //   and hazeCol * 0.5 fills the shadows as sky light
//   vec4 far = engineFar(ro, rd, tMax, pix);            // the world's sky: col = col * (1 - far.a) + far.rgb
//   float lod = engineLod(ro, pix);                     // the recommended lod for a camera at ro
//
// keyDir points TOWARD the light (engine-local, unit); keyCol = its colour * strength (linear). Everything linear.
// Call each entry point from ONE call site (drivers inline per call site).
//
// THE MACHINE: 16 hubs (big chamfered blocks: inset plates, a square port, lit windows, their 4D address in binary,
// lamps on the corner facets) joined by 32 box-section girders. A girder: heavy chamfered corner chords that carry the
// spectral conduit's light (the hypercube's edges read as lines of colour on a dark mass), a run of bays between two end
// sleeves (hex-plated fittings with the girder's number and a lit collar), each bay either plated (inset panels, rows of
// tiny lit windows, vents: the scale) or open Warren lacing you see through to the conduit inside and the sky beyond;
// rails with rivets and navigation lights. Triangular gusset plates (a hexagonal lightening hole in each) brace every
// corner of all 24 faces. Gunmetal with a thin-film coat and a groove grating: the spectrum lives in the highlights.
// The 8 cells: a captured star in each (7 colours + 1 white: a white-hot point, a halo, a six-point diffraction spike,
// a slow pulse) in a containment frame (corner brackets, a ruler, its serial C1..C8, a barcode), its light filling the
// cell like a lit room and falling on the girders round it; faint containment fields on the faces. The core: a black
// glass sphere, its rim in the spectrum, the starlight it holds swirling inside, in a miniature tesseract of light
// turning on its own (the world's tesseract takes over from it).
// Hue by corner = the number of its positive coordinates (tess_space's cornerHue), drifting; in the fold it blends to
// the world's grading across the square (tess_world's hueAt) so the hand-over keeps its colours.

#define ENG_POSE 48
uniform vec4 Eng[ENG_POSE];

#define ENG_M_HULL 1.0
#define ENG_M_INNER 2.0
#define ENG_M_CONDUIT 3.0
#define ENG_M_NODE 4.0
#define ENG_M_CORE 5.0
#define ENG_M_GUSSET 6.0

/** Girder half-width and hub half-size at size 1 (TesseractEngine.HB / NB). */
const float ENG_HB = 0.05;
const float ENG_NB = 0.105;
/** The girders' chamfer: their corners cut at this many half-widths along the diagonal. */
const float ENG_CH = 1.2;
/** The end sleeves' half-width, in girder half-widths. */
const float ENG_SL = 1.34;
/** How far the corner gussets reach along each girder, in girder half-widths. */
const float ENG_GU = 4.4;
const vec3 ENG_WHITE = vec3(1.0, 0.97, 1.0);
const vec3 ENG_TELE = vec3(0.62, 0.92, 1.0);
const vec3 ENG_WARM = vec3(1.0, 0.78, 0.5);

struct EngHit {
    float t;     // distance along the ray; < 0 = missed
    vec3 n;      // normal (engine-local)
    vec3 p;      // the hit point (engine-local; the glitch's shift included)
    float mat;   // ENG_M_*
    float id;    // girder 0..31 / hub 0..15 / face 0..23
    vec4 data;   // girders: the hit in the girder's frame and its plane; hubs: (-, -, -, slab); gussets: plane coords
};

// ---------------------------------------------------------------- the pose, loaded at each entry point
int gEngZero = 0;
float gEngSec = 0.0;
float gEngHull = 1.0;
float gEngSquash = 1.0;
float gEngExt = 1.9;
float gEngScanY = 9.0;
float gEngScan = 0.0;
float gEngFlash = 0.0;
float gEngGlitch = 0.0;
float gEngPhase = 0.0;
float gEngHue = 0.0;
float gEngPane = 0.0;
float gEngLines = 0.0;
vec4 gEngAbsorb = vec4(0.0);
float gEngBoot = 1.0;
float gEngThroat = 0.0;
float gEngEmerge = 0.0;
float gEngFold = 0.0;
vec3 gEngCoreC = vec3(0.0);
float gEngCoreS = 0.062;
float gEngCoreR = 0.058;
float gEngCoreI = 1.0;
vec4 gEngCosA = vec4(1.0);
vec4 gEngSinA = vec4(0.0);
/** engineFar's sunlight (engineKey); the haze (engineHaze). */
vec3 gEngKeyDir = vec3(0.0, 1.0, 0.0);
vec3 gEngKeyCol = vec3(0.0);
vec3 gEngHazeCol = vec3(0.0);
float gEngHazeK = 0.0;
/** Look-dev switches (bits): 256 no inner lights, 512 no grating, 1024 emissive only, 2048 no gussets, 4096 no hubs. */
int gEngDebug = 0;

void engLoad() {
    // a zero the compiler cannot see (x * 0.0 is folded on AMD, and a loop with a visible bound is unrolled whole)
    gEngZero = int(Eng[47].y);
    gEngSec = Eng[42].x;
    gEngHull = Eng[42].y;
    gEngSquash = Eng[42].z;
    gEngExt = Eng[42].w;
    gEngScanY = Eng[43].x;
    gEngScan = Eng[43].y;
    gEngFlash = Eng[43].z;
    gEngGlitch = Eng[43].w;
    gEngPhase = Eng[44].x;
    gEngHue = Eng[44].y;
    gEngPane = Eng[44].z;
    gEngLines = Eng[44].w;
    gEngAbsorb = Eng[45];
    gEngBoot = Eng[46].x;
    gEngThroat = Eng[46].y;
    gEngEmerge = Eng[46].z;
    gEngFold = Eng[46].w;
    gEngCoreC = vec3(0.0, Eng[41].x, 0.0);
    gEngCoreS = Eng[41].y;
    gEngCoreR = Eng[41].z;
    gEngCoreI = Eng[41].w;
    gEngCosA = cos(Eng[40]);
    gEngSinA = sin(Eng[40]);
}

/** engineFar's sunlight: toward the light (engine-local), colour * strength. */
void engineKey(vec3 keyDir, vec3 keyCol) {
    gEngKeyDir = keyDir;
    gEngKeyCol = keyCol;
}

/** Aerial depth inside the machine: parts blend toward hazeCol by 1 - exp(-t * perUnit) (t in engine units from the
 *  camera); hazeCol * 0.5 also fills the shadows (sky light). */
void engineHaze(vec3 hazeCol, float perUnit) {
    gEngHazeCol = hazeCol;
    gEngHazeK = perUnit;
}

/** The recommended lod for a camera at ro (0 hero close-ups .. 1 far). */
float engineLod(vec3 ro, float pix) {
    return smoothstep(0.0045, 0.012, pix * max(length(ro) - 1.0, 0.3));
}

float engHazeAt(float t) {
    return gEngHazeK > 0.0 ? 1.0 - exp(-max(t, 0.0) * gEngHazeK) : 0.0;
}

// ---------------------------------------------------------------- small helpers

float engLine(float d, float w, float aa) {
    return 1.0 - smoothstep(w - aa, w + aa, d);
}

/** 1 while a feature of this size is wider than ~1.5 pixels, fading to 0 below. */
float engFade(float size, float fp) {
    return 1.0 - smoothstep(0.4, 1.0, fp / max(size, 1e-6));
}

float engSpec(vec3 n, vec3 v, vec3 l, float rough) {
    vec3 hv = normalize(l + v);
    float nl = max(dot(n, l), 0.0);
    float nv = max(dot(n, v), 1e-3);
    float a = max(rough * rough, 0.003);
    float a2 = a * a;
    float nh = max(dot(n, hv), 0.0);
    float dd = nh * nh * (a2 - 1.0) + 1.0;
    float D = a2 / (PI * dd * dd);
    float kk = sqr(a + 1.0) / 8.0;
    float G = nv / (nv * (1.0 - kk) + kk) * nl / (nl * (1.0 - kk) + kk);
    return D * G / (4.0 * nv * nl + 1e-4) * nl;
}

/** Thin film (a dichroic coat on the gunmetal): its colour slides through the spectrum as the path through it shortens. */
vec3 engFilm(float nv, float hue) {
    return mix(vec3(0.62), prism7(hue + 0.62 * (1.0 - nv)), 0.32);
}

/** A groove grating round the girder (grooves across its axis u): the light it diffracts fans out along u in colours,
 *  so bands of the spectrum slide along a girder as the eye or the light moves. */
vec3 engGrating(vec3 n, vec3 v, vec3 l, vec3 u) {
    float nl = dot(n, l);
    if (nl <= 0.0) return vec3(0.0);
    vec3 sv = l + v;
    vec3 t2 = cross(n, u);
    float t2l = length(t2);
    if (t2l < 1e-4) return vec3(0.0);
    float across = dot(sv, t2 / t2l);
    float lobe = exp(-across * across / 0.02) * nl;
    float along = abs(dot(sv, u));
    vec3 c = vec3(0.0);
    for (int m = 1; m <= 2 + gEngZero; m++) {
        float lam = along * 1.6 / float(m);
        float w = smoothstep(0.38, 0.42, lam) * (1.0 - smoothstep(0.66, 0.72, lam));
        c += prism7((0.70 - lam) / 0.32 * (6.0 / 7.0)) * w / float(m);
    }
    return c * lobe;
}

/** What the hull mirrors: the key's side of the sky bright (the galaxy floor below / the Sun), the rest near black. */
vec3 engEnv(vec3 r, vec3 keyDir, vec3 keyCol) {
    float k = max(dot(r, keyDir), 0.0);
    return keyCol * (0.025 + 0.14 * k * k * k) + vec3(0.004, 0.0045, 0.007) + gEngHazeCol * 0.25 * saturate(r.y + 0.5);
}

vec3 engHex(vec2 p, float size) {
    vec2 q = p / size;
    vec2 rr = vec2(1.0, 1.7320508);
    vec2 hh = rr * 0.5;
    vec2 a = mod(q, rr) - hh;
    vec2 b = mod(q - hh, rr) - hh;
    vec2 g = dot(a, a) < dot(b, b) ? a : b;
    vec2 id = q - g;
    float e = 0.5 - max(abs(g.x), dot(abs(g), vec2(0.5, 0.8660254)));
    return vec3(e * size, id);
}

float engBar(float u, float seed) {
    float id = floor(u);
    float hh = hash11(id * 1.37 + seed * 17.0);
    float w = hh < 0.35 ? 0.25 : hh < 0.7 ? 0.5 : 0.75;
    return step(0.18, hh) * step(fract(u), w);
}

/** Seven-segment masks: 0-9, 10 = C, 11 = -, else blank. */
int engMask(int n) {
    return n == 0 ? 63 : n == 1 ? 6 : n == 2 ? 91 : n == 3 ? 79 : n == 4 ? 102 : n == 5 ? 109 : n == 6 ? 125
         : n == 7 ? 7 : n == 8 ? 127 : n == 9 ? 111 : n == 10 ? 57 : n == 11 ? 64 : 0;
}

float engSeg(vec2 p, int m) {
    float d = 1e3;
    if ((m & 1) != 0) d = min(d, sdSegment2(p, vec2(0.15, 1.85), vec2(0.85, 1.85)));
    if ((m & 2) != 0) d = min(d, sdSegment2(p, vec2(0.9, 1.78), vec2(0.9, 1.07)));
    if ((m & 4) != 0) d = min(d, sdSegment2(p, vec2(0.9, 0.93), vec2(0.9, 0.22)));
    if ((m & 8) != 0) d = min(d, sdSegment2(p, vec2(0.15, 0.15), vec2(0.85, 0.15)));
    if ((m & 16) != 0) d = min(d, sdSegment2(p, vec2(0.1, 0.93), vec2(0.1, 0.22)));
    if ((m & 32) != 0) d = min(d, sdSegment2(p, vec2(0.1, 1.78), vec2(0.1, 1.07)));
    if ((m & 64) != 0) d = min(d, sdSegment2(p, vec2(0.15, 1.0), vec2(0.85, 1.0)));
    return d;
}

/** Up to four seven-segment glyphs (codes as engMask) from `at`, glyph height hgt, in a plane's (u, v). */
float engGlyphs(vec2 uv, vec2 at, float hgt, ivec4 code, int count, float aa) {
    vec2 p = (uv - at) / (hgt * 0.5);
    float cellW = 1.35;
    if (p.y < -0.2 || p.y > 2.2 || p.x < -0.2 || p.x > cellW * float(count)) return 0.0;
    float fi = clamp(floor(p.x / cellW), 0.0, float(count - 1));
    int i = int(fi);
    int g = i == 0 ? code.x : i == 1 ? code.y : i == 2 ? code.z : code.w;
    float d = engSeg(vec2(p.x - fi * cellW, p.y), engMask(g));
    float a = aa / (hgt * 0.5);
    return smoothstep(0.12 + a, 0.12 - a, d);
}

// ---------------------------------------------------------------- colour

float engCornerHue(int i) {
    int n = (i & 1) + ((i >> 1) & 1) + ((i >> 2) & 1) + ((i >> 3) & 1);
    return float(n) * (1.5 / 7.0) + gEngHue;
}

/** tess_world's grading across the square (the cube +-1 standing on it), for the hand-over. */
float engWorldHue(vec3 p) {
    return (p.x + p.z + 2.0) * 0.25 * (6.0 / 7.0) + (p.y + 1.0) * 0.5 * 0.18 + gEngHue;
}

float engBeamHue(int i, int j, float s, vec3 p) {
    return mix(mix(engCornerHue(i), engCornerHue(j), s), engWorldHue(p), gEngFold);
}

/** A star's colour at T kelvin: the blackbody sweep from a red supergiant to a blue giant, a little deepened so
 *  Betelgeuse reads red and Rigel blue from the ground; linear, brightest channel 1 (TesseractEngine.kelvin is the same). */
vec3 engKelvin(float T) {
    vec3 c = mix(vec3(1.0, 0.15, 0.0), vec3(1.0, 0.3, 0.05), saturate((T - 3500.0) / 800.0));
    c = mix(c, vec3(1.0, 0.8, 0.6), saturate((T - 4300.0) / 1700.0));
    c = mix(c, vec3(0.55, 0.68, 1.0), saturate((T - 6000.0) / 3700.0));
    return mix(c, vec3(0.35, 0.5, 1.0), saturate((T - 9700.0) / 2400.0));
}

/** Cell c's star from the pose: (its serial 0..7, its temperature K, its radius as a fraction of the cell's scale). */
vec3 engStarCode(int c) {
    float v = Eng[17 + 3 * c].w;
    return vec3(floor(v / 1000.0), floor(mod(v, 1000.0)) * 100.0, fract(v));
}

/** Cell c's light: its star's colour. */
vec3 engCellCol(int c) {
    return engKelvin(engStarCode(c).y);
}

// ---------------------------------------------------------------- the glitch (the lock's bursts)

/** Torn in slices across the engine's own y: each slice of rays shifted sideways for a few frames. */
vec3 engGlitch(vec3 ro, vec3 rd) {
    if (gEngGlitch <= 0.001) return ro;
    float tc = max(-dot(ro, rd), 0.0);
    float yc = ro.y + rd.y * tc;
    float band = floor(yc / 0.055);
    float tq = floor(gEngSec * 24.0);
    float on = step(1.0 - 0.45 * gEngGlitch, hash12(vec2(band, tq)));
    float off = (hash12(vec2(band * 1.7 + 3.0, tq + 3.1)) - 0.5) * 0.16 * gEngGlitch * on;
    vec3 side = cross(rd, vec3(0.0, 1.0, 0.0));
    float sl = length(side);
    side = sl > 1e-3 ? side / sl : vec3(1.0, 0.0, 0.0);
    return ro + side * off;
}

// ---------------------------------------------------------------- the girders

/** Girder b: its corners i (bit k clear) and j = i | bit k. */
void engEdge(int b, out int i, out int j, out int k) {
    k = b >> 3;
    int m = b & 7;
    int low = (1 << k) - 1;
    i = (m & low) | ((m & (7 - low)) << 1);
    j = i | (1 << k);
}

/** Girder b's frame: from corner a along u (length len); e1, e2 across (rolled to its neighbour edge so its faces follow
 *  the cube's); its half-widths at both ends (the 4D perspective tapers it). */
void engFrame(int b, out int i, out int j, out vec3 a, out vec3 u, out vec3 e1, out vec3 e2, out float len,
              out float ha, out float hb) {
    int k;
    engEdge(b, i, j, k);
    a = Eng[i].xyz;
    vec3 ab = Eng[j].xyz - a;
    len = length(ab);
    u = ab / max(len, 1e-6);
    int ka = k == 0 ? 1 : k == 1 ? 2 : k == 2 ? 0 : 1;
    vec3 r = Eng[i ^ (1 << ka)].xyz - a;
    r -= u * dot(r, u);
    float rl = length(r);
    e1 = rl > 1e-5 ? r / rl : normalize(cross(u, vec3(0.31, 0.83, 0.47)));
    e2 = cross(u, e1);
    ha = ENG_HB * Eng[i].w * gEngHull;
    hb = ENG_HB * Eng[j].w * gEngHull;
}

/** How long a girder's end sleeves are: past the hub, never more than 28 % of it. */
float engEndZ(int i, int j, float len) {
    return min(ENG_NB * max(Eng[i].w, Eng[j].w) * gEngHull * 1.95, len * 0.28);
}

/** The bays between a girder's sleeves: their count and length (about 2.1 half-widths each). */
void engBays(float len, float endZ, float hm, out float np, out float pl) {
    float span = max(len - 2.0 * endZ, 1e-4);
    np = max(1.0, floor(span / (2.1 * max(hm, 1e-5)) + 0.5));
    pl = span / np;
}

/** Bay k of girder b: open lacing (1) or plated (0), the pattern symmetric about the girder's middle. */
float engBayOpen(int b, float k, float np) {
    float m = min(k, np - 1.0 - k);
    return step(hash12(vec2(float(b) * 1.73 + 0.5, m * 3.1 + 0.7)), 0.5);
}

/** One plane of a convex solid, f = dot(n, p) - c <= 0 inside: narrows (entry, exit) and records their planes. */
void engPl(vec3 n, float c, vec3 lo, vec3 ld, int id, inout vec2 tt, inout ivec2 pp) {
    float f0 = dot(n, lo) - c;
    float f1 = dot(n, ld);
    if (abs(f1) < 1e-9) {
        if (f0 > 0.0) tt.x = 1e30;
        return;
    }
    float t = -f0 / f1;
    if (f1 < 0.0) {
        if (t > tt.x) {
            tt.x = t;
            pp.x = id;
        }
    } else if (t < tt.y) {
        tt.y = t;
        pp.y = id;
    }
}

/** Plane id's normal in a girder's frame (g = the taper of that solid): 0-3 faces +x -x +y -y, 4-7 chamfers ++ +- -+ --,
 *  8 the z0 end, 9 the z1 end. */
vec3 engPlaneN(int id, float g) {
    if (id >= 8) return vec3(0.0, 0.0, id == 8 ? -1.0 : 1.0);
    if (id >= 4) {
        float sx = (id & 2) == 0 ? 0.70710678 : -0.70710678;
        float sy = (id & 1) == 0 ? 0.70710678 : -0.70710678;
        return vec3(sx, sy, -g * ENG_CH);
    }
    float sg = (id & 1) == 0 ? 1.0 : -1.0;
    return id < 2 ? vec3(sg, 0.0, -g) : vec3(0.0, sg, -g);
}

/** A chamfered box section along z (half-width h0 + g z) between z0 and z1, in a girder's frame: (entry, exit) and
 *  their planes base + engPlaneN's ids. caps = 0 leaves the ends open. */
void engSection(vec3 lo, vec3 ld, float h0, float g, float z0, float z1, int base, float caps, out vec2 tt, out ivec2 pp) {
    tt = vec2(-1e30, 1e30);
    pp = ivec2(-1);
    int np = (caps > 0.5 ? 10 : 8) + gEngZero;
    for (int k = 0; k < np; k++) {
        float c = k < 4 ? h0 : k < 8 ? h0 * ENG_CH : k == 8 ? -z0 : z1;
        engPl(engPlaneN(k, g), c, lo, ld, base + k, tt, pp);
    }
}

/**
 * The lacing in an open bay on face `face` of a girder: > 0 inside an opening (by how much, engine units), < 0 on metal.
 * One Warren diagonal a bay (alternating) with posts; opposite faces mirrored, so seen through them the diagonals cross.
 * lod > 0 thickens the bars until (lod 0.7) there are no openings.
 */
float engHole(vec3 q, int face, float ha, float g, float len, float endZ, int b, float lod) {
    if (lod > 0.7) return -1.0;
    float h = ha + g * q.z;
    float c = face < 2 ? q.y : q.x;
    if ((face & 1) == 1) c = -c;
    float hm = ha + g * len * 0.5;
    float np, pl;
    engBays(len, endZ, hm, np, pl);
    float z = q.z - endZ;
    if (z < 0.0 || z > np * pl) return -1.0;
    float zp = z / pl;
    float bay = min(floor(zp), np - 1.0);
    if (engBayOpen(b, bay, np) < 0.5) return -1.0;
    float fv = zp - bay;
    float R = 0.44 * h;
    float dir = mod(bay, 2.0) < 0.5 ? 1.0 : -1.0;
    vec2 P = vec2(fv * pl, c * dir);
    float dz = sdSegment2(P, vec2(0.0, -R), vec2(pl, R));
    float bw = h * (0.1 + 0.4 * lod);
    float dp = min(fv, 1.0 - fv) * pl;
    float pw = h * (0.1 + 0.35 * lod);
    return min(min(0.46 * h - abs(c), dz - bw), dp - pw);
}

/** The conduit inside a girder (a cylinder round its axis, radius rc) between t0 and t1, or -1. */
float engConduitT(vec3 lo, vec3 ld, float rc, float len, float t0, float t1) {
    float A = dot(ld.xy, ld.xy);
    if (A < 1e-9) return -1.0;
    float B = dot(lo.xy, ld.xy);
    float C = dot(lo.xy, lo.xy) - rc * rc;
    float D = B * B - A * C;
    if (D < 0.0) return -1.0;
    float t = (-B - sqrt(D)) / A;
    if (t < t0 || t > t1) return -1.0;
    float z = lo.z + ld.z * t;
    if (z < 0.0 || z > len) return -1.0;
    return t;
}

/** Ray against girder b: the main section (see-through lacing, the conduit inside) and its two end sleeves. */
void engBeamHit(int b, vec3 ro, vec3 rd, float lod, inout float best, inout EngHit h) {
    int i, j;
    vec3 a, u, e1, e2;
    float len, ha, hb;
    engFrame(b, i, j, a, u, e1, e2, len, ha, hb);
    if (len < 1e-4 || max(ha, hb) < 1e-5) return;
    float hmax = max(ha, hb) * ENG_SL * 1.22;
    // cheap rejects: the distance between the ray's line and the girder's, then its bounding sphere
    vec3 o = ro - a;
    vec3 cr = cross(rd, u);
    float cl = length(cr);
    if (cl > 1e-5 && abs(dot(o, cr)) > hmax * cl) return;
    vec3 oc = o - u * (len * 0.5);
    float bb = dot(oc, rd);
    float rad = len * 0.5 + hmax;
    float disc = bb * bb - dot(oc, oc) + rad * rad;
    if (disc < 0.0 || -bb - sqrt(disc) > best) return;
    vec3 lo = vec3(dot(o, e1), dot(o, e2), dot(o, u));
    vec3 ld = vec3(dot(rd, e1), dot(rd, e2), dot(rd, u));
    float g = (hb - ha) / len;
    float endZ = engEndZ(i, j, len);
    float tHit = best;
    int plane = -1;
    float mat = ENG_M_HULL;
    // three solids: the sleeve at each end, then the main section (see-through lacing, the conduit inside)
    for (int sid = 0; sid < 3 + gEngZero; sid++) {
        vec2 tt;
        ivec2 pp;
        engSection(lo, ld, sid == 0 ? ha * ENG_SL : sid == 1 ? hb * ENG_SL : ha, sid == 2 ? g : 0.0,
                   sid == 1 ? len - endZ : 0.0, sid == 0 ? endZ : len, sid == 0 ? 10 : sid == 1 ? 20 : 0, 1.0, tt, pp);
        if (tt.x >= tt.y || tt.x <= 0.0 || tt.x >= tHit) continue;
        float tm = tt.x;
        int pm = pp.x;
        float mm = ENG_M_HULL;
        if (sid == 2 && pm < 4) {
            // in through an opening? then the conduit, the inside of the far wall, or out through an opening there
            float o0 = -1.0;
            float o1 = -1.0;
            for (int e = 0; e < 2 + gEngZero; e++) {
                int pe = e == 0 ? pp.x : pp.y;
                float m = pe < 4 ? engHole(lo + ld * (e == 0 ? tt.x : tt.y), pe, ha, g, len, endZ, b, lod) : -1.0;
                if (e == 0) o0 = m; else o1 = m;
                if (o0 <= 0.0) break;
            }
            if (o0 > 0.0) {
                float tc = engConduitT(lo, ld, 0.17 * min(ha, hb), len, tt.x, tt.y);
                if (tc > 0.0) {
                    tm = tc;
                    mm = ENG_M_CONDUIT;
                } else if (o1 > 0.0) {
                    continue;
                } else {
                    tm = tt.y;
                    pm = pp.y;
                    mm = ENG_M_INNER;
                }
            }
        }
        tHit = tm;
        plane = pm;
        mat = mm;
    }
    if (plane < 0) return;
    best = tHit;
    vec3 q = lo + ld * tHit;
    vec3 nl;
    if (mat == ENG_M_CONDUIT) {
        nl = vec3(q.xy, 0.0);
    } else {
        nl = engPlaneN(plane - (plane >= 20 ? 20 : plane >= 10 ? 10 : 0), plane >= 10 ? 0.0 : g);
        if (mat == ENG_M_INNER) nl = -nl;
    }
    h.t = tHit;
    h.n = normalize(e1 * nl.x + e2 * nl.y + u * nl.z);
    h.p = ro + rd * tHit;
    h.mat = mat;
    h.id = float(b);
    h.data = vec4(q, float(plane));
}

// ---------------------------------------------------------------- the hubs

/** |o + t d| <= c: narrows (entry, exit), records the entry's slab and side. */
void engSlab(float o, float d, float c, int id, inout vec2 tt, inout int pN, inout float sN) {
    if (abs(d) < 1e-9) {
        if (abs(o) > c) tt.x = 1e30;
        return;
    }
    float inv = 1.0 / d;
    float t0 = (-c - o) * inv;
    float t1 = (c - o) * inv;
    float tn = min(t0, t1);
    if (tn > tt.x) {
        tt.x = tn;
        pN = id;
        sN = d > 0.0 ? -1.0 : 1.0;
    }
    tt.y = min(tt.y, max(t0, t1));
}

/** The hub's slabs: 0-2 the faces (x y z), 3-8 the edge chamfers (x+y, x-y, x+z, x-z, y+z, y-z), 9-12 the corner facets
 *  (+++, ++-, +-+, -++). Unnormalised. */
vec3 engSlabN(int id) {
    if (id < 3) return vec3(id == 0 ? 1.0 : 0.0, id == 1 ? 1.0 : 0.0, id == 2 ? 1.0 : 0.0);
    if (id < 9) {
        int q = id - 3;
        float sg = (q & 1) == 0 ? 1.0 : -1.0;
        return q < 2 ? vec3(1.0, sg, 0.0) : q < 4 ? vec3(1.0, 0.0, sg) : vec3(0.0, 1.0, sg);
    }
    return vec3(id == 12 ? -1.0 : 1.0, id == 11 ? -1.0 : 1.0, id == 10 ? -1.0 : 1.0);
}

/** Hub i: a chamfered cube block (6 faces, 12 edge chamfers, 8 corner facets) at the corner. */
void engNodeHit(int i, vec3 ro, vec3 rd, inout float best, inout EngHit h) {
    float nh = ENG_NB * Eng[i].w * gEngHull;
    if (nh < 1e-5) return;
    vec3 o = ro - Eng[i].xyz;
    float bb = dot(o, rd);
    float rad = nh * 1.62;
    float disc = bb * bb - dot(o, o) + rad * rad;
    if (disc < 0.0 || -bb - sqrt(disc) > best) return;
    vec2 tt = vec2(-1e30, 1e30);
    int pN = -1;
    float sN = 1.0;
    for (int k = 0; k < 13 + gEngZero; k++) {
        vec3 sn = engSlabN(k);
        engSlab(dot(o, sn), dot(rd, sn), (k < 3 ? 1.0 : k < 9 ? 1.75 : 2.3) * nh, k, tt, pN, sN);
    }
    if (tt.x >= tt.y || tt.x <= 0.0 || tt.x >= best) return;
    best = tt.x;
    h.t = tt.x;
    h.n = normalize(engSlabN(pN) * sN);
    h.p = ro + rd * tt.x;
    h.mat = ENG_M_NODE;
    h.id = float(i);
    h.data = vec4(0.0, 0.0, 0.0, float(pN));
}

// ---------------------------------------------------------------- the faces: gusset plates, fields

/** Face f (0..23): its corner i0 and the two bits that span it. */
void engFace(int f, out int i0, out int ia, out int ib) {
    int pr = f >> 2;
    int cmb = f & 3;
    int ax = pr < 3 ? 0 : pr < 5 ? 1 : 2;
    int ay = pr == 0 ? 1 : pr == 1 ? 2 : pr == 3 ? 2 : 3;
    int r0 = pr == 0 ? 2 : pr < 3 ? 1 : 0;
    int r1 = pr == 0 ? 3 : pr == 1 ? 3 : pr == 2 ? 2 : pr == 3 ? 3 : pr == 4 ? 2 : 1;
    i0 = ((cmb & 1) << r0) | ((cmb >> 1) << r1);
    ia = 1 << ax;
    ib = 1 << ay;
}

/**
 * Face f against the ray: its t (< 0 none), the point's distances inside its four edges (d.x along p00-p10, then round),
 * and how far inside a corner gusset it is (gs > 0: on a plate; its lightening hole excluded), which corner (0..3).
 */
float engFaceHit(int f, vec3 ro, vec3 rd, float tMax, out vec4 d, out float gs, out int corner, out vec3 n) {
    int i0, ia, ib;
    engFace(f, i0, ia, ib);
    d = vec4(-1.0);
    gs = -1.0;
    corner = 0;
    vec3 p00 = Eng[i0].xyz;
    vec3 p10 = Eng[i0 | ia].xyz;
    vec3 p01 = Eng[i0 | ib].xyz;
    vec3 p11 = Eng[i0 | ia | ib].xyz;
    n = vec3(0.0, 1.0, 0.0);
    // a sphere round the quad rejects most rays
    vec3 mc = (p00 + p10 + p01 + p11) * 0.25;
    float r2 = max(max(dot(p00 - mc, p00 - mc), dot(p10 - mc, p10 - mc)), max(dot(p01 - mc, p01 - mc), dot(p11 - mc, p11 - mc)));
    vec3 oq = ro - mc;
    float bq = dot(oq, rd);
    float cq = dot(oq, oq) - r2;
    if (cq > 0.0 && (bq > 0.0 || bq * bq < cq)) return -1.0;
    n = cross(p10 - p00, p01 - p00);
    float nl = length(n);
    if (nl < 1e-7) return -1.0;
    n /= nl;
    float den = dot(rd, n);
    if (abs(den) < 1e-5) return -1.0;
    float t = dot(p00 - ro, n) / den;
    if (t <= 0.0 || t >= tMax) return -1.0;
    vec3 q = ro + rd * t;
    vec3 E0 = p10 - p00;
    vec3 E1 = p11 - p10;
    vec3 E2 = p01 - p11;
    vec3 E3 = p00 - p01;
    d.x = dot(cross(E0, q - p00), n) * inversesqrt(dot(E0, E0) + 1e-12);
    d.y = dot(cross(E1, q - p10), n) * inversesqrt(dot(E1, E1) + 1e-12);
    d.z = dot(cross(E2, q - p11), n) * inversesqrt(dot(E2, E2) + 1e-12);
    d.w = dot(cross(E3, q - p01), n) * inversesqrt(dot(E3, E3) + 1e-12);
    if (min(min(d.x, d.y), min(d.z, d.w)) <= 0.0) return -1.0;
    float k = ENG_HB * ENG_GU * gEngHull;
    vec4 G = vec4(Eng[i0].w, Eng[i0 | ia].w, Eng[i0 | ia | ib].w, Eng[i0 | ib].w) * k;
    vec4 legA = vec4(d.w, d.x, d.y, d.z);
    vec4 legB = vec4(d.x, d.y, d.z, d.w);
    vec4 m = G - (legA + legB);
    corner = m.x >= max(m.y, max(m.z, m.w)) ? 0 : m.y >= max(m.z, m.w) ? 1 : m.z >= m.w ? 2 : 3;
    float gk = corner == 0 ? G.x : corner == 1 ? G.y : corner == 2 ? G.z : G.w;
    float la = corner == 0 ? legA.x : corner == 1 ? legA.y : corner == 2 ? legA.z : legA.w;
    float lb = corner == 0 ? legB.x : corner == 1 ? legB.y : corner == 2 ? legB.z : legB.w;
    gs = gk - la - lb;
    // the lightening hole: a hexagon in the plate's middle
    vec2 hc = vec2(la, lb) - gk * 0.3;
    float hexd = max(max(abs(hc.x), abs(hc.y)), abs(hc.x + hc.y) * 0.75);
    gs = min(gs, hexd - gk * 0.1);
    return t;
}

/**
 * The gusset plates round hub i: in each of its 6 faces a triangle bracing the corner (legs G along its two girders, in
 * the plane through both girders' axes) with a hexagonal lightening hole. Found per hub (a sphere round each rejects
 * nearly every ray), so the cost does not grow with the faces.
 */
void engGussetHit(vec3 ro, vec3 rd, inout float best, inout EngHit h) {
    int nn = 16 + gEngZero;
    for (int i = 0; i < nn; i++) {
        float G = ENG_HB * ENG_GU * Eng[i].w * gEngHull;
        if (G < 1e-5) continue;
        vec3 P = Eng[i].xyz;
        vec3 o = ro - P;
        float bb = dot(o, rd);
        float cc = dot(o, o) - G * G;
        float disc = bb * bb - cc;
        if (disc < 0.0 || (cc > 0.0 && bb > 0.0)) continue;
        if (-bb - sqrt(disc) > best) continue;
        for (int k = 0; k < 6 + gEngZero; k++) {
            int ka = k < 3 ? 0 : k < 5 ? 1 : 2;
            int kb = k == 0 ? 1 : k == 1 ? 2 : k == 2 ? 3 : k == 3 ? 2 : 3;
            vec3 A = Eng[i ^ (1 << ka)].xyz - P;
            vec3 B = Eng[i ^ (1 << kb)].xyz - P;
            float la = length(A);
            float lb = length(B);
            if (la < 1e-4 || lb < 1e-4) continue;
            vec3 ua = A / la;
            vec3 ub = B / lb;
            vec3 n = cross(ua, ub);
            float nl = length(n);
            if (nl < 1e-3) continue;
            n /= nl;
            float den = dot(rd, n);
            if (abs(den) < 1e-5) continue;
            float t = -dot(o, n) / den;
            if (t <= 0.0 || t >= best) continue;
            vec3 q = o + rd * t;
            float qa = dot(q, ua);
            float qb = dot(q, ub);
            float ab = dot(ua, ub);
            float det = max(1.0 - ab * ab, 1e-4);
            float al = (qa - ab * qb) / det;
            float be = (qb - ab * qa) / det;
            float Gk = min(G, min(la, lb) * 0.45);
            float gs = min(min(al, be), Gk - al - be);
            vec2 hc = vec2(al, be) - Gk * 0.3;
            float hexd = max(max(abs(hc.x), abs(hc.y)), abs(hc.x + hc.y) * 0.75);
            gs = min(gs, hexd - Gk * 0.1);
            if (gs <= 0.0) continue;
            best = t;
            h.t = t;
            h.n = den < 0.0 ? n : -n;
            h.p = ro + rd * t;
            h.mat = ENG_M_GUSSET;
            h.id = float(i);
            h.data = vec4(al, be, Gk - al - be, Gk);
        }
    }
}

// ---------------------------------------------------------------- the trace

EngHit engineTrace(vec3 ro, vec3 rd, float tMax, float lod) {
    engLoad();
    EngHit h;
    h.t = -1.0;
    h.n = vec3(0.0, 1.0, 0.0);
    h.p = vec3(0.0);
    h.mat = 0.0;
    h.id = 0.0;
    h.data = vec4(0.0);
    ro = engGlitch(ro, rd);
    vec2 bs = raySphere(ro, rd, vec3(0.0), gEngExt);
    if (bs.y <= 0.0 || bs.x > tMax) return h;
    float best = tMax;
    if (gEngHull > 0.001) {
        int nb = 32 + gEngZero;
        for (int b = 0; b < nb; b++) engBeamHit(b, ro, rd, lod, best, h);
        int nn = 16 + gEngZero;
        if ((gEngDebug & 4096) == 0) for (int i = 0; i < nn; i++) engNodeHit(i, ro, rd, best, h);
        if ((gEngDebug & 2048) == 0) engGussetHit(ro, rd, best, h);
    }
    if (gEngCoreR > 1e-4) {
        vec2 hc = raySphere(ro, rd, gEngCoreC, gEngCoreR);
        if (hc.x > 0.0 && hc.x < best) {
            best = hc.x;
            h.t = hc.x;
            h.p = ro + rd * hc.x;
            h.n = normalize(h.p - gEngCoreC);
            h.mat = ENG_M_CORE;
            h.id = 0.0;
            h.data = vec4(0.0);
        }
    }
    return h;
}

// ---------------------------------------------------------------- light

/** The stars' and the core's light on a surface: diffuse irradiance (rgb) and a glossy glint along r. */
void engInnerLight(vec3 p, vec3 n, vec3 r, out vec3 diff, out vec3 gloss) {
    diff = vec3(0.0);
    gloss = vec3(0.0);
    int nc = 8 + gEngZero;
    for (int c = 0; c < nc; c++) {
        vec4 A = Eng[16 + 3 * c];
        float br = Eng[18 + 3 * c].w;
        if (A.w <= 0.0 || br <= 0.0) continue;
        vec3 L = A.xyz - p;
        float d2 = dot(L, L);
        float r2 = A.w * A.w;
        vec3 Ln = L * inversesqrt(d2 + 1e-8);
        float fall = br * r2 / (d2 + r2 * 0.5);
        vec3 tint = engCellCol(c);
        diff += tint * fall * saturate(dot(n, Ln) * 0.8 + 0.2);
        float rl = max(dot(r, Ln), 0.0);
        gloss += tint * fall * pow(rl, 14.0);
    }
    vec3 L = gEngCoreC - p;
    float d2 = dot(L, L);
    vec3 Ln = L * inversesqrt(d2 + 1e-8);
    vec3 cc = mix(vec3(0.8, 0.86, 1.0), gEngAbsorb.rgb, saturate(gEngAbsorb.w * 0.5)) * gEngCoreI;
    float fall = 0.01 / (d2 + 0.01) * (1.0 + gEngAbsorb.w * 0.6);
    diff += cc * fall * saturate(dot(n, Ln) * 0.8 + 0.2);
    gloss += cc * fall * pow(max(dot(r, Ln), 0.0), 14.0);
}

/** Gunmetal with its coat: key (wrapped Lambert + GGX tinted by the film), the grating, a backlit rim when you look
 *  toward the light, the mirrored sky, sky fill in the shadows, and the machine's own lights. */
vec3 engLit(vec3 p, vec3 n, vec3 v, vec3 keyDir, vec3 keyCol, vec3 alb, float rough, float hue, vec3 u, float grating) {
    float nv = saturate(dot(n, v));
    vec3 r = reflect(-v, n);
    float nl = dot(n, keyDir);
    vec3 film = engFilm(nv, hue);
    float x = 1.0 - nv;
    float x2 = x * x;
    vec3 F = (0.06 + 0.5 * x2 * x2 * x) * film;
    vec3 col = alb * keyCol * (max((nl + 0.2) / 1.2, 0.0) + 0.06);
    col += F * keyCol * engSpec(n, v, keyDir, rough) * 1.4;
    if ((gEngDebug & 1024) != 0) return vec3(0.0);
    if (grating > 0.0 && (gEngDebug & 512) == 0) col += engGrating(n, v, keyDir, u) * keyCol * 0.35 * grating;
    col += F * engEnv(r, keyDir, keyCol);
    // backlit: the silhouette's edges catch the light behind it
    col += film * keyCol * x2 * x * saturate(dot(-v, keyDir)) * 0.35;
    col += alb * gEngHazeCol * 0.5 * (0.55 + 0.45 * n.y);
    if ((gEngDebug & 256) == 0) {
        vec3 dI, gI;
        engInnerLight(p, n, r, dI, gI);
        col += alb * dI * 2.2 + F * gI * 1.5;
    }
    return col;
}

// ---------------------------------------------------------------- the girders' skin

vec3 engConduitCol(int b, float s, float hue, float len) {
    float flow = s * len / 0.32 + gEngPhase * 2.2 + hash11(float(b) * 3.7);
    float pulse = exp(-sqr((fract(flow) - 0.5) / 0.07));
    vec3 hc = prism7(hue);
    vec3 c = hc * (0.35 + 1.4 * gEngBoot) + ENG_WHITE * pulse * 2.4 * gEngBoot;
    return c * (1.0 + 1.6 * gEngFlash + 1.5 * gEngThroat + 2.0 * gEngLines);
}

/** Seven-segment text a surface asks for: drawn once, after the surfaces (one inlined copy of the glyphs). */
struct EngText {
    vec2 uv;
    vec2 at;
    float hgt;
    ivec4 code;
    int count;
    float aa;
    float amt;
};

/** A row of tiny lit windows (the scale) at w = (along, across) in half-widths: 0..1, averaged when too small to see. */
float engWindows(vec2 w, float seed, float fpH) {
    float sp = 0.075;
    float id = floor(w.x / sp);
    float on = step(hash12(vec2(id, seed)), 0.55);
    float lamp = step(abs((fract(w.x / sp) - 0.5) * sp), 0.022) * step(abs(w.y), 0.03);
    float flick = 0.8 + 0.2 * sin(gEngSec * (0.7 + hash12(vec2(id, seed + 3.0)) * 2.0) + id);
    float avg = step(abs(w.y), 0.03) * 0.55 * 0.59;
    return mix(avg, lamp * on * flick, engFade(0.03, fpH));
}

/**
 * A girder's skin at q (its frame) on plane pl (0-9 the main section, 10-19 / 20-29 the sleeves): albedo, emission,
 * roughness and how much of the grating. h = the half-width there, fp = the footprint, cond = the conduit's light.
 */
void engSkin(int b, vec3 q, int pl, float h, float len, float endZ, float hm, float fp, float hue, vec3 cond,
             out vec3 alb, out vec3 emit, out float rough, out float grat, out float ao, out float bev, out vec2 nj,
             inout EngText tx) {
    int base = pl >= 20 ? 20 : pl >= 10 ? 10 : 0;
    int id = pl - base;
    vec3 hc = prism7(hue);
    float fpH = fp / max(h, 1e-6);
    // gunmetal, streaked along the girder
    alb = vec3(0.075, 0.077, 0.086) * (0.8 + 0.4 * vnoise2(vec2(q.z / h * 1.3, (q.x + q.y) / h * 2.0 + float(b) * 7.0)));
    emit = vec3(0.0);
    rough = 0.42;
    grat = 0.0;
    ao = 1.0;
    bev = 0.0;
    nj = vec2(0.0);
    if (id < 4) {
        float c = (id < 2 ? q.y : q.x) / h;
        float ac = abs(c);
        // the faces' edges are bevelled into the chamfers (the shade tilts the normal by bev)
        bev = smoothstep(0.55, 0.67, ac) * sign(c);
        if (base > 0) {
            // the end sleeves: heavy fittings, hex-plated, a lit collar, the girder's number
            float zz = base == 10 ? q.z : len - q.z;
            vec3 hx = engHex(vec2(zz / h, c), 0.13);
            float seam = engLine(hx.x, 0.012, fpH * 0.6) * engFade(0.03, fpH);
            alb *= (1.0 - 0.55 * seam) * (0.85 + 0.3 * hash12(hx.yz + float(b)));
            nj = (hash22(hx.yz + float(b) * 1.3) - 0.5) * 0.1 * engFade(0.08, fpH);
            float collar = engLine(abs(zz / max(endZ, 1e-6) - 0.82), 0.014, fpH * 0.8 / max(endZ / h, 1e-3));
            emit += hc * collar * (0.45 + 1.2 * gEngFlash) * gEngBoot;
            float lit = step(0.95, hash12(hx.yz + float(b) * 7.1)) * smoothstep(0.012, 0.03, hx.x) * engFade(0.05, fpH);
            emit += ENG_WARM * lit * 0.22 * gEngBoot;
            if (id == 0 || id == 2) {
                int nb = b + 1;
                tx.uv = vec2(zz / h, c);
                tx.at = vec2(0.45, -0.3);
                tx.hgt = 0.55;
                tx.code = ivec4(nb / 10, nb - (nb / 10) * 10, 0, 0);
                tx.count = 2;
                tx.aa = fpH * 0.7;
                tx.amt = engFade(0.05, fpH);
            }
            grat = 0.5;
            rough = 0.36;
        } else {
            float np, pl2;
            engBays(len, endZ, hm, np, pl2);
            float zp = (q.z - endZ) / pl2;
            float bay = clamp(floor(zp), 0.0, np - 1.0);
            float zl = zp - bay;
            float zb = zl * pl2 / h;
            float open = engBayOpen(b, bay, np);
            float seamZ = engLine(min(zl, 1.0 - zl) * pl2 / h, 0.012, fpH * 0.6) * engFade(0.025, fpH);
            // in the sleeves' shadow
            ao = 0.45 + 0.55 * smoothstep(0.0, 1.4 * h, min(q.z - endZ, len - endZ - q.z));
            if (ac > 0.46) {
                // the chords' rails: rivets, seams, navigation lights every third bay
                float rv = length(vec2((fract(q.z / (0.12 * h)) - 0.5) * 0.12, ac - 0.56));
                float rivet = engLine(rv, 0.011, fpH * 0.6) * engFade(0.03, fpH);
                alb = mix(alb * 0.8, vec3(0.13), rivet) * (1.0 - 0.6 * seamZ);
                if (id < 2 && mod(bay, 3.0) < 0.5) {
                    float led = length(vec2(min(zl, 1.0 - zl) * pl2 / h, ac - 0.57));
                    float w = max(0.04, fpH * 0.8);
                    float ph = fract(gEngSec * 0.5 + float(b) * 0.21 + bay * 0.13);
                    float strobe = exp(-sqr((ph - 0.1) / 0.03));
                    vec3 lc = c > 0.0 ? vec3(1.0, 0.12, 0.06) : ENG_WHITE;
                    emit += lc * exp(-sqr(led / w)) * (0.35 + 6.0 * strobe) * gEngBoot;
                }
                grat = 1.0;
                rough = 0.38;
            } else if (open > 0.5) {
                // the lacing's bars and posts (and any opening the trace closed, painted: dark, the conduit inside)
                vec3 qh = id < 2 ? vec3(0.0, c * h, q.z) : vec3(c * h, 0.0, q.z);
                float m0 = engHole(qh, id, h, 0.0, len, endZ, b, 0.0);
                float shut = smoothstep(-fp * 0.6, fp * 0.6, m0);
                alb *= 0.8 * (1.0 - shut);
                emit += (vec3(0.002) + cond * 0.045) * shut;
                grat = 0.6;
            } else {
                // plated: an inset panel split in two or three, seams, a row of windows, a block of vents
                float hb = hash12(vec2(float(b) * 3.7, bay * 1.3));
                float inset = max(ac - 0.38, abs(zl - 0.5) * pl2 / h - (pl2 / h * 0.5 - 0.08));
                float edge = engLine(abs(inset), 0.012, fpH * 0.6) * engFade(0.025, fpH);
                float split = fract(hb * 7.0) < 0.5 ? 0.5 : 0.36;
                float sd = engLine(abs(zl - split) * pl2 / h, 0.01, fpH * 0.6) * engFade(0.025, fpH) * step(inset, 0.0);
                vec2 pid = vec2(bay, float(b) + step(split, zl) * 5.0);
                float tone = 0.8 + 0.45 * hash12(pid);
                // each plate set a hair off true, so the sky it mirrors breaks up plate by plate
                nj = (hash22(pid + 3.7) - 0.5) * 0.16 * step(inset, 0.0);
                alb *= tone * (1.0 - 0.6 * max(edge, sd)) * (1.0 - 0.45 * seamZ);
                ao *= 1.0 - 0.35 * smoothstep(-0.08, 0.0, inset) * step(inset, 0.0);
                float rowC = (fract(hb * 13.0) - 0.5) * 0.4;
                float wl = engWindows(vec2(zb, c - rowC), float(b) * 5.0 + bay, fpH) * step(inset, -0.02) * step(0.25, hb);
                vec3 wc = fract(hb * 31.0) < 0.6 ? ENG_WARM : ENG_TELE;
                emit += wc * wl * 0.9 * gEngBoot;
                if (fract(hb * 19.0) < 0.35) {
                    float vz = zb - 0.35;
                    float slot = step(abs(fract(vz / 0.06) - 0.5), 0.22) * step(abs(c + rowC * 0.5), 0.2) * step(0.0, vz)
                               * step(vz, 0.42);
                    alb *= 1.0 - 0.75 * slot * engFade(0.03, fpH);
                }
                grat = 0.25;
                rough = 0.5;
            }
        }
    } else if (id < 8) {
        // the chamfered chords carry the conduit's light down the girder's four corners
        float sg1 = (id == 4 || id == 5) ? 1.0 : -1.0;
        float sg2 = (id == 4 || id == 6) ? 1.0 : -1.0;
        float xc = dot(q.xy, vec2(sg1, -sg2)) * 0.70710678 / h;
        // a light tube set in the chord: a hot thin core (its energy kept as it shrinks under a pixel), a soft spill
        float wc = max(0.022, fpH * 0.7);
        float tube = exp(-sqr(xc / wc)) * (0.022 / wc) * 1.6 + exp(-abs(xc) / 0.07) * 0.1;
        float edges = engLine(abs(abs(xc) - 0.2), 0.012, max(fpH, 0.01)) * engFade(0.03, fpH);
        emit += cond * tube;
        alb *= 1.0 - 0.6 * edges;
        grat = 0.8;
        rough = 0.32;
    } else if (base > 0) {
        // the sleeve's shoulder (its step face): a ring of hue
        emit += hc * 0.25 * gEngBoot;
    }
}

/** A girder's surface: its material for engLit, or (returns true) a finished colour (the conduit, the inside wall). */
bool engBeamSurf(EngHit h, vec3 rd, vec3 keyCol, float fp, inout vec3 n, out vec3 alb, out vec3 emit, out float rough,
                 out float grat, out float ao, out float hue, out vec3 u, inout EngText tx, out vec3 direct) {
    int b = int(h.id + 0.5);
    int i, j;
    vec3 a, e1, e2;
    float len, ha, hb;
    engFrame(b, i, j, a, u, e1, e2, len, ha, hb);
    len = max(len, 1e-5);
    vec3 q = h.data.xyz;
    int plane = int(h.data.w + 0.5);
    float g = (hb - ha) / len;
    float hz = max(ha + g * q.z, 1e-6);
    float s = saturate(q.z / len);
    hue = engBeamHue(i, j, s, h.p);
    vec3 cond = engConduitCol(b, s, hue, len);
    alb = vec3(0.0);
    emit = vec3(0.0);
    rough = 0.4;
    grat = 0.0;
    ao = 1.0;
    direct = vec3(0.0);
    if (h.mat == ENG_M_CONDUIT) {
        // a plasma tube: white-hot along its axis, its colour toward the edges
        float nv = saturate(dot(n, -rd));
        direct = cond * (0.35 + 0.6 * nv) + ENG_WHITE * nv * nv * nv * nv * 1.2 * gEngBoot;
        return true;
    }
    if (h.mat == ENG_M_INNER) {
        direct = vec3(0.002) + cond * 0.05 * exp(-length(q.xy) / hz * 1.5) + keyCol * 0.003;
        return true;
    }
    float endZ = engEndZ(i, j, len);
    float hFace = plane >= 20 ? hb * ENG_SL : plane >= 10 ? ha * ENG_SL : hz;
    float bev;
    vec2 nj;
    engSkin(b, q, plane, hFace, len, endZ, ha + g * len * 0.5, fp, hue, cond, alb, emit, rough, grat, ao, bev, nj, tx);
    int face = plane - (plane >= 20 ? 20 : plane >= 10 ? 10 : 0);
    if (face < 4) n = normalize(n + (face < 2 ? e2 : e1) * (bev * 0.9 + nj.x) + u * nj.y);
    emit += cond * (1.0 - gEngHull) * 1.4;
    hue += 0.25;
    return false;
}

/** A hub's surface. */
void engNodeSurf(EngHit h, float fp, inout vec3 n, out vec3 alb, out vec3 emit, out float rough, out float hue,
                 inout EngText tx) {
    int i = int(h.id + 0.5);
    float nh = max(ENG_NB * Eng[i].w * gEngHull, 1e-6);
    vec3 q = (h.p - Eng[i].xyz) / nh;
    int pl = int(h.data.w + 0.5);
    hue = mix(engCornerHue(i), engWorldHue(h.p), gEngFold);
    vec3 hc = prism7(hue);
    alb = vec3(0.075, 0.077, 0.086);
    rough = 0.42;
    emit = hc * (1.0 - gEngHull) * 2.0;
    float fl = fp / nh;
    if (pl < 3) {
        // the flat of the face runs to 0.75 (the chamfers take the rest)
        vec2 uv = (pl == 0 ? q.yz : pl == 1 ? q.xz : q.xy) / 0.75;
        fl /= 0.75;
        vec2 au = abs(uv);
        float sq = max(au.x, au.y);
        // a stepped aperture where the conduits meet: three square lips going in, the port glowing at the bottom
        float port = 1.0 - smoothstep(0.3 - fl, 0.3 + fl, sq);
        float lips = engLine(abs(sq - 0.3), 0.012, fl * 0.7) + engLine(abs(sq - 0.23), 0.008, fl * 0.7) * 0.6
                   + engLine(abs(sq - 0.16), 0.006, fl * 0.7) * 0.4;
        float deep = 1.0 - smoothstep(0.15, 0.16 + fl, sq);
        float brk = engLine(abs(sq - 0.38), 0.01, fl * 0.7) * step(0.3, min(au.x, au.y));
        // plates: a 4 x 4 grid, some split again, each its own tone, roughness and a hair of tilt; seams shadowed
        vec2 gcell = floor((uv + 1.0) * 2.0);
        vec2 gl = fract((uv + 1.0) * 2.0) - 0.5;
        float hp = hash12(gcell + float(i) * 3.3 + float(pl) * 11.0);
        vec2 gl2 = hp < 0.4 ? vec2(fract(gl.x * 2.0 + 0.5) - 0.5, gl.y) : gl;
        float seam = engLine(0.5 - max(abs(gl2.x), abs(gl2.y)), 0.025, fl * 2.0) * engFade(0.02 * nh, fp) * (1.0 - port);
        float tone = 0.75 + 0.5 * hash12(gcell * 1.7 + float(i) + float(pl) * 5.0 + step(0.0, gl.x) * step(hp, 0.4));
        alb *= tone * (1.0 - 0.6 * seam) * (1.0 - 0.95 * port);
        rough = 0.32 + 0.25 * hp;
        // bevelled into the chamfers, each plate set a hair off true
        vec2 tl = smoothstep(0.86, 1.0, au) * sign(uv) * 0.9 + (hash22(gcell * 2.3 + float(i) + float(pl) * 7.0) - 0.5) * 0.14 * (1.0 - port);
        n = normalize(n + (pl == 0 ? vec3(0.0, tl.x, tl.y) : pl == 1 ? vec3(tl.x, 0.0, tl.y) : vec3(tl.x, tl.y, 0.0)));
        // windows along some plates; vents on others
        float wrow = step(abs(gl.y + 0.28), 0.03) * step(abs(gl.x), 0.4) * step(0.42, sq) * step(0.55, hp);
        float win = wrow * step(hash12(vec2(floor(gl.x * 16.0), gcell.x * 7.0 + gcell.y + float(i))), 0.6);
        emit += mix(ENG_WARM, ENG_TELE, step(0.8, hp)) * mix(wrow * 0.33, win, engFade(0.025 * nh, fp)) * 0.8 * gEngBoot;
        float vent = step(abs(fract(gl.x * 7.0) - 0.5), 0.2) * step(abs(gl.y), 0.3) * step(abs(gl.x), 0.38)
                   * step(0.42, sq) * step(hp, 0.18);
        alb *= 1.0 - 0.8 * vent * engFade(0.02 * nh, fp);
        emit += hc * (lips * 1.1 + brk * 0.5) * gEngBoot;
        emit += mix(hc, ENG_WHITE, 0.5) * deep * (0.35 + 1.2 * gEngFlash) * gEngBoot;
        // its 4D address in binary, along one edge
        tx.uv = uv;
        tx.at = vec2(-0.82, 0.66);
        tx.hgt = 0.2;
        tx.code = ivec4(i & 1, (i >> 1) & 1, (i >> 2) & 1, (i >> 3) & 1);
        tx.count = 4;
        tx.aa = fl * 0.7;
        tx.amt = engFade(0.05 * nh, fp);
    } else if (pl < 9) {
        // the edge chamfers: a light seam down the middle (a hot thin core, a soft spill)
        vec3 ax = engSlabN(pl);
        vec3 along = ax.x == 0.0 ? vec3(1.0, 0.0, 0.0) : ax.y == 0.0 ? vec3(0.0, 1.0, 0.0) : vec3(0.0, 0.0, 1.0);
        float xc = dot(q, normalize(cross(along, ax)));
        float wc = max(0.012, fl * 0.7);
        emit += hc * (exp(-sqr(xc / wc)) * (0.012 / wc) * 1.4 + exp(-abs(xc) / 0.05) * 0.06) * gEngBoot;
        alb *= 0.85 * (1.0 - 0.6 * engLine(abs(abs(xc) - 0.12), 0.006, fl * 0.6) * engFade(0.02 * nh, fp));
    } else {
        // the corner facets: a dark plate, a lamp at its middle double-blinking like a ship's
        vec3 cn = normalize(engSlabN(pl));
        float dc = length(q - cn * dot(q, cn));
        float ph = fract(gEngSec * 0.45 + float(i) * 0.37 + float(pl) * 0.11);
        float blink = exp(-sqr((ph - 0.05) / 0.02)) + exp(-sqr((ph - 0.13) / 0.02));
        emit += mix(hc, ENG_WHITE, 0.5) * exp(-sqr(dc / max(0.06, fl * 0.8))) * (0.4 + 5.0 * blink) * gEngBoot;
        alb *= 0.7;
    }
    hue += 0.4;
}

/** A gusset plate's surface: hex pattern pressed in, rivets along its legs, its free edge and its hole's lip lit. */
void engGussetSurf(EngHit h, float fp, out vec3 alb, out vec3 emit, out float hue) {
    int ci = int(h.id + 0.5);
    hue = mix(engCornerHue(ci), engWorldHue(h.p), gEngFold);
    vec3 hc = prism7(hue);
    float G = max(h.data.w, 1e-6);
    vec2 lg = h.data.xy / G;
    float fpG = fp / G;
    vec3 hx = engHex(lg, 0.1);
    float seam = engLine(hx.x, 0.006, fpG * 0.6) * engFade(0.015 * G, fp);
    float rv = min(length(vec2((fract(lg.x / 0.07) - 0.5) * 0.07, lg.y - 0.08)),
                   length(vec2(lg.x - 0.08, (fract(lg.y / 0.07) - 0.5) * 0.07)));
    float rivet = engLine(rv, 0.01, fpG * 0.6) * engFade(0.02 * G, fp);
    alb = vec3(0.07, 0.072, 0.08) * (0.8 + 0.35 * vnoise2(lg * 6.0 + h.id)) * (1.0 - 0.5 * seam) + vec3(0.06) * rivet;
    vec2 hcn = lg - 0.3;
    float hexd = max(max(abs(hcn.x), abs(hcn.y)), abs(hcn.x + hcn.y) * 0.75);
    emit = hc * (engLine(h.data.z / G, 0.015, fpG) * 0.9 + engLine(abs(hexd - 0.1), 0.008, fpG) * 0.5) * gEngBoot
         + hc * (1.0 - gEngHull) * 2.0;
    hue += 0.3;
}

vec3 engCoreShade(EngHit h, vec3 rd, vec3 keyDir, vec3 keyCol) {
    vec3 n = h.n;
    vec3 v = -rd;
    float nv = saturate(dot(n, v));
    float x = 1.0 - nv;
    float fr = x * x * x;
    float ang = atan(n.z, n.x);
    vec3 rim = prism7(ang / TAU + n.y * 0.35 + gEngHue * 3.0 + gEngSec * 0.12);
    vec3 held = mix(vec3(0.85, 0.9, 1.0), gEngAbsorb.rgb, saturate(gEngAbsorb.w));
    // inside the black glass, the starlight it holds swirls: specks of light on turning streams
    float lat = asin(clamp(n.y, -1.0, 1.0));
    float a2 = ang - gEngSec * 0.7 + lat * 2.2;
    vec2 sg = vec2(a2 * 3.0, lat * 3.5);
    vec2 sq = fract(sg) - 0.5;
    float hs = hash12(floor(sg) + 7.0);
    float speck = step(0.45, hs) * exp(-dot(sq, sq) / 0.012) * (0.55 + 0.45 * sin(gEngSec * 3.0 + hs * 40.0));
    float stream = 0.5 + 0.5 * sin(a2 * 2.0 + lat * 3.0);
    vec3 col = vec3(0.003) + rim * fr * 2.4 * gEngCoreI;
    col += held * (speck * 1.4 + stream * stream * 0.08) * nv * saturate(gEngAbsorb.w * 0.6) * gEngCoreI;
    col += keyCol * engSpec(n, v, keyDir, 0.08) * 0.4;
    col += engEnv(reflect(rd, n), keyDir, keyCol) * (0.04 + 0.6 * fr);
    return col;
}

vec3 engineShade(EngHit h, vec3 ro, vec3 rd, vec3 keyDir, vec3 keyCol, float pix) {
    engLoad();
    float fp = pix * max(h.t, 1e-4);
    if (h.mat == ENG_M_CORE) return engCoreShade(h, rd, keyDir, keyCol);
    // each part says what its surface is; one light, one set of glyphs for them all
    vec3 n = h.n;
    vec3 alb = vec3(0.07);
    vec3 emit = vec3(0.0);
    float rough = 0.45;
    float grat = 0.0;
    float ao = 1.0;
    float hue = 0.0;
    vec3 u = vec3(0.0, 1.0, 0.0);
    EngText tx;
    tx.uv = vec2(0.0);
    tx.at = vec2(0.0);
    tx.hgt = 1.0;
    tx.code = ivec4(0);
    tx.count = 1;
    tx.aa = 0.01;
    tx.amt = 0.0;
    if (h.mat == ENG_M_NODE) {
        engNodeSurf(h, fp, n, alb, emit, rough, hue, tx);
    } else if (h.mat == ENG_M_GUSSET) {
        engGussetSurf(h, fp, alb, emit, hue);
    } else {
        vec3 direct;
        if (engBeamSurf(h, rd, keyCol, fp, n, alb, emit, rough, grat, ao, hue, u, tx, direct)) return direct;
    }
    if (tx.amt > 0.001) {
        float txt = engGlyphs(tx.uv, tx.at, tx.hgt, tx.code, tx.count, tx.aa) * tx.amt;
        emit += ENG_TELE * txt * 0.8 * gEngBoot;
        alb *= 1.0 - 0.5 * txt;
    }
    // the lock's scan plane cuts a line of light across everything, a faint tint where it has passed
    if (gEngScan > 0.001) {
        float dy = h.p.y - gEngScanY;
        float w = max(0.004, fp * 1.2);
        emit += ENG_TELE * gEngScan * (exp(-sqr(dy / w)) * 5.0 + (dy > 0.0 ? exp(-dy / 0.15) * 0.15 : 0.0));
    }
    emit += prism7(hue) * gEngFlash * 0.2;
    vec3 col = engLit(h.p, n, -rd, keyDir, keyCol, alb, rough, hue, u, grat) * ao + emit;
    return mix(col, gEngHazeCol, engHazeAt(h.t));
}

// ---------------------------------------------------------------- the cells: real stars in their frames

/** A 16-segment glyph's lit segments: ' ' 0, A-Z 1-26, 0-9 27-36, '.' 37. */
int engSeg16Mask(int ch) {
    return ch == 1 ? 975
         : ch == 2 ? 19007
         : ch == 3 ? 243
         : ch == 4 ? 18495
         : ch == 5 ? 499
         : ch == 6 ? 451
         : ch == 7 ? 763
         : ch == 8 ? 972
         : ch == 9 ? 18483
         : ch == 10 ? 124
         : ch == 11 ? 37312
         : ch == 12 ? 240
         : ch == 13 ? 5324
         : ch == 14 ? 33996
         : ch == 15 ? 255
         : ch == 16 ? 967
         : ch == 17 ? 33023
         : ch == 18 ? 33735
         : ch == 19 ? 955
         : ch == 20 ? 18435
         : ch == 21 ? 252
         : ch == 22 ? 12480
         : ch == 23 ? 41164
         : ch == 24 ? 46080
         : ch == 25 ? 21504
         : ch == 26 ? 12339
         : ch == 27 ? 12543
         : ch == 28 ? 12
         : ch == 29 ? 887
         : ch == 30 ? 575
         : ch == 31 ? 908
         : ch == 32 ? 955
         : ch == 33 ? 1019
         : ch == 34 ? 15
         : ch == 35 ? 1023
         : ch == 36 ? 959
         : ch == 37 ? 65536
         : 0;
}

/** Distance to the lit segments of a 16-segment glyph, p in its cell 0..1 across, 0..2 up. */
float engSeg16(vec2 p, int m) {
    float d = 1e3;
    if ((m & 1) != 0) d = min(d, sdSegment2(p, vec2(0.1, 1.9), vec2(0.48, 1.9)));
    if ((m & 2) != 0) d = min(d, sdSegment2(p, vec2(0.52, 1.9), vec2(0.9, 1.9)));
    if ((m & 4) != 0) d = min(d, sdSegment2(p, vec2(0.9, 1.88), vec2(0.9, 1.04)));
    if ((m & 8) != 0) d = min(d, sdSegment2(p, vec2(0.9, 0.96), vec2(0.9, 0.12)));
    if ((m & 16) != 0) d = min(d, sdSegment2(p, vec2(0.52, 0.1), vec2(0.9, 0.1)));
    if ((m & 32) != 0) d = min(d, sdSegment2(p, vec2(0.1, 0.1), vec2(0.48, 0.1)));
    if ((m & 64) != 0) d = min(d, sdSegment2(p, vec2(0.1, 0.96), vec2(0.1, 0.12)));
    if ((m & 128) != 0) d = min(d, sdSegment2(p, vec2(0.1, 1.88), vec2(0.1, 1.04)));
    if ((m & 256) != 0) d = min(d, sdSegment2(p, vec2(0.12, 1.0), vec2(0.48, 1.0)));
    if ((m & 512) != 0) d = min(d, sdSegment2(p, vec2(0.52, 1.0), vec2(0.88, 1.0)));
    if ((m & 1024) != 0) d = min(d, sdSegment2(p, vec2(0.16, 1.82), vec2(0.46, 1.08)));
    if ((m & 2048) != 0) d = min(d, sdSegment2(p, vec2(0.5, 1.88), vec2(0.5, 1.04)));
    if ((m & 4096) != 0) d = min(d, sdSegment2(p, vec2(0.84, 1.82), vec2(0.54, 1.08)));
    if ((m & 8192) != 0) d = min(d, sdSegment2(p, vec2(0.46, 0.92), vec2(0.16, 0.18)));
    if ((m & 16384) != 0) d = min(d, sdSegment2(p, vec2(0.5, 0.96), vec2(0.5, 0.12)));
    if ((m & 32768) != 0) d = min(d, sdSegment2(p, vec2(0.54, 0.92), vec2(0.84, 0.18)));
    if ((m & 65536) != 0) d = min(d, sdSegment2(p, vec2(0.45, 0.1), vec2(0.55, 0.1)));
    return d;
}

/** The tray labels, 6 bits a character, 5 to a word, 3 words a line: star k's line 0 ("C1 BETELGEUSE") and line 1
 *  ("M1 IA 3500K") are words k * 6 + line * 3 + 0..2. */
int engLabelWord(int i) {
    return i == 0 ? 84412163
         : i == 1 ? 85770580
         : i == 2 ? 21717
         : i == 3 ? 19138317
         : i == 4 ? 460195712
         : i == 5 ? 11
         : i == 6 ? 235145027
         : i == 7 ? 320151636
         : i == 8 ? 0
         : i == 9 ? 8541965
         : i == 10 ? 503324745
         : i == 11 ? 2995937
         : i == 12 ? 201590659
         : i == 13 ? 302260548
         : i == 14 ? 897
         : i == 15 ? 153356299
         : i == 16 ? 462544905
         : i == 17 ? 731
         : i == 18 ? 302254019
         : i == 19 ? 357127427
         : i == 20 ? 19
         : i == 21 ? 8541963
         : i == 22 ? 520131145
         : i == 23 ? 2995934
         : i == 24 ? 255854595
         : i == 25 ? 321200204
         : i == 26 ? 0
         : i == 27 ? 35915910
         : i == 28 ? 460175424
         : i == 29 ? 11
         : i == 30 ? 155977795
         : i == 31 ? 5067346
         : i == 32 ? 1
         : i == 33 ? 5768961
         : i == 34 ? 191740196
         : i == 35 ? 0
         : i == 36 ? 89655427
         : i == 37 ? 71
         : i == 38 ? 0
         : i == 39 ? 5768897
         : i == 40 ? 191740004
         : i == 41 ? 0
         : i == 42 ? 155715779
         : i == 43 ? 49479
         : i == 44 ? 0
         : i == 45 ? 19138754
         : i == 46 ? 460445440
         : 731;
}

/** Line `line` of star k's label from `at` (glyph height hgt) in a plane's (u, v): 1 on the lit segments. */
float engLabel(vec2 uv, vec2 at, float hgt, int k, int line, float aa) {
    vec2 p = (uv - at) / (hgt * 0.5);
    float cw = 1.3;
    if (p.y < -0.2 || p.y > 2.2 || p.x < -0.2 || p.x > cw * 15.0) return 0.0;
    float fi = clamp(floor(p.x / cw), 0.0, 14.0);
    int i = int(fi);
    int w = i / 5;
    int ch = (engLabelWord(k * 6 + line * 3 + w) >> (6 * (i - w * 5))) & 63;
    if (ch == 0) return 0.0;
    float d = engSeg16(vec2(p.x - fi * cw, p.y), engSeg16Mask(ch));
    float a = aa / (hgt * 0.5);
    return smoothstep(0.1 + a, 0.1 - a, d);
}

/** The containment frame round a star, in its tray's plane (uv in frame units): corner brackets, a ruler, the star's
 *  name and class in 16-segment capitals ("C1 BETELGEUSE" / "M1 IA 3500K"), a barcode. */
float engTray(vec2 uv, int k, float aa) {
    vec2 au = abs(uv);
    float sq = 1.12;
    if (au.x > 2.1 || uv.y > 1.5 || uv.y < -2.1) return 0.0;
    float d = min(sdSegment2(au, vec2(sq, sq), vec2(sq - 0.26, sq)), sdSegment2(au, vec2(sq, sq), vec2(sq, sq - 0.26)));
    float v = engLine(d, 0.012, aa) * step(au.x, 1.2) * step(au.y, 1.2);
    float tk = abs(fract(uv.x * 5.0) - 0.5) / 5.0;
    v += engLine(tk, 0.006, aa) * engLine(abs(au.y - sq), 0.03, aa) * step(au.x, sq - 0.36) * 0.5;
    v += engLabel(uv, vec2(-1.12, -1.5), 0.2, k, 0, aa);
    v += engLabel(uv, vec2(-1.12, -1.8), 0.13, k, 1, aa) * 0.8;
    float bc = engBar((uv.x - 0.55) / 0.022, float(k) * 3.1) * step(0.55, uv.x) * step(uv.x, 1.12)
             * step(-1.86, uv.y) * step(uv.y, -1.76);
    v += bc * 0.6 * engFade(0.022, aa);
    return saturate(v) * engFade(0.02, aa);
}

/** The frames' colours: the spectrum along the serials (C1 red .. C7 violet), C8 white. */
vec3 engTrayCol(int k) {
    return k == 7 ? vec3(0.85, 0.9, 1.0) : prism7(float(k) / 7.0);
}

/**
 * Star c, a real one (Betelgeuse .. Rigel, its own colour and size): its disc (star.glsl's granulated, spotted,
 * limb-darkened starSurface up close; a plain limb-darkened disc far = 1), its glare (space.glsl's sunGlare: corona,
 * bloom, an anamorphic streak; far: a cross glint), a slow pulse, the cell lit round it, Sirius B beside Sirius, its
 * containment frame and label. `cover` = light in the way.
 */
vec3 engStar(int c, vec3 ro, vec3 rd, float tMax, float pix, float far, inout float cover) {
    vec4 A = Eng[16 + 3 * c];
    vec4 B = Eng[17 + 3 * c];
    vec4 C = Eng[18 + 3 * c];
    float R = A.w;
    float br = C.w;
    if (R <= 1e-4 || br <= 1e-3) return vec3(0.0);
    vec3 sc = engStarCode(c);
    int k = int(sc.x + 0.5);
    float rs = R * sc.z;
    vec3 oc = ro - A.xyz;
    float bb = dot(oc, rd);
    float cc = dot(oc, oc) - sqr(R * 1.5 + rs);
    if (cc > 0.0 && (bb > 0.0 || bb * bb < cc)) return vec3(0.0);
    vec3 sCol = engKelvin(sc.y);
    float I = br * (0.9 + 0.1 * sin(gEngSec * (0.9 + 0.11 * float(k)) + float(k) * 1.7));
    vec3 ex = B.xyz;
    vec3 ey = C.xyz;
    vec3 col = vec3(0.0);
    // the disc (Betelgeuse a touch oblate along its frame's y)
    float ob = k == 0 ? 1.0 / 0.9 - 1.0 : 0.0;
    vec3 o2 = oc + ey * (dot(oc, ey) * ob);
    vec3 d2 = rd + ey * (dot(rd, ey) * ob);
    float qa = dot(d2, d2);
    float qb = dot(o2, d2);
    float disc = qb * qb - qa * (dot(o2, o2) - rs * rs);
    float tp = -bb;
    bool onDisc = false;
    if (disc > 0.0) {
        float th = (-qb - sqrt(disc)) / qa;
        if (th > 0.0 && th < tMax) {
            vec3 n = normalize(o2 + d2 * th);
            vec3 surf;
            if (far > 0.5) {
                float mu = max(dot(n, -rd), 0.0);
                surf = sCol * (0.3 + 1.1 * sqrt(mu)) * (0.75 + 0.5 * vnoise3(n * 7.0 + float(k) * 3.1)) * 60.0;
            } else {
                surf = starSurface(n, rd, sCol, float(k) * 7.3);
            }
            col += surf * 0.016 * I;
            cover = 1.0;
            onDisc = true;
        }
    }
    if (tp > 0.0 && tp < tMax + rs) {
        vec3 off = oc + rd * tp;
        float d = length(off);
        float px = pix * tp;
        float ar = max(rs, px * 1.5);
        // its glare: a corona hugging the limb, a bloom kept to its cell, a streak across the view (far: a cross)
        float win = 1.0 - smoothstep(R * 1.05, R * 1.45, d);
        float corona = exp(-(d - ar) / (min(ar, R * 0.12) * 1.2)) * step(ar, d) * win;
        float bloom = ar * ar / (d * d + ar * ar) * exp(-d / (R * 0.5)) * win;
        // the streak lies across the line of sight to the star (one basis for the whole star, so it stays straight)
        vec3 sd = normalize(-oc);
        vec3 ax = normalize(cross(sd, abs(sd.y) < 0.95 ? vec3(0.0, 1.0, 0.0) : vec3(1.0, 0.0, 0.0)));
        float x = dot(off, ax);
        float y = dot(off, cross(ax, sd));
        float pts = min(ar / px, 30.0) * 0.02;
        float streak = exp(-abs(y) / (px * 1.6)) * exp(-abs(x) / (R * 0.5)) * pts;
        if (far > 0.5) streak += exp(-abs(x) / (px * 1.6)) * exp(-abs(y) / (R * 0.5)) * pts;
        streak *= win;
        // the point itself, so the small hot ones (Sirius, Vega) burn as pinpoints from anywhere
        float pr = max(rs, px * 1.1);
        float point = onDisc ? 0.0 : exp(-d * d / (pr * pr)) * 3.0 * (1.0 - smoothstep(1.0, 3.0, rs / px));
        col += (sCol * (corona * 0.22 + bloom * 0.12 + point) + mix(sCol, ENG_WHITE, 0.3) * streak * 1.2) * I;
        // the cell lit round it like a room
        col += sCol * I * exp(-sqr(d / (R * 0.8))) * 0.03 * win;
        cover = max(cover, exp(-d * d / (pr * pr)) * min(I, 1.0));
        // Sirius B, the white dwarf, on its orbit
        if (k == 5) {
            float an = gEngSec * 0.35;
            vec3 wp = oc + (ex * cos(an) + cross(ex, ey) * sin(an)) * (R * 0.24);
            float tq = -dot(wp, rd);
            float dq = length(wp + rd * tq);
            float wr = max(R * 0.012, pix * max(tq, 1e-4) * 1.1);
            if (tq > 0.0 && tq < tMax) col += vec3(0.75, 0.85, 1.0) * (exp(-dq * dq / (wr * wr)) * 3.0 + wr / (dq + wr) * 0.05) * I;
        }
    }
    if (far < 0.5) {
        vec3 nrm = normalize(cross(ex, ey));
        float den = dot(rd, nrm);
        if (abs(den) > 1e-5) {
            float t = -dot(oc, nrm) / den;
            if (t > 0.0 && t < tMax) {
                float fr = max(R * 0.42, rs * 1.08);
                vec3 q = oc + rd * t;
                vec2 uv = vec2(dot(q, ex), dot(q, ey)) / fr;
                float tray = engTray(uv, k, pix * t / fr / max(abs(den), 0.15));
                col += mix(engTrayCol(k), ENG_TELE, 0.35) * tray * (0.5 + 0.6 * min(br, 2.5)) * 1.2 * gEngBoot;
            }
        }
    }
    return col;
}

vec3 engStars(vec3 ro, vec3 rd, float tMax, float pix, float far, inout float cover) {
    vec3 col = vec3(0.0);
    int nc = 8 + gEngZero;
    for (int c = 0; c < nc; c++) col += engStar(c, ro, rd, tMax, pix, far, cover);
    return col;
}

// ---------------------------------------------------------------- the core's light and its tesseract

/** The core tesseract's corner i (TesseractPath.corner: XW, YW, ZW, perspective, a Y turn), scaled and placed. */
vec3 engCoreCorner(int i) {
    float x = (i & 1) == 0 ? -1.0 : 1.0;
    float y = (i & 2) == 0 ? -1.0 : 1.0;
    float z = (i & 4) == 0 ? -1.0 : 1.0;
    float w = (i & 8) == 0 ? -1.0 : 1.0;
    float x1 = x * gEngCosA.x - w * gEngSinA.x;
    float w1 = x * gEngSinA.x + w * gEngCosA.x;
    float y1 = y * gEngCosA.y - w1 * gEngSinA.y;
    float w2 = y * gEngSinA.y + w1 * gEngCosA.y;
    float z1 = z * gEngCosA.z - w2 * gEngSinA.z;
    float w3 = z * gEngSinA.z + w2 * gEngCosA.z;
    float k = 3.2 / (3.2 - w3) * 1.1;
    vec3 p = vec3(x1, y1, z1) * k;
    p = vec3(p.x * gEngCosA.w - p.z * gEngSinA.w, p.y, p.x * gEngSinA.w + p.z * gEngCosA.w);
    return p * gEngCoreS + gEngCoreC;
}

vec3 engCoreGlow(vec3 ro, vec3 rd, float tMax, float pix) {
    vec3 col = vec3(0.0);
    vec3 held = mix(vec3(0.82, 0.88, 1.0), gEngAbsorb.rgb, saturate(gEngAbsorb.w * 0.5));
    float tp;
    float d = rayPointDist(ro, rd, gEngCoreC, tp);
    if (tp < tMax) {
        float rr = max(gEngCoreR, 0.02);
        float x = max(d - rr, 0.0);
        col += held * gEngCoreI * (exp(-x / (rr * 0.35)) * 0.35 + exp(-x / (rr * 2.5)) * 0.05)
             * (1.0 + 0.4 * gEngAbsorb.w);
    }
    float bound = gEngCoreS * 2.9 + 0.03;
    vec2 bs = raySphere(ro, rd, gEngCoreC, bound);
    if (bs.y <= 0.0 || bs.x > tMax) return col;
    float lit = min(gEngCoreI, 2.0) * (0.6 + 0.4 * gEngBoot) * (1.0 + 0.4 * gEngFold);
    int ne = 32 + gEngZero;
    for (int e = 0; e < ne; e++) {
        int i, j, k;
        engEdge(e, i, j, k);
        vec3 a = engCoreCorner(i);
        vec3 b = engCoreCorner(j);
        float tRay;
        float dd = raySegmentDist(ro, rd, a, b, tRay);
        if (tRay <= 0.0 || tRay > tMax) continue;
        vec3 ba = b - a;
        float s = saturate(dot(ro + rd * tRay - a, ba) / max(dot(ba, ba), 1e-8));
        float w = max(pix * tRay * 0.8, 0.0022 * gEngCoreS / 0.062);
        vec3 hc = prism7(mix(engCornerHue(i), engCornerHue(j), s));
        col += mix(hc, ENG_WHITE, 0.3) * (exp(-sqr(dd / w)) * 1.6 + exp(-dd / (w * 3.0)) * 0.06) * lit;
    }
    return col;
}

// ---------------------------------------------------------------- the containment fields on the 24 faces

/** Faint fields across the faces: a soap-film sheen at grazing angles, tinted by the cells' light behind them (lit
 *  windows), a hex lattice that shows when a cell flashes; detail 0 drops the lattice. */
vec3 engPanes(vec3 ro, vec3 rd, float tMax, float pix, float detail) {
    vec3 col = vec3(0.0);
    int nf = 24 + gEngZero;
    for (int f = 0; f < nf; f++) {
        int i0, ia, ib;
        engFace(f, i0, ia, ib);
        // its two cells: the coordinates the face holds fixed
        int span = ia | ib;
        int r0 = (span & 1) == 0 ? 0 : (span & 2) == 0 ? 1 : 2;
        int r1 = (span & 8) == 0 ? 3 : (span & 4) == 0 ? 2 : 1;
        int ca = 2 * r0 + ((i0 >> r0) & 1);
        int cb = 2 * r1 + ((i0 >> r1) & 1);
        float bA = Eng[18 + 3 * ca].w;
        float bB = Eng[18 + 3 * cb].w;
        float flash = max(bA - 1.0, 0.0) + max(bB - 1.0, 0.0);
        vec3 wash = (engCellCol(ca) * min(bA, 1.0) + engCellCol(cb) * min(bB, 1.0)) * 0.5;
        float base = gEngPane * 0.4 * detail;
        float fla = gEngPane * 2.5 * flash + gEngThroat * 3.0 + gEngEmerge * 1.5;
        if (base + fla <= 0.002) continue;
        vec4 d;
        float gs;
        int corner;
        vec3 n;
        float t = engFaceHit(f, ro, rd, tMax, d, gs, corner, n);
        if (t < 0.0 || gs > 0.0) continue;
        float dm = min(min(d.x, d.y), min(d.z, d.w));
        float hw = ENG_HB * 0.8 * gEngHull;
        if (dm <= hw) continue;
        float fp = pix * t;
        float slant = abs(dot(rd, n));
        float x = 1.0 - slant;
        float fres = x * x * x * x;
        vec3 ex = normalize(Eng[i0 | ia].xyz - Eng[i0].xyz);
        vec3 ey = cross(n, ex);
        vec3 q = ro + rd * t - Eng[i0].xyz;
        vec2 pp = vec2(dot(q, ex), dot(q, ey));
        float hue = (engCornerHue(i0) + engCornerHue(i0 | ia | ib)) * 0.5 + 0.8 * x + dm * 2.0;
        vec3 film = prism7(hue);
        vec3 hx = engHex(pp, 0.045);
        float see = engFade(0.006, fp / max(slant, 0.2));
        float lattice = engLine(hx.x, 0.0018, fp * 0.8) * see;
        float border = exp(-(dm - hw) / 0.025);
        // at rest a faint soap film; a flash lights the field's lattice and its border (a faint fill when too small)
        col += (film * (fres * 0.012 + border * 0.012) + wash * (0.002 + border * 0.01)) * base;
        col += mix(film, wash, 0.5) * (lattice * 0.12 + border * 0.08 + (1.0 - see) * 0.006) * fla;
    }
    return col * (1.0 - engHazeAt(length(ro) - 1.0));
}

// ---------------------------------------------------------------- beacons, feeders, the scan sheet, the folded light

vec3 engBeacons(vec3 ro, vec3 rd, float tMax, float pix) {
    vec3 col = vec3(0.0);
    if (gEngHull <= 0.01) return col;
    int nn = 16 + gEngZero;
    for (int i = 0; i < nn; i++) {
        vec3 c = Eng[i].xyz;
        float nh = ENG_NB * Eng[i].w * gEngHull;
        vec3 bp = c * (1.0 + nh * 2.1 * inversesqrt(dot(c, c) + 1e-8));
        vec3 o = bp - ro;
        float tp = dot(o, rd);
        if (tp > tMax || tp <= 0.0) continue;
        float d = length(o - rd * tp);
        float w = max(pix * tp * 1.2, nh * 0.06);
        if (d > w * 8.0) continue;
        float ph = fract(gEngSec * 0.45 + float(i) * 0.37);
        float blink = exp(-sqr((ph - 0.05) / 0.025)) + exp(-sqr((ph - 0.14) / 0.025));
        vec3 hc = mix(prism7(engCornerHue(i)), ENG_WHITE, 0.55);
        col += hc * (exp(-sqr(d / w)) * (0.3 + 6.0 * blink) + exp(-d / (w * 2.5)) * 0.2 * blink) * gEngBoot;
    }
    return col;
}

/** Power from each star to the core: a dashed line of light, packets running inward (bright as they are drained). */
vec3 engFeeders(vec3 ro, vec3 rd, float tMax, float pix) {
    vec3 col = vec3(0.0);
    int nc = 8 + gEngZero;
    for (int c = 0; c < nc; c++) {
        vec4 A = Eng[16 + 3 * c];
        float br = Eng[18 + 3 * c].w;
        if (A.w <= 0.0 || br <= 0.0) continue;
        vec3 a = A.xyz;
        vec3 b = gEngCoreC;
        float tRay;
        float d = raySegmentDist(ro, rd, a, b, tRay);
        if (tRay <= 0.0 || tRay > tMax) continue;
        float w = max(pix * tRay * 0.7, 0.0018);
        if (d > w * 8.0) continue;
        vec3 ba = b - a;
        float L = max(length(ba), 1e-4);
        float s = saturate(dot(ro + rd * tRay - a, ba) / (L * L));
        float run = fract(s * L / 0.09 - gEngPhase * 3.0);
        float dash = step(run, 0.55);
        float packet = exp(-sqr((fract(s * L / 0.45 - gEngPhase * 1.2 + float(c) * 0.3) - 0.5) / 0.05));
        float ends = smoothstep(0.0, 0.15, s) * smoothstep(1.0, 0.85, s);
        float drain = 1.0 + 3.0 * gEngFold;
        col += mix(engCellCol(c), ENG_WHITE, 0.3) * exp(-sqr(d / w)) * (0.05 * dash + 1.0 * packet) * ends * min(br, 2.0)
             * drain * gEngBoot;
    }
    return col;
}

/** The lock's scan plane: a sheet of light the size of the outer cube with its outline and scan lines. */
vec3 engScanSheet(vec3 ro, vec3 rd, float tMax, float pix) {
    if (gEngScan <= 0.001 || abs(rd.y) < 1e-5) return vec3(0.0);
    float t = (gEngScanY - ro.y) / rd.y;
    if (t <= 0.0 || t >= tMax) return vec3(0.0);
    vec3 q = ro + rd * t;
    float e = max(abs(q.x), abs(q.z));
    if (e > 1.15) return vec3(0.0);
    float fp = pix * t / max(abs(rd.y), 0.15);
    float inside = 1.0 - smoothstep(1.0 - fp, 1.0 + fp, e);
    float outline = engLine(abs(e - 1.0), 0.004, fp);
    float lines = engLine(abs(fract(q.z * 24.0) - 0.5) / 24.0, 0.0012, fp) * engFade(0.01, fp);
    float grid = engLine(abs(fract(q.x * 6.0) - 0.5) / 6.0, 0.0015, fp) * engFade(0.03, fp);
    float below = gEngScanY < -1.0 ? exp((gEngScanY + 1.0) * 1.2) : 1.0;
    return ENG_TELE * gEngScan * below * (inside * (0.03 + lines * 0.22 + grid * 0.12) + outline * 1.4);
}

/** As the hulls fold into light: each girder a line of light (the cube cage at the end). */
vec3 engLightLines(vec3 ro, vec3 rd, float tMax, float pix) {
    vec3 col = vec3(0.0);
    if (gEngLines <= 0.001) return col;
    int nb = 32 + gEngZero;
    for (int b = 0; b < nb; b++) {
        int i, j, k;
        engEdge(b, i, j, k);
        vec3 a = Eng[i].xyz;
        vec3 e = Eng[j].xyz;
        vec3 ba = e - a;
        float bl = dot(ba, ba);
        if (bl < 1e-8) continue;
        float tRay;
        float d = raySegmentDist(ro, rd, a, e, tRay);
        if (tRay <= 0.0 || tRay > tMax) continue;
        float w = max(pix * tRay * 1.1, 0.0045);
        if (d > w * 10.0) continue;
        float s = saturate(dot(ro + rd * tRay - a, ba) / bl);
        float hue = engBeamHue(i, j, s, a + ba * s);
        vec3 hc = prism7(hue);
        float run = fract(s * 3.0 - gEngSec * 0.9 + float(b) * 0.29);
        float pulse = exp(-sqr((run - 0.5) / 0.03));
        col += (mix(hc, ENG_WHITE, 0.3 + 0.5 * pulse) * exp(-sqr(d / w)) * (2.0 + 2.5 * pulse)
                + hc * exp(-d / (w * 8.0)) * 0.3) * gEngLines;
    }
    return col;
}

vec3 engineGlow(vec3 ro, vec3 rd, float tMax, float pix) {
    engLoad();
    ro = engGlitch(ro, rd);
    vec2 bs = raySphere(ro, rd, vec3(0.0), gEngExt + 0.3);
    if (bs.y <= 0.0 || bs.x > tMax) return vec3(0.0);
    float cover = 0.0;
    vec3 col = engStars(ro, rd, tMax, pix, 0.0, cover);
    col += engCoreGlow(ro, rd, tMax, pix);
    col += engPanes(ro, rd, tMax, pix, 1.0);
    col += engBeacons(ro, rd, tMax, pix);
    col += engFeeders(ro, rd, tMax, pix);
    col += engScanSheet(ro, rd, tMax, pix);
    col += engLightLines(ro, rd, tMax, pix);
    return col;
}

// ---------------------------------------------------------------- the far look (the world's sky)

/** The far look's light: dark gunmetal, wrapped key, a tinted highlight, a backlit rim, sky fill. */
vec3 engLitFar(vec3 n, vec3 v, vec3 keyDir, vec3 keyCol, float alb, float hue) {
    float nv = saturate(dot(n, v));
    float x = 1.0 - nv;
    vec3 film = engFilm(nv, hue);
    vec3 hv = normalize(keyDir + v);
    float sp = pow(max(dot(n, hv), 0.0), 40.0) * max(dot(n, keyDir), 0.0) * 3.0;
    vec3 col = vec3(alb) * keyCol * (max((dot(n, keyDir) + 0.2) / 1.2, 0.0) + 0.06);
    col += film * keyCol * (sp * (0.06 + 0.5 * x * x * x * x * x) + x * x * x * saturate(dot(-v, keyDir)) * 0.35);
    col += film * (keyCol * 0.025 + gEngHazeCol * 0.25 * saturate(reflect(-v, n).y + 0.5)) * (0.06 + 0.5 * x * x * x);
    col += vec3(alb) * gEngHazeCol * 0.5 * (0.55 + 0.45 * n.y);
    return col;
}

/**
 * The engine from the ground, through the haze: one compact pass. Girders as anti-aliased box sections seen
 * analytically (the face the ray meets, flat-shaded, a light tube on every corner of the section, plated bays with a
 * row of windows, open bays you see the sky through, the sleeves with their lit collars); the hubs, gussets and core
 * exact and plainly shaded; then the stars, beacons, the core's tesseract and the folded light. Two girders deep
 * (front to back). rgb = light, a = how much it covers what is behind it.
 */
vec4 engineFar(vec3 ro, vec3 rd, float tMax, float pix) {
    engLoad();
    vec2 bs = raySphere(ro, rd, vec3(0.0), gEngExt + 0.3);
    if (bs.y <= 0.0 || bs.x > tMax) return vec4(0.0);
    vec3 keyDir = gEngKeyDir;
    vec3 keyCol = gEngKeyCol;
    vec3 v = -rd;
    // the solids found exactly: hubs, gussets, the core
    EngHit hs;
    hs.t = -1.0;
    hs.n = vec3(0.0, 1.0, 0.0);
    hs.p = vec3(0.0);
    hs.mat = 0.0;
    hs.id = 0.0;
    hs.data = vec4(0.0);
    float tS = tMax;
    if (gEngHull > 0.001) {
        int nn = 16 + gEngZero;
        for (int i = 0; i < nn; i++) engNodeHit(i, ro, rd, tS, hs);
        engGussetHit(ro, rd, tS, hs);
    }
    vec3 cS = vec3(0.0);
    float aS = 0.0;
    if (hs.t > 0.0) {
        int ci = int(hs.id + 0.5);
        float hue = mix(engCornerHue(ci), engWorldHue(hs.p), gEngFold);
        vec3 hc = prism7(hue);
        vec3 emit = vec3(0.0);
        float px = pix * hs.t;
        if (hs.mat == ENG_M_NODE) {
            // the hub: its port glowing, a light seam on each chamfer, its lamps
            float nh = max(ENG_NB * Eng[ci].w * gEngHull, 1e-6);
            vec3 aq = abs((hs.p - Eng[ci].xyz) / nh);
            int pl = int(hs.data.w + 0.5);
            float sq = pl == 0 ? max(aq.y, aq.z) : pl == 1 ? max(aq.x, aq.z) : max(aq.x, aq.y);
            float face = pl < 3 ? 1.0 : 0.0;
            float lamp = pl > 8 ? 1.0 : 0.0;
            emit += hc * (1.0 - smoothstep(0.22, 0.24 + px / nh, sq)) * face * (0.4 + gEngFlash);
            emit += hc * (1.0 - face) * (1.0 - lamp) * 0.25 + mix(hc, ENG_WHITE, 0.5) * lamp * 0.4;
        } else {
            // a gusset: its free edge lit
            emit += hc * engLine(hs.data.z / max(hs.data.w, 1e-6), 0.02, px / max(hs.data.w, 1e-6)) * 0.8;
        }
        cS = engLitFar(hs.n, v, keyDir, keyCol, 0.075, hue + 0.35) + emit * gEngBoot + hc * (1.0 - gEngHull) * 2.0;
        cS = mix(cS, gEngHazeCol, engHazeAt(hs.t));
        aS = 1.0;
    }
    if (gEngCoreR > 1e-4) {
        vec2 hc2 = raySphere(ro, rd, gEngCoreC, gEngCoreR);
        if (hc2.x > 0.0 && hc2.x < tS) {
            tS = hc2.x;
            vec3 nc = normalize(ro + rd * hc2.x - gEngCoreC);
            float x = 1.0 - saturate(dot(nc, v));
            cS = vec3(0.003) + prism7(atan(nc.z, nc.x) / TAU + gEngHue * 3.0 + gEngSec * 0.12) * x * x * x * 2.4 * gEngCoreI;
            aS = 1.0;
        }
    }
    // the girders
    float t1 = 1e30;
    float t2 = 1e30;
    vec3 c1 = vec3(0.0);
    vec3 c2 = vec3(0.0);
    float a1 = 0.0;
    float a2 = 0.0;
    if (gEngHull > 0.001) {
        int nb = 32 + gEngZero;
        for (int b = 0; b < nb; b++) {
            int i, j, k;
            engEdge(b, i, j, k);
            vec3 A = Eng[i].xyz;
            vec3 u = Eng[j].xyz - A;
            float len = length(u);
            if (len < 1e-4) continue;
            u /= len;
            float ha = ENG_HB * Eng[i].w * gEngHull;
            float hb = ENG_HB * Eng[j].w * gEngHull;
            vec3 oa = ro - A;
            float bard = dot(u, rd);
            float den = 1.0 - bard * bard;
            float s = den > 1e-9 ? saturate((dot(u, oa) - bard * dot(rd, oa)) / den / len) : 0.0;
            vec3 P = A + u * (s * len);
            float tR = dot(P - ro, rd);
            if (tR <= 0.0 || tR > tS || tR > t2) continue;
            vec3 off = ro + rd * tR - P;
            float dd = length(off);
            float endZ = engEndZ(i, j, len);
            float z = s * len;
            float sleeve = z < endZ || z > len - endZ ? 1.0 : 0.0;
            float h = sleeve > 0.5 ? (z < endZ ? ha : hb) * ENG_SL : ha + (hb - ha) * s;
            float px = pix * tR;
            float cov = saturate((h * 1.12 - dd) / px + 0.5);
            if (cov <= 0.0) continue;
            // its roll (the faces follow the cube's)
            vec3 e1 = Eng[i ^ (1 << (k == 0 ? 1 : k == 1 ? 2 : k == 2 ? 0 : 1))].xyz - A;
            e1 -= u * dot(e1, u);
            float e1l = length(e1);
            e1 = e1l > 1e-5 ? e1 / e1l : normalize(cross(u, vec3(0.31, 0.83, 0.47)));
            vec3 e2 = cross(u, e1);
            // the section across the view: its front corner, the face the ray meets, where across it
            vec3 vp = v - u * dot(v, u);
            float vl = length(vp);
            vp = vl > 1e-5 ? vp / vl : e1;
            vec3 tx = cross(u, vp);
            float xr = dot(off, tx);
            float sx = dot(vp, e1) >= 0.0 ? 1.0 : -1.0;
            float sy = dot(vp, e2) >= 0.0 ? 1.0 : -1.0;
            float t1x = dot(e1, tx);
            float t2x = dot(e2, tx);
            float xc = h * (sx * t1x + sy * t2x);
            bool faceA = (xr - xc) * (-sy * t2x) > 0.0;
            vec3 nrm = faceA ? e1 * sx : e2 * sy;
            float proj = faceA ? t2x : t1x;
            float across = (xr - h * (faceA ? sx * t1x : sy * t2x)) / (abs(proj) > 1e-3 ? proj : 1e-3) / h;
            // the corners' light tubes: the front corner and both silhouette edges
            float cw = max(h * 0.06, px * 0.7);
            float tube = exp(-sqr((xr - xc) / cw)) + exp(-sqr((abs(xr) - h * 1.12 + cw) / cw));
            float hue = engBeamHue(i, j, s, P);
            vec3 hc = prism7(hue);
            vec3 cond = engConduitCol(b, s, hue, len);
            vec3 emit = cond * tube * (h * 0.06 / cw) * 0.9;
            float alb = 0.075;
            if (sleeve > 0.5) {
                float zz = z < endZ ? z : len - z;
                emit += hc * engLine(abs(zz / max(endZ, 1e-6) - 0.82), 0.02, px / max(endZ, 1e-6)) * 0.45;
                alb = 0.085;
            } else {
                float np, pl;
                engBays(len, endZ, ha + (hb - ha) * 0.5, np, pl);
                float zp = (z - endZ) / pl;
                float bay = clamp(floor(zp), 0.0, np - 1.0);
                float fv = zp - bay;
                float ac = abs(across);
                if (engBayOpen(b, bay, np) > 0.5) {
                    // open Warren lacing: the sky through it (the bars and posts stay)
                    float dz = sdSegment2(vec2(fv * pl / h, across * (mod(bay, 2.0) < 0.5 ? 1.0 : -1.0)), vec2(0.0, -0.44),
                                          vec2(pl / h, 0.44));
                    float post = min(fv, 1.0 - fv) * pl / h;
                    float open = smoothstep(0.0, px / h + 0.02, min(min(0.46 - ac, dz - 0.1), post - 0.1));
                    cov *= 1.0 - 0.9 * open * engFade(0.25 * h, px);
                    emit += cond * 0.04 * open;
                } else {
                    // plated: a row of lit windows
                    float hb2 = hash12(vec2(float(b) * 3.7, bay * 1.3));
                    float row = (fract(hb2 * 13.0) - 0.5) * 0.4;
                    float wl = engWindows(vec2(fv * pl / h, across - row), float(b) * 5.0 + bay, px / h) * step(0.25, hb2)
                             * step(ac, 0.38);
                    emit += (fract(hb2 * 31.0) < 0.6 ? ENG_WARM : ENG_TELE) * wl * 0.9;
                    alb *= 0.8 + 0.4 * hash12(vec2(bay, float(b)));
                }
            }
            vec3 col = engLitFar(nrm, v, keyDir, keyCol, alb, hue + 0.25) + emit * gEngBoot;
            col += cond * (1.0 - gEngHull) * 1.4;
            if (gEngScan > 0.001) col += ENG_TELE * gEngScan * exp(-sqr((P.y - gEngScanY) / max(0.004, px))) * 4.0;
            col = mix(col, gEngHazeCol, engHazeAt(tR));
            if (tR < t1) {
                t2 = t1;
                c2 = c1;
                a2 = a1;
                t1 = tR;
                c1 = col;
                a1 = cov;
            } else {
                t2 = tR;
                c2 = col;
                a2 = cov;
            }
        }
    }
    vec3 rgb = c1 * a1 + (1.0 - a1) * (c2 * a2 + (1.0 - a2) * cS * aS);
    float alpha = a1 + (1.0 - a1) * (a2 + (1.0 - a2) * aS);
    float tOcc = a1 > 0.5 ? t1 : a2 > 0.5 ? min(t2, tS) : tS;
    float cover = 0.0;
    vec3 add = engStars(ro, rd, tOcc, pix, 1.0, cover);
    add += engCoreGlow(ro, rd, tOcc, pix);
    add += engBeacons(ro, rd, tOcc, pix);
    add += engLightLines(ro, rd, tOcc, pix);
    add *= 1.0 - engHazeAt(length(ro) - 1.0) * 0.6;
    rgb += add * (1.0 - alpha * 0.85);
    alpha = alpha + (1.0 - alpha) * cover * 0.6;
    return vec4(rgb, saturate(alpha));
}
