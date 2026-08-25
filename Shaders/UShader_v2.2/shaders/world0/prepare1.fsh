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

/* RENDERTARGETS: 4 */
layout(location = 0) out vec4 skyboxData;

#include "/lib/head.glsl"

in vec2 uv;

flat in vec3 Skylight;
flat in mat2x3 CelestialLight;

flat in vec3 sunDir;
flat in vec3 moonDir;
flat in vec3 cloudLightDir, lightDir;

uniform sampler2D colortex4;

uniform sampler2D noisetex;
uniform sampler3D depthtex1;

uniform int frameCounter;
uniform int worldTime;

uniform float aspectRatio;
uniform float eyeAltitude;
uniform float frameTimeCounter;
uniform float wetness;
uniform float worldAnimTime;

uniform vec2 viewSize, pixelSize;

uniform vec3 cameraPosition;

uniform vec4 daytime;

uniform mat4 gbufferModelView, gbufferModelViewInverse;
uniform mat4 gbufferProjection, gbufferProjectionInverse;

const vec3 upDir = vec3(0.0, 1.0, 0.0);


/* ------ includes ------ */
#define FUTIL_ROT2
#include "/lib/fUtil.glsl"
#include "/lib/frag/bluenoise.glsl"
#include "/lib/frag/gradnoise.glsl"
#include "/lib/atmos/phase.glsl"
#define airmassStepBias 0.33
#include "/lib/atmos/air/const.glsl"
#include "/lib/atmos/air/density.glsl"

#include "/lib/atmos/project.glsl"
#include "/lib/frag/noise.glsl"
#include "/lib/util/bicubic.glsl"

#include "/lib/atmos/CloudsCommon.glsl"

vec4 cloudSystemReflected(vec3 worldDir, float vDotL, float dither, vec3 skyColor) {
    vec3 totalScattering    = vec3(0.0);
    float totalTransmittance = 1.0;

    vec3 sunlight       = (worldTime>23000 || worldTime<12900) ? CelestialLight[0] : CelestialLight[1];
    vec3 skylight       = Skylight;

    float pFade         = saturate(mieCS(vDotL, 0.5));
        pFade           = mix(pFade, vDotL * 0.5 + 0.5, 1.0 / sqrt2);

    const float eyeAltitude = 64.0;
    vec3 camPos     = vec3(cameraPosition.x, eyeAltitude, cameraPosition.z);
    const uint volumeSamples = 45;

    // --- volumetric clouds --- //
    #ifdef cloudVolumeEnabled
    bool visibleVol = worldDir.y > 0.0;

    float lightNoise = ditherGradNoise();

    if (visibleVol) {

        vec3 bottom     = worldDir * ((cloudCumulusAlt - eyeAltitude) * rcp(worldDir.y));
        vec3 top        = worldDir * ((cloudCumulusMaxY - eyeAltitude) * rcp(worldDir.y));

        float airDist   = length(worldDir.y < 0.0 ? bottom : top);
            airDist     = min(airDist, cloudVolumeClip);

        vec3 airmass    = getAirmass(vec3(0.0, planetRad + eyeAltitude, 0.0), worldDir, airDist, 0.15, 2) * rcp(airDist) * tau;

        vec3 start      = bottom;
        vec3 end        = top;

        const float baseLength  = cloudCumulusDepth / float(volumeSamples);
        float stepLength    = length(end - start) * rcp(float(volumeSamples));
        float stepCoeff     = stepLength * rcp(baseLength);
            stepCoeff       = 0.45 + clamp(stepCoeff - 1.1, 0.0, 2.5) * 0.5;

        uint steps          = uint(volumeSamples * stepCoeff);

        vec3 rStep          = (end - start) * rcp(float(steps));
        vec3 rPos           = rStep * dither + start + camPos;
        float rLength       = length(rStep);

        vec3 scattering     = vec3(0.0);
        float transmittance = 1.0;

        vec3 bouncelight    = vec3(0.6, 1.0, 0.8) * sunlight * rcp(pi * 14.0 * sqrt2) * max0(dot(cloudLightDir, upDir));

        const float sigmaA  = 1.0;
        const float sigmaT  = 0.2;

        for (uint i = 0; i < steps; ++i, rPos += rStep) {
            if (transmittance < cloudTransmittanceThreshold) break;
            if (rPos.y < cloudCumulusAlt || rPos.y > cloudCumulusMaxY) continue;

            float dist  = distance(rPos, camPos);
            if (dist > cloudVolumeClip) continue;

            float density = cloudCumulusShape(rPos);
            if (density <= 0.0) continue;

            float extinction    = density * sigmaT;
            float stepT         = exp(-extinction * rLength);
            float integral      = (1.0 - stepT) * rcp(sigmaT);

            float airmassMult = 1.0 + sstep(dist / cloudVolumeClip, 0.5, 1.0) * pi; 
            vec3 atmosFade = expf(-max(airScatterMat * airmass.xy * (dist * airmassMult), 0.0));

            if (maxOf(atmosFade) < 1e-4) {
                scattering     += (skyColor * sigmaT) * (integral * transmittance);
                transmittance  *= stepT;

                continue;
            }

            vec3 stepScatter    = vec3(0.0);

            float lightOD       = cloudVolumeLightOD(rPos, 4);
            
            float skyOD         = cloudVolumeSkyOD(rPos, 3);
            
            float bounceOD      = cube(1.0 - linStep(rPos.y, cloudCumulusAlt, cloudCumulusAlt + cloudCumulusDepth * 0.3));
            /*
            float powder        = 8.0 * (1.0 - 0.97 * expf(-extinction * 16.0 * powderBias));     //this is loosely based on spectrum
            float anisoPowder   = powder * (1.0 - expf(-max0(lightOD - sigmaT) * powderBias * (1.0 + sigmaT)) * rpi);
                anisoPowder     = mix(anisoPowder, 1.0, pFade);
            */
            float powderCoeff   = 16.0;

            float powderLo1 = 1.0 - exp(-extinction *  2.0 * powderCoeff);
            float powderLo2 = 1.0 - exp(-extinction *  4.0 * powderCoeff);
            float powderLo  = (powderLo1 + powderLo2) / 4.0;

            float powderHi1 = 1.0 - exp(-extinction *  5.0 * powderCoeff);
            float powderHi2 = 1.0 - exp(-extinction * 20.0 * powderCoeff);
            float powderHi  = (powderHi1 + powderHi2) / 6.0;

            float powder    = (powderLo + powderHi) * 2.2;
            float anisoPowder = mix(powder, 1.0, pFade);

            vec3 phaseG         = pow(vec3(0.45, 0.45, 0.95), vec3(1.0 + lightOD));

            for (uint j = 0; j < 5; ++j) {
                float n     = float(j);

                float td    = sigmaT * pow(0.5, n);
                float phase = cloudPhase(vDotL, pow(0.5, n), phaseG);

                stepScatter.x  += expf(-lightOD * td) * phase * td;
                stepScatter.y  += expf(-skyOD * td) * td;
            }

            stepScatter.xy *= vec2(anisoPowder, powder);

            stepScatter.z  += bounceOD * powder;

            stepScatter     = (sunlight * stepScatter.x) + (skylight * stepScatter.y) + (bouncelight * stepScatter.z);
            stepScatter     = mix(skyColor * sigmaT, stepScatter, atmosFade);
            scattering     += stepScatter * (integral * transmittance);

            transmittance  *= stepT;
        }

        transmittance       = linStep(transmittance, cloudTransmittanceThreshold, 1.0);

        totalScattering    += scattering;
        totalTransmittance *= transmittance;
    }
    #endif

    #ifdef cloudCirrusEnabled
    // --- planar cirrus clouds --- //
    bool visiblePlane   = worldDir.y > 0.0;

    if (visiblePlane && totalTransmittance > 1e-10) {
        vec3 plane      = worldDir * ((cloudCirrusPlaneY - eyeAltitude) * rcp(worldDir.y));

        float airDist   = length(plane);
            //airDist     = mix(min(airDist, cloudVolumeClip), 9e4, within);

        vec3 airmass    = getAirmass(vec3(0.0, planetRad + eyeAltitude, 0.0), worldDir, airDist, 0.25, 3) * rcp(airDist) * tau;

        vec3 rPos       = plane + camPos;

        const float sigmaT  = 0.04;

        float dist      = distance(rPos, camPos);

        vec3 scattering = vec3(0.0);
        float transmittance = 1.0;

        mat2x3 planarBounds = mat2x3(worldDir*((cloudCirrusMaxY-eyeAltitude)/worldDir.y) + cameraPosition,
                                     worldDir*((cloudCirrusAlt-eyeAltitude)/worldDir.y) + cameraPosition);

        float rLength   = distance(planarBounds[0], planarBounds[1]);

        if (dist < cloudCirrusClip) {
            float density   = cloudCirrusShape(rPos);

            if (density > 0.0) {
                float extinction    = density * sigmaT;
                float stepT         = exp(-extinction * rLength);
                float integral      = (1.0 - stepT) * rcp(sigmaT);

                vec3 atmosFade  = expf(-max(airScatterMat * airmass.xy * dist, 0.0));

                if (maxOf(atmosFade) < 1e-4) {
                    scattering     += (skyColor * sigmaT) * (integral * transmittance);
                    transmittance  *= stepT;
                } else {
                    float lightOD       = cloudCirrusLightOD(rPos, 4, cloudLightDir);
                    float skyOD         = cloudCirrusLightOD(rPos, 3, vec3(0.0, 1.0, 0.0));

                    float powder        = 8.0 * (1.0 - 0.97 * expf(-extinction * 38.0));     //this is loosely based on spectrum
                    float anisoPowder   = mix(powder, 1.0, pFade);

                    vec3 phaseG         = pow(vec3(0.45, 0.45, 0.95), vec3(1.0 + lightOD));

                    for (uint j = 0; j < 5; ++j) {
                        float n     = float(j);

                        float td    = sigmaT * pow(0.5, n);
                        float phase = cloudPhase(vDotL, pow(0.5, n), phaseG);

                        scattering.x   += expf(-lightOD * td) * anisoPowder * phase * td;
                        scattering.y   += expf(-skyOD * td) * powder * td;
                    }

                    scattering      = (sunlight * scattering.x) + (skylight * scattering.y);
                    scattering      = mix(skyColor * sigmaT, scattering, atmosFade);
                    scattering      = scattering * (integral * transmittance);

                    transmittance  *= stepT;
                }
            }
        }

        totalScattering    += scattering * totalTransmittance;
        totalTransmittance *= transmittance;
    }
    #endif

    return vec4(totalScattering, totalTransmittance);
}

/* ------ cloud shadows ------ */

uniform mat4 shadowModelViewInverse;

float generateCloudShadowmap(vec2 uv, vec3 lightDir, float dither) {
    vec3 position   = vec3(uv, 0.0) * 2.0 - 1.0;
        position.xy *= cloudShadowmapRenderDistance;
        position    = mat3(shadowModelViewInverse) * position;
        position.xz += cameraPosition.xz;
        //position    += lightDir * (256.0 - position.y) * rcp(lightDir.y);

    float lightFade = cubeSmooth(sqr(linStep(lightDir.y, 0.1, 0.15)));

    float transmittance = 1.0;

    if (lightFade > 0.0) {
        vec3 plane = lightDir * ((cloudCirrusPlaneY - position.y) * rcp(lightDir.y));
            plane += position;

        float fade      = 1.0 - sstep(distance(plane.xz, cameraPosition.xz), cloudShadowmapRenderDistance * 0.5, cloudShadowmapRenderDistance);
        if (fade < 1e-3) {
            transmittance = 1.0 - wetness * 0.90;
        } else {
            float density   = cloudCirrusShape(plane);

            float extinction = density * 0.04;
            float stepT     = exp(-extinction * (cloudCirrusMaxY - cloudCirrusAlt) * 0.71);
                stepT       = mix(1.0 - wetness * 0.90, stepT, fade);
            transmittance *= stepT;
        }

        if (transmittance > 0.05) {
            vec3 bottom     = lightDir * ((cloudCumulusAlt - position.y) * rcp(lightDir.y));
            vec3 top        = lightDir * ((cloudCumulusMaxY - position.y) * rcp(lightDir.y));

            vec3 start      = bottom;
            vec3 end        = top;

            uint steps          = 40;

            vec3 rStep          = (end - start) * rcp(float(steps));
            vec3 rPos           = rStep * dither + start + position;
            float rLength       = length(rStep);

            const float sigmaT  = 0.2;

            for (uint i = 0; i < steps; ++i, rPos += rStep) {
                if (transmittance < 0.05) break;

                float fade      = 1.0 - sstep(distance(rPos.xz, cameraPosition.xz), cloudShadowmapRenderDistance * 0.5, cloudShadowmapRenderDistance);
                if (fade < 1e-3) {
                    transmittance = 1.0 - wetness * 0.90;
                    continue;
                }

                float density   = cloudCumulusShape(rPos);

                float extinction = density * sigmaT;
                float stepT     = exp(-extinction * rLength);
                    stepT       = mix(1.0 - wetness * 0.90, stepT, fade);

                transmittance  *= stepT;
            }
        }

        transmittance       = linStep(transmittance, 0.05, 1.0);
        transmittance       = mix(1.0 - wetness * 0.95, transmittance, lightFade);
    } else {
        transmittance   = 1.0 - wetness * 0.95;
    }

    return transmittance * 0.8 + 0.2;
}

void main() {
    skyboxData      = texture(colortex4, uv);

    vec2 projectionUV   = fract(uv * vec2(1.0, 3.0));

    uint index      = uint(floor(uv.y * 3.0));

    if (index == 2) {
        vec3 skyColor   = texture(colortex4, projectionUV / vec2(1.0, 3.0)).rgb;

        vec3 direction   = unprojectSky(projectionUV);

            skyColor    = mix(skyColor, Skylight, saturate(1.0 - exp(-max0(-direction.y) * 16.0) * 0.9));

        #if (defined cloudVolumeEnabled || defined cloudCirrusEnabled)
            #ifdef cloudReflectionsToggle
            vec4 cloudData      = cloudSystemReflected(direction, dot(direction, cloudLightDir), ditherBluenoiseStatic(), skyColor);

            skyColor    = skyColor * cloudData.a + cloudData.rgb;
            #endif        
        #endif

        skyboxData.rgb  = skyColor;
    }

    #ifdef cloudShadowsEnabled
    vec2 shadowmapCoord     = uv * vec2(1.0, 1.0 + (1.0/3.0));

    if (saturate(shadowmapCoord) == shadowmapCoord) {
        #if (defined cloudVolumeEnabled)
            skyboxData.a    = generateCloudShadowmap(shadowmapCoord, lightDir, ditherBluenoiseStatic());
        #endif
    }
    #endif

    skyboxData      = clamp16F(skyboxData);
}