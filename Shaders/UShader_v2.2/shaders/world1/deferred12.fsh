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


/*DRAWBUFFERS:035*/
layout(location = 0) out vec4 sceneColor;
layout(location = 1) out vec4 directLightAlbedo;
layout(location = 2) out vec4 translucentColor;

#include "/lib/head.glsl"
#include "/lib/util/encoders.glsl"

in vec2 uv;

flat in mat3x3 lightColor;

uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D colortex2;
uniform sampler2D colortex3;
uniform sampler2D colortex5;
uniform sampler2D colortex7;
uniform sampler2D colortex12;

uniform sampler2D depthtex0;
uniform sampler2D depthtex2;

uniform float lightFlip;
uniform float sunAngle;
uniform float near, far;

uniform vec2 pixelSize, viewSize;

#define FUTIL_LINDEPTH
#define FUTIL_MAT16
#include "/lib/fUtil.glsl"

vec3 unpackDirectLight(vec4 data){
    vec3 shadows    = decodeRGBE8(vec4(unpack2x8(data.x), unpack2x8(data.y)));

    return shadows;
}

vec4 packReflectionAux(vec3 directLight, vec3 albedo) {
    vec4 lightRGBE  = encodeRGBE8(directLight);
    vec4 albedoRGBE = encodeRGBE8(albedo);

    return vec4(pack2x8(lightRGBE.xy),
                pack2x8(lightRGBE.zw),
                pack2x8(albedoRGBE.xy),
                pack2x8(albedoRGBE.zw));
}

vec2 packDirectLight(vec3 directLight) {
    vec4 lightRGBE  = encodeRGBE8(directLight);

    return vec2(pack2x8(lightRGBE.xy),
                pack2x8(lightRGBE.zw));
}

void main() {
    sceneColor          = stex(colortex0);
    float sceneDepth    = stex(depthtex0).x;

    directLightAlbedo   = stex(colortex3);

    if (landMask(sceneDepth)) {
        vec4 tex1       = stex(colortex1);
        vec4 tex2       = stex(colortex2);
        vec3 sceneNormal = decodeNormal(tex1.xy);

        bool hand   = sceneDepth < stex(depthtex2).x;

        vec3 albedo         = sceneColor.rgb;
        vec3 directLight    = unpackDirectLight(stex(colortex3));

        float ssao          = texture(colortex12, uv).x;
        vec2 aoData         = unpack2x8(tex2.w);
        vec2 lightmaps      = saturate(unpack2x8(tex1.z));

        vec3 directCol      = lightColor[0];

        directLightAlbedo.xy = packDirectLight(directLight * directCol);

            directLight    *= directCol * aoData.x * (ssao);

        //vec3 indirectLight  = lightColor[1] * pow5(lightmaps.y);
        //    indirectLight  += directCol * 0.03 * cube(lightmaps.y);
        //   indirectLight  += vec3(0.3, 0.6, 1.0) * 0.01;
        //    indirectLight  *= ssao * sqr(aoData.x);

        vec3 indirectLight = texture(colortex5, uv).rgb * sqrt(ssao) * aoData.x;

        #ifdef MAT_AO_ENABLED
            indirectLight  *= aoData.y;
        #endif

        int matID           = decodeMatID16(tex2.z);

        float albedoLum = mix(avgOf(sceneColor.rgb), maxOf(sceneColor.rgb), 0.71);
            albedoLum   = saturate(albedoLum * sqrt2);

        float emitterLum = saturate(mix(sqr(albedoLum), sqrt(maxOf(sceneColor.rgb)), albedoLum));
            emitterLum *= (float(matID == 5) + float(matID == 6) * 0.25);

        vec3 emission       = mix(sqr(normalize(albedo)), vec3(1.0), emitterLum) * emitterLum * maxOf(lightColor[2]);
        if (hand) emission *= 0.05;
            //emission        = max(emission, lightColor[3] * pow5(lightmaps.x) * 0.71 * aoData.x * ssao);

        sceneColor.rgb     *= directLight + indirectLight + emission;
        //sceneColor.rgb      = indirectLight;

        //sceneColor.rgb     *= directCol / pi;

        #if DEBUG_VIEW == 3
            sceneColor.rgb      = indirectLight;
            //sceneColor.rgb = stex(colortex7).rgb;
        #endif
        //indirectLuma        = avgOf(indirectLight);
    }

    sceneColor          = clamp16F(sceneColor);
    translucentColor    = vec4(0.0);
}