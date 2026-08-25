/*
====================================================================================================

    Copyright (C) 2022 RRe36

    All Rights Reserved unless otherwise explicitly stated.


    By downloading this you have agreed to the license and terms of use.
    These can be found inside the included license-file
    or here: https://rre36.com/copyright-license

    Violating these terms may be penalized with actions according to the Digital Millennium
    Copyright Act (DMCA), the Information Society Directive and/or similar laws
    depending on your country.

====================================================================================================
*/

/* RENDERTARGETS: 0,6 */
layout(location = 0) out vec3 sceneImage;
layout(location = 1) out vec4 temporal;

#include "/lib/head.glsl"
#include "/lib/util/colorspace.glsl"

#define INFO 0  //[0]

/* ------ color grading related settings ------ */
//#define doColorgrading

#define vibranceInt 1.00       //[0.00 0.05 0.10 0.15 0.20 0.25 0.30 0.35 0.40 0.45 0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.00 1.05 1.10 1.15 1.20 1.25 1.30 1.35 1.40 1.45 1.50 1.55 1.60 1.65 1.70 1.75 1.80 1.85 1.90 1.95 2.00]
#define saturationInt 1.00     //[0.00 0.05 0.10 0.15 0.20 0.25 0.30 0.35 0.40 0.45 0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.00 1.05 1.10 1.15 1.20 1.25 1.30 1.35 1.40 1.45 1.50 1.55 1.60 1.65 1.70 1.75 1.80 1.85 1.90 1.95 2.00]
#define gammaCurve 1.00        //[0.00 0.05 0.10 0.15 0.20 0.25 0.30 0.35 0.40 0.45 0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.00 1.05 1.10 1.15 1.20 1.25 1.30 1.35 1.40 1.45 1.50 1.55 1.60 1.65 1.70 1.75 1.80 1.85 1.90 1.95 2.00]
#define brightnessInt 0.00     //[-0.50 -0.45 -0.40 -0.35 -0.30 -0.25 -0.20 -0.15 -0.10 -0.05 0.00 0.05 0.10 0.15 0.20 0.25 0.30 0.35 0.40 0.45 0.5]
#define constrastInt 1.00      //[0.00 0.05 0.10 0.15 0.20 0.25 0.30 0.35 0.40 0.45 0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.00 1.05 1.10 1.15 1.20 1.25 1.30 1.35 1.40 1.45 1.50 1.55 1.60 1.65 1.70 1.75 1.80 1.85 1.90 1.95 2.00]

#define colorlumR 1.00         //[0.00 0.05 0.10 0.15 0.20 0.25 0.30 0.35 0.40 0.45 0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.00 1.05 1.10 1.15 1.20 1.25 1.30 1.35 1.40 1.45 1.50 1.55 1.60 1.65 1.70 1.75 1.80 1.85 1.90 1.95 2.00]
#define colorlumG 1.00         //[0.00 0.05 0.10 0.15 0.20 0.25 0.30 0.35 0.40 0.45 0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.00 1.05 1.10 1.15 1.20 1.25 1.30 1.35 1.40 1.45 1.50 1.55 1.60 1.65 1.70 1.75 1.80 1.85 1.90 1.95 2.00]
#define colorlumB 1.00         //[0.00 0.05 0.10 0.15 0.20 0.25 0.30 0.35 0.40 0.45 0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.00 1.05 1.10 1.15 1.20 1.25 1.30 1.35 1.40 1.45 1.50 1.55 1.60 1.65 1.70 1.75 1.80 1.85 1.90 1.95 2.00]

#define vignetteEnabled
#define vignetteStart 0.15     //[0.00 0.05 0.10 0.15 0.20 0.25 0.30 0.35 0.40 0.45 0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.00]
#define vignetteEnd 0.85       //[0.00 0.05 0.10 0.15 0.20 0.25 0.30 0.35 0.40 0.45 0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.00]
#define vignetteIntensity 0.80 //[0.00 0.05 0.10 0.15 0.20 0.25 0.30 0.35 0.40 0.45 0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85 0.90 0.95 1.00]
#define vignetteExponent 2.25  //[0.50 0.75 1.0 1.25 1.50 1.75 2.00 2.25 2.50 2.75 3.00 3.25 3.50 3.75 4.00 4.25 4.50 4.75 5.00]

in vec2 uv;

flat in float exposure;

uniform sampler2D colortex0;
uniform sampler2D colortex2;
uniform sampler2D colortex5;
uniform sampler2D colortex6;
uniform sampler2D colortex14;

uniform sampler2D depthtex0;

const bool colortex6Clear   = false;

uniform sampler2D noisetex;

uniform int frameCounter;
uniform int isEyeInWater, hideGUI;

uniform float frameTimeCounter, aspectRatio;
uniform float nightVision, rainStrength;

uniform vec2 bloomResolution;
uniform vec2 pixelSize;
uniform vec2 viewSize;

vec3 purkinje(vec3 hdr) {
    const vec3 reseponse = vec3(0.15, 0.50, 0.35);

    vec3 desatColor     = vec3(0.23, 0.65, 1.0);
        desatColor      = mix(desatColor, vec3(0.5, 0.9, 1.0), nightVision);

    float desat = dot(hdr, reseponse) * (1.0 + nightVision);
        hdr     = mix(hdr, vec3(desat)*desatColor, pow(1.0-linStep(desat, 0.0, 0.005 * (1.0 + nightVision)), 1.75));

    vec2 noisecoord = uv * vec2(aspectRatio * 1080.0, 1080.0);
    float anim  = frameTimeCounter*8*256;

    vec3 noise  = vec3(0.0);
        noise.r = texture(noisetex, floor(noisecoord+anim*1.8)*rcp(256.0)).x;
        noise.g = texture(noisetex, floor(noisecoord+vec2(-anim, anim)*1.2)*rcp(256.0)).x;
        noise.b = texture(noisetex, floor(noisecoord+vec2(anim, -anim)*1.4)*rcp(256.0)).x;

        hdr    += noise * sqrt(1.0-sstep(desat, 0.00, 0.005)) * 0.0003;

    return hdr;
}

/* ------ tonemapping operators ------ */

const mat3 XYZ_P3D65 = mat3(
	 2.4933963, -0.9313459, -0.4026945,
	-0.8294868,  1.7626597,  0.0236246,
	 0.0358507, -0.0761827,  0.9570140
);
const mat3 P3D65_XYZ = mat3(
	0.4865906, 0.2656683, 0.1981905,
	0.2289838, 0.6917402, 0.0792762,
	0.0000000, 0.0451135, 1.0438031
);

// https://en.wikipedia.org/wiki/Adobe_RGB_color_space
const mat3 XYZ_AdobeRGB = mat3(
      2.04158790381075,  -0.56500697427886,  -0.34473135077833,
     -0.96924363628088,   1.87596750150772, 0.0415550574071756,
    0.0134442806320311, -0.118362392231018,   1.01517499439121
);

// Bradford chromatic adaptation from standard D65 to DCI Cinema White
const mat3 D65_DCI = mat3(
    1.02449672775258,     0.0151635410224164, 0.0196885223342068,
    0.0256121933371582,   0.972586305624413,  0.00471635229242733,
    0.00638423065008769, -0.0122680827367302, 1.14794244517368
);

const mat3 REC2020_P3DCI = ((CM_2020_XYZ) * XYZ_P3D65) * D65_DCI;
const mat3 REC2020_P3D65 = (CM_2020_XYZ) * XYZ_P3D65;
const mat3 REC2020_AdobeRGB = CM_2020_XYZ * XYZ_AdobeRGB;

#if (defined COLOR_SPACE_SRGB || defined COLOR_SPACE_DCI_P3 || defined COLOR_SPACE_DISPLAY_P3 || defined COLOR_SPACE_REC2020 || defined COLOR_SPACE_ADOBE_RGB)

uniform int currentColorSpace;

// https://en.wikipedia.org/wiki/Rec._709#Transfer_characteristics
vec3 EOTF_Curve(vec3 LinearCV, const float LinearFactor, const float Exponent, const float Alpha, const float Beta) {
    return mix(LinearCV * LinearFactor, clamp(Alpha * pow(LinearCV, vec3(Exponent)) - (Alpha - 1.0), 0.0, 1.0), step(Beta, LinearCV));
}

// https://en.wikipedia.org/wiki/SRGB#Transfer_function_(%22gamma%22)
vec3 EOTF_IEC61966(vec3 LinearCV) {
    return EOTF_Curve(LinearCV, 12.92, 1.0 / 2.4, 1.055, 0.0031308);;
    //return mix(LinearCV * 12.92, clamp(pow(LinearCV, vec3(1.0/2.4)) * 1.055 - 0.055, 0.0, 1.0), step(0.0031308, LinearCV));
}
// https://en.wikipedia.org/wiki/Rec._709#Transfer_characteristics
vec3 EOTF_BT709(vec3 LinearCV) {
    return EOTF_Curve(LinearCV, 4.5, 0.45, 1.099, 0.018);
    //return mix(LinearCV * 4.5, clamp(pow(LinearCV, vec3(0.45)) * 1.099 - 0.099, 0.0, 1.0), step(0.018, LinearCV));
}
// https://en.wikipedia.org/wiki/DCI-P3
vec3 EOTF_P3DCI(vec3 LinearCV) {
    return pow(LinearCV, vec3(1.0 / 2.6));
}
// https://en.wikipedia.org/wiki/Adobe_RGB_color_space
vec3 EOTF_Adobe(vec3 LinearCV) {
    return pow(LinearCV, vec3(1.0 / 2.2));
}

vec3 OutputGamutTransform(vec3 REC2020) {
    switch(currentColorSpace) {
        case COLOR_SPACE_SRGB:
            REC2020 = REC2020 * CM_2020_sRGB;
            return EOTF_IEC61966(REC2020);

        case COLOR_SPACE_DCI_P3:
            REC2020 = REC2020 * REC2020_P3DCI;
            return EOTF_P3DCI(REC2020);

        case COLOR_SPACE_DISPLAY_P3:
            REC2020 = REC2020 * REC2020_P3D65;
            return EOTF_IEC61966(REC2020);

        case COLOR_SPACE_REC2020:
            return EOTF_BT709(REC2020);

        case COLOR_SPACE_ADOBE_RGB:
            REC2020 = REC2020 * REC2020_AdobeRGB;
            return EOTF_Adobe(REC2020);
    }
    // Fall back to sRGB if unknown
    REC2020 = REC2020 * CM_2020_sRGB;
    return EOTF_IEC61966(REC2020);
}

#else

#define VIEWPORT_GAMUT 0    //[0 1 2] 0: sRGB, 1: P3D65, 2: Display P3

vec3 OutputGamutTransform(vec3 REC2020) {
#if VIEWPORT_GAMUT == 1
    vec3 P3 = REC2020 * REC2020_P3D65;
    //return LinearToSRGB(P3);
    return pow(P3, vec3(1.0 / 2.6));
#elif VIEWPORT_GAMUT == 2
    vec3 P3 = REC2020 * REC2020_P3D65;
    return LinearToSRGB(P3);
    //return pow(P3, vec3(1.0 / 2.2));
#else
    return LinearToSRGB(REC2020 * CM_2020_sRGB);
#endif
}

#endif

vec3 tonemapReinhardSEUS(vec3 hdr) {
    float luma      = getLuma(hdr);

        hdr        *= 0.66;

        hdr         = pow(hdr, vec3(0.97));

    float coeff     = 0.25;

    vec3 col        = hdr/(hdr + coeff);
        col         = mix(hdr/(luma + 0.95), col, col) * 1.1;
        col         = saturate(col);

    return OutputGamutTransform(col);
}

/* ------ color grading utilities ------ */

vec3 rgbLuma(vec3 x) {
    return x * vec3(colorlumR, colorlumG, colorlumB);
}

vec3 applyGammaCurve(vec3 x) {
    return pow(x, vec3(gammaCurve));
}

vec3 vibranceSaturation(vec3 color) {
    float lum   = dot(color, lumacoeffAP1);
    float mn    = min(min(color.r, color.g), color.b);
    float mx    = max(max(color.r, color.g), color.b);
    float sat   = (1.0 - saturate(mx-mn)) * saturate(1.0-mx) * lum * 5.0;
    vec3 light  = vec3((mn + mx) / 2.0);

    color   = mix(color, mix(light, color, vibranceInt), saturate(sat));

    color   = mix(color, light, saturate(1.0-light) * (1.0-vibranceInt) / 2.0 * abs(vibranceInt));

    color   = mix(vec3(lum), color, saturationInt);

    return color;
}

vec3 brightnessContrast(vec3 color) {
    return (color - 0.5) * constrastInt + 0.5 + brightnessInt;
}

vec3 vignette(vec3 color) {
    float fade      = length(uv*2.0-1.0);
        fade        = linStep(abs(fade) * 0.5, vignetteStart, vignetteEnd);
        fade        = 1.0 - pow(fade, vignetteExponent) * vignetteIntensity;

    return color * fade;
}

#ifdef showFocusPlane

uniform float centerDepthSmooth, far, near, screenBrightness;

float depthLinear(float depth) {
    return (2.0*near) / (far+near-depth * (far-near));
}

void getFocusPlane(inout vec3 color) {

    float centerDepth = texture(depthtex0, vec2(0.5 * ResolutionScale)).x;

    #if camFocus == 0 //   Auto
        float focus = centerDepth;
    #elif camFocus == 1 // Manual
        float focus = camManFocDis;
              focus = (far * ( focus - near)) / ( focus * (far - near));
    #elif camFocus == 2 // Manual+
        float focus = screenBrightness * camManFocDis;
              focus = (far * ( focus - near)) / ( focus * (far - near));
    #elif camFocus == 3 // Auto+
        float offset = screenBrightness * 2.0 - 1.0;
        float autoFocus = depthLinear(centerDepth) * far * 0.5;
        float focus = offset > 0.0 ? autoFocus + (offset * camManFocDis) : autoFocus * saturate(offset * 0.9 + 1.1);
              focus = (far * ( focus - near)) / ( focus * (far - near));
    #endif

    if (texture(depthtex0, uv * ResolutionScale).x > focus) color    = mix(color, vec3(0.7, 0.2, 1.0) * 0.8, 0.5);
}
#endif

const float gauss9w[9] = float[9] (
     0.0779, 0.12325, 0.0779,
    0.12325, 0.1954,  0.12225,
     0.0779, 0.12325, 0.0779
);

const vec2 gauss9o[9] = vec2[9] (
    vec2(1.0, 1.0), vec2(0.0, 1.0), vec2(-1.0, 1.0),
    vec2(1.0, 0.0), vec2(0.0, 0.0), vec2(-1.0, 0.0),
    vec2(1.0, -1.0), vec2(0.0, -1.0), vec2(-1.0, -1.0)
);

float gauss9Rain(sampler2D tex) {
    float col        = 0.0;

    for (int i = 0; i<9; i++) {
        vec2 bcoord = uv + gauss9o[i]*pixelSize;
        col += texture(tex, bcoord * ResolutionScale).x*gauss9w[i];
    }
    return col;
}

void main() {
    vec3 sceneHDR   = textureLod(colortex0, uv, 0).rgb;

    #ifdef bloomEnabled
        vec2 cres       = max(viewSize, bloomResolution);

        float bloomInt = 0.2;

        #if DIM == -1
            bloomInt   = 0.4;
        #elif DIM == 1
            bloomInt  *= 1.5;
        #endif

            bloomInt   *= bloomIntensity;

        if (isEyeInWater == 1) bloomInt = mix(bloomInt, 1.0, 0.4);

        vec3 bloom  = texture(colortex5, uv/cres*bloomResolution*0.5).rgb * 4.0;

        sceneHDR    = mix(sceneHDR, bloom, saturate(bloomInt));

        if (rainStrength > 0.0) {
            float rint      = gauss9Rain(colortex14);
            bool rain       = rint > 0.0;

            if (rain) sceneHDR = mix(sceneHDR, bloom * 1.8, rint * 0.5);
        }
    #else
        if (rainStrength > 0.0) {
            float rint      = gauss9Rain(colortex14);
            bool rain       = rint > 0.0;

            if (rain) sceneHDR = mix(sceneHDR, sceneHDR * 1.8, rint * 0.5);
        }
    #endif

    //sceneHDR    = mix(sceneHDR, texelFetch(colortex5, ivec2(uv * viewSize * 0.25 * 0.25 * 0.25), 0).rrr, 0.5);

    //if (saturate(uv * 4.0) == uv * 4.0) sceneHDR = texture(colortex4, uv * 4.0).aaa;

    #ifdef manualExposureEnabled
        sceneHDR   *= rcp(manualExposureValue);
    #else
        sceneHDR   *= exposure * exposureBias;
    #endif

    #if DIM == -1
        sceneHDR  *= 0.5;
    #elif DIM == 1
        sceneHDR  *= 1.0;
    #endif

    #ifdef showFocusPlane
    if (hideGUI == 0) getFocusPlane(sceneHDR);
    #endif

    #ifdef doColorgrading
        sceneHDR    = vibranceSaturation(sceneHDR);
        sceneHDR    = rgbLuma(sceneHDR);
    #endif

    #ifdef vignetteEnabled
        sceneHDR    = vignette(sceneHDR);
    #endif

    vec3 sceneLDR   = tonemapReinhardSEUS(sceneHDR);
        sceneLDR    = pow(sceneLDR, vec3(1.02));
    
    #if DEBUG_VIEW==5
        sceneLDR    = sqrt(sceneHDR);
    #endif

    #ifdef doColorgrading
        sceneLDR    = brightnessContrast(sceneLDR);
        sceneLDR    = applyGammaCurve(saturate(sceneLDR));
    #endif

    sceneImage      = saturate(sceneLDR);

    temporal        = texture(colortex6, uv);
    temporal.a      = exposure;

    temporal        = clamp16F(temporal);
}