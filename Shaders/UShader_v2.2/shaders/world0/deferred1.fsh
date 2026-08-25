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

/* RENDERTARGETS: 5,8,9 */
layout(location = 0) out vec4 cloudImage;
layout(location = 1) out vec4 cloudHistory;
layout(location = 2) out vec4 historyData;

#include "/lib/head.glsl"
#include "/lib/util/encoders.glsl"

const bool colortex8Clear   = false;
const bool colortex9Clear   = false;

in vec2 uv;

uniform sampler2D colortex5;
uniform sampler2D colortex8;
uniform sampler2D colortex9;

uniform sampler2D depthtex0;

uniform int frameCounter, WorldTimeChange;

uniform float aspectRatio;
uniform float eyeAltitude;
uniform float frameTimeCounter;
uniform float wetness;
uniform float far, near;

uniform vec2 viewSize, pixelSize;
uniform vec2 taaOffset;

uniform vec4 daytime;

uniform mat4 gbufferProjection, gbufferModelView;
uniform mat4 gbufferProjectionInverse, gbufferModelViewInverse;
uniform mat4 gbufferPreviousProjection, gbufferPreviousModelView;

uniform vec3 cameraPosition, previousCameraPosition;


/* ------ includes ------*/
#define FUTIL_D3X3
#include "/lib/fUtil.glsl"
#include "/lib/util/bicubic.glsl"
#include "/lib/util/transforms.glsl"


/* --- TEMPORAL CHECKERBOARD --- */
#include "/lib/frag/checkerboard.glsl"

vec3 reproject(vec3 sceneSpace) {
    vec3 prevScreenPos = sceneSpace;
    prevScreenPos = transMAD(gbufferPreviousModelView, prevScreenPos);
    prevScreenPos = transMAD(gbufferPreviousProjection, prevScreenPos) * (0.5 / -prevScreenPos.z) + 0.5;

    return prevScreenPos;
}

vec4 sampleCheckerboardSmooth(sampler2D tex, vec2 uv) {
    vec2 pos        = uv * viewSize - 0.5;
    ivec2 pixelPos  = ivec2(pos);

    vec2 weights    = cubeSmooth(fract(pos));

    vec4 resultA    = mix(unpack4x4(texelFetch(tex, pixelPos, 0).a)              , unpack4x4(texelFetch(tex, pixelPos + ivec2(1, 0), 0).a), weights.x);
    vec4 resultB    = mix(unpack4x4(texelFetch(tex, pixelPos + ivec2(0, 1), 0).a), unpack4x4(texelFetch(tex, pixelPos + ivec2(1, 1), 0).a), weights.x);

    return mix(resultA, resultB, weights.y);
}

vec4 textureBicubicCustom(sampler2D sampler, vec2 uv, int coeff) {
	vec2 res = textureSize(sampler, 0) * coeff;

	uv = uv * res - 0.5;

	vec2 f = fract(uv);
	uv -= f;

	vec2 ff = f * f;
	vec4 w0;
	vec4 w1;
	w0.xz = 1 - f; w0.xz *= w0.xz * w0.xz;
	w1.yw = ff * f;
	w1.xz = 3 * w1.yw + 4 - 6 * ff;
	w0.yw = 6 - w1.xz - w1.yw - w0.xz;

	vec4 s = w0 + w1;
	vec4 c = uv.xxyy + vec2(-0.5, 1.5).xyxy + w1 / s;
	c /= res.xxyy;

	vec2 m = s.xz / (s.xz + s.yw);
	return mix(
		mix(textureLod(sampler, c.yw, 0), textureLod(sampler, c.xw, 0), m.x),
		mix(textureLod(sampler, c.yz, 0), textureLod(sampler, c.xz, 0), m.x),
		m.y);
}

float depthMin3x3(sampler2D depthtex, vec2 uv, vec2 px) {
    float tl    = texture(depthtex, uv + vec2(-px.x, -px.y)).x;
    float tc    = texture(depthtex, uv + vec2(0.0, -px.y)).x;
    float tr    = texture(depthtex, uv + vec2(px.x, -px.y)).x;
    float tmin  = min(tl, min(tc, tr));

    float ml    = texture(depthtex, uv + vec2(-px.x, 0.0)).x;
    float mc    = texture(depthtex, uv).x;
    float mr    = texture(depthtex, uv + vec2(px.x, 0.0)).x;
    float mmin  = min(ml, min(mc, mr));

    float bl    = texture(depthtex, uv + vec2(-px.x, px.y)).x;
    float bc    = texture(depthtex, uv + vec2(0.0, px.y)).x;
    float br    = texture(depthtex, uv + vec2(px.x, px.y)).x;
    float bmin  = min(bl, min(bc, br));

    return min(tmin, min(mmin, bmin));
}

vec4 textureCatmullRom(sampler2D tex, vec2 uv) {   //~5fps
    vec2 res    = textureSize(tex, 0);

    vec2 coord  = uv*res;
    vec2 coord1 = floor(coord - 0.5) + 0.5;

    vec2 f      = coord-coord1;

    vec2 w0     = f * (-0.5 + f * (1.0 - (0.5 * f)));
    vec2 w1     = 1.0 + sqr(f) * (-2.5 + (1.5 * f));
    vec2 w2     = f * (0.5 + f * (2.0 - (1.5 * f)));
    vec2 w3     = sqr(f) * (-0.5 + (0.5 * f));

    vec2 w12    = w1+w2;
    vec2 delta12 = w2 * rcp(w12);

    vec2 uv0    = (coord1 - vec2(1.0)) * pixelSize;
    vec2 uv3    = (coord1 + vec2(1.0)) * pixelSize;
    vec2 uv12   = (coord1 + delta12) * pixelSize;

    vec4 col    = vec4(0.0);
        col    += textureLod(tex, vec2(uv0.x, uv0.y), 0)*w0.x*w0.y;
        col    += textureLod(tex, vec2(uv12.x, uv0.y), 0)*w12.x*w0.y;
        col    += textureLod(tex, vec2(uv3.x, uv0.y), 0)*w3.x*w0.y;

        col    += textureLod(tex, vec2(uv0.x, uv12.y), 0)*w0.x*w12.y;
        col    += textureLod(tex, vec2(uv12.x, uv12.y), 0)*w12.x*w12.y;
        col    += textureLod(tex, vec2(uv3.x, uv12.y), 0)*w3.x*w12.y;

        col    += textureLod(tex, vec2(uv0.x, uv3.y), 0)*w0.x*w3.y;
        col    += textureLod(tex, vec2(uv12.x, uv3.y), 0)*w12.x*w3.y;
        col    += textureLod(tex, vec2(uv3.x, uv3.y), 0)*w3.x*w3.y;

    return clamp(col, 0.0, 65535.0);
}

void main() {
    cloudImage      = stex(colortex5);
    cloudHistory    = vec4(0.0, 0.0, 0.0, 1.0);
    historyData     = stex(colortex9);

    const float cLOD    = sqrt(CLOUD_RENDER_LOD);

    vec2 cloudCoord  = uv * cLOD;

    float d     = depthMax3x3(depthtex0, cloudCoord * ResolutionScale, pixelSize*cLOD);

    //cloudCoord /= ResolutionScale;

    if (clamp(cloudCoord, -pixelSize, 1.0 + pixelSize) == cloudCoord) {
        cloudCoord      = saturate(cloudCoord);
        vec3 position   = screenToViewSpace(vec3(cloudCoord, 1.0), false);
            position    = viewToSceneSpace(position);
        //cloudCoord     *= ResolutionScale;
        
        float sceneDepth    = texelFetch(depthtex0, ivec2(cloudCoord * viewSize * ResolutionScale), 0).x;

        vec3 reprojection   = reproject(position);

        bool offscreen  = saturate(reprojection.xy) != reprojection.xy;

        #ifdef cloudTemporalUpscaleEnabled
            int frame       = (frameCounter) % 9;
            ivec2 offset    = temporalOffset9[frame];


            ivec2 pixels    = ivec2(uv * viewSize);
            ivec2 CurrentPixelUV = ivec2(floor(pixels / 3)*3) + offset;

            
            bool currentPixel  = (mod(pixels, 3) - offset) == ivec2(0);

            vec2 historyPos     = clamp(reprojection.xy, -pixelSize, 1.0 + pixelSize) * rcp(cLOD);

            vec4 historyColor   = clamp16F(textureCatmullRom(colortex8, historyPos));
            vec2 TemporalData   = clamp16F(textureCatmullRom(colortex9, historyPos)).yz;   //Land Mask, Pixel Age

            vec2 currentPos     = saturate(cloudCoord) * rcp(cLOD * 3.0) - offset * rcp(3.0) * pixelSize;
            vec4 currentColor   = texelFetch(colortex5, ivec2(currentPos * viewSize), 0);
            vec4 currentColorSmooth = clamp16F(textureCatmullRom(colortex5, currentPos));

            //vec2 skylightIntensity = textureBicubicCustom(colortex14, currentPos, 1).xy;

            bool Discoccluded   = !landMask(sceneDepth) && TemporalData.x < 1.0-1e-6;

            bool DiscardHistory = offscreen || Discoccluded || WorldTimeChange != 0;

            vec4 FinalColor     = currentColorSmooth;

            float PixelAge      = TemporalData.y * 256.0;

            if (DiscardHistory) {
                TemporalData.y = 0.0;
            } else {
                float Samples   = max(PixelAge - 9, 1.0);

                float AccumulationWeight = max(1.0 / Samples, rpi);

                AccumulationWeight = 1.0 - AccumulationWeight;

                vec2 PixelDelta     = 1.0 - abs(2.0 * fract(historyPos * viewSize) - 1.0);

                AccumulationWeight *= sqrt(PixelDelta.x * PixelDelta.y) * 0.75 + 0.25;

                //AccumulationWeight *= 1.0 / (1.0 + )

                AccumulationWeight = 1.0 - AccumulationWeight;

                AccumulationWeight *= float(currentPixel);

                //if (!currentPixel && (PixelAge - 9) < 1) currentColor = currentColorSmooth;

                FinalColor  = mix(historyColor, currentColor, AccumulationWeight);

                TemporalData.y = saturate((PixelAge + 1) / 256.0);
            }

            cloudImage  = FinalColor;
            //cloudImage.rgb += (vec3(0.45, 0.43, 1.0) * max(1.5, skylightIntensity.y * 64.0 * 6.0)) * skylightIntensity.x * pi * isLightningSmooth;
            cloudHistory = FinalColor;

            TemporalData.x  = float(!landMask(sceneDepth));

            historyData.yz = TemporalData;

        #else
            ivec2 pixels    = ivec2(uv * viewSize);

            vec2 historyPos     = clamp(reprojection.xy, -pixelSize, 1.0 + pixelSize) * rcp(cLOD);

            vec4 historyColor   = clamp16F(texture(colortex8, historyPos));

            vec4 currentColor   = texelFetch(colortex5, pixels, 0);

            //vec2 skylightIntensity = textureBicubicCustom(colortex14, uv, 1).xy;

            float reprojectionDistance = distance(reprojection.xy, cloudCoord.xy);

            float frames        = offscreen || reprojectionDistance > 0.16 ? 1.0 : sampleCheckerboardSmooth(colortex9, historyPos).x * 15.0 + 1.0;

            float accumulationWeight = 1.0 - sqr(rcp(1.0 + reprojectionDistance * 128.0)) * 0.75;
                accumulationWeight  = max(accumulationWeight, (1.0 / (max(frames, 1.0))));
                //accumulationWeight  = max(accumulationWeight, isLightningSmooth);

            if (clamp16F(historyColor) != historyColor) historyColor = currentColor;

            vec4 accumulated    = historyColor;

                accumulated     = mix(accumulated, currentColor, accumulationWeight);

            if (landMask(d)) {
                cloudImage  = vec4(0.0, 0.0, 0.0, 1.0);
                cloudHistory = vec4(0.0, 0.0, 0.0, 1.0);
            }

            cloudImage  = accumulated;
            //cloudImage.rgb  = vec3(frames);
            //cloudImage.rgb += (vec3(0.45, 0.43, 1.0) * max(1.5, skylightIntensity.y * 64.0 * 6.0)) * skylightIntensity.x * pi * isLightningSmooth;
            cloudHistory = accumulated;

            historyData.a = pack4x4(vec4(vec2(saturate(frames / 15.0), 0), unpack4x4(historyData.a).zw));
        #endif

        /*
        reprojection   *= ResolutionScale;

        int frame       = (frameCounter) % 9;
        ivec2 offset    = temporalOffset9[frame];

        ivec2 pixels    = ivec2(uv * viewSize);

        bool currentPixel  = (mod(pixels, 3) - offset) == ivec2(0);

        vec2 historyPos     = clamp(reprojection.xy, -pixelSize, 1.0 + pixelSize) * rcp(cLOD);

        vec4 historyColor   = clamp16F(texture(colortex8, historyPos));
        vec4 checkerboard   = sampleCheckerboardSmooth(colortex9, historyPos);

        vec2 currentPos     = saturate(cloudCoord) * rcp(cLOD * 3.0) - offset * rcp(3.0) * pixelSize;
        vec4 currentColor   = texelFetch(colortex5, ivec2(currentPos * viewSize), 0);
        vec4 currentColorSmooth = textureBicubicCustom(colortex5, currentPos, 3);

        vec4 accumulated    = historyColor;

        float reprojectionDistance = distance(reprojection.xy, cloudCoord.xy) / ResolutionScale;

        float accumulationWeight = 1.0 - sqr(rcp(1.0 + reprojectionDistance * 128.0)) * 0.5;
            accumulationWeight  = max(accumulationWeight, float(checkerboard.y < 0.75));

        if (clamp16F(historyColor) != historyColor) historyColor = currentColorSmooth;

        if (currentPixel){
            checkerboard.x  = landMask(sceneDepth) ? 0.0 : 1.0;
            if (checkerboard.y < 0.75) accumulated = currentColor;
            else accumulated = mix(accumulated, currentColor, accumulationWeight);
        } else if (offscreen || checkerboard.x < 0.5 || reprojectionDistance > 0.16) {
            accumulated = currentColorSmooth;
        }

        checkerboard.y  = landMask(sceneDepth) ? 0.0 : 1.0;
        
        if (landMask(d)) {
            cloudImage  = vec4(0.0, 0.0, 0.0, 1.0);
            cloudHistory = vec4(0.0, 0.0, 0.0, 1.0);
            checkerboard.xy = vec2(0.0);
        }

        cloudImage  = accumulated;
        cloudHistory = accumulated;

        historyData.a = pack4x4(vec4(checkerboard.xy, unpack4x4(historyData.a).zw));
        */
    }

    cloudImage      = clamp16F(cloudImage);
    cloudHistory    = clamp16F(cloudHistory);
}