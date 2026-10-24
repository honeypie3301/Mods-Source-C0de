// SS-05, Tesseract, in the world — all of it in the seven colours of the spectrum, graded corner to corner across the
// square (red in one corner, violet in the far one, the same way the lattice is laid on the pit floor), drifting slowly.
// From the cast the square is painted on the land; the W-Engine (tess_sky) falls onto it and lands as the cage, a shock
// ring of the spectrum running out across the land. The cage: a cube of light 256 blocks across standing on the square, a
// grid of cells on its faces, a scan running up them; inside it, hanging over the middle, the tesseract's shadow — sixteen
// corners and thirty-two edges turning through the fourth dimension. On the land: the grid of 8 × 8 cells, bracketed at
// their corners and numbered in seven-segment figures. Then the cracks race along the grid out from the middle, white-
// hot at their heads; the air in the cage shimmers; the land is cut free — a curtain of light up the square's four sides
// — and cell by cell the cubes of land lurch up into the sky: a column of light under each as it goes, its outline
// burning, then settling to a thin line of colour. At the fold the cage collapses into the tesseract, which snaps still,
// and a ripple through four dimensions runs out of it: rings of the spectrum across the land and the sky, the frame
// itself bent. Camera-relative world space.
//
// Grid = the square's corner (its ground) from the camera. Pts[16] = the tesseract's corners from the camera, their 4D w.
// Cubes[i], i = cz * 8 + cx = (seconds since the cell rose or < 0, its cube's foot y from the camera, its height, its
// depth in z). P0 = (seconds, seed, the mark, the cage lit 0..1), P1 = (seconds since the cracks or < 0, since the land
// was cut free or < 0, since the fold or < 0, pulse phase), P2 = (the pit floor's y from the camera, shimmer, the cage
// folded 0..1, the outlines' afterglow), P3 = (the fold's centre y from the camera, the square's side, the shear's dimming, the square's scale),
// P4 = (the cage landed 0..1, seconds since it landed or < 0, the pit's tier step (blocks), its lowest floor (camera-relative y)).

#include "star.glsl"

uniform vec3 Grid;
uniform vec4 Cubes[64];
uniform vec4 P4;

// the square's side and cells as cast (P3.w: its size against the remote's; Mrityu's is half), set in main
float SIZE = 256.0;
float CELL = 32.0;
float gS = 1.0;
const vec3 WHITE_HOT = vec3(1.0, 0.98, 1.0);

/** The spectrum at a place: graded corner to corner across the square, a little up its height, drifting. */
float hueAt(vec3 p) {
    vec3 g = p - Grid;
    return (g.x + g.z) / (2.0 * SIZE) * (6.0 / 7.0) + g.y / SIZE * 0.18 + gTime * 0.035;
}

float digitDist(vec2 p, int n) {
    int m = n == 0 ? 63 : n == 1 ? 6 : n == 2 ? 91 : n == 3 ? 79 : n == 4 ? 102 : n == 5 ? 109 : n == 6 ? 125
            : n == 7 ? 7 : n == 8 ? 127 : 111;
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

float readout(vec2 uv, vec2 at, float h, float value, int count, float aa) {
    vec2 p = (uv - at) / (h * 0.5);
    float cellW = 1.35;
    if (p.y < -0.2 || p.y > 2.2 || p.x < -0.2 || p.x > cellW * float(count)) return 0.0;
    float i = floor(p.x / cellW);
    int digit = int(mod(floor(value / pow(10.0, float(count) - 1.0 - i) + 0.001), 10.0));
    return smoothstep(0.1 + aa, 0.1 - aa, digitDist(vec2(p.x - i * cellW, p.y), digit));
}

/** Closest approach of the view ray to a segment: distance, the ray's t, where along the segment (0..1). */
float raySeg(vec3 rd, vec3 a, vec3 b, out float tRay, out float s) {
    vec3 ba = b - a;
    float baba = dot(ba, ba);
    float bard = dot(ba, rd);
    float baoa = dot(ba, -a);
    float rdoa = dot(rd, -a);
    float denom = baba - bard * bard;
    s = denom > 1e-9 ? saturate((baoa - bard * rdoa) / denom) : 0.0;
    vec3 q = a + ba * s;
    tRay = max(dot(q, rd), 0.0);
    return length(rd * tRay - q);
}

/** The view ray through a box: entry and exit t (exit < entry: missed). */
vec2 rayBox(vec3 rd, vec3 lo, vec3 hi) {
    vec3 r = rd + vec3(equal(rd, vec3(0.0))) * 1e-6;
    vec3 inv = 1.0 / r;
    vec3 t0 = lo * inv;
    vec3 t1 = hi * inv;
    vec3 tmin = min(t0, t1);
    vec3 tmax = max(t0, t1);
    return vec2(max(max(tmin.x, tmin.y), tmin.z), min(min(tmax.x, tmax.y), tmax.z));
}

/** How near a point on a box's surface is to one of its edges (blocks). */
float boxEdge(vec3 p, vec3 lo, vec3 hi) {
    vec3 e = min(p - lo, hi - p);
    float a = min(min(e.x, e.y), e.z);
    float b = max(max(e.x, e.y), e.z);
    return e.x + e.y + e.z - a - b;
}

/** A glint on the screen at a camera-relative point: a core, a cross, a halo. */
vec3 glint(vec3 at, float size, float sceneT, vec3 tint) {
    vec3 hp = project(at);
    if (hp.z <= 0.0 || length(at) > sceneT + 5.0) return vec3(0.0);
    vec2 dd = (texCoord - hp.xy) * vec2(OutSize.x / OutSize.y, 1.0);
    float px = 1.0 / OutSize.y;
    float len = 0.02 + 0.2 * size;
    float core = exp(-dot(dd, dd) / sqr(px * (1.5 + 4.0 * size)));
    float cross = exp(-abs(dd.y) / (px * 0.8)) * exp(-abs(dd.x) / len) + exp(-abs(dd.x) / (px * 0.8)) * exp(-abs(dd.y) / len);
    float halo = exp(-length(dd) / (px * (6.0 + 40.0 * size)));
    return WHITE_HOT * core * 4.0 + tint * (cross * 1.8 + halo * 0.6);
}

/** A corner of the tesseract's hue: its place along the 4D diagonal (how many of its coordinates are positive). */
float cornerHue(int i) {
    int n = (i & 1) + ((i >> 1) & 1) + ((i >> 2) & 1) + ((i >> 3) & 1);
    return float(n) * (1.5 / 7.0) + gTime * 0.05;
}

void main() {
    initPixel(texCoord);
    gTime = P0.x;
    gSeed = P0.y;
    gS = P3.w > 0.001 ? P3.w : 1.0;
    // the square's side as cast (snapped to the chunk grid), else from its scale
    SIZE = P3.y > 0.5 ? P3.y : 256.0 * gS;
    CELL = SIZE / 8.0;
    vec3 rd = viewDir(texCoord);
    vec3 surf = scenePosAt(texCoord);
    bool sky = skyAt(texCoord);
    float sceneT = sky ? FAR : length(surf);
    vec3 glow = vec3(0.0);
    float mark = P0.z;
    float cracks = P1.x;
    float sever = P1.y;
    float fold = P1.z;
    float folded = P2.z;
    float pitY = P2.x;
    vec3 foldAt = vec3(Grid.x + SIZE * 0.5, P3.x, Grid.z + SIZE * 0.5);

    // the cage: a cube on the square, collapsing into the tesseract at the fold
    vec3 cageC = mix(Grid + vec3(SIZE * 0.5), foldAt, folded);
    float cageH = mix(SIZE * 0.5, 13.0, folded * folded * (3.0 - 2.0 * folded));
    vec3 lo = cageC - cageH;
    vec3 hi = cageC + cageH;
    vec2 cageT = rayBox(rd, lo, hi);
    bool inCage = cageT.y > max(cageT.x, 0.0) && max(cageT.x, 0.0) < sceneT;
    float landed = P4.x;
    float sinceLand = P4.y;
    float cageOn = landed * (fold < 0.0 ? 1.0 : 1.0 - smoothstep(0.9, 1.4, fold));
    // the moment it lands: every edge white-hot
    float slam = sinceLand >= 0.0 ? exp(-sinceLand * 3.0) : 0.0;

    // ---- the air in the cage shimmering, the world through it bent
    vec3 base = sampleScene(texCoord);
    if (inCage && P2.y > 0.001) {
        float through = min(cageT.y, sceneT) - max(cageT.x, 0.0);
        vec3 mid = rd * (max(cageT.x, 0.0) + through * 0.5);
        float n = vnoise2(texCoord * vec2(OutSize.x / OutSize.y, 1.0) * 30.0 + vec2(0.0, -gTime * 2.5));
        vec2 off = (vec2(n, vnoise2(texCoord * 41.0 - gTime * 1.7)) - 0.5) * 0.004 * P2.y * saturate(through / 60.0);
        base = sampleScene(texCoord + off);
        float streak = pow(vnoise2(vec2(texCoord.x * OutSize.x / 9.0, mid.y * 0.05 - gTime * 1.3)), 8.0);
        glow += prism7(hueAt(mid) + n * 0.2) * saturate(through / SIZE) * (0.03 + 0.25 * streak) * P2.y;
    }

    // ---- the shear: the world round the cage cooled and dimmed, the sky over it thinned to space, stars through it
    float shear = P3.z;
    if (shear > 0.001) {
        float zen = sky ? smoothstep(-0.05, 0.55, rd.y) : 0.0;
        float k = shear * (inCage ? 0.8 : 0.55) * (1.0 - 0.25 * zen) + shear * zen * 0.2;
        base = mix(base, base * vec3(0.3, 0.29, 0.44) + vec3(0.004, 0.003, 0.012), k);
        if (sky) {
            glow += starField(rd, gPix, 0.8) * shear * zen;
        }
    }

    // ---- the 4D ripple out of the fold: the frame itself bent round a travelling ring
    if (fold >= 0.0 && fold < 3.0) {
        vec3 hp = project(foldAt);
        if (hp.z > 0.0) {
            vec2 aspect = vec2(OutSize.x / OutSize.y, 1.0);
            vec2 dd = (texCoord - hp.xy) * aspect;
            float r = length(dd);
            float front = fold * 1.1;
            float wave = sin((r - front) * 60.0) * exp(-sqr((r - front) / 0.08)) * exp(-fold * 1.2);
            vec2 off = dd / max(r, 1e-4) * wave * 0.02 / aspect;
            base = sampleScene(texCoord + off);
            glow += prism7((r - front) * 4.0 + 0.5) * abs(wave) * 0.9;
        }
    }

    if (cageOn > 0.001) {
        // ---- the cage's edges, lighting one after another, each drawn from one end to the other
        for (int k = 0; k < 12; k++) {
            int axis = k / 4;
            int c = k - axis * 4;
            vec3 a, b;
            vec2 o = vec2(float(c & 1), float((c >> 1) & 1));
            if (axis == 0) { a = vec3(lo.x, mix(lo.y, hi.y, o.x), mix(lo.z, hi.z, o.y)); b = vec3(hi.x, a.y, a.z); }
            else if (axis == 1) { a = vec3(mix(lo.x, hi.x, o.x), lo.y, mix(lo.z, hi.z, o.y)); b = vec3(a.x, hi.y, a.z); }
            else { a = vec3(mix(lo.x, hi.x, o.x), mix(lo.y, hi.y, o.y), lo.z); b = vec3(a.x, a.y, hi.z); }
            float lit = saturate(P0.w * 12.0 - float(k));
            if (lit <= 0.0) continue;
            float tRay, s;
            float d = raySeg(rd, a, b, tRay, s);
            if (tRay <= 0.0 || tRay > sceneT + 2.0 || s > lit) continue;
            float w = max(0.45 + folded * 0.4, tRay * gPix * 1.1);
            vec3 at = a + (b - a) * s;
            vec3 hc = prism7(hueAt(at));
            float run = fract(s * 3.0 - gTime * 0.9 + float(k) * 0.29);
            float pulse = exp(-sqr((run - 0.5) / 0.03));
            float head = exp(-sqr((s - lit) * 40.0)) * step(lit, 0.999);
            glow += (mix(hc, WHITE_HOT, 0.3 + 0.5 * pulse + 0.2 * slam) * exp(-sqr(d / w)) * (2.0 + 2.5 * pulse + 3.0 * folded + 6.0 * slam)
                    + hc * exp(-d / (w * 8.0)) * 0.35 + WHITE_HOT * head * exp(-d / (w * 3.0)) * 4.0) * cageOn;
        }
        // its faces: the cells' grid on them, faint, a scan running up them
        if (inCage && folded < 0.5) {
            for (int k = 0; k < 2; k++) {
                float t = k == 0 ? cageT.x : cageT.y;
                if (t <= 0.0 || t > sceneT) continue;
                vec3 p = rd * t;
                vec3 g = (p - lo) / (2.0 * cageH) * 8.0;
                vec3 f = abs(fract(g + 0.5) - 0.5);
                vec3 edgeOf = min(p - lo, hi - p);
                // the lines on this face: the two coordinates that are not its normal
                float lineD = 1e3;
                if (edgeOf.x > 0.5) lineD = min(lineD, f.x);
                if (edgeOf.y > 0.5) lineD = min(lineD, f.y);
                if (edgeOf.z > 0.5) lineD = min(lineD, f.z);
                float px = gPix * t / (2.0 * cageH) * 8.0;
                float grid = exp(-sqr(lineD / (px + 0.012)));
                float scanY = fract(gTime * 0.22) * 2.0 * cageH + lo.y;
                float scan = exp(-sqr((p.y - scanY) / 1.5)) + exp(-sqr((p.y - scanY + 6.0) / 0.6)) * 0.5;
                glow += prism7(hueAt(p)) * (grid * 0.22 + scan * 0.5) * cageOn * (1.0 - folded * 2.0) * (k == 0 ? 1.0 : 0.6);
            }
        }
    }

    // ---- the tesseract hanging in the middle: its edges and corners in the spectrum along its 4D diagonal
    if (landed > 0.001) {
        float stillness = fold >= 0.0 ? P2.w : 1.0;
        for (int i = 0; i < 16; i++) {
            vec3 a = Pts[i].xyz;
            float wa = Pts[i].w;
            for (int k = 0; k < 4; k++) {
                int bit = 1 << k;
                if ((i & bit) != 0) continue;
                int j = i | bit;
                float tRay, s;
                float d = raySeg(rd, a, Pts[j].xyz, tRay, s);
                if (tRay <= 0.0 || tRay > sceneT + 2.0) continue;
                float w4 = mix(wa, Pts[j].w, s);
                float near4 = 0.62 + 0.38 * w4;
                float w = max(0.35 * near4, tRay * gPix * 0.9);
                vec3 hc = prism7(mix(cornerHue(i), cornerHue(j), s));
                float run = fract(s - gTime * 0.8 + float(i) * 0.137 + float(k) * 0.31);
                float pulse = exp(-sqr((run - 0.5) / 0.05));
                glow += (mix(hc, WHITE_HOT, 0.35 + 0.4 * pulse) * exp(-sqr(d / w)) * (1.6 + 2.0 * pulse)
                        + hc * exp(-d / (w * 7.0)) * 0.3) * near4 * landed * stillness;
            }
            glow += glint(a, 0.12 + 0.1 * wa, sceneT, prism7(cornerHue(i))) * landed * stillness;
        }
    }

    // ---- the land in the square: its cells gridded, bracketed, numbered; the cracks racing along the grid
    vec3 g = surf - Grid;
    bool inSquare = !sky && g.x >= -2.0 && g.z >= -2.0 && g.x <= SIZE + 2.0 && g.z <= SIZE + 2.0 && abs(g.y) < 70.0 * max(gS, 0.5);
    if (inSquare) {
        vec2 cell = clamp(floor(g.xz / CELL), 0.0, 7.0);
        int idx = int(cell.y) * 8 + int(cell.x);
        vec2 local = g.xz - cell * CELL;
        bool risen = Cubes[idx].x >= 0.0;
        float aa = gPix * sceneT / max(abs(rd.y), 0.1);
        gAA = aa;
        float toLine = min(min(local.x, CELL - local.x), min(local.y, CELL - local.y));
        vec3 hc = prism7(hueAt(surf));
        float pulse = 0.6 + 0.4 * (1.0 - fract(P1.w));
        if (mark > 0.001 && !risen && sever < 0.0) {
            float lines = line(toLine, 0.28);
            vec2 pc = vec2(local.x < CELL * 0.5 ? 2.0 : CELL - 2.0, local.y < CELL * 0.5 ? 2.0 : CELL - 2.0);
            vec2 inward = sign(vec2(CELL * 0.5) - pc);
            vec2 a = (local - pc) * inward;
            float bracket = line(min(sdSegment2(a, vec2(0.0), vec2(6.0, 0.0)), sdSegment2(a, vec2(0.0), vec2(0.0, 6.0))), 0.3);
            float num = readout(local, vec2(4.0, CELL - 10.0), 5.0, cell.y * 10.0 + cell.x + 11.0, 2, aa / 2.5);
            float pip = step(length(local - vec2(CELL * 0.5)), 0.9);
            glow += (hc * (lines * 1.6 + bracket * 2.2) + mix(hc, WHITE_HOT, 0.6) * (num * 1.8 + pip)) * mark * pulse;
        }
        // the cracks: out from the middle along the grid, jagged, white-hot at their heads, the spectrum behind
        if (cracks >= 0.0 && (!risen || Cubes[idx].x < 0.4)) {
            float m = abs(g.x - SIZE * 0.5) + abs(g.z - SIZE * 0.5);
            float front = cracks * 215.0 * gS;
            float along = local.x < local.y ? g.z : g.x;
            float jag = (vnoise2(vec2(along * 0.35, cell.x * 7.0 + cell.y)) - 0.5) * 2.4;
            float cd = abs(toLine - max(jag, 0.0) * 0.8);
            float burnt = step(m, front);
            float head = exp(-sqr((m - front) / 8.0)) * step(cracks, 1.6);
            float crack = line(cd, 0.55 + head * 0.8) * burnt;
            float hot = exp(-max(front - m, 0.0) / (60.0 * gS));
            float fade = sever < 0.0 ? 1.0 : exp(-sever * 0.6);
            glow += (mix(hc, WHITE_HOT, hot * 0.7) * crack * (2.2 + 3.0 * hot) + WHITE_HOT * head * exp(-cd / 2.0) * 3.0
                    + hc * exp(-cd / 4.0) * burnt * 0.35) * fade;
        }
        // cut free: every line of the grid flashes white
        if (sever >= 0.0 && sever < 1.0) {
            glow += WHITE_HOT * line(toLine, 0.8) * exp(-sever * 4.0) * 5.0;
        }
    }

    // ---- cut free: a curtain of the spectrum up the square's four sides
    if (sever >= 0.0 && sever < 4.0) {
        float H = (16.0 + sever * 140.0) * max(gS, 0.5);
        float fade = exp(-sever * 1.1);
        for (int k = 0; k < 4; k++) {
            vec3 n = k < 2 ? vec3(1.0, 0.0, 0.0) : vec3(0.0, 0.0, 1.0);
            vec3 at = Grid + (k == 1 ? vec3(SIZE, 0.0, 0.0) : k == 3 ? vec3(0.0, 0.0, SIZE) : vec3(0.0));
            float t = rayPlane(vec3(0.0), rd, at, n);
            if (t <= 0.0 || t > sceneT) continue;
            vec3 p = rd * t - Grid;
            float along = k < 2 ? p.z : p.x;
            if (along < 0.0 || along > SIZE) continue;
            float up = p.y - (pitY - Grid.y);
            if (up < 0.0 || up > H) continue;
            float rise = up / H;
            float bars = 0.6 + 0.4 * step(0.4, hash11(floor(along / 4.0) + float(k) * 71.0));
            glow += prism7(hueAt(rd * t) + rise * 0.3) * (1.0 - rise) * bars * fade * 1.4
                    + WHITE_HOT * exp(-up / 3.0) * fade * 2.5;
        }
    }

    // ---- the cubes: the column of light under each as it goes up, its outline burning, settling to a line of colour
    if (sever >= 0.0) {
        for (int i = 0; i < 64; i++) {
            float since = Cubes[i].x;
            if (since < 0.0) continue;
            float cx = float(i - (i / 8) * 8);
            float cz = float(i / 8);
            float zd = Cubes[i].w;
            vec3 clo = vec3(Grid.x + cx * CELL, Cubes[i].y, Grid.z + cz * CELL + (CELL - zd) * 0.5);
            vec3 chi = vec3(clo.x + CELL, clo.y + Cubes[i].z, clo.z + zd);
            float hue = (cx + cz) / 14.0 * (6.0 / 7.0) + gTime * 0.035;
            vec3 hc = prism7(hue);
            float burn = exp(-since * 1.6);
            // its column, from the pit floor up to its foot
            if (since < 4.0) {
                // from its own tier of the pit (a ring deeper each way in: Tesseract.floor), never under the bedrock
                float ring = floor(max(abs(cx - 3.5), abs(cz - 3.5)));
                float tier = max(pitY - (4.0 - ring) * P4.z, min(pitY, P4.w));
                vec3 plo = vec3(Grid.x + cx * CELL, tier, Grid.z + cz * CELL);
                vec3 phi = vec3(plo.x + CELL, clo.y, plo.z + CELL);
                vec2 pt = rayBox(rd, plo, phi);
                if (pt.y > max(pt.x, 0.0) && max(pt.x, 0.0) < sceneT) {
                    float through = min(pt.y, sceneT) - max(pt.x, 0.0);
                    vec3 p = rd * max(pt.x, 0.0);
                    float e = boxEdge(p, plo, phi);
                    float w = max(0.5, max(pt.x, 0.0) * gPix * 1.2);
                    float rise = saturate((p.y - tier) / max(clo.y - tier, 1.0));
                    glow += (prism7(hue + rise * 0.4) * saturate(through / CELL) * 0.12 + mix(hc, WHITE_HOT, 0.5) * exp(-sqr(e / w)) * 1.6
                            * step(0.0, pt.x)) * exp(-since * 1.3);
                }
            }
            // its outline
            vec2 ct = rayBox(rd, clo - 0.3, chi + 0.3);
            if (ct.y > max(ct.x, 0.0) && ct.x > 0.0 && ct.x < sceneT + 1.5) {
                vec3 p = rd * ct.x;
                float e = boxEdge(p, clo - 0.3, chi + 0.3);
                float w = max(0.35, ct.x * gPix * 1.1);
                float flash = exp(-since * 9.0);
                glow += (mix(hc, WHITE_HOT, 0.3 + 0.6 * burn) * exp(-sqr(e / w)) * (1.2 + 5.0 * burn) * max(P2.w, burn)
                        + hc * exp(-e / (w * 6.0)) * 0.25 * burn) + WHITE_HOT * flash * 1.5 * step(ct.x, sceneT + 1.0);
            }
        }
    }

    // ---- the landing: a ring of the spectrum running out across the land from the square, white at its front
    if (sinceLand >= 0.0 && sinceLand < 3.0 && !sky) {
        vec3 mid = Grid + vec3(SIZE * 0.5, 0.0, SIZE * 0.5);
        float hd = length(surf.xz - mid.xz);
        float front = sinceLand * 420.0 * max(gS, 0.5);
        float f = exp(-sinceLand * 1.3);
        float band = (front - hd) / 90.0;
        if (band > 0.0 && band < 1.0) {
            glow += prism7(band * (6.0 / 7.0) + 0.1) * (1.0 - band) * 1.8 * f;
        }
        glow += WHITE_HOT * exp(-sqr((hd - front) / 4.0)) * 3.5 * f;
    }

    // ---- the fold: the tesseract flares, rings of the spectrum run out across the land and through the sky
    if (fold >= 0.0 && fold < 8.0) {
        float f = exp(-fold * 0.9);
        glow += glint(foldAt, 1.0 + 2.0 * exp(-fold * 3.0), sceneT, prism7(gTime * 0.5)) * f * 2.0;
        float front = fold * 190.0;
        if (!sky) {
            float hd = length(surf.xz - foldAt.xz);
            float band = (front - hd) / 70.0;
            if (band > 0.0 && band < 1.0) {
                glow += prism7(band * (6.0 / 7.0)) * (1.0 - band) * 2.4 * f;
            }
            glow += WHITE_HOT * exp(-sqr((hd - front) / 3.0)) * 3.0 * f;
        }
        float tp;
        float dp = rayPointDist(vec3(0.0), rd, foldAt, tp);
        if (tp < sceneT) {
            float band = (front - dp) / 50.0;
            if (band > 0.0 && band < 1.0) {
                glow += prism7(band * (6.0 / 7.0)) * (1.0 - band) * 0.9 * f;
            }
        }
    }

    fragColor = vec4(tonemap(base + glow), 1.0);
}
