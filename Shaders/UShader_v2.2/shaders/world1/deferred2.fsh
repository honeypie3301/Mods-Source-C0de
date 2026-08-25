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


#include "/lib/head.glsl"

/*DRAWBUFFERS:05*/
layout(location = 0) out vec4 sceneColor;
layout(location = 1) out float vpsSigmaStore;

#include "/lib/util/colorspace.glsl"

const bool shadowHardwareFiltering = false;

in vec2 uv;

#ifndef airTransmittanceHQ
flat in vec3 sunColor;
#endif

uniform sampler2D colortex0;
uniform sampler2D colortex4;
uniform sampler2D colortex5;

uniform sampler2D depthtex0;

uniform sampler2D noisetex;

uniform sampler2D shadowtex0;
uniform sampler2D shadowtex1;

uniform int frameCounter;
uniform int worldTime;

uniform float far, near;
uniform float frameTimeCounter;

uniform vec2 taaOffset;
uniform vec2 pixelSize, viewSize;

uniform vec3 upDir, upDirView;
uniform vec3 sunDir, sunDirView;
uniform vec3 moonDir, moonDirView;
uniform vec3 lightDir, lightDirView;

uniform vec4 daytime;

uniform mat4 gbufferModelView, gbufferModelViewInverse;
uniform mat4 gbufferProjection, gbufferProjectionInverse;
uniform mat4 shadowModelView, shadowProjection;

/* ------ includes ------*/
#define FUTIL_LINDEPTH
#define FUTIL_ROT2
#include "/lib/fUtil.glsl"
#include "/lib/util/encoders.glsl"

#include "/lib/util/transforms.glsl"
#include "/lib/atmos/air/const.glsl"
#include "/lib/atmos/project.glsl"
#include "/lib/util/bicubic.glsl"
#include "/lib/frag/gradnoise.glsl"

/* ------ SKYBOX ------ */

vec3 sunDisk(vec3 viewDir) {
    vec3 v      = -viewDir;
    vec3 sv     = normalize(lightDirView + v);
    float sun   = dot(sv, v);

    const float size = 0.04;
    float maxsize = size + 0.0004;

    float s   = cube(1.0-linStep(sun, size, maxsize));
        //s    *= 1.0-sstep(sun, 0.004, 0.0059)*0.5;

    float invS = cube(linStep(sun, size * 0.95, maxsize));

        s    *= invS;

        s = cube(1.0 - saturate(abs(1000.0 * (sun - 0.05))));

    return s * endSunlightColor * 1000.0;
}

#include "/lib/frag/noise.glsl"

vec3 skyStars(vec3 worldDir) {

    float Blackhole = cube(1.0 - linStep((dot(worldDir, lightDir)), 0.95, 0.97));
    float Ring = (1.0 - saturate(abs(max0(dot(worldDir, lightDir)) - 0.96) * 50.0));
        Ring = pow(Ring, 32.0);

    worldDir += normalize(lightDir - worldDir) * cube(linStep((dot(worldDir, lightDir)), 0.8, 0.97));
    worldDir = normalize(worldDir);

    vec3 plane  = worldDir/(worldDir.y+length(worldDir.xz)*0.66);
    plane.yz    = rotatePos(plane.yz, (25.0/180.0)*pi);
    vec2 uv1    = floor((plane.xz) * (Blackhole * 0.5 + 0.5) * 512) / 512.0;
    vec2 uv2    = (plane.xz)*0.06;

    vec3 starcol = vec3(0.3, 0.78, 1.0);
        starcol  = mix(starcol, vec3(1.0, 0.5, 0.4), noise2D(uv2).x);
        starcol  = normalize(starcol)*(noise2D(uv2*1.5).x+1.0);

    float star  = 1.0;
        star   *= noise2D(uv1).x;
        star   *= noise2D(uv1+0.1).x;
        star   *= noise2D(uv1+0.26).x;

    star        = max(star-0.22, 0.0);
    star        = saturate(star*4.0) * saturate(worldDir.y * 4.0);

    float Time = frameTimeCounter * 0.003;

    float NebulaNoise  = noise2D(uv2 * 0.6 + noise2D(uv2 * 0.1 + Time * vec2(0.3, -0.1) * 0.3).xy * 0.1 + Time * vec2(0.2, 0.05)).x;
        NebulaNoise += noise2D(uv2 * 1.5 + NebulaNoise * 0.1 - Time * vec2(0.4, 0.1)).x * 0.5;
        NebulaNoise += noise2D(uv2 * 3.5 + NebulaNoise * 0.25).x * 0.2;
    vec3 Nebula = pow(starcol, vec3(4.0)) * cubeSmooth(max0(NebulaNoise - 0.75) * max0(worldDir.y)) * 0.15;

    return (star*starcol* tau + Nebula) * (Blackhole + Ring * 50.0) + Ring * cube(starcol) * 0.1;
}

/* ------ SHADOWPASS PRECOMPUTION ------ */

#include "/lib/shadowconst.glsl"
#include "/lib/light/warp.glsl"

#include "/lib/offset/random.glsl"


float shadowVPSSigma(sampler2D tex, vec3 scenePos) {    
    vec3 pos        = scenePos + vec3(shadowmapBias) * lightDir;
    float a         = length(pos);
        pos         = transMAD(shadowModelView, pos);
        pos         = projMAD(shadowProjection, pos);

        pos.z      *= 0.2;

    if (pos.z > 1.0) return 0.0;

        pos.z      -= 0.0012*(saturate(a/256.0));

    vec2 posUnwarped = pos.xy;

    float warp      = 1.0;
        pos.xy      = shadowmapWarp(pos.xy, warp);
        pos         = pos * 0.5 + 0.5;

    const uint iterations = 6;

    const float penumbraScale = tan(radians(0.3));

    float penumbraMax   = shadowmapDepthScale * penumbraScale * shadowProjection[0].x;
    float searchRad     = min(0.5 * shadowProjection[0].x, penumbraMax / tau);

    float maxRad        = max(searchRad, 2.0 / shadowmapSize.x / warp);

    float minDepth      = pos.z - maxRad / penumbraMax / tau;
    float maxDepth      = pos.z;

    const uint itSquare = iterations * iterations;
    const float w = 1.0 / float(itSquare);

    float weightSum = 0.0;
    float depthSum  = 0.0;

    float dither    = ditherGradNoiseTemporal();

    for (uint i = 0; i<iterations; ++i) {
        vec2 offset     = R2((i + dither) * 64.0);
            offset      = vec2(cos(offset.x * tau), sin(offset.x * tau)) * sqrt(offset.y);            

        vec2 searchPos  = posUnwarped + offset * searchRad;
            searchPos   = shadowmapWarp(searchPos) * 0.5 + 0.5;

        float depth     = texelFetch(tex, ivec2(searchPos * shadowmapSize), 0).x;
        float weight    = step(depth, pos.z);

            depthSum   += weight * clamp(depth, minDepth, maxDepth);
            weightSum  += weight;
    }
    depthSum   /= weightSum > 0.0 ? weightSum : 1.0;

    float sigma     = weightSum > 0.0 ? (pos.z - depthSum) * penumbraMax : 0.0;

    return max0(sigma) * rcp(warp);
}

void main() {
    sceneColor      = texture(colortex0, uv);

    float sceneDepth = texture(depthtex0, uv).x;

    vec3 viewPos    = screenToViewSpace(vec3(uv / ResolutionScale, sceneDepth));
    vec3 scenePos   = viewToSceneSpace(viewPos);

    if (!landMask(sceneDepth)) {
        vec3 viewDir    = normalize(viewPos);
        vec3 sceneDir   = normalize(scenePos);

        vec3 sunMoon    = sunDisk(viewDir) + skyStars(sceneDir);

        float groundOcclusion = exp(-max0(-sceneDir.y) * sqrPi);

        sceneColor.rgb = endSkylightColor * 0.006 + sunMoon;
    }

    sceneColor      = clamp16F(sceneColor);

    vpsSigmaStore   = 0.0;

    #ifdef shadowVPSEnabled
    if (landMask(sceneDepth)) vpsSigmaStore = shadowVPSSigma(shadowtex1, scenePos);

    vpsSigmaStore   = clamp16F(vpsSigmaStore);
    #endif
}