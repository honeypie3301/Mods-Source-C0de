#version 400 compatibility

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

/* RENDERTARGETS: 0,5,11 */
layout(location = 0) out vec3 sceneColor;
layout(location = 1) out vec4 fogScattering;
layout(location = 2) out vec3 fogTransmittance;

#include "/lib/head.glsl"
#include "/lib/util/encoders.glsl"
#include "/lib/shadowconst.glsl"

const bool shadowHardwareFiltering = true;

in vec2 uv;

flat in mat3x3 lightColor;

uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D colortex2;
uniform sampler2D colortex3;
uniform sampler2D colortex4;
uniform sampler2D colortex5;

uniform sampler2D noisetex;

uniform sampler2D depthtex0;
uniform sampler2D depthtex1;

uniform sampler2DShadow shadowtex0;
uniform sampler2DShadow shadowtex1;
uniform sampler2D shadowcolor0;

uniform int frameCounter;
uniform int isEyeInWater;
uniform int worldTime;

uniform float eyeAltitude;
uniform float far, near;
uniform float frameTimeCounter;
uniform float lightFlip;
uniform float sunAngle;
uniform float rainStrength, wetness;
uniform float worldAnimTime;

uniform ivec2 eyeBrightness;
uniform ivec2 eyeBrightnessSmooth;

uniform vec2 taaOffset;
uniform vec2 viewSize, pixelSize;

uniform vec3 cameraPosition;
uniform vec3 lightDir, lightDirView;

uniform mat4 gbufferModelView, gbufferModelViewInverse;
uniform mat4 gbufferProjection, gbufferProjectionInverse;
uniform mat4 shadowModelView, shadowModelViewInverse;
uniform mat4 shadowProjection, shadowProjectionInverse;

/* ------ INCLUDES ------ */
#define FUTIL_MAT16
#define FUTIL_TBLEND
#define FUTIL_LINDEPTH
#define FUTIL_ROT2
#include "/lib/fUtil.glsl"
#include "/lib/frag/bluenoise.glsl"
#include "/lib/frag/gradnoise.glsl"
#include "/lib/util/transforms.glsl"
#include "/lib/atmos/air/const.glsl"
#include "/lib/atmos/phase.glsl"
#include "/lib/atmos/waterConst.glsl"
#include "/lib/frag/noise.glsl"

/* ------ SHADOW PREP ------ */
#include "/lib/light/warp.glsl"

vec3 shadowColorSample(sampler2D tex, vec2 position) {
    vec4 colorSample = texture(shadowcolor0, position);
    return mix(vec3(1.0), colorSample.rgb * 4.0, colorSample.a);
}

/* ------ VOLUMETRIC FOG ------ */

#ifdef freezeAtmosAnim
    const float fogTime   = float(atmosAnimOffset) * 0.006;
#else
    float fogTime     = frameTimeCounter * 0.6;
#endif


vec3 hsv2rgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

float RemapAltitude(float Value) {
    Value -= 80.0;
    if (Value > 0.0) Value = mix(Value, Value * 0.1, cubeSmooth(saturate(Value / 100.0)));

    return (Value + 80.0) * 0.3;
}

vec2 smokeDensity(vec3 rPos, float altitude, out vec3 color) {
    vec3 center     = (rPos + cameraPosition) + vec3(0.0, -64.0, 0.0);

    float smoke     = 0.0;
    float smokeGlowing = 0.0;
    color   = vec3(0);

    vec3 wind   = fogTime * vec3(0.5, -0.9, 0.1);

    rPos += cameraPosition;

    //vec2 SpinOffset = rotatePos(normalize(rPos.xz), pi / 2.0) * cube(1.0 - saturate(length(rPos.xz) / 1024.0));

    rPos.xz = rotatePos(rPos.xz, mix(0.0, mix(pi / 12.0, tau, (saturate(altitude / 768.0))), (1.0 - saturate(length(rPos.xz) / 512.0))));

    float SmokeCenter = cube(1.0 - saturate(length(rPos.xz) / 384.0));
    
    float smokeFade = sstep(altitude, -64.0, 0.0) * (1.0 - sstep(altitude, 128.0 + SmokeCenter * 128.0, 192.0 + SmokeCenter * 384.0));
        smokeFade = smokeFade * 0.2 + 0.8;

    rPos.xz -= mix(normalize(rPos.xz) * min(192.0, length(rPos.xz)), vec2(0.0), sqrt(sstep(altitude, -32.0, 128.0))) * (1.0 - sstep(length(rPos.xz), 128.0, 512.0));

    rPos.y = RemapAltitude(rPos.y);

    //rPos.xz += SpinOffset;

    //rPos.y *= 0.71;

    vec3 pos    = (rPos) * 0.06;
        pos.xz  = rotatePos(pos.xz, pi / 1.8);
        pos    += value3D(pos * 4.0 + wind * 0.5) * 1.5 - 0.75;
        pos.xz  = rotatePos(pos.xz, pi / 3.0);
        pos    += value3D(pos * 8.0 + wind.zyx) - 0.5;

        pos.xz  = rotatePos(pos.xz, -pi / 1.8);

    pos.x *= 0.7;
    pos.y *= 0.6;

    float noise     = value3D(pos * 2.0 + wind);
        pos.xz  = rotatePos(pos.xz, pi / 2.5);
        noise      += value3D(pos * 8.0 + wind.zyx * 2 + noise * 0.5) * 0.5;
        noise      += value3D(pos * 16.0 + wind * 4 + noise * 0.5) * 0.25;
        noise      /= 1.5;

    smoke       = smokeFade - noise;

    #ifdef endSmokeGlow
    float glowProximity = sqrt(sstep(length(rPos), 4.0, 24.0));
        smokeGlowing = saturate((glowProximity * (0.3 + cube(smokeFade) * 0.15) - noise) * pi);

        color   = hsv2rgb(vec3(cubeSmooth(value3D(pos * vec3(1.0, 1.41, 1.0) + wind * 0.2)) * 0.5 + 0.5, 0.7, 0.45));

        smokeGlowing *= smokeFade;
    #endif

    smoke       = (cube(saturate(smoke))) * sqrt(smokeFade);

    return vec2(smoke, smokeGlowing);
}

vec3 mieHG3(float cosTheta, vec3 g) {
    vec3 mie   = 1.0 + sqr(g) - 2.0*g*cosTheta;
        mie     = (1.0 - sqr(g)) / ((4.0*pi) * mie*(mie*0.5+0.5));
    return mie;
}

const vec3 fogCol = endSunlightColor;
const vec3 fogCol2 = endSkylightColor.bgr * 0.5;

const vec3 hazeCoeff    = vec3(3e-2, 1.5e-2, 4.5e-2);
const vec3 smokeCoeff   = vec3(4e-2);

mat2x3 volumetricFog(vec3 scenePos, vec3 sceneDir, float dither, float vDotL, bool isSky) {
    vec3 startPos   = gbufferModelViewInverse[3].xyz;
    vec3 endPos     = scenePos;
        if (length(endPos) > 256.0) endPos = sceneDir * 256.0;
        if (isSky) endPos = sceneDir * 512.0;

    float baseStep  = length(endPos - startPos);
    float stepCoeff = clamp(baseStep * rcp(clamp(far, 128.0, 512.0)), 0.0, 2.0);

    uint steps      = 8 + uint(stepCoeff * 16.0);

    vec3 rStep      = (endPos - startPos) / float(steps);
    vec3 rPos       = startPos + rStep * dither;
    float rLength   = length(rStep);

    vec3 shadowStartPos = transMAD(shadowModelView, (startPos));
        shadowStartPos  = projMAD(shadowProjection, shadowStartPos);
        shadowStartPos.z *= 0.2;
    vec3 shadowEndPos   = transMAD(shadowModelView, (endPos));
        shadowEndPos    = projMAD(shadowProjection, shadowEndPos);
        shadowEndPos.z *= 0.2;

    vec3 shadowStep = (shadowEndPos - shadowStartPos) / float(steps);
    vec3 shadowPos  = shadowStartPos + shadowStep * dither;

    mat2x3 scattering = mat2x3(0.0);
    vec3 transmittance = vec3(1.0);

    const mat2x3 scatterMat   = mat2x3(hazeCoeff, smokeCoeff);
    const mat2x3 extinctMat   = mat2x3(hazeCoeff * 1.1, smokeCoeff);

    for (uint i = 0; i < steps; ++i, rPos += rStep, shadowPos += shadowStep) {
        if (maxOf(transmittance) < 0.01) break;

        float altitude  = rPos.y + eyeAltitude;

        //if (altitude > 256.0) continue;

        vec3 glowColor;

        vec2 density    = smokeDensity(rPos, altitude, glowColor);

        vec2 stepRho    = density * rLength;
        vec3 od         = extinctMat * stepRho;

        vec3 stepT      = expf(-od);
        vec3 scatterInt = saturate((stepT - 1.0) * rcp(-max(od, 1e-16)));
        vec3 visScatter = transmittance * scatterInt;

        vec3 a          = visScatter * transmittance;

        float shadow    = 1.0;
        vec3 shadowCol  = vec3(1.0);

        if (length(rPos.xy) < 256.0) {
        vec3 shadowCoord = vec3(shadowmapWarp(shadowPos.xy), shadowPos.z) * 0.5 + 0.5;

        float shadow0   = texture(shadowtex0, shadowCoord);
        
        if (shadow0 < 1.0) {
            shadow      = texture(shadowtex1, shadowCoord);

            if (abs(shadow - shadow0) > 0.1) {
                //shadowCol   = shadowColorSample(shadowcolor0, shadowCoord.xy);
            }
        }
        }

        mat2x3 stepScatter = mat2x3(scatterMat[0] * stepRho.x * a * shadow, (scatterMat[1] * stepRho.y * a) * glowColor);

            scattering    += stepScatter;

        transmittance  *= stepT;
    }

    //vec3 smokeCol       = mix(fogCol, lightColor[1], saturate(scattering[1]));

    vec3 color          = scattering[0] * fogCol * mieHG3(vDotL, mix(vec3(0.4), vec3(0.95), (transmittance))) + scattering[1] * sqrt2;


    if (color != color) {   //because NaNs on nVidia don't need a logic cause to happen
        color = vec3(0.0);
        transmittance = vec3(1.0);
    }

    return mat2x3(color, saturate(transmittance));
}

void applyFogData(inout vec3 color, in mat2x3 data) {
    color = color * data[1] + data[0];
}

#include "/lib/atmos/fog.glsl"

/* ------ REFRACTION ------ */
vec3 refract2(vec3 I, vec3 N, vec3 NF, float eta) {     //from spectrum by zombye
    float NoI = dot(N, I);
    float k = 1.0 - eta * eta * (1.0 - NoI * NoI);
    if (k < 0.0) {
        return vec3(0.0); // Total Internal Reflection
    } else {
        float sqrtk = sqrt(k);
        vec3 R = (eta * dot(NF, I) + sqrtk) * NF - (eta * NoI + sqrtk) * N;
        return normalize(R * sqrt(abs(NoI)) + eta * I);
    }
}

/* --- TEMPORAL CHECKERBOARD --- */

#define checkerboardDivider 4
#define ditherPass
#include "/lib/frag/checkerboard.glsl"

void main() {
    sceneColor  = stex(colortex0).rgb;

    vec2 sceneDepth = vec2(stex(depthtex0).x, stex(depthtex1).x);

    vec3 viewPos0   = screenToViewSpace(vec3(uv / ResolutionScale, sceneDepth.x));
    vec3 scenePos0  = viewToSceneSpace(viewPos0);

    vec3 viewPos1   = screenToViewSpace(vec3(uv / ResolutionScale, sceneDepth.y));
    vec3 scenePos1  = viewToSceneSpace(viewPos1);

    vec3 viewDir    = normalize(viewPos0);
    vec3 worldDir   = normalize(scenePos0);

    bool translucent    = sceneDepth.x < sceneDepth.y;

    float cave      = saturate(float(eyeBrightnessSmooth.y) / 240.0);

    if (translucent){
        vec4 tex1           = stex(colortex1);
        vec3 sceneNormal    = decodeNormal(tex1.xy);
        vec3 viewNormal     = mat3(gbufferModelView) * sceneNormal;
        vec3 flatNormal     = normalize(cross(dFdx(scenePos0), dFdy(scenePos0)));
        vec3 flatViewNormal = normalize(mat3(gbufferModelView) * flatNormal);

        vec3 normalCorrected = dot(viewNormal, viewDir) > 0.0 ? -viewNormal : viewNormal;

        vec3 refractedDir   = refract2(normalize(viewPos1), normalCorrected, flatViewNormal, rcp(1.33));
        //vec3 refractedDir   = refract(normalize(viewPos1), normalCorrected, rcp(1.33));

        float refractedDist = distance(viewPos0, viewPos1);

        vec3 refractedPos   = viewPos1 + refractedDir * refractedDist;

        vec3 screenPos      = viewToScreenSpace(refractedPos);

        float distToEdge    = maxOf(abs(screenPos.xy * 2.0 - 1.0));
            distToEdge      = sqr(sstep(distToEdge, 0.7, 1.0));

            screenPos.xy    = mix(screenPos.xy, uv / ResolutionScale, distToEdge);

        //vec2 refractionDelta = uv - screenPos.xy;

        float sceneDepthNew = texture(depthtex1, screenPos.xy * ResolutionScale).x;

        if (sceneDepthNew > sceneDepth.x) {
            sceneDepth.y    = sceneDepthNew;
            viewPos1        = screenToViewSpace(vec3(screenPos.xy, sceneDepth.y));
            scenePos1       = viewToSceneSpace(viewPos1);

            sceneColor.rgb  = texture(colortex0, screenPos.xy * ResolutionScale).rgb;
        }
    }

    float vDotL     = dot(viewDir, lightDirView);
    float bluenoise = ditherBluenoise();

    vec4 tex2       = stex(colortex2);
    int matID       = decodeMatID16(tex2.z);
    bool water      = matID == 102;

    if (translucent) {

        if (water && isEyeInWater == 0) {
            sceneColor  = waterFog(sceneColor, distance(scenePos0, scenePos1), lightColor[1]);
        }

        vec4 translucencyColor  = stex(colortex5);
        vec4 reflectionAux      = stex(colortex3);

        vec3 albedo     = decodeRGBE8(vec4(unpack2x8(reflectionAux.z), unpack2x8(reflectionAux.w)));

        vec3 tint       = sqr(saturate(normalize(albedo)));

        sceneColor  = blendTranslucencies(sceneColor, translucencyColor, tint);
    }

    sceneColor      = clamp16F(sceneColor);

    fogScattering   = vec4(0.0);
    fogTransmittance = vec3(1.0);

    #if (defined END_VolumetricSmoke)
    bool isSky      = !landMask(sceneDepth.x);

    mat2x3 fogData  = mat2x3(vec3(0.0), vec3(1.0));

    if (isEyeInWater == 1) {
    } else {
        #ifdef END_VolumetricSmoke
        fogData    = volumetricFog(scenePos0, worldDir, bluenoise, vDotL, isSky);
        #endif
    }

    fogScattering.rgb = fogData[0];
    fogScattering.a = depthLinear(sceneDepth.x);
    fogTransmittance = fogData[1];

    fogScattering       = clamp16F(fogScattering);

    #endif
}