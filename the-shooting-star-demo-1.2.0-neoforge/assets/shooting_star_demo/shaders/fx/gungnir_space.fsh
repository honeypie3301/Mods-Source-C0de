// SS-03, Gungnir — the universe its film is shot in. Nothing here is in the world: a camera at the origin looks along
// CamFwd/Up/Right at bodies drawn at nested scales, each given relative to the camera in its own frame's unit
// (GungnirPath, StarPath): the Earth frame in Earth radii (the Earth, the Moon, the ember mark on the target, the needle's
// entry burning down through the air onto it), the Solar frame in AU (the Sun, the planets), and the Jupiter frame in
// Jupiter radii — Jupiter close up: its bands (smeared under a camera riding round it), finer turbulence where the map
// runs out, its haze, the thin black ring's shadow across its clouds and the ring's own glow lighting the cloud tops under
// it as it wakes and heats lap by lap, lightning in the storms on the night side stirred by its field, the auroras at its
// poles flaring with the power it draws, and the cloud tops rippling out from under the breech at the release.
// The sky round it all: the Milky Way and the stars — seen from the needle's flight, crowded forward into a starbow,
// blue ahead and red behind (relativistic aberration and Doppler shift).
//
// G0 = (tan half vertical fov, seconds, seed, cover), G1 = (Earth shown, Solar System shown, Jupiter close, cloud
// dissolve 0..1), G2 = (Moon radius ER, Sun radius AU, stars streaming, the flight's speed as a fraction of c), G3 =
// (seconds since the release or < 0, the bands' smear in radians of longitude, lightning, auroras), G4 = (the ring's glow,
// the needle's plasma in the air over the target, the ring's radius RJ, the camera's frame), G5 = (the mark on the target
// seen from space, the ring's thickness RJ, the target lit from above as the needle comes, the needle's height ER).
// JupRel = Jupiter's centre from the camera (RJ); JupPole/JupX/JupZ its axes (its map's); SunJ toward the Sun from it;
// NeedleJ/BreechJ = the needle's and the breech's directions from its centre. Heading = the direction of flight.

#include "star.glsl"

uniform sampler2D EarthDay;
uniform sampler2D EarthAux; // r city lights, g clouds, b land elevation
uniform sampler2D MoonColor;
uniform sampler2D MilkyWay;
uniform sampler2D Planets;
uniform sampler2D Rings;
uniform sampler2D Jupiter;
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
uniform vec3 JupRel;
uniform vec3 JupPole;
uniform vec3 JupX;
uniform vec3 JupZ;
uniform vec3 SunJ;
uniform vec3 NeedleJ;
uniform vec3 BreechJ;
uniform vec3 Heading;
uniform vec4 G0;
uniform vec4 G1;
uniform vec4 G2;
uniform vec4 G3;
uniform vec4 G4;
uniform vec4 G5;

#define CLOUD_CUT
#include "space.glsl"

const vec3 EMBER = vec3(1.0, 0.3, 0.06);
const vec3 EMBER_HOT = vec3(1.0, 0.62, 0.3);
const vec3 AURORA_A = vec3(0.25, 1.0, 0.85);
const vec3 AURORA_B = vec3(0.62, 0.36, 1.0);

vec3 texAxes(vec3 v) {
    return vec3(dot(v, EarthX), dot(v, EarthY), dot(v, EarthZ));
}

/** SS-03's light on the Earth's ground: the ember mark on the target, and the land lit white as the needle comes down. */
vec3 groundGlow(vec3 n) {
    vec3 site = texAxes(SiteN);
    float near = length(n - site);
    vec3 col = vec3(0.0);
    float mark = max(G5.x, G5.z);
    if (mark > 0.001) {
        // the ember mark: a hot dot, a ring round it 200 blocks out, a faint zone
        float ring = exp(-sqr((near - 0.000031) / 0.000006));
        col += EMBER * (exp(-near / 0.00012) * 5.0 + exp(-near / 0.004) * 0.3 + ring * 2.0) * mark;
    }
    if (G5.w > 0.0 && G4.y > 0.001) {
        // the needle's light on the land under it, a hot pool growing as it comes down
        float h = max(G5.w, 0.0004);
        col += vec3(1.0, 0.62, 0.42) * G4.y * exp(-near / (h * 0.5)) * 0.8 * smoothstep(0.02, 0.006, h);
    }
    return col;
}

/**
 * The needle's bow shock blows the cloud deck open over the target as it comes down: a round clearing opening under
 * it, the cloud it pushed out piled in a ring round its edge.
 */
float cloudCut(vec3 n) {
    if (G4.y < 0.001) return 1.0;
    vec3 site = texAxes(SiteN);
    float d = length(n - site);
    float r = mix(0.001, 0.02, G4.y);
    float hole = smoothstep(r * 0.7, r, d);
    float rim = exp(-sqr((d - r * 1.08) / (r * 0.12)));
    return hole + rim * 0.9;
}

/** SS-03's light in the air: none of its own here. */
vec3 airGlow(vec3 p) {
    return vec3(0.0);
}

// ---------------------------------------------------------------- the sky, as the flight sees it

/**
 * The direction a star's light comes from when it is seen along rd from a ship moving at beta toward h, and the Doppler
 * factor of that light: the sky crowds forward into a starbow, bright and blue ahead, dim and red behind.
 */
vec3 aberrate(vec3 rd, vec3 h, float beta, out float doppler) {
    float c = dot(rd, h);
    float cs = (c - beta) / (1.0 - beta * c);
    vec3 perp = rd - h * c;
    float pl = length(perp);
    doppler = sqrt(max(1.0 - beta * beta, 1e-4)) / max(1.0 - beta * c, 1e-3);
    if (pl < 1e-5) return rd;
    return h * cs + perp / pl * sqrt(max(1.0 - cs * cs, 0.0));
}

vec3 dopplerShift(vec3 col, float d) {
    float l = lum(col);
    float s = log2(max(d, 1e-3));
    vec3 blue = l * vec3(0.5, 0.72, 1.35);
    vec3 red = l * vec3(1.45, 0.5, 0.28);
    col = mix(col, blue, saturate(s * 0.55));
    col = mix(col, red, saturate(-s * 0.55));
    return col * clamp(d * d * d, 0.03, 9.0);
}

vec3 sky(vec3 rd) {
    float beta = G2.w;
    if (beta < 0.001) {
        return panorama(rd) + starField(rd, gPixel, 0.5);
    }
    float d;
    vec3 src = aberrate(rd, normalize(Heading), beta, d);
    vec3 col = panorama(src) * 0.9 + starField(src, gPixel * mix(1.0, 0.6, beta), 0.55);
    return dopplerShift(col, d);
}

// ---------------------------------------------------------------- Jupiter, close (its radii, centred on it)

vec3 jupLocal(vec3 v) {
    return vec3(dot(v, JupX), dot(v, JupPole), dot(v, JupZ));
}

/** Where its surface point n (unit) sits against the ring: distance to the ring's circle. */
float ringDistance(vec3 p) {
    float y = dot(p, JupPole);
    float r = length(p - JupPole * y);
    return length(vec2(r - G4.z, y));
}

vec3 jupiterBody(vec3 n, vec3 rd, float t) {
    vec3 ln = jupLocal(n);
    vec2 uv = sphereUV(ln);
    float mu = max(dot(n, -rd), 0.0);
    float arc = gPixel * t / max(mu, 0.1);
    float lod = lodFor(arc, 2048.0);
    // the bands, smeared along their longitude under a camera running round the planet
    float smear = G3.y;
    vec3 tex = vec3(0.0);
    const int TAPS = 9;
    if (smear > 0.002) {
        for (int i = 0; i < TAPS; i++) {
            float o = (float(i) / float(TAPS - 1) - 0.5) * smear / TAU;
            tex += toLinear(textureLod(Jupiter, uv + vec2(o, 0.0), lod + 1.0).rgb);
        }
        tex /= float(TAPS);
    } else {
        tex = toLinear(textureLod(Jupiter, uv, lod).rgb);
    }
    // close up the map runs out of pixels: the clouds themselves take over — turbulent flow sheared along the bands,
    // cream tops, ochre, blue-grey festoons in the gaps — and they stand in relief, lit low across by the Sun
    float detail = saturate(-lod * 0.4 + 0.25);
    float relief = 0.0;
    vec3 east = normalize(cross(JupPole, n) + vec3(1e-6));
    vec3 north = cross(n, east);
    if (detail > 0.0) {
        float lat = asin(clamp(ln.y, -1.0, 1.0));
        float lon = atan(ln.z, ln.x);
        vec2 q = vec2(lon * cos(lat), lat) * 46.0 + vec2(gTime * 0.02, 0.0);
        vec2 w = vec2(fbm2(q * 1.2 + gSeed * 3.0), fbm2(q * 1.2 + vec2(5.2, 1.3)));
        float shear = sin(q.y * 1.6 + w.y * 2.0) * 3.5;
        vec2 r = q * vec2(0.55, 2.4) + vec2(shear, 0.0) + (w - 0.5) * 3.2;
        float c1 = fbm2(r);
        float c2 = fbm2(r * 3.1 + w * 2.0 + 7.7);
        float cloud = c1 * 0.62 + c2 * 0.38;
        float l = lum(tex);
        vec3 cream = tex * 1.12 + vec3(0.03, 0.025, 0.015);
        vec3 ochre = l * vec3(0.95, 0.66, 0.42);
        vec3 festoon = l * vec3(0.3, 0.33, 0.42);
        vec3 dc = mix(festoon, ochre, smoothstep(0.28, 0.46, cloud));
        dc = mix(dc, cream, smoothstep(0.5, 0.7, cloud));
        tex = mix(tex, dc, detail * 0.85);
        // the cloud tops' slope toward the Sun, strongest where it is low
        float e = 0.06;
        vec2 grad = vec2(fbm2(r + vec2(e, 0.0)) - c1, fbm2(r + vec2(0.0, e)) - c1) / e;
        vec2 sunT = vec2(dot(SunJ, east), dot(SunJ, north));
        relief = dot(grad * vec2(0.55, 2.4), sunT) * detail;
    }
    float ndl = dot(n, SunJ);
    float day = max(ndl, 0.0);
    // limb darkening, and the soft terminator of a thick atmosphere
    // (its map is pale: pushed a little darker and richer, so its bands read in the frame instead of washing out)
    tex = pow(tex, vec3(1.18)) * vec3(1.02, 0.97, 0.9);
    float low = 1.0 - smoothstep(0.1, 0.7, day);
    float bumped = max(day + relief * (0.08 + 0.3 * low), 0.0);
    vec3 col = tex * SUNLIGHT * 0.7 * smoothstep(-0.06, 0.25, ndl) * (0.2 + 0.8 * bumped) * (0.45 + 0.55 * sqrt(mu));
    // the ring's shadow, a thin dark line thrown across the clouds
    float up = dot(SunJ, JupPole);
    if (abs(up) > 1e-3 && ndl > 0.0) {
        float tt = -dot(n, JupPole) / up;
        if (tt > 0.0) {
            vec3 q = n + SunJ * tt;
            float r = length(q);
            float shadow = exp(-sqr((r - G4.z) / (G5.y * 1.6 + gPixel * t * 0.8)));
            col *= 1.0 - 0.85 * shadow;
        }
    }
    // the ring's own light on the cloud tops under it: ember as it wakes, white-hot by the last laps
    if (G4.x > 0.001) {
        float d = ringDistance(n);
        float glow = 0.05 / (d * d + 0.004);
        col += blackbody(0.35 + 0.7 * G4.x) * glow * G4.x * G4.x * 0.25 * (0.5 + 0.5 * tex / max(lum(tex), 1e-3));
    }
    // lightning on the night side: storms flashing, most under the ring along the equator
    float night = 1.0 - smoothstep(-0.12, 0.05, ndl);
    if (G3.z > 0.001 && night > 0.01) {
        vec2 cell = floor(vec2(uv.x * 180.0, uv.y * 90.0));
        float storm = step(0.86, hash12(cell + gSeed * 17.0));
        float beat = floor(gTime * 9.0 + hash12(cell) * 40.0);
        float flash = step(0.9, hash12(cell + beat * 3.7)) * storm;
        vec2 f = fract(vec2(uv.x * 180.0, uv.y * 90.0)) - 0.5;
        float blob = exp(-dot(f, f) * 9.0);
        float equator = exp(-sqr(ln.y / 0.28));
        col += vec3(0.75, 0.85, 1.0) * flash * blob * night * G3.z * (0.4 + 2.6 * equator) * 3.0;
        // the glow of the whole storm deck under the flashes
        col += vec3(0.35, 0.42, 0.7) * night * G3.z * equator * 0.02 * (0.5 + 0.5 * sin(gTime * 23.0 + uv.x * 300.0));
    }
    // the auroras: ovals round both poles, curtains shimmering, flaring with the draw of the ring
    if (G3.w > 0.001) {
        float colat = acos(clamp(abs(ln.y), 0.0, 1.0));
        float lon = atan(ln.z, ln.x);
        float oval = exp(-sqr((colat - 0.25 - 0.03 * sin(lon * 3.0 + gTime * 0.7)) / 0.035));
        float curtain = 0.55 + 0.45 * fbm2(vec2(lon * 9.0, gTime * 1.3));
        vec3 aur = mix(AURORA_A, AURORA_B, 0.5 + 0.5 * sin(lon * 2.0 + gTime * 0.4));
        col += aur * oval * curtain * G3.w * 1.6;
    }
    // the release: the cloud tops rippling out from under the breech, a flash of it first
    if (G3.x >= 0.0) {
        float a = acos(clamp(dot(n, BreechJ), -1.0, 1.0));
        float s = G3.x;
        float front = s * 1.4;
        float ring = exp(-sqr((a - front) / (0.02 + 0.05 * s))) * exp(-s * 0.7);
        float second = exp(-sqr((a - front * 0.6) / (0.015 + 0.03 * s))) * exp(-s * 1.1) * 0.6;
        col *= 1.0 + (ring + second) * 2.2;
        col += EMBER_HOT * exp(-a / 0.03) * exp(-s * 7.0) * 4.0 + vec3(1.0, 0.9, 0.8) * (ring + second) * 0.2;
    }
    return col;
}

/** Its thin haze at the limb, lit toward the Sun, and the auroras standing up off it at the poles. */
vec3 jupiterHaze(vec3 rd, vec3 c, float tSolid) {
    float tc = dot(c, rd);
    if (tc <= 0.0) return vec3(0.0);
    vec3 closest = rd * tc - c;
    float b = length(closest);
    if (b < 1.0 || b > 1.08) return vec3(0.0);
    vec3 n = closest / b;
    float lit = smoothstep(-0.25, 0.3, dot(n, SunJ));
    float haze = exp(-(b - 1.0) / 0.006);
    vec3 col = vec3(0.95, 0.78, 0.58) * haze * lit * 0.9;
    // backlit, the whole limb glows
    col += vec3(1.0, 0.7, 0.45) * haze * sqr(sqr(max(dot(rd, SunJ), 0.0))) * 3.0;
    if (G3.w > 0.001) {
        vec3 ln = jupLocal(n);
        float colat = acos(clamp(abs(ln.y), 0.0, 1.0));
        float lon = atan(ln.z, ln.x);
        float oval = exp(-sqr((colat - 0.25) / 0.06));
        float curtain = fbm2(vec2(lon * 12.0, (b - 1.0) * 200.0 - gTime * 2.0));
        col += mix(AURORA_A, AURORA_B, (b - 1.0) / 0.08) * oval * exp(-(b - 1.0) / 0.025) * curtain * G3.w * 2.4;
    }
    return col;
}

void main() {
    gTime = G0.y;
    gSeed = G0.z;
    float tanFov = G0.x;
    gPixel = 2.0 * tanFov / OutSize.y;
    gPix = gPixel;
    vec2 ndc = texCoord * 2.0 - 1.0;
    vec2 screen = vec2(ndc.x * OutSize.x / OutSize.y, ndc.y);
    vec3 rd = normalize(CamFwd + (CamRight * screen.x + CamUp * screen.y) * tanFov);

    // ---- the sky
    vec3 col = sky(rd);
    if (G2.z > 0.001) {
        // (only round the heading: far off it the streaming cells blow up into blocks)
        float ahead = smoothstep(0.3, 0.65, dot(rd, normalize(Heading)));
        col += warpField(rd, normalize(Heading), gTime * mix(5.0, 12.0, G2.w), mix(1.6, 3.0, G2.w), gPixel,
                         vec3(0.62, 0.78, 1.0), vec3(1.0, 0.8, 0.6)) * G2.z * ahead;
    }

    // ---- the Solar System (AU)
    float tSolid = NEVER;
    vec3 solid = vec3(0.0);
    bool close = G1.z > 0.5;
    vec2 hs = resolvable(SunRelS, G2.y) ? raySphere(vec3(0.0), rd, SunRelS, G2.y) : vec2(-1.0);
    if (hs.x > 0.0) {
        tSolid = hs.x;
        solid = sunBody(rd * hs.x, SunRelS, G2.y, rd, hs.x);
    }
    for (int i = 0; i < 8; i++) {
        if (i == 2) continue;
        if (i == 4 && close) continue;
        vec3 c = Planet[i].xyz;
        float R = Planet[i].w;
        vec2 h = resolvable(c, R) ? raySphere(vec3(0.0), rd, c, R) : vec2(-1.0);
        if (h.x > 0.0 && h.x < tSolid) {
            tSolid = h.x;
            solid = planetBody(i, rd * h.x, c, R, rd, h.x);
        } else if (h.x <= 0.0) {
            float d = length(rd - normalize(c));
            float lit = 0.5 + 0.5 * dot(normalize(c - SunRelS), normalize(-c));
            col += vec3(1.0, 0.95, 0.85) * pointGlow(d, gPixel, 1.1) * (0.5 + lit) * 0.9;
        }
    }
    if (tSolid < NEVER) {
        col = solid;
    }
    vec4 ring = resolvable(Planet[5].xyz, Planet[5].w * 2.3) ? saturnRings(rd, Planet[5].xyz, Planet[5].w, tSolid) : vec4(0.0);
    if (ring.a > 0.0) {
        float front = rayPlane(vec3(0.0), rd, Planet[5].xyz, SaturnPole);
        col = mix(col, ring.rgb, ring.a * (front < tSolid ? 1.0 : 0.0));
    }
    // the Sun's glare, unless Jupiter stands in front of it
    float sunSeen = 1.0;
    if (close) {
        vec3 sd = normalize(SunRelS);
        vec2 hj = raySphere(vec3(0.0), sd, JupRel, 1.0);
        if (hj.y > 0.0) {
            float tc = dot(JupRel, sd);
            float b = length(sd * tc - JupRel);
            sunSeen = smoothstep(0.985, 1.02, b);
        }
    }
    col += sunGlare(rd, SunRelS, G2.y) * sunSeen;

    // ---- Jupiter close up (its radii)
    if (close) {
        vec2 hj = raySphere(vec3(0.0), rd, JupRel, 1.0);
        float tJup = hj.x > 0.0 ? hj.x : NEVER;
        if (hj.x > 0.0) {
            vec3 n = normalize(rd * hj.x - JupRel);
            col = jupiterBody(n, rd, hj.x);
        } else if (!resolvable(JupRel, 1.0)) {
            float d = length(rd - normalize(JupRel));
            col += vec3(1.0, 0.9, 0.75) * pointGlow(d, gPixel, 1.3) * 1.4;
        }
        col += jupiterHaze(rd, JupRel, tJup);
    }

    // ---- the Earth and the Moon (Earth radii)
    if (G1.x > 0.001) {
        vec3 ro = -EarthRel;
        vec2 he = raySphere(ro, rd, vec3(0.0), 1.0);
        // (a body far below a float's precision at its distance false-hits the ray test: only if resolvable)
        vec2 hm = resolvable(MoonRel, G2.x) ? raySphere(vec3(0.0), rd, MoonRel, G2.x) : vec2(-1.0);
        float tEarth = he.x > 0.0 ? he.x : NEVER;
        float tMoon = hm.x > 0.0 ? hm.x : NEVER;
        bool earthSeen = resolvable(EarthRel, 1.0);
        vec3 near = col;
        if (tMoon < tEarth) {
            near = moonBody(rd * tMoon, MoonRel, G2.x, rd, tMoon);
        } else if (he.x > 0.0 && earthSeen) {
            near = earthSurface(ro + rd * tEarth, rd, tEarth);
        }
        if (earthSeen) {
            vec3 through;
            vec3 air = atmosphere(ro, rd, min(tEarth, tMoon), through);
            // down inside the air, looking down through it: it clears, the land under it shows
            float inside = 1.0 - smoothstep(0.004, 0.035, length(ro) - 1.0);
            air *= 1.0 - 0.7 * inside;
            through = mix(through, vec3(1.0), 0.6 * inside);
            near = near * through + air;
        } else {
            float d = length(rd - normalize(EarthRel));
            near += vec3(0.55, 0.75, 1.0) * pointGlow(d, gPixel, 1.2) * 1.6;
        }
        col = mix(col, near, G1.x);
    }

    // filmic roll-off, then back to display space
    col = 1.0 - exp(-col * 1.1);
    col = pow(col, vec3(1.0 / 2.2));

    // up out of the world: cloud streaming past the camera as the planet opens up below
    float dis = G1.w;
    float cover0 = G0.w;
    float fog = sin(saturate(dis) * PI) * (1.0 - step(0.999, dis)) * step(G4.w, 0.5);
    float mask = 1.0;
    vec3 outCol = col;
    if (cover0 < 0.999 || fog > 0.001) {
        vec3 world = texture(DiffuseSampler, texCoord).rgb;
        float r = length(screen);
        float ang = atan(screen.y, screen.x);
        float wisps = fbm2(vec2(ang * 2.5, log(r + 0.03) * 2.2 - dis * 7.0) + gSeed);
        mask = smoothstep(wisps - 0.12, wisps + 0.12, cover0 * 1.35 - 0.2);
        outCol = mix(world, col, mask);
        float cloud = smoothstep(0.35, 0.8, fbm2(screen * 2.2 + vec2(0.0, -dis * 5.0) + wisps));
        outCol = mix(outCol, vec3(0.92, 0.94, 1.0), fog * (0.35 + 0.65 * cloud) * 0.95);
    }
    fragColor = vec4(outCol, 1.0 - mask);
}
