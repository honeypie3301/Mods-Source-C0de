#version 400 compatibility
/* RENDERTARGETS: 5 */
layout(location = 0) out vec4 indirectCurrent;

#include "/lib/head.glsl"
#include "/lib/util/encoders.glsl"

in vec2 uv;

uniform sampler2D colortex3;
uniform sampler2D colortex4;
uniform sampler2D colortex5;
uniform sampler2D colortex7;
uniform sampler2D colortex11;

uniform sampler2D depthtex0;

uniform sampler2D noisetex;

uniform int frameCounter;

uniform float far, near;

uniform vec2 viewSize;

#include "/lib/frag/bluenoise.glsl"

#define colorSampler colortex5
#define gbufferSampler colortex11

#define colorHistorySampler colortex7

/* ------ ATROUS ------ */

#include "/lib/offset/gauss.glsl"

ivec2 clampTexelPos(ivec2 pos) {
    return clamp(pos, ivec2(0.0), ivec2(viewSize));
}

float computeVariance(sampler2D tex, ivec2 pos) {
    float sumMsqr   = 0.0;
    float sumMean   = 0.0;

    for (int i = 0; i<9; i++) {
        ivec2 deltaPos     = kernelO_3x3[i];

        vec3 col    = texelFetch(tex, clampTexelPos(pos + deltaPos), 0).rgb;
        float lum   = getLuma(col);

        sumMsqr    += sqr(lum);
        sumMean    += lum;
    }
    sumMsqr  /= 9.0;
    sumMean  /= 9.0;

    return sqrt(abs(sumMsqr - sqr(sumMean))) / max(sumMean, 1e-20);
}


void main() {
    indirectCurrent = clamp16F(stex(colorSampler));
    indirectCurrent.a = computeVariance(colorSampler, ivec2(floor(uv * viewSize))) * max(1.0, 4.0 / stex(colorHistorySampler).a);
}