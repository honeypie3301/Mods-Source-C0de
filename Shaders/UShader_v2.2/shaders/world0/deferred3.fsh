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


/* RENDERTARGETS: 3,5,12 */
layout(location = 0) out vec4 directLightAlbedo;
layout(location = 1) out vec3 IndirectSources;
layout(location = 2) out float ambientOcclusion;

#include "/lib/head.glsl"
#include "/lib/util/encoders.glsl"
#include "/lib/util/colorspace.glsl"
#include "/lib/shadowconst.glsl"

const bool shadowHardwareFiltering = true;

in vec2 uv;

flat in mat4x3 lightColor;

uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D colortex2;
uniform sampler2D colortex3;
uniform sampler2D colortex4;
uniform sampler2D colortex5;

uniform sampler2D depthtex0;

uniform sampler2D noisetex;

uniform sampler2DShadow shadowtex0;
uniform sampler2DShadow shadowtex1;
uniform sampler2D shadowcolor0;

uniform int frameCounter;

uniform float aspectRatio;
uniform float near, far;
uniform float lightFlip;
uniform float sunAngle;

uniform vec2 taaOffset;
uniform vec2 pixelSize, viewSize;

uniform vec3 lightDir, lightDirView;

uniform mat4 gbufferModelView, gbufferModelViewInverse;
uniform mat4 gbufferProjection, gbufferProjectionInverse;
uniform mat4 shadowModelView, shadowProjection;

/* ------ includes ------*/
#define FUTIL_MAT16
#define FUTIL_LINDEPTH
#include "/lib/fUtil.glsl"
#include "/lib/util/transforms.glsl"
#include "/lib/frag/bluenoise.glsl"
#include "/lib/frag/gradnoise.glsl"
#include "/lib/light/warp.glsl"
#include "/lib/light/contactShadow.glsl"

struct shadowData {
    float shadow;
    vec3 color;
    vec3 subsurfaceScatter;
};

#include "/lib/offset/random.glsl"


vec3 ReadShadowColor(ivec2 Pixel) {
    vec4 Sample = texelFetch(shadowcolor0, Pixel, 0);

    return mix(vec3(1.0), Sample.rgb * 4.0, Sample.a);
}
vec4 GetSampleColor(vec3 Color, float SolidOcclusion, float TranslucentOcclusion, float SharpenAlpha) {
    if (TranslucentOcclusion >= SolidOcclusion) Color = vec3(1.0);

    return mix(vec4(Color * SolidOcclusion, SolidOcclusion), vec4(Color, SolidOcclusion), SharpenAlpha);
}

vec4 GetShadowBilinear(vec3 uv, float SharpenAlpha) {
    ivec2 ShadowRes = ivec2(shadowMapResolution);

    ivec2 SamplePixel = ivec2(uv.xy * ShadowRes - 0.5);

    vec4 OcclusionSamples = textureGather(shadowtex1, uv.xy, uv.z).wzxy;
    vec4 OcclusionSamples_T = textureGather(shadowtex0, uv.xy, uv.z).wzxy;

    vec3[4] ColorSamples = vec3[4](
        ReadShadowColor(SamplePixel + ivec2(0,0)),
        ReadShadowColor(SamplePixel + ivec2(1,0)),
        ReadShadowColor(SamplePixel + ivec2(0,1)),
        ReadShadowColor(SamplePixel + ivec2(1,1))
    );

    vec2 PixelFract = fract(uv.xy * ShadowRes - 0.5);

    vec4 Color0 = mix(GetSampleColor(ColorSamples[0], OcclusionSamples[0], OcclusionSamples_T[0], SharpenAlpha), GetSampleColor(ColorSamples[1], OcclusionSamples[1], OcclusionSamples_T[1], SharpenAlpha), PixelFract.x);
    vec4 Color1 = mix(GetSampleColor(ColorSamples[2], OcclusionSamples[2], OcclusionSamples_T[2], SharpenAlpha), GetSampleColor(ColorSamples[3], OcclusionSamples[3], OcclusionSamples_T[3], SharpenAlpha), PixelFract.x);

    return mix(Color0, Color1, PixelFract.y);
}

vec4 shadowFiltered(vec3 pos, float sigma) {
    float stepsize = rcp(float(shadowMapResolution));
    float dither   = ditherBluenoise();

    vec4 TotalShadow   = vec4(0.0);

    const float minSoftSigma = shadowmapPixel.x * 2.0;

    float softSigma = max(sigma, minSoftSigma);

    float sharpenLerp = saturate(sigma / minSoftSigma);

    vec2 noise  = vec2(cos(dither * pi), sin(dither * pi)) * stepsize;
    
    vec3 colorMin   = vec3(1.0);

    for (uint i = 0; i < shadowFilterIterations; ++i) {
        vec2 offset     = R2((i + dither) * 64.0);
            offset      = vec2(cos(offset.x * tau), sin(offset.x * tau)) * sqrt(offset.y);

            vec4 colorSample = GetShadowBilinear(pos + vec3(offset * softSigma, 0.0), (1.0 - sharpenLerp));

            TotalShadow   += colorSample;
            colorMin    = min(colorMin, colorSample.rgb);
    }
    TotalShadow  /= float(shadowFilterIterations);

    //vec2 sharpenBorders = mix(vec2(0.4, 0.6), vec2(0.0, 1.0), sharpenLerp);
    vec2 sharpenBorders = mix(vec2(0.5, 0.6), vec2(0.0, 1.0), sharpenLerp);

    float sharpenedShadow = linStep(TotalShadow.a, sharpenBorders.x, sharpenBorders.y);

    float colorEdgeWeight = saturate(distance(TotalShadow.a, sharpenedShadow));

    TotalShadow.rgb = mix(TotalShadow.rgb, colorMin, sqrt(colorEdgeWeight));

    return vec4(mix(TotalShadow.rgb * sharpenedShadow, TotalShadow.rgb, saturate((sigma / minSoftSigma) - 1)), sharpenedShadow);
}

vec3 RShadow_GetBias(vec3 GeometryNormal, vec3 ShadowPosition, float Distortion) {
    float BiasScale = log2(max(128.0 - shadowMapResolution / 8.0, 4.0)) * 0.35;
    return mat3(shadowProjection) * (mat3(shadowModelView) * GeometryNormal) * Distortion * BiasScale;
}

shadowData getShadowRegular(vec3 scenePos, float sigma, vec3 GeometryNormal) {   
    shadowData data     = shadowData(1.0, vec3(1.0), vec3(0.0));
   
    vec3 pos        = scenePos;
    float a         = length(pos);
        pos         = transMAD(shadowModelView, pos);
        pos         = projMAD(shadowProjection, pos);

        pos.z      *= 0.2;

    if (pos.z > 1.0) return data;

        pos.z      -= 0.0012*(saturate(a/256.0));

    vec2 posUnwarped = pos.xy;

    float warp      = 1.0;
        pos.xy      = shadowmapWarp(pos.xy, warp);
        pos         = pos * 0.5 + 0.5;

        pos.z      -= (sigma * warp);

        vec4 shadow     = shadowFiltered(pos, sigma);

        data.shadow     = shadow.w;
        data.color      = shadow.rgb;

    return data;
}

#include "/lib/atmos/phase.glsl"

shadowData getShadowSubsurface(bool diffLit, vec3 scenePos, float sigma, vec3 viewDir, vec3 albedo, float opacity) {
    shadowData data     = shadowData(1.0, vec3(1.0), vec3(0.0));

    vec3 pos        = scenePos + vec3(shadowmapBias) * lightDir;
    float a         = length(pos);
        pos         = transMAD(shadowModelView, pos);
        pos         = projMAD(shadowProjection, pos);

        pos.z      *= 0.2;

    if (pos.z > 1.0) return data;

        pos.z      -= 0.0012*(saturate(a/256.0));

    vec2 posUnwarped = pos.xy;

    float warp      = 1.0;
        pos.xy      = shadowmapWarp(pos.xy, warp);
        pos         = pos * 0.5 + 0.5;

        pos.z      -= (sigma * warp);

    if (diffLit) {
        #ifdef shadowVPSEnabled
            vec4 shadow     = shadowFiltered(pos, sigma);

            data.shadow     = shadow.w;
            data.color      = shadow.rgb;
        #else
            vec4 shadow     = shadowFiltered(pos, 0.005 * warp);

            data.shadow     = shadow.w;
            data.color      = shadow.rgb;
        #endif
    }

    if (opacity < (0.5 / 255.0)) return data;

    float bluenoise     = ditherBluenoise();
    float sssRad        = 0.001 * sqrt(opacity);
    vec3 sssShadow      = vec3(0.0);
    
    #define sssLoops 5

    float rStep         = rcp(float(sssLoops));
    float offsetMult    = rStep;
    vec2 noise          = vec2(sin(bluenoise * pi), cos(bluenoise * pi));
    
    for (int i = 0; i < sssLoops; i++) {
        vec3 offset         = vec3(noise, -bluenoise) * offsetMult;
        float falloff       = sqr(rcp(1.0 + length(offset)));
            offset.xy      *= rcp(warp);
            offset         *= sssRad;

        float sssShadowTemp = texture(shadowtex1, pos + vec3(offset.xy, offset.z));
            sssShadowTemp  += texture(shadowtex1, pos + vec3(-offset.xy, offset.z));
            sssShadowTemp  *= falloff;

            sssShadow      += vec3(sssShadowTemp);
            offsetMult     += rStep;
    }

    sssShadow   = saturate(sssShadow * rStep * 1.2);

    vec3 albedoNorm     = normalize(albedo) * (avgOf(albedo) * 0.5 + 0.5);
    vec3 scattering     = mix(albedoNorm * normalize(albedo), mix(albedoNorm, vec3(0.8), sssShadow * 0.7), sssShadow) * sssShadow;
        scattering     *= mix(mieHG(dot(viewDir, lightDirView), 0.65), 1.2, 0.4);  //eyeballed to look good because idk the accurate version

    data.subsurfaceScatter = scattering * sqrt2 * rpi * opacity;

    return data;
}

float readCloudShadowmap(sampler2D shadowmap, vec3 position) {
    position    = mat3(shadowModelView) * position;
    position   /= cloudShadowmapRenderDistance;
    position.xy = position.xy * 0.5 + 0.5;

    position.xy /= vec2(1.0, 1.0 + (1.0 / 3.0));

    return texture(shadowmap, position.xy).a;
}

vec4 packLightingAlbedo(vec3 directLight, vec3 albedo) {
    vec4 lightRGBE  = encodeRGBE8(directLight);
    vec4 albedoRGBE = encodeRGBE8(albedo);

    return vec4(pack2x8(lightRGBE.xy),
                pack2x8(lightRGBE.zw),
                pack2x8(albedoRGBE.xy),
                pack2x8(albedoRGBE.zw));
}


/* ------ BRDF ------ */

#include "/lib/brdf/fresnel.glsl"
#include "/lib/brdf/hammon.glsl"
#include "/lib/brdf/labPBR.glsl"



/*
    SSAO based on BSL Shaders by Capt Tatsu with permission
*/

vec2 offsetDist(float x) {
	float n = fract(x * 8.0) * pi;
    return vec2(cos(n), sin(n)) * x;
}

float getDSSAO(sampler2D depthtex, vec3 sceneNormal, float depth, vec2 uv, float dither) {
    const uint steps = 6;
    const float baseRadius = sqrt2;

    float radius    = baseRadius * (0.75 + abs(1.0-dot(sceneNormal, vec3(0.0, 1.0, 0.0))) * 0.5) * ResolutionScale;

    bool hand       = depth < 0.56;
        depth       = depthLinear(depth);

    float currStep  = 0.2 * dither + 0.2;
	float fovScale  = gbufferProjection[1][1] / 1.37;
	float distScale = max((far - near) * depth + near, 5.0);
	vec2 scale      = radius * vec2(1.0 / aspectRatio, 1.0) * fovScale / distScale;

    float ao = 0.0;

    const float maxOcclusionDist    = tau;
    const float anibleedExp         = 0.71;

    for (uint i = 0; i < steps; ++i) {
		vec2 offset = offsetDist(currStep) * scale;
		float mult  = (0.7 / radius) * (far - near) * (hand ? 1024.0 : 1.0);

		float sampleDepth = depthLinear(texture(depthtex, uv + offset).r);
		float sample0 = (depth - sampleDepth) * mult;
        float antiBleed = 1.0 - rcp(1.0 + max0(distance(sampleDepth, depth) * far - maxOcclusionDist) * anibleedExp);
		float angle = mix(clamp(0.5 - sample0, 0.0, 1.0), 0.5, antiBleed);
		float dist  = mix(clamp(0.25 * sample0 - 1.0, 0.0, 1.0), 0.5, antiBleed);

		sampleDepth = depthLinear(texture(depthtex, uv - offset).r);
		sample0     = (depth - sampleDepth) * mult;
        antiBleed   = 1.0 - rcp(1.0 + max0(distance(sampleDepth, depth) * far - maxOcclusionDist) * anibleedExp);
        angle      += mix(clamp(0.5 - sample0, 0.0, 1.0), 0.5, antiBleed);
        dist       += mix(clamp(0.25 * sample0 - 1.0, 0.0, 1.0), 0.5, antiBleed);
		
		ao         += (clamp(angle + dist, 0.0, 1.0));
		currStep   += 0.2;
    }
	ao *= 1.0 / float(steps);
	
	return ao;
}


vec3 GetBlocklightColor(vec3 Color, float Lightmap) {
    float Exponent = mix(2.0, 0.8, sqrt(Lightmap));
    vec3 ColorGradient = pow(Color / maxOf(Color), vec3(Exponent)) * maxOf(Color);

    return ColorGradient * pow5(Lightmap);
}

void main() {
    vec4 sceneColor = stex(colortex0);
    vec3 directSunlight  = vec3(1.0);
    vec3 albedo     = vec3(1.0);
    IndirectSources = vec3(0);

    float sceneDepth = stex(depthtex0).x;

    if (landMask(sceneDepth)) {
        vec4 tex1       = stex(colortex1);
        vec4 tex2       = stex(colortex2);

        albedo          = sceneColor.rgb;

        vec3 viewPos    = screenToViewSpace(vec3(uv / ResolutionScale, sceneDepth));
        vec3 viewDir    = -normalize(viewPos);
        vec3 scenePos   = viewToSceneSpace(viewPos);

        vec3 sceneNormal = decodeNormal(tex1.xy);
        vec3 viewNormal = mat3(gbufferModelView) * sceneNormal;

        materialLAB material = decodeSpecularTexture(vec4(unpack2x8(tex2.x), unpack2x8(tex2.y)));

        int matID       = decodeMatID16(tex2.z);
        bool isSSS      = matID == 2 || matID == 4 || material.opacity > 1e-2;
        float sssOpacity = max(float(matID == 2 || matID == 4), material.opacity);

        vec2 lightmaps      = saturate(unpack2x8(tex1.z));
        vec2 aux        = unpack2x8(tex1.w);    //parallax shadows and wetness

        float diffuse   = diffuseHammon(viewNormal, viewDir, lightDirView, material.roughness);
        #ifdef contactShadowsEnabled
        if (diffuse > 0.0) diffuse *= getContactShadow(depthtex0, viewPos, ditherBluenoise(), sceneDepth, dot(viewNormal, viewDir), lightDirView);
        #endif
            diffuse    *= aux.x;

        shadowData shadow   = shadowData(1.0, vec3(1.0), vec3(0.0));

        bool diffuseLit = diffuse > 0.0;

        #ifdef shadowVPSEnabled
        float shadowSigma   = stex(colortex5).x;
        #else
        const float shadowSigma = 0.001 * shadowPenumbraScale;
        #endif

        //vec3 shadowPosition     = scenePos + lightDir * shadowmapBias * sqrt(length(scenePos) / 128.0);
        //    shadowPosition     += lightDir * shadowmapBias * (1.0 - max0(dot(sceneNormal, lightDir)));

        vec3 GeometryNormal = texture(colortex3, uv).xyz * 2.0 - 1.0;

        vec3 shadowPosition = scenePos;
            shadowPosition += GeometryNormal * min(0.1 + length(scenePos) / 200.0, 0.5) * (2.0 - max0(dot(sceneNormal, lightDir))) * log2(max(128.0 - shadowMapResolution * shadowMapDepthScale, euler)) / euler;

        if (isSSS) shadow   = getShadowSubsurface(diffuseLit, shadowPosition, shadowSigma, viewDir, stex(colortex0).rgb, sssOpacity);
        else if (diffuseLit) shadow = getShadowRegular(shadowPosition, shadowSigma, GeometryNormal);

        directSunlight  = diffuse * shadow.color * shadow.shadow + shadow.subsurfaceScatter;

        #ifdef cloudShadowsEnabled
            directSunlight *= readCloudShadowmap(colortex4, scenePos);
        #endif

        float albedoLum = mix(avgOf(sceneColor.rgb), maxOf(sceneColor.rgb), 0.71);
            albedoLum   = saturate(albedoLum * sqrt2);

        float emitterLum = saturate(mix(sqr(albedoLum), sqrt(maxOf(sceneColor.rgb)), albedoLum));
            emitterLum *= (float(matID == 5) + float(matID == 6) * 0.25);

        vec3 emission       = mix(sqr(normalize(albedo)), vec3(1.0), emitterLum) * emitterLum * maxOf(lightColor[3]);
            emission        = max(emission, GetBlocklightColor(lightColor[3], lightmaps.x) * 0.71);

        IndirectSources = directSunlight * (sunAngle<0.5 ? lightColor[0] : lightColor[2]) * lightFlip * sqrt2;
        IndirectSources += emission * sqrt3;
        IndirectSources *= albedo;
    }

    ambientOcclusion    = 1.0;

    vec2 lowresCoord    = uv;
    ivec2 pixelPos      = ivec2(floor(uv * viewSize));
        sceneDepth      = texelFetch(depthtex0, pixelPos, 0).x;

    if (landMask(sceneDepth) && saturate(lowresCoord / ResolutionScale) == (lowresCoord / ResolutionScale)) {
        vec2 uv      = saturate(lowresCoord);

        vec4 tex1       = texelFetch(colortex1, pixelPos, 0);
        vec3 sceneNormal = decodeNormal(tex1.xy);

        ambientOcclusion = getDSSAO(depthtex0, sceneNormal, sceneDepth, uv, ditherBluenoise());
    }

    directLightAlbedo   = packLightingAlbedo(directSunlight, albedo);
}