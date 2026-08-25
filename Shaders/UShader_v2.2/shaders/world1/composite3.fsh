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

/*DRAWBUFFERS:05*/
layout(location = 0) out vec3 sceneColor;
layout(location = 1) out vec4 exposureTemp;

#include "/lib/head.glsl"
#include "/lib/util/colorspace.glsl"
#include "/lib/util/encoders.glsl"

in vec2 uv;

flat in mat3x3 lightColor;

uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D colortex2;
uniform sampler2D colortex3;
uniform sampler2D colortex4;
uniform sampler2D colortex5;
uniform sampler2D colortexC;
uniform sampler2D colortex11;

uniform sampler2D depthtex0;
uniform sampler2D depthtex1;

uniform sampler2D noisetex;

uniform int frameCounter;
uniform int isEyeInWater;

uniform float near, far;
uniform float lightFlip;
uniform float sunAngle;

uniform vec2 taaOffset;
uniform vec2 pixelSize, viewSize;

uniform vec3 lightDir, lightDirView;

uniform mat4 gbufferModelView, gbufferModelViewInverse;
uniform mat4 gbufferProjection, gbufferProjectionInverse;

#define FUTIL_MAT16
#define FUTIL_LINDEPTH
#include "/lib/fUtil.glsl"
#include "/lib/frag/bluenoise.glsl"
#include "/lib/frag/gradnoise.glsl"
#include "/lib/util/transforms.glsl"
#include "/lib/brdf/fresnel.glsl"
#include "/lib/brdf/material.glsl"
#include "/lib/brdf/specular.glsl"
#include "/lib/frag/capture.glsl"
#include "/lib/atmos/project.glsl"

/*
    These two functions used for rough reflections are based on zombye's spectrum shaders
    https://github.com/zombye/spectrum
*/

mat3 getRotationMat(vec3 x, vec3 y) {
	float cosine = dot(x, y);
	vec3 axis = cross(y, x);

	float tmp = 1.0 / dot(axis, axis);
	      tmp = tmp - tmp * cosine;
	vec3 tmpv = axis * tmp;

	return mat3(
		axis.x * tmpv.x + cosine, axis.x * tmpv.y - axis.z, axis.x * tmpv.z + axis.y,
		axis.y * tmpv.x + axis.z, axis.y * tmpv.y + cosine, axis.y * tmpv.z - axis.x,
		axis.z * tmpv.x - axis.y, axis.z * tmpv.y + axis.x, axis.z * tmpv.z + cosine
	);
}
vec3 ggxFacetDist(vec3 viewDir, float roughness, vec2 xy) {
	/*
        GGX VNDF sampling
        http://www.jcgt.org/published/0007/04/01/
    */

    viewDir     = normalize(vec3(roughness * viewDir.xy, viewDir.z));

    float clsq  = dot(viewDir.xy, viewDir.xy);
    vec3 T1     = vec3(clsq > 0.0 ? vec2(-viewDir.y, viewDir.x) * inversesqrt(clsq) : vec2(1.0, 0.0), 0.0);
    vec3 T2     = vec3(-T1.y * viewDir.z, viewDir.z * T1.x, viewDir.x * T1.y - T1.x * viewDir.y);

	float r     = sqrt(xy.x);
	float phi   = tau * xy.y;
	float t1    = r * cos(phi);
	float a     = saturate(1.0 - t1 * t1);
	float t2    = mix(sqrt(a), r * sin(phi), 0.5 + 0.5 * viewDir.z);

	vec3 normalH = t1 * T1 + t2 * T2 + sqrt(saturate(a - t2 * t2)) * viewDir;

	return normalize(vec3(roughness * normalH.xy, normalH.z));
}

mat2x3 unpackReflectionAux(vec4 data){
    vec3 shadows    = decodeRGBE8(vec4(unpack2x8(data.x), unpack2x8(data.y)));
    vec3 albedo     = decodeRGBE8(vec4(unpack2x8(data.z), unpack2x8(data.w)));

    return mat2x3(shadows, albedo);
}

vec3 screenspaceRT(vec3 position, vec3 direction, float noise) {
    const uint maxSteps     = 14;

  	float rayLength = ((position.z + direction.z * far * sqrt3) > -near) ?
                      (-near - position.z) / direction.z : far * sqrt3;

    vec3 screenPosition     = viewToScreenSpace(position);
    vec3 endPosition        = position + direction * rayLength;
    vec3 endScreenPosition  = viewToScreenSpace(endPosition);

    vec3 screenDirection    = normalize(endScreenPosition - screenPosition);
        screenDirection.xy  = normalize(screenDirection.xy);

    vec3 maxLength          = (step(0.0, screenDirection) - screenPosition) / screenDirection;
    float stepMult          = minOf(maxLength);
    vec3 screenVector       = screenDirection * stepMult / float(maxSteps);

    vec3 screenPos          = screenPosition + screenDirection * maxOf(pixelSize * pi);

    if (saturate(screenPos.xy) == screenPos.xy) {
        float depthSample   = texelFetch(depthtex0, ivec2(screenPos.xy * viewSize * ResolutionScale), 0).x;
        float linearSample  = depthLinear(depthSample);
        float currentDepth  = depthLinear(screenPos.z);

        if (linearSample < currentDepth) {
            float dist      = abs(linearSample - currentDepth) / currentDepth;
            if (dist <= 0.25) return vec3(screenPos.xy, depthSample);
        }
    }

        screenPos          += screenVector * noise;

    for (uint i = 0; i < maxSteps; ++i) {
        if (saturate(screenPos.xy) != screenPos.xy) break;

        float depthSample   = texelFetch(depthtex0, ivec2(screenPos.xy * viewSize * ResolutionScale), 0).x;
        float linearSample  = depthLinear(depthSample);
        float currentDepth  = depthLinear(screenPos.z);

        if (linearSample < currentDepth) {
            float dist      = abs(linearSample - currentDepth) / currentDepth;
            if (dist <= 0.5) return vec3(screenPos.xy, depthSample);
        }

        screenPos      += screenVector;
    }

    return vec3(1.1);
}

vec3 screenspaceRT_LR(vec3 position, vec3 direction, float noise) {
    const uint maxSteps     = 7;

  	float rayLength = ((position.z + direction.z * far * sqrt3) > -near) ?
                      (-near - position.z) / direction.z : far * sqrt3;

    vec3 screenPosition     = viewToScreenSpace(position);
    vec3 endPosition        = position + direction * rayLength;
    vec3 endScreenPosition  = viewToScreenSpace(endPosition);

    vec3 screenDirection    = normalize(endScreenPosition - screenPosition);
        screenDirection.xy  = normalize(screenDirection.xy);

    vec3 maxLength          = (step(0.0, screenDirection) - screenPosition) / screenDirection;
    float stepMult          = min(minOf(maxLength), 0.5);
    vec3 screenVector       = screenDirection * stepMult / float(maxSteps);

    vec3 screenPos          = screenPosition;

        screenPos          += screenVector * noise;

    for (uint i = 0; i < maxSteps; ++i) {
        if (saturate(screenPos.xy) != screenPos.xy) break;

        float depthSample   = texelFetch(depthtex0, ivec2(screenPos.xy * viewSize * ResolutionScale), 0).x;
        float linearSample  = depthLinear(depthSample);
        float currentDepth  = depthLinear(screenPos.z);

        if (linearSample < currentDepth) {
            float dist      = abs(linearSample - currentDepth) / currentDepth;
            if (dist <= 0.5) return vec3(screenPos.xy, depthSample);
        }

        screenPos      += screenVector;
    }

    return vec3(1.1);
}

vec4 readSkybox(float occlusion, vec3 direction) {
    return vec4(lightColor[1] * 0.1, 1.0);
}

/* ------ FOG ------ */
#include "/lib/offset/gauss.glsl"

ivec2 clampTexelPos(ivec2 pos) {
    return clamp(pos, ivec2(0.0), ivec2(viewSize));
}

vec2 bluenoiseJitter() {
    return sincos(ditherBluenoise());
}

mat2x3 sampleFogSpatial(vec2 uv, const float LOD) {
    ivec2 pixelCoordUnscaled = ivec2(uv * viewSize);

    vec2 newCoord       = uv / LOD;
    ivec2 pixelCoord    = ivec2(newCoord * viewSize);

    ivec2 pos           = ivec2(uv * viewSize);

    vec3 centerScatter  = texelFetch(colortex5, pixelCoord, 0).rgb;
    vec3 centerTransmittance = texelFetch(colortex11, pixelCoord, 0).rgb;

    float centerDepth   = depthLinear(texelFetch(depthtex0, pixelCoordUnscaled, 0).x) * far;

    float totalWeight   = 1.0;
    vec3 totalScatter   = centerScatter * totalWeight;
    vec3 totalTrans     = centerTransmittance * totalWeight;

    for (int i = 0; i<9; i++) {
        ivec2 deltaPos      = kernelO_3x3[i] + ivec2(sincos(ditherBluenoise()));
        if (i == 4) continue;

        ivec2 samplePos     = pixelCoordUnscaled + deltaPos;
        ivec2 samplePosScaled = ivec2(vec2(samplePos) / LOD);

        bool valid          = all(greaterThanEqual(samplePos, ivec2(0))) && all(lessThan(samplePos, ivec2(viewSize)));

        if (!valid) continue;

        vec3 currentScatter = texelFetch(colortex5, clampTexelPos(samplePosScaled), 0).rgb;
        vec3 currentTrans   = texelFetch(colortex11, clampTexelPos(samplePosScaled), 0).rgb;
        float currentDepth  = depthLinear(texelFetch(depthtex0, samplePos, 0).x) * far;

        float depthDelta    = abs(currentDepth - centerDepth) * 2.0;

        float weight        = exp(-depthDelta);

        //accumulate stuff
        totalScatter   += currentScatter * weight;
        totalTrans     += currentTrans * weight;

        totalWeight    += weight;
    }

    totalScatter   /= max(totalWeight, 1e-16);
    totalTrans     /= max(totalWeight, 1e-16);

    return mat2x3(totalScatter, totalTrans);
}

void applyFogData(inout vec3 color, in mat2x3 data) {
    color = color * data[1] + data[0];
}

#include "/lib/atmos/air/const.glsl"
#include "/lib/atmos/waterConst.glsl"

#include "/lib/atmos/fog.glsl"

void main() {
    sceneColor  = stex(colortex0).rgb;

    float sceneDepth = stex(depthtex0).x;

    vec3 viewPos    = screenToViewSpace(vec3(uv / ResolutionScale, sceneDepth));
    vec3 viewDir    = normalize(viewPos);
    vec3 scenePos   = viewToSceneSpace(viewPos);

    if (landMask(sceneDepth)) {
        vec4 tex1       = stex(colortex1);
        vec4 tex2       = stex(colortex2);

        vec3 sceneNormal = decodeNormal(tex1.xy);
        vec3 viewNormal = mat3(gbufferModelView) * sceneNormal;

        vec2 lightmaps  = saturate(unpack2x8(tex1.z));

        int matID       = decodeMatID16(tex2.z);

        bool water      = matID == 102;

        mat2x3 reflectionAux = unpackReflectionAux(stex(colortex3));
            reflectionAux[0] *= pi;

        vec3 directCol  = lightColor[0];
            reflectionAux[0] = min(reflectionAux[0], directCol);

        materialProperties material = materialProperties(1.0, 0.02, false, false, mat2x3(0.0));
        if (water) material = materialProperties(0.0001, 0.02, false, false, mat2x3(0.0));
        else material   = decodeLabBasic(unpack2x8(tex2.x));

        if (dot(viewDir, viewNormal) > 0.0) viewNormal = -viewNormal;

        vec3 reflectDir = reflect(viewDir, viewNormal);
        
        vec4 reflection = vec4(0.0);
        vec3 fresnel    = vec3(0.0);

        float skyOcclusion  = cubeSmooth(sqr(linStep(lightmaps.y, skyOcclusionThreshold - 0.2, skyOcclusionThreshold)));

        #ifdef resourcepackReflectionsEnabled
            /* --- ROUGH REFLECTIONS --- */

            float roughnessFalloff  = 1.0 - (linStep(material.roughness, roughnessThreshold * 0.71, roughnessThreshold));

            #ifdef roughReflectionsEnabled
            if (material.roughness < 0.0002 || water) {
            #endif

                vec3 reflectSceneDir = mat3(gbufferModelViewInverse) * reflectDir;
                vec2 sphereCoord = unprojectSphere(reflectSceneDir);

                #ifdef screenspaceReflectionsEnabled
                    vec3 reflectedPos = screenspaceRT(viewPos, reflectDir, ditherBluenoise());
                    if (reflectedPos.z < 1.0) reflection += vec4(texelFetch(colortex0, ivec2(reflectedPos.xy * viewSize * ResolutionScale), 0).rgb, 1.0);
                    else reflection += readSkybox(skyOcclusion, reflectSceneDir);
                #else
                    else reflection += readSkybox(skyOcclusion, reflectSceneDir);
                #endif

                    if (clamp16F(reflection) != reflection) reflection = vec4(0.0);

                    fresnel    += BRDFfresnel(-viewDir, viewNormal, material, reflectionAux[1]);

            #ifdef roughReflectionsEnabled

            } else {
                mat3 rot        = getRotationMat(vec3(0, 0, 1), viewNormal);
                vec3 tangentV   = viewDir * rot;
                float noise     = ditherBluenoise();
                float dither    = ditherGradNoiseTemporal();

                const uint steps    = roughReflectionSamples;
                const float rSteps  = 1.0 / float(steps);

                for (uint i = 0; i < steps; ++i) {
                    if (roughnessFalloff <= 1e-3) break;
                    vec2 xy         = vec2(fract((i + noise) * sqr(32.0) * phi), (i + noise) * rSteps);
                    vec3 roughNrm   = rot * ggxFacetDist(-tangentV, material.roughness, xy);

                    vec3 reflectDir = reflect(viewDir, roughNrm);

                    vec3 reflectSceneDir = mat3(gbufferModelViewInverse) * reflectDir;
                    vec2 sphereCoord = unprojectSphere(reflectSceneDir);

                    #ifdef screenspaceReflectionsEnabled
                        vec3 reflectedPos       = vec3(1.1);
                        if (material.roughness < 0.3) reflectedPos = screenspaceRT(viewPos, reflectDir, dither);
                        else if (material.roughness < 0.7) reflectedPos = screenspaceRT_LR(viewPos, reflectDir, dither);

                        if (reflectedPos.z < 1.0) reflection += vec4(texelFetch(colortex0, ivec2(reflectedPos.xy * viewSize * ResolutionScale), 0).rgb, 1.0);
                        else reflection += readSkybox(skyOcclusion, reflectSceneDir);
                    #else
                        else reflection += readSkybox(skyOcclusion, reflectSceneDir);
                    #endif

                        fresnel    += BRDFfresnel(-viewDir, viewNormal, material, reflectionAux[1]);
                }
                if (clamp16F(reflection) != reflection) reflection = vec4(0.0);

                reflection *= rSteps;
                fresnel    *= rSteps;

                reflection.a *= roughnessFalloff;
            }

            #else
                reflection.a *= roughnessFalloff;
            #endif

            if (material.conductor) sceneColor.rgb = mix(sceneColor.rgb, reflection.rgb * fresnel, reflection.a);
            else sceneColor.rgb = mix(sceneColor.rgb, reflection.rgb, fresnel * reflection.a);

            if (water) sceneColor.rgb += specularBeckmann(-viewDir, lightDirView, viewNormal, material) * reflectionAux[0];
            else sceneColor.rgb += specularTrowbridgeReitzGGX(-viewDir, lightDirView, viewNormal, material, reflectionAux[1]) * reflectionAux[0];
            
        #else
            /* --- WATER REFLECTIONS --- */
            if (water) {
                vec3 reflectSceneDir = mat3(gbufferModelViewInverse) * reflectDir;
                vec2 sphereCoord = unprojectSphere(reflectSceneDir);

                #ifdef screenspaceReflectionsEnabled
                    vec3 reflectedPos = screenspaceRT(viewPos, reflectDir, ditherBluenoise());
                    if (reflectedPos.z < 1.0) reflection += vec4(texelFetch(colortex0, ivec2(reflectedPos.xy * viewSize * ResolutionScale), 0).rgb, 1.0);
                    else reflection += readSkybox(skyOcclusion, reflectSceneDir);
                #else
                    reflection += readSkybox(skyOcclusion, reflectSceneDir);
                #endif

                    if (clamp16F(reflection) != reflection) reflection = vec4(0.0);

                    fresnel    += BRDFfresnel(-viewDir, viewNormal, material, reflectionAux[1]);
                sceneColor.rgb = mix(sceneColor.rgb, reflection.rgb, fresnel * reflection.a);
                sceneColor.rgb += specularBeckmann(-viewDir, lightDirView, viewNormal, material) * reflectionAux[0];
            }   

        #endif
        //sceneColor.rgb  = texture(colortexC, unprojectSphere(normalize(scenePos))).rgb;

        //if (isEyeInWater == 0) {
        //    sceneColor  = simpleFog(sceneColor, length(scenePos), lightColor[1]);
       //}
    }


    #if (defined END_VolumetricSmoke)

    #ifdef fogSmoothingEnabled
        mat2x3 fogData      = sampleFogSpatial(uv, 1.0);
    #else
        mat2x3 fogData      = mat2x3(texture(colortex5, uv).rgb, texture(colortex11, uv).rgb);
    #endif

    applyFogData(sceneColor, fogData);

    #endif

    if (isEyeInWater == 1) {
        sceneColor  = waterFog(sceneColor, length(scenePos), lightColor[1]);
    }

    exposureTemp    = vec4(0.0);

    //sceneColor.rgb  = texture(colortexC, 1-uv).rgb;
}