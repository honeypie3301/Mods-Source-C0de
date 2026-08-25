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

#define shadowmap_bias 0.85

float calculateWarp(in vec2 x) {
    return length(x * 1.169) * shadowmap_bias + (1.0 - shadowmap_bias);
}

vec2 shadowmapWarp(vec2 uv, out float distortion) {
    distortion = calculateWarp(uv);
    return uv/distortion;
}
vec2 shadowmapWarp(vec2 uv) {
    float distortion = calculateWarp(uv);
    return uv/distortion;
}