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

flat in vec3 airIlluminance;
flat in mat2x3 celestialLight;
flat in mat2x3 airIllumMod;

flat in vec3 sunDir;
flat in vec3 moonDir;

uniform float aspectRatio;
uniform float eyeAltitude, RMoonPhaseOcclusion;

uniform vec2 viewSize, pixelSize;

uniform vec4 daytime;

uniform mat4 gbufferModelView, gbufferModelViewInverse;
uniform mat4 gbufferProjection, gbufferProjectionInverse;


/* ------ includes ------ */
#include "/lib/atmos/phase.glsl"
#include "/lib/atmos/air/atmosphere.glsl"
#include "/lib/atmos/project.glsl"


void main() {
    skyboxData      = vec4(0, 0, 0, 1);

    vec2 projectionUV   = fract(uv * vec2(1.0, 3.0));

    uint index      = uint(floor(uv.y * 3.0));

    if (index == 0) {
        // Clear Sky Capture
        vec3 direction   = unprojectSky(projectionUV);
            skyboxData.rgb  = atmosphericScattering(direction, mat2x3(sunDir, moonDir), airIlluminance, airIllumMod, celestialLight);
    } else if (index == 1) {
        #ifdef airTransmittanceHQ
            vec3 direction  = unprojectSky(projectionUV);
            skyboxData.rgb  = getAirTransmittance(vec3(0.0, planetRad * mix(0.9997, 1.0, saturate(sqrt(max0(sunDir.y * tau)))) + eyeAltitude, 0.0), direction);
        #endif
    }

    skyboxData      = clamp16F(skyboxData);
}