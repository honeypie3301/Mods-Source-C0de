// Final pass: bloom, screen shake, chromatic aberration (after Orbital Railgun's chromatic_abjuration),
// radial zoom blur, desaturation and contrast grading, coloured vignette, flash with a burned-in afterimage,
// and anime impact frames.
uniform float Shake;
uniform float Aberration;
uniform float Desaturate;
uniform float ZoomBlur;
uniform float Bloom;
uniform vec4 Flash;
uniform vec4 Vignette;
uniform vec4 Impact; // strength, mode (0 ink / 1 inverted / 2 crimson / 3-5 ink with a cyan, blue or magenta accent / 6 colour negative / 7-8 white and red only / 9-10 white and gold only / 11-12 white and yellow only / 13-14 navy and yellow / 15-16 black and ember / 17 ember line-art / 18 slashed across / 19 ember halftone / 20 glitched / 21-26 the same in violet / 27-32 the same in the spectrum / 33 prism line-art / 34 spectral bands / 35 isometric wireframe), centre uv
uniform sampler2D SceneSampler;
uniform sampler2D SceneLowSampler;
uniform float Upscaled;
uniform sampler2D ExposureSampler;
uniform float AutoExposure;
uniform sampler2D HoldSampler;
uniform vec4 Grade; // contrast, film grain, afterimage of the held frame, highlights kept in colour

/** Eye adaptation: the more light the magic pours into the frame, the further the "camera" stops down. */
float exposure() {
    if (AutoExposure < 0.5) {
        return 1.0;
    }
    float added = 0.0;
    for (int i = 0; i < 16; i++) {
        vec2 p = (vec2(float(i - (i / 4) * 4), float(i / 4)) + 0.5) / 4.0;
        added += lum(texture(ExposureSampler, p).rgb);
    }
    added /= 16.0;
    return 1.0 / (1.0 + max(added - 0.05, 0.0) * 3.0);
}

/**
 * Spell passes may run below native resolution. Their result is re-sharpened by adding back the detail the
 * low-resolution copy of the scene lost, so the untouched world stays crisp.
 */
vec3 px(vec2 uv) {
    uv = clamp(uv, 0.001, 0.999);
    vec3 fx = texture(DiffuseSampler, uv).rgb;
    if (Upscaled > 0.001) {
        // multiplicative detail transfer: survives darkening and tinting without bright halos
        vec3 full = texture(SceneSampler, uv).rgb;
        vec3 low = texture(SceneLowSampler, uv).rgb;
        fx *= mix(vec3(1.0), clamp((full + 0.03) / (low + 0.03), 0.5, 2.0), Upscaled);
    }
    return fx;
}

vec3 fetch(vec2 uv, vec2 dir, float ca) {
    if (ca < 1e-5) {
        return px(uv);
    }
    return vec3(px(uv + dir * ca).r, px(uv).g, px(uv - dir * ca).b);
}

vec3 bloomAt(vec2 uv) {
    return texture(AuxSampler, clamp(uv, 0.001, 0.999)).rgb;
}

void main() {
    vec2 uv = texCoord;
    float t = GTime;
    vec2 jitter = vec2(vnoise2(vec2(t * 31.0, 1.7)), vnoise2(vec2(5.3, t * 29.0))) - 0.5;
    uv += jitter * Shake * 0.03;

    vec2 c = uv - 0.5;
    float aspect = OutSize.x / OutSize.y;
    float ca = Aberration * 0.018 * dot(c * vec2(aspect, 1.0), c * vec2(aspect, 1.0)) * 2.0;
    vec3 col = fetch(uv, c, ca);
    vec3 bloom = bloomAt(uv);

    if (ZoomBlur > 0.001) {
        vec3 acc = col;
        vec3 bacc = bloom;
        float total = 1.0;
        for (int i = 1; i < 10; i++) {
            float k = float(i) / 10.0;
            vec2 suv = 0.5 + c * (1.0 - ZoomBlur * 0.12 * k);
            float w = 1.0 - k * 0.6;
            acc += fetch(suv, c, ca) * w;
            bacc += bloomAt(suv) * w;
            total += w;
        }
        col = acc / total;
        bloom = bacc / total;
    }

    float ev = exposure();
    col *= ev;
    bloom *= ev;

    // bloom: soft screen blend so it glows without clipping everything to white
    vec3 b = bloom * Bloom;
    col = col + b - col * b * 0.35;

    float grey = lum(col);
    vec3 colour = col;
    col = mix(col, vec3(grey) * vec3(0.92, 1.0, 0.97), saturate(Desaturate));
    col = mix(col, colour * 1.15, Grade.w * smoothstep(0.62, 0.95, grey));
    if (Grade.x > 0.001) {
        // stark, crushed monochrome: the world drained to ink and paper
        col = clamp((col - 0.42) * (1.0 + Grade.x) + 0.42, 0.0, 1.6);
    }

    float edge = smoothstep(0.25, 0.95, length(c * vec2(aspect * 0.8, 1.0)) * 1.3);
    col = mix(col, Vignette.rgb * (0.35 + 0.65 * grey), saturate(Vignette.a * edge));

    if (Grade.z > 0.001) {
        // flash-blindness: the last thing seen stays burned in, soft and bleached, fading slowly
        vec3 held = vec3(0.0);
        for (int i = 0; i < 5; i++) {
            vec2 o = i == 0 ? vec2(0.0) : vec2(cos(float(i) * 1.571), sin(float(i) * 1.571)) * 0.006;
            held += texture(HoldSampler, clamp(texCoord + o, 0.001, 0.999)).rgb;
        }
        float ghost = smoothstep(0.08, 0.9, lum(held / 5.0)) * saturate(Grade.z);
        col = 1.0 - (1.0 - col) * (1.0 - ghost * vec3(1.0, 0.96, 0.88));
    }

    col += Flash.rgb * Flash.a;
    col = mix(col, vec3(1.0), saturate(Flash.a - 1.0));

    if (Grade.y > 0.001) {
        col += (hash12(texCoord * OutSize + fract(t * 7.3) * 431.0) - 0.5) * Grade.y * 0.2;
    }

    // impact frame: stark two-tone ink with inked edges (no focus lines: the frames hold still)
    if (Impact.x > 0.001) {
        // 21-26 are 15-20 in violet (SS-04) instead of ember (SS-03); 27-32 the same in the spectrum (SS-05), a swirl of
        // all seven colours turning out of the hit; 33-35 SS-05's own
        float mode = Impact.y;
        vec3 accent = vec3(1.0, 0.33, 0.06);
        bool spectral = false;
        if (mode > 26.5 && mode < 32.5) {
            mode -= 12.0;
            spectral = true;
        } else if (mode > 20.5 && mode < 26.5) {
            mode -= 6.0;
            accent = vec3(0.64, 0.46, 1.0);
        }
        vec2 step1 = 1.5 / OutSize;
        float gx = lum(texture(DiffuseSampler, uv + vec2(step1.x, 0.0)).rgb) - lum(texture(DiffuseSampler, uv - vec2(step1.x, 0.0)).rgb);
        float gy = lum(texture(DiffuseSampler, uv + vec2(0.0, step1.y)).rgb) - lum(texture(DiffuseSampler, uv - vec2(0.0, step1.y)).rgb);
        float ink = smoothstep(0.06, 0.18, length(vec2(gx, gy)));
        float l = lum(px(uv));
        // local adaptive threshold: compare with the surrounding brightness so shapes survive even
        // when a flash has pushed the whole frame toward white
        float avg = 0.0;
        for (int i = 0; i < 8; i++) {
            float a = float(i) * 0.785398;
            avg += lum(px(uv + vec2(cos(a) / aspect, sin(a)) * 0.045));
        }
        avg /= 8.0;
        float two = step(avg + 0.004, l);
        vec2 d = (texCoord - Impact.zw) * vec2(aspect, 1.0);
        float ang = atan(d.y, d.x);
        if (spectral) {
            accent = prism7(ang / TAU + length(d) * 0.9 - t * 0.7);
        }
        vec3 frame;
        // manga screentone: a rotated dot grid whose dots grow with the darkness of the midtones
        vec2 tp = mat2(0.7071, -0.7071, 0.7071, 0.7071) * (texCoord * OutSize) / 5.0;
        float tone = saturate((l - avg) * 5.0 + 0.5);
        float dots = step(length(fract(tp) - 0.5), sqrt(saturate(1.0 - tone)) * 0.62);
        float mid = smoothstep(0.15, 0.35, tone) * (1.0 - smoothstep(0.65, 0.85, tone));
        float core = step(avg + 0.18, l);
        if (mode > 32.5) {
            vec3 black = vec3(0.01, 0.008, 0.02);
            if (mode < 33.5) {
                // 33: prism line-art — the world's edges on black, split into the seven colours outward from the hit
                vec2 out1 = normalize(d + 1e-5) / vec2(aspect, 1.0);
                vec3 acc = vec3(0.0);
                for (int k = 0; k < 7; k++) {
                    vec2 o = uv + out1 * float(k - 3) * (0.0035 + 0.004 * length(d));
                    float ex = lum(texture(DiffuseSampler, o + vec2(step1.x, 0.0)).rgb) - lum(texture(DiffuseSampler, o - vec2(step1.x, 0.0)).rgb);
                    float ey = lum(texture(DiffuseSampler, o + vec2(0.0, step1.y)).rgb) - lum(texture(DiffuseSampler, o - vec2(0.0, step1.y)).rgb);
                    acc += prism7(float(k) / 7.0) * smoothstep(0.05, 0.16, length(vec2(ex, ey)));
                }
                frame = black + acc * 0.75;
                frame = mix(frame, vec3(1.0), core * 0.9);
            } else if (mode < 34.5) {
                // 34: the spectrum by light — the world posterized into seven bands, violet in the dark up to red in
                // the light, white where it burns, inked black
                float band = floor(saturate((l - avg) * 2.4 + 0.5) * 6.999);
                // and rings of it out from the hit, so even a flat sky breaks into the seven
                int ring = int(floor(length(d) * 9.0 - t * 6.0));
                frame = prismStop(int(mod(float(6 - int(band) + ring), 7.0)));
                frame = mix(frame, vec3(1.0), core);
                frame = mix(frame, black, ink * 0.9);
            } else {
                // 35: isometric wireframe — only the edges, graded through the spectrum across the frame, on black, over
                // a thirty-degree grid of the same colours; white where it burns
                vec2 sp = texCoord * OutSize / 46.0;
                float gridD = 1.0;
                gridD = min(gridD, abs(fract(dot(sp, vec2(-0.5, 0.866))) - 0.5));
                gridD = min(gridD, abs(fract(dot(sp, vec2(0.5, 0.866))) - 0.5));
                gridD = min(gridD, abs(fract(sp.x * 1.1547) - 0.5));
                float gl = smoothstep(0.035, 0.0, gridD);
                vec3 hue = prism7(dot(texCoord, vec2(0.6, 0.4)) + t * 0.5);
                frame = black + hue * gl * 0.28;
                frame = mix(frame, hue * 1.1, ink);
                frame = mix(frame, vec3(1.0), core * 0.85);
            }
        } else if (mode < 0.5) {
            frame = vec3(1.0 - two) * (1.0 - ink);
            frame = mix(frame, vec3(1.0 - dots), mid * 0.8);
        } else if (mode < 1.5) {
            frame = vec3(two) * (1.0 - ink);
            frame = mix(frame, vec3(dots), mid * 0.8);
        } else if (mode < 2.5) {
            frame = mix(vec3(0.05, 0.0, 0.0), vec3(1.0, 0.1, 0.12), two) * (1.0 - ink);
            frame = mix(frame, vec3(1.0, 0.1, 0.12) * dots, mid * 0.7);
        } else if (mode < 5.5) {
            // ink and one accent: 3 Six-Eyes cyan, 4 shadow blue, 5 cursed magenta; white where it burns hottest
            vec3 accent = mode < 3.5 ? vec3(0.35, 0.9, 1.0) : mode < 4.5 ? vec3(0.22, 0.42, 1.0)
                                                                    : vec3(1.0, 0.22, 0.9);
            frame = mix(vec3(0.0), accent, two);
            frame = mix(frame, vec3(1.0), core);
            frame = mix(frame, accent * dots, mid * 0.75);
            frame *= 1.0 - ink;
        } else if (mode < 6.5) {
            // the colour negative: every hue flipped, pushed hard
            vec3 neg = 1.0 - px(uv);
            float g = lum(neg);
            frame = clamp((mix(vec3(g), neg, 1.8) - 0.5) * 1.6 + 0.5, 0.0, 1.0) * (1.0 - ink * 0.7);
        } else if (mode > 16.5) {
            vec3 black = vec3(0.012, 0.006, 0.006);
            vec3 ember = accent;
            vec3 white = spectral ? vec3(1.0) : accent.b > 0.5 ? vec3(0.95, 0.94, 1.0) : vec3(1.0, 0.93, 0.82);
            if (mode > 19.5) {
                // 20: glitched — the frame torn into bands slid sideways and blocks knocked out of place, its channels
                // pulled apart, crushed to black, ember and white, scanlined, a few blocks of raw data burning through
                float beat = floor(t * 20.0);
                float band = floor(texCoord.y * OutSize.y / 18.0);
                float slide = (hash11(band * 13.1 + beat) - 0.5) * 0.16 * step(0.5, hash11(band * 7.7 + beat * 3.0));
                vec2 blk = floor(texCoord * OutSize / vec2(64.0, 36.0));
                vec2 knock = (vec2(hash12(blk + beat), hash12(blk * 1.7 + beat)) - 0.5) * 0.08 * step(0.86, hash12(blk * 3.1 + beat));
                vec2 g = texCoord + vec2(slide, 0.0) + knock;
                float split = 0.006 + 0.01 * hash11(beat);
                vec3 gc = vec3(px(g + vec2(split, 0.0)).r, px(g).g, px(g - vec2(split, 0.0)).b);
                float lv = lum(gc);
                frame = lv < 0.25 ? black : lv < 0.6 ? ember : white;
                frame.r += max(gc.r - lv, 0.0) * 1.2;
                frame.gb += max(gc.b - lv, 0.0) * vec2(0.9, 1.4);
                frame *= 0.72 + 0.28 * step(0.5, fract(texCoord.y * OutSize.y / 3.0));
                float data = step(0.975, hash12(floor(texCoord * OutSize / vec2(24.0, 8.0)) + beat * 7.0));
                frame = mix(frame, hash11(beat + blk.x) > 0.5 ? white : vec3(0.3, 0.9, 1.0), data * 0.85);
            } else if (mode > 18.5) {
                // 19: the world in big ember halftone dots on black, white where it burns hottest
                vec2 hp = mat2(0.866, -0.5, 0.5, 0.866) * (texCoord * OutSize) / 12.0;
                float big = step(length(fract(hp) - 0.5), sqrt(saturate((l - avg) * 3.0 + 0.5)) * 0.64);
                frame = mix(black, ember, big);
                frame = mix(frame, white, core);
                frame = mix(frame, black, ink * 0.85);
            } else if (mode > 17.5) {
                // 18: slashed across through the hit — ember on black one side, black on ember the other, a jagged
                // white cut between them, at a new angle every frame
                float ang = hash11(floor(t * 20.0) + 3.0) * PI;
                vec2 nrm = vec2(cos(ang), sin(ang));
                float along = dot(d, vec2(-nrm.y, nrm.x));
                float side = dot(d, nrm) + (vnoise2(vec2(along * 38.0, floor(t * 20.0))) - 0.5) * 0.02;
                float a = step(0.0, side);
                float lit = mix(two, 1.0 - two, a);
                frame = mix(black, ember, lit);
                frame = mix(frame, a > 0.5 ? black : ember, ink * lit);
                frame = mix(frame, white, saturate(exp(-abs(side) / 0.0035) * 1.6));
            } else {
                // 17: the world drawn in ember line-art on black, white where it burns
                frame = mix(black, ember, ink);
                frame = mix(frame, white, core);
            }
        } else if (mode > 14.5) {
            // the world in black and ember (SS-03's silent strike): 15 lit shapes ember on black, white where it burns
            // hottest; 16 black shapes on ember; the inked edges in the two
            vec3 black = vec3(0.012, 0.006, 0.006);
            vec3 ember = accent;
            float lit = mode < 15.5 ? two : 1.0 - two;
            frame = mix(black, ember, lit);
            frame = mix(frame, vec3(1.0, 0.93, 0.82), core * (mode < 15.5 ? 1.0 : 0.0));
            frame = mix(frame, mix(black, ember, dots), mid * 0.7);
            frame = mix(frame, black, ink * lit);
        } else if (mode > 12.5) {
            // the world in deep navy and hot yellow (the Serious Punch, the fist in the plasma): 13 lit shapes yellow on
            // navy, white where it burns hottest; 14 navy shapes on yellow; the inked edges in the two
            vec3 navy = vec3(0.035, 0.045, 0.16);
            vec3 yellow = vec3(1.0, 0.8, 0.12);
            float lit = mode < 13.5 ? two : 1.0 - two;
            frame = mix(navy, yellow, lit);
            frame = mix(frame, vec3(1.0, 0.98, 0.9), core * (mode < 13.5 ? 1.0 : 0.0));
            frame = mix(frame, mix(navy, yellow, dots), mid * 0.7);
            frame = mix(frame, navy * 0.5, ink * lit);
        } else if (mode > 10.5) {
            // the world in white and blazing yellow (the Field Radio's detonations): 11 lit shapes white on yellow,
            // 12 yellow shapes on white, the inked edges burnt orange
            vec3 yellow = vec3(1.0, 0.84, 0.1);
            vec3 white = vec3(1.0, 0.99, 0.95);
            float lit = mode < 11.5 ? two : 1.0 - two;
            frame = mix(yellow, white, lit);
            frame = mix(frame, mix(white, yellow, dots), mid * 0.7);
            frame = mix(frame, vec3(0.62, 0.26, 0.0), ink * lit);
        } else if (mode > 8.5) {
            // the world in white and burning gold (SS-02's cut): 9 lit shapes white on gold, 10 gold shapes on white
            vec3 gold = vec3(0.98, 0.58, 0.08);
            vec3 white = vec3(1.0, 0.98, 0.94);
            float lit = mode < 9.5 ? two : 1.0 - two;
            frame = mix(gold, white, lit);
            frame = mix(frame, mix(white, gold, dots), mid * 0.7);
            frame = mix(frame, vec3(0.35, 0.12, 0.0), ink * lit);
        } else {
            // the world in white and red and nothing else: 7 lit shapes white on red, 8 red shapes on white; the
            // inked edges and the screentone in the same two
            vec3 red = vec3(0.93, 0.03, 0.07);
            vec3 white = vec3(1.0, 0.97, 0.97);
            float lit = mode < 7.5 ? two : 1.0 - two;
            frame = mix(red, white, lit);
            frame = mix(frame, mix(white, red, dots), mid * 0.7);
            frame = mix(frame, red, ink * lit);
        }
        col = mix(col, frame, saturate(Impact.x));
    }
    fragColor = vec4(col, 1.0);
}
