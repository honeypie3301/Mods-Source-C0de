#version 150

uniform sampler2D DiffuseSampler;
uniform float DashIntensity;
uniform float PunchIntensity;
uniform float ShakeIntensity;
uniform float GrabIntensity;
uniform float LockIntensity;
uniform float Time;

uniform float ChopIntensity;
uniform float ChopType;
uniform float ChopIsLeft; // Hangi kolla vurduğunu anlar (1.0 = Sol, 0.0 = Sağ)

in vec2 texCoord;
out vec4 fragColor;

void main() {
    vec2 baseUv = texCoord;
    vec2 center = vec2(0.5, 0.5);

    float safeDash = clamp(DashIntensity, 0.0, 1.5);
    float safePunch = clamp(PunchIntensity, 0.0, 1.5);
    float safeShake = clamp(ShakeIntensity, 0.0, 1.5);
    float safeGrab = clamp(GrabIntensity, 0.0, 1.0);
    float safeLock = clamp(LockIntensity, 0.0, 1.0);
    float safeChop = clamp(ChopIntensity, 0.0, 1.0);

    if (safeDash <= 0.001 && safePunch <= 0.001 && safeShake <= 0.001 && safeGrab <= 0.001 && safeLock <= 0.001 && safeChop <= 0.001) {
        vec4 defaultColor = texture(DiffuseSampler, baseUv);
        defaultColor.a = 1.0;
        fragColor = defaultColor;
        return;
    }

    // ==========================================
    // 2. CAMERA SHAKE (Titreme + Chop Kırbacı)
    // ==========================================
    float shakeAmplitude = (0.015 * safeDash) + (0.032 * safeShake) + (0.005 * safeGrab);
    float shakeX = sin(Time * (80.0 + (safeShake * 40.0) + (safeGrab * 150.0))) * shakeAmplitude;
    float shakeY = cos(Time * (95.0 + (safeShake * 40.0) + (safeGrab * 150.0))) * shakeAmplitude;

    // CHOP KIRBACI (Hem kola hem type'a göre sağa/sola sarsıntı)
    if (safeChop > 0.0) {
        float baseDir = (ChopIsLeft > 0.5) ? -1.0 : 1.0;       // Sol kol: -1.0, Sağ kol: 1.0
        float typeMultiplier = (ChopType > 0.5) ? 1.0 : -1.0;  // Type 1 ise normal, Type 0 ise tersi
        float chopDir = baseDir * typeMultiplier;              // İkisini çarparak nihai yönü bul

        shakeX += sin(safeChop * 3.1415) * 0.025 * chopDir;
    }

    baseUv.x += shakeX;
    baseUv.y += shakeY;

    float dist = distance(baseUv, center);
    float effectRadius = smoothstep(0.1, 0.8, dist);
    float dashPower = safeDash * effectRadius;
    float punchPower = safePunch * effectRadius;

    vec4 finalColor;

    // ==========================================
    // CHOP (GİRDAP VE PARLAMA)
    // ==========================================
    if (safeChop > 0.0) {
        vec2 toCenter = baseUv - center;
        vec4 chopColor = vec4(0.0);

        // GİRDAP BULANIKLIĞI (ROTATIONAL SWIRL BLUR) - Artık her iki Type için de aktif!
        float baseSwirlDir = (ChopIsLeft > 0.5) ? -1.0 : 1.0;
        float typeSwirlMult = (ChopType > 0.5) ? 1.0 : -1.0;
        float swirlDir = baseSwirlDir * typeSwirlMult; // Yön mantığını buraya da uyguladık

        // 0.4 çarpanı swirl gücünü belirliyor
        float swirlStrength = safeChop * 0.25 * smoothstep(0.1, 0.9, dist) * swirlDir;

        for(int i = 0; i < 5; i++) {
            float angle = swirlStrength * (float(i) / 4.0);
            float s = sin(angle);
            float c = cos(angle);

            vec2 rotUv = vec2(toCenter.x * c - toCenter.y * s, toCenter.x * s + toCenter.y * c) + center;
            chopColor += texture(DiffuseSampler, rotUv);
        }
        chopColor /= 5.0;

        // Genel kesme parlaması (Hafif kromatik etki)
        chopColor.r += safeChop * 0.1 * effectRadius;
        chopColor.b -= safeChop * 0.035 * effectRadius;

        finalColor = chopColor;
    }
    // ==========================================
    // DİĞER YETENEKLER (PUNCH / DASH)
    // ==========================================
    else if ((dashPower + punchPower) > 0.0 && dist > 0.001) {
        vec2 dir = normalize(baseUv - center);

        float caOffset = (0.065 * dashPower) + (0.12 * punchPower);
        float r = texture(DiffuseSampler, baseUv + dir * caOffset).r;
        float g = texture(DiffuseSampler, baseUv).g;
        float b = texture(DiffuseSampler, baseUv - dir * caOffset).b;
        vec4 caColor = vec4(r, g, b, 1.0);

        if (safePunch > 0.0) {
            caColor.r += safePunch * 0.25 * effectRadius;
            caColor.g -= safePunch * 0.05 * effectRadius;
            caColor.b -= safePunch * 0.05 * effectRadius;
        }

        float blurStrength = (0.081 * dashPower) + (0.18 * punchPower);
        vec4 blurColor = vec4(0.0);
        blurColor += texture(DiffuseSampler, baseUv + dir * (blurStrength * 0.00));
        blurColor += texture(DiffuseSampler, baseUv + dir * (blurStrength * 0.25));
        blurColor += texture(DiffuseSampler, baseUv + dir * (blurStrength * 0.50));
        blurColor += texture(DiffuseSampler, baseUv + dir * (blurStrength * 0.75));
        blurColor += texture(DiffuseSampler, baseUv + dir * (blurStrength * 1.00));
        blurColor /= 5.0;

        finalColor = mix(caColor, blurColor, 0.6);
    } else {
        finalColor = texture(DiffuseSampler, baseUv);
    }

    // 4. TARGET LOCK VIGNETTE
    if (safeLock > 0.0) {
        float vignette = smoothstep(0.85, 0.35, dist);
        finalColor.rgb = mix(finalColor.rgb, finalColor.rgb * vignette, safeLock * 0.85);
    }

    finalColor.a = 1.0;
    fragColor = finalColor;
}