// SS-03, Gungnir, in the world. Before the strike: an ember mark on the target — hexagonal brackets closing and turning,
// rings, a cross — the strike's zone swept round the land by a radar line with pulses closing on the mark, and the
// path it will come down, a dashed line standing straight up from the mark into the zenith. Then, out of the zenith, in
// silence: a white-hot point falling, its plasma trail burning above it, the shock cone round it in rings of
// condensation, the land lit white under it. It goes in: a flash, then the shock ring running out flat over the land
// — its front a band of white-ember light bending the view behind it, a wall of dust rolling low behind it, hugging the
// ground (never a mushroom) — and the crater's floor molten round the needle's tail. After: the needle's column of
// ionised air standing in the sky over it, twisting and fading; heat shimmering off the spire, ember pulses running up it.
// Camera-relative world space.
//
// Target = the ground point it strikes. P0 = (seconds, seed, the mark, incoming 0..1), P1 = (seconds since the impact or
// < 0, the shock ring's radius, the zone's radius, the dust), P2 = (the reticle, the pulse phase, the ground's y relative
// to the camera, the crater's heat), P3 = (the spire's glow, the trail in the sky, -, the heat haze), P4 = (the spire's
// top y relative to the camera, the bottom of the crater's y, the spire's hull radius, the ring's strength), P5 = (the
// telemetry burned into the land, the scan shells, the schematic in the sky, -).
//
// The landing is a weapon system reporting its hit: impact telemetry burned into the land from the needle outward — a
// hexagonal lattice, circuit traces branching out to vias with pulses of data running down them, range rings read off in
// seven-segment figures, a crosshair and targeting brackets; holographic scan shells thrown up the spire, barcoded and
// spinning, a scan line climbing it; a wireframe schematic of the needle standing in the sky with its dimensions; and a
// stream of chevrons riding the shock ring's front.

#include "star.glsl"

uniform vec4 P4;
uniform vec4 P5;
/** The zone's size against the remote's (P5.w): Mrityu drives a quarter of it. */
float gK = 1.0;

const vec3 EMBER = vec3(1.0, 0.3, 0.06);
const vec3 EMBER_HOT = vec3(1.0, 0.62, 0.3);
const vec3 WHITE_HOT = vec3(1.0, 0.95, 0.88);

/** A regular hexagon's outline distance, apothem r (the needle's own cross-section, as a HUD motif). */
float hexLine(vec2 p, float r) {
    const vec3 k = vec3(-0.866025404, 0.5, 0.577350269);
    p = abs(p);
    p -= 2.0 * min(dot(k.xy, p), 0.0) * k.xy;
    p -= vec2(clamp(p.x, -k.z * r, k.z * r), r);
    return abs(length(p) * sign(p.y));
}

/** The dust the shock ring throws up, rolling low behind its front: density at a point (y above the ground). */
float dustAt(vec3 p, float front, float since) {
    float hd = length(p.xz - Target.xz);
    float y = p.y - P2.z;
    if (y < -2.0) return 0.0;
    // a wall behind the front, thinning back toward the needle, lower and lower far out
    float behind = front - hd;
    float kd = max(gK, 0.35);
    float wall = smoothstep(-3.0, 4.0, behind) * exp(-max(behind, 0.0) / ((45.0 + since * 40.0) * kd));
    float h = mix(48.0, 12.0, saturate(hd / (P1.z * 1.3))) * (1.0 + since * 0.35) * kd;
    float vertical = exp(-max(y, 0.0) / h) * smoothstep(-2.0, 1.5, y);
    float a = atan(p.z - Target.z, p.x - Target.x);
    float roll = fbm3(vec3(a * 26.0, y * 0.06 / kd - since * 0.8, hd * 0.035 / kd - since * 1.4) + gSeed * 7.0);
    return wall * vertical * smoothstep(0.25, 0.75, roll) * 1.4;
}

// ---------------------------------------------------------------- read-outs

/** Distance to the lit segments of a seven-segment digit, p in its cell: 0..1 across, 0..2 up. */
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

/** A number of `count` digits laid left to right from `at` (height h) in a plane's (u, v); 1 on its lit segments. */
float readout(vec2 uv, vec2 at, float h, float value, int count, float aa) {
    vec2 p = (uv - at) / (h * 0.5);
    float cellW = 1.35;
    if (p.y < -0.2 || p.y > 2.2 || p.x < -0.2 || p.x > cellW * float(count)) return 0.0;
    float i = floor(p.x / cellW);
    int digit = int(mod(floor(value / pow(10.0, float(count) - 1.0 - i) + 0.001), 10.0));
    float d = digitDist(vec2(p.x - i * cellW, p.y), digit);
    return smoothstep(0.1 + aa, 0.1 - aa, d);
}

/** The distance to the nearest edge of a hexagonal lattice of cell size `size`, and the cell's id. */
vec3 hexCell(vec2 p, float size) {
    vec2 q = p / size;
    const vec2 r = vec2(1.0, 1.7320508);
    vec2 h = r * 0.5;
    vec2 a = mod(q, r) - h;
    vec2 b = mod(q - h, r) - h;
    vec2 g = dot(a, a) < dot(b, b) ? a : b;
    vec2 id = q - g;
    vec2 ag = abs(g);
    float edge = 0.5 - max(dot(ag, normalize(vec2(1.0, 1.7320508))), ag.x);
    return vec3(edge * size, id);
}

// ---------------------------------------------------------------- the landing, reported

/**
 * The telemetry the landing burns into the land, spreading from the needle as fast as the shock ring runs: a hexagonal
 * lattice, some of its cells lit and flickering; circuit traces branching out cell by cell to vias, pulses of data
 * running out along them; range rings dashed and ticked, read off at 050, 100, 150, 200; a crosshair through the needle;
 * targeting brackets at the corners of the zone. Each line flashes white as it is drawn, burns ember, and cools.
 */
vec3 telemetry(vec3 at, float s, float aaBlocks) {
    vec2 q = at.xz - Target.xz;
    float R = P1.z + 5.0;
    float reveal = R * 1.04 * (1.0 - exp(-s * 3.0));
    float r = length(q);
    float box = max(abs(q.x), abs(q.y));
    if ((r > reveal + 6.0 && box > reveal) || abs(at.y - P2.z) > 28.0) return vec3(0.0);
    gAA = aaBlocks;
    // the lattice
    vec3 hx = hexCell(q, 9.0);
    float lattice = line(hx.x, 0.12) * 0.45;
    float lit = step(0.9, hash12(hx.yz + floor(gTime * 6.0 + hash12(hx.yz) * 9.0)));
    float cells = lit * smoothstep(0.0, 0.6, hx.x) * 0.35;
    // the traces: from each cell's centre to the edges it shares with its neighbours, where their edge's hash allows
    float c = 12.0;
    vec2 cell = floor(q / c);
    vec2 f = q / c - cell - 0.5;
    float trace = 1e3;
    float links = 0.0;
    for (int k = 0; k < 4; k++) {
        vec2 dir = k == 0 ? vec2(1.0, 0.0) : k == 1 ? vec2(-1.0, 0.0) : k == 2 ? vec2(0.0, 1.0) : vec2(0.0, -1.0);
        vec2 edgeId = cell * 2.0 + dir + vec2(k < 2 ? 0.37 : 0.0, k < 2 ? 0.0 : 0.61);
        if (hash12(edgeId * 1.3 + gSeed) < 0.42) {
            trace = min(trace, sdSegment2(f, vec2(0.0), dir * 0.5));
            links += 1.0;
        }
    }
    float traces = line(trace * c, 0.35) * step(0.5, links);
    float via = links == 1.0 || links >= 3.0 ? line(abs(length(f) * c - 1.1), 0.3) + line(length(f) * c, 0.45) : 0.0;
    float pulse = step(0.72, fract(r / 11.0 - s * 5.0));
    float circuit = (traces * (0.6 + 1.4 * pulse) + via) * smoothstep(R * 0.2, R * 0.28, r);
    // range rings, dashed, ticked, and read off
    float a = atan(q.y, q.x);
    float rings = 0.0;
    float labels = 0.0;
    for (int i = 1; i <= 4; i++) {
        float rr = float(i) * (R - 5.0) * 0.25;
        float dash = step(0.3, fract(a / TAU * (48.0 + float(i) * 24.0) + s * (float(i) - 2.5) * 0.05));
        rings += line(abs(r - rr), 0.45) * (i == 4 ? 1.0 : dash);
        rings += line(abs(r - rr - 2.2), 0.18) * step(0.8, fract(a / TAU * 360.0));
        for (int j = 0; j < 4; j++) {
            float ang = float(j) * PI * 0.5 + PI * 0.25;
            vec2 dirL = vec2(cos(ang), sin(ang));
            vec2 perp = vec2(-dirL.y, dirL.x);
            vec2 uv = vec2(dot(q, perp), dot(q, dirL));
            labels += readout(uv, vec2(-10.0, rr + 6.0), 8.0, rr, 3, aaBlocks / 4.0);
        }
    }
    // the crosshair: long lines through the needle, gapped round it, ticked every ten
    float axisD = min(abs(q.x), abs(q.y));
    float along = max(abs(q.x), abs(q.y));
    float edgeR = R + 7.0;
    float cross = line(axisD, 0.4) * step(R * 0.11, along) * step(along, edgeR);
    float crossTicks = step(axisD, 3.0) * step(0.9, fract(along / 10.0)) * step(R * 0.11, along) * step(along, edgeR);
    // targeting brackets at the corners of the zone's square
    vec2 aq = abs(q);
    float corner = (line(abs(aq.x - edgeR), 0.7) * step(edgeR - R * 0.18, aq.y) * step(aq.y, edgeR)
            + line(abs(aq.y - edgeR), 0.7) * step(edgeR - R * 0.18, aq.x) * step(aq.x, edgeR));
    float lines = saturate(lattice + cells + circuit + rings + labels * 1.4 + cross + crossTicks + corner);
    float fr = reveal;
    float d = max(r, box * 0.97);
    float drawn = smoothstep(fr + 2.0, fr - 3.0, d);
    float flash = exp(-max(fr - d, 0.0) / 24.0);
    float cool = exp(-s / 12.0);
    vec3 col = mix(vec3(0.55, 0.06, 0.02), mix(EMBER_HOT, WHITE_HOT, flash), cool) * (1.0 + 5.0 * flash * exp(-s * 0.5));
    return col * lines * drawn * (0.35 + 1.8 * cool) * P5.x;
}

/**
 * Scan shells thrown up the spire at the landing: holographic rings stacked up its shaft, barcoded in dashes of every
 * length, spinning each its own way, ticked, bracketed at the four quarters; and a scan line climbing the spire.
 */
vec3 shells(vec3 rd, float sceneT, float s) {
    vec3 col = vec3(0.0);
    if (abs(rd.y) < 1e-4 || P5.y < 0.001) return col;
    for (int i = 0; i < 7; i++) {
        float fi = float(i);
        bool scan = i == 6;
        float k = scan ? s : s - fi * 0.045;
        if (k <= 0.0) continue;
        float y = scan ? P2.z + 380.0 * (1.0 - exp(-s * 1.4)) : P2.z + 18.0 + fi * 50.0 + k * 34.0;
        float tp = y / rd.y;
        if (tp <= 0.0 || tp > sceneT) continue;
        vec2 q = rd.xz * tp - Target.xz;
        float r = length(q);
        float rr = scan ? P4.z + 12.0 : P4.z + 5.0 + fi * 6.0 + P1.z * 0.75 * (1.0 - exp(-k * (1.9 - fi * 0.2)));
        float fp = max(gPix * tp / max(abs(rd.y), 0.05), 0.05);
        float fade = scan ? exp(-s * 0.6) : exp(-k * (0.9 + fi * 0.2));
        float a = atan(q.y, q.x) / TAU;
        float spin = k * (fi - 2.5) * 0.12;
        float seg = floor((a + spin) * 72.0);
        float barcode = step(0.35, hash11(seg * 1.7 + fi * 13.0)) * step(0.12, fract((a + spin) * 72.0));
        float band = exp(-sqr((r - rr) / max(0.9, fp))) * barcode;
        float inner = exp(-sqr((r - rr * 0.95) / max(0.35, fp)));
        float ticks = step(0.75, fract(a * 180.0)) * step(rr * 1.015, r) * step(r, rr * 1.04);
        float quarter = abs(fract(a * 4.0 + 0.125 - spin * 2.0) - 0.5);
        float brackets = exp(-sqr((r - rr * 1.08) / max(0.6, fp))) * step(quarter, 0.07);
        col += mix(WHITE_HOT, EMBER, saturate(k * 1.1)) * (band * 2.6 + inner * 1.2 + ticks * 1.0 + brackets * 2.4) * fade;
    }
    return col * P5.y;
}

/**
 * The schematic: a wireframe of the whole needle, point down as it went in, standing in the sky over the landing inside
 * a gridded frame with corner brackets — its hex edges, its sections, its fins — a dimension line down its side read off
 * at 1020 m, a callout from its point with its speed, and a scan line sweeping down it, lighting it as it passes.
 */
vec3 schematic(vec3 rd, float sceneT, float s) {
    if (P5.z < 0.001) return vec3(0.0);
    vec2 toCam = -Target.xz;
    float l = length(toCam);
    if (l < 1.0) return vec3(0.0);
    vec3 n = vec3(toCam.x / l, 0.0, toCam.y / l);
    float tp = rayPlane(vec3(0.0), rd, Target, n);
    if (tp <= 0.0 || tp > sceneT) return vec3(0.0);
    vec3 h = rd * tp - Target;
    float scale = clamp(P1.z / 250.0, 0.3, 1.6);
    float u = dot(h, vec3(-n.z, 0.0, n.x)) / scale;
    float v = h.y / scale;
    float px = max(gPix * tp / scale, 0.2);
    gAA = px;
    float v0 = 70.0;
    float v1 = 640.0;
    if (v < v0 - 40.0 || v > v1 + 40.0 || abs(u) > 170.0) return vec3(0.0);
    // the frame, its grid and its corner brackets
    vec2 fu = vec2(abs(u), v);
    float grid = (line(abs(fract(u / 20.0 + 0.5) - 0.5) * 20.0, 0.12) + line(abs(fract(v / 20.0 + 0.5) - 0.5) * 20.0, 0.12))
            * step(abs(u), 150.0) * step(v0 - 20.0, v) * step(v, v1 + 20.0) * 0.22;
    float frameL = (line(abs(fu.x - 150.0), 0.8) * (step(v1 - 20.0, v) + step(v, v0 + 20.0)) * step(v0 - 20.0, v) * step(v, v1 + 20.0)
            + line(abs(v - v1 - 20.0), 0.8) * step(130.0, fu.x) * step(fu.x, 150.0)
            + line(abs(v - v0 + 20.0), 0.8) * step(130.0, fu.x) * step(fu.x, 150.0));
    // the needle: point at the bottom, tail fins at the top
    float kv = saturate((v - v0) / (v1 - v0));
    float hw = 26.0 * min(kv / 0.42, 1.0) * mix(1.0, 0.8, smoothstep(0.93, 1.0, kv));
    float inside = step(v0, v) * step(v, v1);
    float outline = line(abs(abs(u) - hw), 0.9) * inside;
    float edges = (line(abs(u), 0.5) + line(abs(abs(u) - hw * 0.5), 0.4)) * step(v0 + 10.0, v) * step(v, v1);
    float sections = line(abs(fract((v - v0) / 57.0 + 0.5) - 0.5) * 57.0, 0.5) * step(abs(u), hw) * inside;
    float fz = saturate((v - (v1 - 90.0)) / 90.0);
    float finHw = mix(hw, 66.0, fz);
    float fins = line(abs(abs(u) - finHw), 0.8) * step(v1 - 90.0, v) * step(v, v1) * step(hw, abs(u) + 1.0)
            + line(abs(v - v1), 0.8) * step(abs(u), 66.0);
    // the dimension line down its right, arrowheads at its ends, read off in metres
    float dimX = 104.0;
    float dim = line(abs(u - dimX), 0.5) * step(v0, v) * step(v, v1)
            + line(abs(v - v0), 0.5) * step(abs(u - dimX), 10.0) + line(abs(v - v1), 0.5) * step(abs(u - dimX), 10.0)
            + line(abs(abs(u - dimX) - (v - v0) * 0.35), 0.5) * step(v, v0 + 14.0) * step(v0, v)
            + line(abs(abs(u - dimX) - (v1 - v) * 0.35), 0.5) * step(v1 - 14.0, v) * step(v, v1);
    float metres = readout(vec2(u, v), vec2(dimX + 8.0, (v0 + v1) * 0.5 - 12.0), 24.0, 1020.0, 4, px / 12.0);
    // a callout from its point: a leader line out to a box, its speed in it
    float lead = line(sdSegment2(vec2(u, v), vec2(0.0, v0), vec2(-60.0, v0 + 50.0)), 0.5)
            + line(sdSegment2(vec2(u, v), vec2(-60.0, v0 + 50.0), vec2(-140.0, v0 + 50.0)), 0.5);
    float speed = readout(vec2(u, v), vec2(-138.0, v0 + 56.0), 18.0, 9987.0, 4, px / 9.0);
    // the scan line sweeping down it: everything above it drawn, the line itself burning
    float scanV = v1 + 40.0 - (v1 - v0 + 80.0) * saturate(s / 0.9);
    float drawn = step(scanV, v);
    float scanLine = exp(-abs(v - scanV) / max(1.5, px)) * step(abs(u), 150.0) * step(s, 0.95);
    float lines = saturate(grid + frameL + (outline + edges * 0.6 + sections * 0.5 + fins + dim + metres * 1.3 + lead + speed * 1.3) * drawn);
    return (WHITE_HOT * 2.2 + EMBER * 1.4) * lines * P5.z + WHITE_HOT * scanLine * 3.0 * P5.z;
}

void main() {
    initPixel(texCoord);
    gTime = P0.x;
    gSeed = P0.y;
    gK = P5.w > 0.001 ? P5.w : 1.0;
    vec3 rd = viewDir(texCoord);
    vec3 surf = scenePosAt(texCoord);
    bool sky = skyAt(texCoord);
    float sceneT = sky ? FAR : length(surf);
    float since = P1.x;
    float front = P1.y;
    float zoneR = P1.z;
    vec2 axis = Target.xz;
    float hd = length(surf.xz - axis);

    // ---- the shock ring bends the view behind its front; the heat over the crater and round the spire shimmers
    vec2 uv = texCoord;
    if (since >= 0.0 && since < 3.5 && !sky) {
        float band = (hd - front) / (6.0 + since * 5.0);
        float bend = band * exp(-band * band) * exp(-since * 0.9) * P4.w;
        vec3 tp = project(Target);
        vec2 away = tp.z > 0.0 ? normalize(texCoord - tp.xy + 1e-5) : vec2(0.0, 1.0);
        uv += away * bend * 0.012;
    }
    if (P3.w > 0.001) {
        float tAx;
        float dAx = raySegmentDist(vec3(0.0), rd, Target + vec3(0.0, P4.y - Target.y, 0.0), vec3(Target.x, P4.x, Target.z), tAx);
        float near = exp(-max(dAx - P4.z, 0.0) / 5.0) * step(tAx, sceneT + 4.0);
        float crater = sky ? 0.0 : exp(-hd / (P1.z * 0.15)) * step(surf.y, Target.y + 30.0);
        float shimmer = (near + crater) * P3.w;
        if (shimmer > 0.001) {
            vec2 wob = vec2(vnoise2(texCoord * 90.0 + vec2(0.0, gTime * 3.0)), vnoise2(texCoord * 90.0 + vec2(7.3, gTime * 2.6))) - 0.5;
            uv += wob * 0.004 * shimmer;
        }
    }
    vec3 base = sampleScene(uv);
    vec3 glow = vec3(0.0);

    // ---- the mark, the zone, the path
    if (P0.z > 0.001) {
        if (!sky && abs(surf.y - Target.y) < 40.0 + hd * 0.4) {
            float w = max(0.12, sceneT * gPix * 1.2);
            vec2 q = surf.xz - axis;
            float ang = atan(q.y, q.x);
            if (P2.x > 0.001 && hd < 16.0) {
                // hexagonal brackets closing and turning, a dashed ring, a cross
                float spin = gTime * 0.6;
                float hr = mix(14.0, 6.0, P2.x);
                vec2 qr = rot(spin) * q;
                float hex = saturate(1.0 - hexLine(qr, hr) / w) * step(0.35, abs(fract(atan(qr.y, qr.x) / TAU * 6.0) - 0.5) * 2.0);
                float hex2 = saturate(1.0 - hexLine(rot(-spin * 1.7) * q, hr * 0.45) / w);
                float ring = saturate(1.0 - abs(hd - 2.2) / w) * step(0.5, fract(ang / TAU * 18.0 - gTime * 1.5));
                float cross = (saturate(1.0 - abs(q.x) / w) + saturate(1.0 - abs(q.y) / w)) * step(3.0, hd) * step(hd, 5.0);
                float dot_ = exp(-sqr(hd / 0.6));
                glow += EMBER * (hex * 2.6 + hex2 * 1.4 + ring * 1.6 + cross * 1.4) * P2.x + EMBER_HOT * dot_ * 3.0 * P0.z;
            }
            // the rim of the zone, ticks, a sweep, pulses closing on the mark
            float edge = saturate(1.1 - abs(hd - zoneR) / w);
            float sweep = fract(ang / TAU + gTime * 0.3);
            float wedge = exp(-sweep * 12.0) * step(hd, zoneR) * smoothstep(0.0, zoneR * 0.5, hd);
            float ticks = step(0.8, fract(ang / TAU * 60.0)) * step(abs(hd - zoneR + 3.0), 2.0);
            float pulse = fract(P2.y);
            float closing = saturate(1.0 - abs(hd - zoneR * (1.0 - pulse)) / (w * 2.0 + 1.0)) * (1.0 - pulse);
            glow += EMBER * (edge * 2.2 + ticks * 1.1 + wedge * 0.4 + closing * 1.5) * P0.z;
            base = mix(base, base * vec3(1.15, 0.8, 0.7), wedge * 0.25 * P0.z);
        }
        // the path it will come down: a dashed ember line standing up from the mark into the zenith
        float tRay;
        float d = raySegmentDist(vec3(0.0), rd, Target, Target + vec3(0.0, 5000.0, 0.0), tRay);
        if (tRay < sceneT) {
            vec3 at = rd * tRay;
            float wl = max(0.06, tRay * gPix * 0.8);
            float dash = step(0.45, fract((at.y - Target.y) / 14.0 + gTime * 1.2));
            float core = saturate(1.2 - d / wl) * dash;
            float air = exp(-d / (wl * 6.0 + 0.3)) * 0.2;
            glow += EMBER * (core * 2.5 + air) * P0.z * (1.0 - P0.w);
        }
    }

    // ---- out of the zenith, silent: the needle
    float k = P0.w;
    if (k > 0.001) {
        // (it does not slow: the last of the fall goes by in a blink)
        float h = 20.0 + 9000.0 * pow(max(1.0 - k, 0.0), 0.75);
        vec3 head = Target + vec3(0.0, h, 0.0);
        // the plasma it drags down behind it
        float tRay;
        float d = raySegmentDist(vec3(0.0), rd, head, head + vec3(0.0, min(h * 1.5, 5000.0), 0.0), tRay);
        if (tRay < sceneT) {
            vec3 at = rd * tRay;
            float up = (at.y - head.y) / max(h * 1.5, 1.0);
            float w = max(0.4 + h * 0.002, tRay * gPix * 0.8);
            float core = exp(-d / w) * exp(-up * 3.0);
            float haze = exp(-d / (w * 8.0 + 3.0)) * exp(-up * 2.0) * 0.35;
            glow += (mix(WHITE_HOT, vec3(1.0, 0.45, 0.5), saturate(up * 2.0)) * core * 2.4 + vec3(1.0, 0.4, 0.3) * haze) * k;
        }
        // the shock cone round it: rings of condensation stacked above the point, widening
        for (int i = 0; i < 4; i++) {
            float fi = float(i);
            float dy = h * (0.015 + fi * 0.03) + fi * 3.0;
            float yc = head.y + dy;
            if (abs(rd.y) < 1e-4) continue;
            float tp = yc / rd.y;
            if (tp <= 0.0 || tp > sceneT) continue;
            vec3 q = rd * tp;
            float rr = length(q.xz - axis);
            float rc = dy * 0.3;
            float wr = max(0.3 + dy * 0.02, tp * gPix);
            glow += vec3(0.95, 0.97, 1.0) * exp(-sqr((rr - rc) / wr)) * (0.9 - fi * 0.18) * smoothstep(0.2, 0.7, k);
        }
        vec3 hp = project(head);
        if (hp.z > 0.0 && length(head) < sceneT + 5.0) {
            vec2 dd = (texCoord - hp.xy) * vec2(OutSize.x / OutSize.y, 1.0);
            float px = 1.0 / OutSize.y;
            float g = smoothstep(0.1, 1.0, k);
            float twinkle = 0.75 + 0.25 * sin(gTime * 61.0) * sin(gTime * 37.0 + 2.0);
            float len = (0.03 + 0.34 * g * g) * twinkle;
            float core = exp(-dot(dd, dd) / sqr(px * (1.5 + 4.0 * g)));
            float cross = exp(-abs(dd.y) / (px * 0.8)) * exp(-abs(dd.x) / len)
                    + exp(-abs(dd.x) / (px * 0.8)) * exp(-abs(dd.y) / len);
            vec2 r45 = mat2(0.7071, 0.7071, -0.7071, 0.7071) * dd;
            float diag = exp(-abs(r45.y) / (px * 0.6)) * exp(-abs(r45.x) / (len * 0.3))
                    + exp(-abs(r45.x) / (px * 0.6)) * exp(-abs(r45.y) / (len * 0.3));
            float halo = exp(-length(dd) / (px * (8.0 + 60.0 * g)));
            glow += (WHITE_HOT * core * 6.0 + mix(WHITE_HOT, EMBER_HOT, 0.4) * (cross * 2.2 + diag * 1.0) + EMBER_HOT * halo * 0.8) * (0.3 + 1.4 * g);
        }
        // the sky over the strike going dark round the zenith as it comes, the Sun with it: nothing up there but the point
        if (sky) {
            float zen = smoothstep(0.2, 0.9, rd.y);
            float dusk = sqr(smoothstep(0.0, 0.6, k)) * zen * 0.92;
            base = mix(base, base * 0.08 + vec3(0.02, 0.018, 0.03), dusk);
        }
        // the land lit white from above as it comes
        if (!sky) {
            float light = k * k * k * 2.0 * 260.0 * 260.0 / (hd * hd + h * h * 0.25 + 260.0 * 260.0);
            base += base * vec3(1.0, 0.9, 0.8) * light;
        } else {
            float toHead = length(rd - normalize(head));
            base += vec3(1.0, 0.8, 0.7) * exp(-toHead / 0.25) * k * k * 0.5;
        }
    }

    // ---- it goes in
    if (since >= 0.0) {
        // the flash where it went in: a dome of white light, gone in a blink
        float tc;
        float dc = rayPointDist(vec3(0.0), rd, Target + vec3(0.0, 4.0, 0.0), tc);
        float dome = exp(-dc / (6.0 + since * 60.0)) * exp(-since * 9.0) * step(tc, sceneT + 30.0);
        glow += WHITE_HOT * dome * 8.0;
        // the shock ring's front, running out flat over the land
        if (!sky && since < 4.0) {
            float wf = 2.5 + since * 4.0;
            float band = exp(-sqr((hd - front) / wf)) * step(abs(surf.y - P2.z), 30.0 + since * 20.0);
            glow += mix(WHITE_HOT, EMBER, saturate(since * 0.9)) * band * 3.0 * exp(-since * 0.8) * P4.w;
            // the land it has passed goes dark and hot
            float passed = smoothstep(front + 2.0, front - 10.0, hd) * step(hd, zoneR + 8.0);
            base = mix(base, base * vec3(0.55, 0.42, 0.38), passed * 0.5 * exp(-since * 0.15));
        }
        // the crater's floor molten round the needle, cooling slowly
        if (!sky && P2.w > 0.001 && hd < P1.z * 0.3 && surf.y < P2.z + 3.0) {
            float cracks = fbm2(surf.xz * 0.25 + gSeed);
            float cool = exp(-hd / (P1.z * 0.11));
            float t = P2.w * cool * (0.4 + 0.8 * smoothstep(0.45, 0.7, cracks));
            glow += blackbody(0.25 + 0.6 * t) * t * 3.0;
        }
        // the shaft it drove down a hundred blocks: white-hot at the bottom, cooling up its walls
        if (!sky && P2.w > 0.001 && hd < 120.0 * gK && surf.y < P2.z - 12.0 * gK) {
            float deep = smoothstep(P2.z - 12.0 * gK, P2.z - 100.0 * gK, surf.y);
            float n = fbm2(vec2(atan(surf.z - Target.z, surf.x - Target.x) * 6.0, surf.y * 0.08) + gSeed);
            float t = P2.w * deep * (0.55 + 0.6 * n);
            glow += blackbody(0.3 + 0.65 * t) * t * 4.0;
        }
        // the ornament of the landing: the sigil burned into the land, runes cut along the running front, a crown of
        // rings thrown up the spire, the spearhead blazing in the sky
        if (!sky) {
            float aaB = gPix * sceneT / max(abs(rd.y), 0.08);
            glow += telemetry(surf, since, aaB);
            if (since < 3.5 && front > 6.0) {
                // a stream of chevrons riding the front, pointing out, running round it
                vec2 q = surf.xz - axis;
                float behind = front - hd;
                float ang = atan(q.y, q.x) * front;
                float kc = max(gK, 0.4);
                float chevron = abs(fract(ang / (7.0 * kc) + since * 2.0) - 0.5) * 7.0 * kc;
                float chev = exp(-sqr((behind - 5.0 * kc - chevron * 0.9) / max(0.35, aaB)))
                        * step(0.0, behind) * step(behind, 12.0 * kc) * step(0.25, fract(ang / (42.0 * kc)));
                glow += mix(WHITE_HOT, EMBER, saturate(since * 0.8)) * chev * 3.0 * exp(-since * 0.6)
                        * step(abs(surf.y - P2.z), 30.0) * P4.w;
            }
        }
        glow += shells(rd, sceneT, since) + schematic(rd, sceneT, since);
        // the dust wall, rolling out low behind the front
        if (P1.w > 0.001) {
            float y0 = P2.z - 2.0;
            float y1 = P2.z + (60.0 + since * 15.0) * max(gK, 0.35);
            float t0 = 0.0;
            float t1 = min(sceneT, 900.0);
            if (abs(rd.y) > 1e-4) {
                float ta = y0 / rd.y;
                float tb = y1 / rd.y;
                t0 = max(t0, min(ta, tb));
                t1 = min(t1, max(ta, tb));
            } else if (y0 > 0.0 || y1 < 0.0) {
                t1 = -1.0;
            }
            if (t1 > t0) {
                const int STEPS = 14;
                float dt = (t1 - t0) / float(STEPS);
                float jitter = hash12(gl_FragCoord.xy + fract(gTime) * 13.0);
                float trans = 1.0;
                vec3 dust = vec3(0.0);
                for (int i = 0; i < STEPS; i++) {
                    vec3 p = rd * (t0 + dt * (float(i) + jitter));
                    float dens = dustAt(p, front, since) * P1.w;
                    if (dens < 0.002) continue;
                    float pd = length(p.xz - axis);
                    // lit by the sky, and on its inner face by the fire at the centre
                    vec3 lightC = vec3(0.5, 0.47, 0.45) + blackbody(0.5) * 1.6 * exp(-pd / (60.0 * gK)) * exp(-since * 0.4)
                            + EMBER * 0.35 * exp(-abs(pd - front) / (12.0 * max(gK, 0.35))) * exp(-since * 0.6);
                    float a = 1.0 - exp(-dens * dt * 0.08);
                    dust += trans * a * vec3(0.4, 0.36, 0.32) * lightC;
                    trans *= 1.0 - a;
                    if (trans < 0.03) break;
                }
                base = base * trans + dust;
                glow *= mix(1.0, trans, 0.7);
            }
        }
    }

    // ---- the spire: ember pulses running up it, an aura of heat round it
    if (P3.x > 0.001) {
        float tAx;
        vec3 foot = vec3(Target.x, P4.y, Target.z);
        vec3 crown = vec3(Target.x, P4.x, Target.z);
        float d = raySegmentDist(vec3(0.0), rd, foot, crown, tAx);
        // (only the air round it glows: a ray that meets the hull itself shows the hull, black, its seams burning)
        bool onHull = !sky && length(surf.xz - axis) < P4.z + 1.5 && surf.y > P4.y - 2.0;
        if (tAx < sceneT + 8.0 && !onHull) {
            vec3 at = rd * tAx;
            float off = max(d - P4.z - 0.5, 0.0);
            float breathe = 0.7 + 0.3 * sin(gTime * 2.2 - (at.y - Target.y) * 0.02);
            float aura = exp(-off / 3.0) * 0.18 + exp(-off / 16.0) * 0.05;
            glow += EMBER * aura * breathe * P3.x;
        }
    }

    // ---- afterwards: the column of burnt air it came down through, standing in the sky, twisting, fading
    if (P3.y > 0.001) {
        float tRay;
        vec3 a = vec3(Target.x, P4.x, Target.z);
        vec3 b = a + vec3(0.0, 4200.0, 0.0);
        float d = raySegmentDist(vec3(0.0), rd, a, b, tRay);
        if (tRay < sceneT) {
            vec3 at = rd * tRay;
            float up = at.y - a.y;
            float drift = (vnoise2(vec2(up * 0.004, gTime * 0.05 + 3.0)) - 0.5) * (20.0 + up * 0.03) * (1.0 - P3.y);
            float dd = max(d - abs(drift) * 0.5, 0.0);
            float w = max(1.2 + (1.0 - P3.y) * 8.0 + up * 0.002, tRay * gPix * 0.8);
            float core = exp(-dd / w);
            float halo = exp(-dd / (w * 6.0)) * 0.3;
            vec3 c = mix(vec3(1.0, 0.55, 0.6), vec3(0.6, 0.35, 0.9), saturate(1.0 - P3.y + up / 6000.0));
            glow += c * (core * 0.7 + halo * 0.5) * P3.y * P3.y * 0.6;
        }
    }

    fragColor = vec4(tonemap(base + glow), 1.0);
}
