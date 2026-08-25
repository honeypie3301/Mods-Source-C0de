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

/* RENDERTARGETS: 5 */
layout(location = 0) out vec4 cloudCurrentFrame;

#include "/lib/util/colorspace.glsl"

in vec2 uv;

flat in mat4x3 lightColor;

uniform sampler2D colortex4;

uniform sampler2D depthtex0, depthtex2;

uniform sampler2D noisetex;
uniform sampler3D depthtex1;

uniform sampler3D colortex1;
uniform sampler3D colortex2;

uniform int frameCounter;
uniform int worldTime;

uniform float eyeAltitude;
uniform float far, near;
uniform float frameTimeCounter;
uniform float wetness;
uniform float worldAnimTime;

uniform vec2 pixelSize;
uniform vec2 viewSize;
uniform vec2 taaOffset;

uniform vec3 cameraPosition;
uniform vec3 upDir, upDirView;
uniform vec3 sunDir, sunDirView;
uniform vec3 moonDir, moonDirView;
uniform vec3 lightDir;
uniform vec3 cloudLightDir, cloudLightDirView;

uniform vec4 daytime;

uniform mat4 gbufferModelView, gbufferModelViewInverse;
uniform mat4 gbufferProjection, gbufferProjectionInverse;


/* ------ includes ------*/
#define FUTIL_LINDEPTH
#define FUTIL_D3X3
#define FUTIL_ROT2
#include "/lib/fUtil.glsl"

#include "/lib/util/transforms.glsl"
#include "/lib/atmos/phase.glsl"
#include "/lib/frag/bluenoise.glsl"
#include "/lib/frag/gradnoise.glsl"

#define airmassStepBias 0.33
#include "/lib/atmos/air/const.glsl"
#include "/lib/atmos/air/density.glsl"

#include "/lib/atmos/project.glsl"
#include "/lib/frag/noise.glsl"
#include "/lib/util/bicubic.glsl"

/*
float bluenoiseLookup1D() {     //surprisingly this works less good with taa
    ivec2 xy    = ivec2(gl_FragCoord.xy) & 255;
    uint z      = frameCounter & 7;

    return texelFetch(colortex2, ivec3(xy, z), 0).x;
}*/

#include "/lib/atmos/CloudsCommon.glsl"

/* ------ cloud system function ------ */

vec4 cloudSystem(vec3 Direction, float vDotL, float dither, float lightNoise, vec3 SkyboxColor) {
    vec3 totalScattering    = vec3(0.0);
    float totalTransmittance = 1.0;

    vec3 sunlight       = (worldTime>23000 || worldTime<12900) ? lightColor[0] : lightColor[2];
    vec3 skylight       = lightColor[1];

    float pFade         = saturate(mieCS(vDotL, 0.5));
        pFade           = mix(pFade, vDotL * 0.5 + 0.5, 1.0 / sqrt3);

    float vDotUp        = Direction.y;

    // --- volumetric clouds --- //
    #ifdef cloudVolumeEnabled
    float within    = sstep(eyeAltitude, cloudCumulusAlt - 75.0, cloudCumulusAlt) * (1.0 - sstep(eyeAltitude, cloudCumulusMaxY, cloudCumulusMaxY + 75.0));
    bool isBelowVol = eyeAltitude < cloudCumulusMidY;
    bool visibleVol = Direction.y > 0.0 && isBelowVol || Direction.y < 0.0 && !isBelowVol;

    if (visibleVol || within > 0.0) {

        vec3 bottom     = Direction * ((cloudCumulusAlt - eyeAltitude) * rcp(Direction.y));
        vec3 top        = Direction * ((cloudCumulusMaxY - eyeAltitude) * rcp(Direction.y));

        float airDist   = length(Direction.y < 0.0 ? bottom : top);
            airDist     = min(airDist, cloudVolumeClip);

        vec3 airmass    = getAirmass(vec3(0.0, planetRad + eyeAltitude, 0.0), Direction, airDist, 0.15, 3) * rcp(airDist) * tau;

        if (Direction.y < 0.0 && isBelowVol || Direction.y > 0.0 && !isBelowVol) {
            bottom      = vec3(0.0);
            top         = vec3(0.0);
        }

        vec3 start      = isBelowVol ? bottom : top;
        vec3 end        = isBelowVol ? top : bottom;
            start       = mix(start, gbufferModelViewInverse[3].xyz, within);
            end         = mix(end, Direction * 6e4, within);

        const float baseLength  = cloudCumulusDepth / cloudVolumeSamples;
        float stepLength    = length(end - start) * rcp(float(cloudVolumeSamples));
        float stepCoeff     = stepLength * rcp(baseLength);
            stepCoeff       = 0.45 + clamp(stepCoeff - 1.1, 0.0, 5.0) * 0.5;
            stepCoeff       = mix(stepCoeff, 10.0, sqr(within));

        uint steps          = uint(cloudVolumeSamples * stepCoeff);

        vec3 rStep          = (end - start) * rcp(float(steps));
        vec3 rPos           = rStep * dither + start + cameraPosition;
        float rLength       = length(rStep);

        vec3 scattering     = vec3(0.0);
        float transmittance = 1.0;

        vec3 bouncelight    = vec3(0.6, 1.0, 0.8) * sunlight * rcp(pi * 14.0 * sqrt2) * max0(dot(cloudLightDir, upDir));

        const float sigmaA  = 1.0;
        const float sigmaT  = 0.2;

        for (uint i = 0; i < steps; ++i, rPos += rStep) {
            if (transmittance < cloudTransmittanceThreshold) break;
            if (rPos.y < cloudCumulusAlt || rPos.y > cloudCumulusMaxY) continue;

            float dist  = distance(rPos, cameraPosition);
            if (dist > cloudVolumeClip) continue;

            float density = cloudCumulusShape(rPos);
            if (density <= 0.0) continue;

            float extinction    = density * sigmaT;
            float stepT         = exp(-extinction * rLength);
            float integral      = (1.0 - stepT) * rcp(sigmaT);

            //float airmassMult = 1.0 + sstep(dist / cloudVolumeClip, 0.5, 1.0) * pi; 
            vec3 atmosFade = expf(-max(airScatterMat * airmass.xy * (dist), 0.0));
            //float atmosFade = exp(-max0(dist * 2e-5));
                atmosFade   = mix(atmosFade, vec3(0.0), sqr(linStep(dist / cloudVolumeClip, 0.5, 1.0)));

            if (maxOf(atmosFade) < 1e-4) {
                scattering     += (SkyboxColor * sigmaT) * (integral * transmittance);
                transmittance  *= stepT;

                continue;
            }

            vec3 stepScatter    = vec3(0.0);

            #ifdef cloudVolumeSunlightDither
                float lightOD       = cloudVolumeLightOD(rPos, 6, lightNoise);
            #else
                float lightOD       = cloudVolumeLightOD(rPos, 6);
            #endif
            
            #ifdef cloudVolumeSkylightDither
                float skyOD         = cloudVolumeSkyOD(rPos, 4, lightNoise);
            #else
                float skyOD         = cloudVolumeSkyOD(rPos, 4);
            #endif
            
            //float bounceOD      = cube(1.0 - linStep(rPos.y, cloudCumulusAlt, cloudCumulusAlt + cloudCumulusDepth * 0.3));
            /*
            float powder        = 8.0 * (1.0 - 0.97 * expf(-extinction * 16.0 * powderBias));     //this is loosely based on spectrum
            float anisoPowder   = powder * (1.0 - expf(-max0(lightOD - sigmaT) * powderBias * (1.0 + sigmaT)) * rpi);
                anisoPowder     = mix(anisoPowder, 1.0, pFade);
            */

            #if 1
                const float albedo = 0.86;
                const float scatterMult = 1.0;

                float avgTransmittance  = exp(-((16.0) / sigmaT) * density);
                float bounceEstimate    = estimateEnergy(albedo * (1.0 - avgTransmittance));
                float baseScatter       = albedo * (1.0 - stepT);

                vec3 phaseG         = pow(vec3(0.55, 0.45, 0.95), vec3((1.0 + (lightOD + density * rLength) * sigmaT)));

                float scatterScale  = pow(1.0 + 1.0 * (lightOD) * sigmaT, -1.0 / 0.8) * bounceEstimate;
                float SkyScatterScale = pow(1.0 + 1.0 * skyOD * sigmaT, -1.0 / 0.9) * bounceEstimate;

                stepScatter.x  += baseScatter * cloudPhaseNew(vDotL, phaseG) * scatterScale;
                stepScatter.y  += baseScatter * cloudPhaseNew(vDotUp, phaseG * vec3(1,1,0.5)) * SkyScatterScale;

                //stepScatter.x += baseScatter * scatterScale * sigmaT * integral;

                //stepScatter.z  += bounceOD * powder;

                stepScatter     = (sunlight * stepScatter.x) + (skylight * stepScatter.y) + (bouncelight * stepScatter.z);
                stepScatter     = mix(SkyboxColor * sigmaT * integral, stepScatter, atmosFade);
                scattering     += stepScatter * (transmittance);
            #else
                float powderCoeff   = 8.0;

                float powderLo1 = 1.0 - exp(-extinction *  2.0 * powderCoeff);
                float powderLo2 = 1.0 - exp(-extinction *  4.0 * powderCoeff);
                float powderLo  = (powderLo1 + powderLo2) / 4.0;

                float powderHi1 = 1.0 - exp(-extinction *  5.0 * powderCoeff);
                float powderHi2 = 1.0 - exp(-extinction * 20.0 * powderCoeff);
                float powderHi  = (powderHi1 + powderHi2) / 6.0;

                float powder    = (powderLo + powderHi) * 2.2;
                float anisoPowder = mix(powder, 1.0, pFade);

                vec3 phaseG         = pow(vec3(0.45, 0.45, 0.95), vec3(1.0 + lightOD));

                for (uint j = 0; j < 8; ++j) {
                    float n     = float(j);

                    float td    = sigmaT * pow(0.5, n);
                    float phase = cloudPhase(vDotL, pow(0.5, n), phaseG);

                    stepScatter.x  += expf(-lightOD * td) * phase * td;
                    stepScatter.y  += expf(-skyOD * td) * td;
                }

                stepScatter.xy *= vec2(anisoPowder, powder);

                //stepScatter.z  += bounceOD * powder;

                stepScatter     = (sunlight * stepScatter.x) + (skylight * stepScatter.y);
                stepScatter     = mix(SkyboxColor * sigmaT, stepScatter, atmosFade);
                scattering     += stepScatter * (integral * transmittance);
            #endif

            transmittance  *= stepT;
        }

        transmittance       = linStep(transmittance, cloudTransmittanceThreshold, 1.0);

        totalScattering    += scattering;
        totalTransmittance *= transmittance;
    }
    #endif

    #ifdef cloudCirrusEnabled
    // --- planar cirrus clouds --- //
    bool isBelowPlane   = eyeAltitude < cloudCirrusPlaneY;
    bool visiblePlane   = Direction.y > 0.0 && isBelowPlane || Direction.y < 0.0 && !isBelowPlane;

    if (visiblePlane && (!isBelowPlane || totalTransmittance > 1e-10)) {
        vec3 plane      = Direction * ((cloudCirrusPlaneY - eyeAltitude) * rcp(Direction.y));

        float airDist   = length(plane);
            //airDist     = mix(min(airDist, cloudVolumeClip), 9e4, within);

        vec3 airmass    = getAirmass(vec3(0.0, planetRad + eyeAltitude, 0.0), Direction, airDist, 0.25, 3) * rcp(airDist) * tau;

        vec3 rPos       = plane + cameraPosition;

        const float SigmaT  = 0.006;

        float dist      = distance(rPos, cameraPosition);

        vec3 scattering = vec3(0.0);
        float transmittance = 1.0;

        mat2x3 planarBounds = mat2x3(Direction*((cloudCirrusMaxY-eyeAltitude)/Direction.y) + cameraPosition,
                                     Direction*((cloudCirrusAlt-eyeAltitude)/Direction.y) + cameraPosition);

        float rLength   = distance(planarBounds[0], planarBounds[1]);

        if (dist < cloudCirrusClip) {
            float Density   = cloudCirrusShape(rPos);

            if (Density > 0.0) {
                float extinction    = Density * SigmaT;
                float stepT         = exp(-extinction * rLength);
                float integral      = (1.0 - stepT) * rcp(SigmaT);

                vec3 atmosFade  = expf(-max(airScatterMat * airmass.xy * dist, 0.0));
                    atmosFade   = mix(atmosFade, vec3(0.0), sqr(linStep(dist / cloudCirrusClip, 0.5, 1.0)));

                if (maxOf(atmosFade) < 1e-4) {
                    scattering     += (SkyboxColor * SigmaT) * (integral * transmittance);
                    transmittance  *= stepT;
                } else {
                    float lightOD       = cloudCirrusLightOD(rPos, 5, cloudLightDir) * euler;
                    float skyOD         = cloudCirrusLightOD(rPos, 4, vec3(0.0, 1.0, 0.0)) * euler;
                    /*
                    float powder        = 8.0 * (1.0 - 0.97 * expf(-extinction * 12.0));     //this is loosely based on spectrum
                    float anisoPowder   = mix(powder, 1.0, pFade);

                    vec3 phaseG         = pow(vec3(0.45, 0.45, 0.95), vec3(1.0 + lightOD));

                    for (uint j = 0; j < 6; ++j) {
                        float n     = float(j);

                        float td    = SigmaT * pow(0.5, n);
                        float phase = cloudPhase(vDotL, pow(0.5, n), phaseG);

                        scattering.x   += expf(-lightOD * td) * anisoPowder * phase * td;
                        scattering.y   += expf(-skyOD * td) * powder * td;
                    }

                    scattering      = (sunlight * scattering.x) + (skylight * scattering.y);
                    scattering      = mix(SkyboxColor * SigmaT, scattering, atmosFade);
                    scattering      = scattering * (integral * transmittance);
                    */

                    //vec2 scattering     = vec2(0);

                    const float albedo = 0.87;
                    const float scatterMult = 1.0;
                    float avgTransmittance  = exp(-(12.0 / SigmaT) * Density);
                    float bounceEstimate    = estimateEnergy(albedo * (1.0 - avgTransmittance));
                    float baseScatter       = albedo * (1.0 - stepT);

                    vec3 phaseG         = pow(vec3(0.65, 0.45, 0.95), vec3(1.0 + (lightOD + Density * rLength) * SigmaT) * vec3(1, 1, 1));
                    vec3 phaseGSky      = pow(vec3(0.5, 0.45, 0.6), vec3(1.0 + (skyOD + Density * rLength) * SigmaT));

                    float scatterScale  = pow(1.0 + 1.0 * (lightOD) * SigmaT, -1.0 / 0.5) * bounceEstimate;
                    float SkyScatterScale = pow(1.0 + 1.0 * skyOD * SigmaT, -1.0 / 0.5) * bounceEstimate;

                    scattering.x  += baseScatter * cloudPhaseNew(vDotL, phaseG) * scatterScale;
                    scattering.y  += baseScatter * cloudPhaseNew(Direction.y, phaseGSky) * SkyScatterScale;

                    scattering.rgb    = (sunlight * scattering.x) + (skylight * scattering.y);
                    scattering.rgb    = mix(SkyboxColor * SigmaT * integral, scattering.rgb, atmosFade);

                    transmittance  *= stepT;
                }
            }
        }

        if (isBelowPlane) {
            totalScattering    += scattering * totalTransmittance;
            totalTransmittance *= transmittance;
        } else {
            totalScattering     = totalScattering * transmittance + scattering;
            totalTransmittance *= transmittance;
        }
    }
    #endif

    return vec4(totalScattering, totalTransmittance);
}

/* --- TEMPORAL CHECKERBOARD --- */

#define checkerboardDivider 9
#define ditherPass
#include "/lib/frag/checkerboard.glsl"

void main() {
    cloudCurrentFrame   = vec4(0.0, 0.0, 0.0, 1.0);

    #if (defined cloudVolumeEnabled || defined cloudCirrusEnabled)

    #ifdef cloudTemporalUpscaleEnabled
        const float cLOD    = sqrt(CLOUD_RENDER_LOD)*3.0;
    #else
        const float cLOD    = sqrt(CLOUD_RENDER_LOD);
    #endif

    vec2 cloudCoord = uv * cLOD;

    if (clamp(cloudCoord, -pixelSize * cLOD, 1.0 + pixelSize * cLOD) == cloudCoord) {
        cloudCoord  = saturate(cloudCoord);

        float depth = depthMax3x3(depthtex2, cloudCoord * ResolutionScale, pixelSize * cLOD);

        if (!landMask(depth)) {
            #ifdef cloudTemporalUpscaleEnabled
            int frame       = (frameCounter) % 9;
            ivec2 offset    = temporalOffset9[frame];
            ivec2 pixel     = ivec2(floor(cloudCoord * viewSize * rcp(cLOD/3.0) + offset));
            cloudCoord      = vec2(pixel) / 3.0 / viewSize * cLOD;

            float dither    = ditherBluenoiseCheckerboard(vec2(offset));
            float noise     = ditherGradNoiseCheckerboard(vec2(offset));
            #else
            float dither    = ditherBluenoise();
            float noise     = ditherGradNoiseTemporal();
            #endif

            vec3 viewPos    = screenToViewSpace(vec3(cloudCoord, 1.0), false);
            vec3 viewDir    = normalize(viewPos);
            vec3 scenePos   = viewToSceneSpace(viewPos);
            vec3 worldDir   = normalize(scenePos);

            vec3 skyColor   = textureBicubic(colortex4, projectSky(worldDir, 0)).rgb;

            cloudCurrentFrame = cloudSystem(worldDir, dot(viewDir, cloudLightDirView), dither, noise, skyColor);
        }
    }
    #endif
}