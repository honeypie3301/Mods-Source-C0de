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

#ifdef cloudPass
    const float eyeAltitude = 800.0;
    #define airmassStepBias 0.33
#else
    uniform float eyeAltitude;
    #define airmassStepBias 0.4
#endif

uniform float wetness, RMoonPhaseOcclusion;

uniform vec3 sunDir;
uniform vec3 moonDir;

uniform vec4 daytime;

uniform sampler2D gaux1;

flat out mat4x3 lightColor;

#include "/lib/atmos/air/const.glsl"
#include "/lib/atmos/air/density.glsl"
#include "/lib/atmos/project.glsl"

void getColorPalette() {
    vec3 airEyePos = vec3(0.0, planetRad + eyeAltitude, 0.0);

    lightColor[0]  = getAirTransmittance(airEyePos, sunDir, 6) * sunIllum * sunlightIllum;

    #if !(defined cloudPass || defined skyboxPass)
        lightColor[0] *= (1.0 - wetness * 0.95);
    #endif
    
    #ifdef fogPass
        lightColor[1]  = texture(gaux1, projectSky(vec3(0.0, 1.0, 0.0), 0)).rgb * skylightIllum;
    #elif (defined cloudPass)
        lightColor[1]  = texture(gaux1, projectSky(vec3(0.0, 1.0, 0.0), 0)).rgb * sqrt3;
    #else
        lightColor[1]  = texture(gaux1, projectSky(vec3(0.0, 1.0, 0.0), 0)).rgb * skylightIllum;
    #endif

    lightColor[1] *= vec3(skylightRedMult, skylightGreenMult, skylightBlueMult);

    lightColor[2]  = getAirTransmittance(airEyePos, moonDir, 6) * moonIllum * moonlightIllum * RMoonPhaseOcclusion;
        
    #ifndef skipBlocklight
        lightColor[3]  = RColor_Lightmap * blocklightIllum * blocklightBaseMult;
    #endif
}