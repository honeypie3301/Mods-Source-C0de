/* RENDERTARGETS: 5,7,10,11 */
layout(location = 0) out vec3 IndirectLight;
layout(location = 1) out vec4 IndirectHistory;
layout(location = 2) out vec4 HistoryGBuffer;
layout(location = 3) out vec4 GBuffer;

#include "/lib/head.glsl"
#include "/lib/util/encoders.glsl"


in vec2 uv;

#ifndef DIM
flat in vec3 BlocklightColor;
#else
flat in vec3 BlocklightColor, AmbientColor;
#endif

uniform sampler2D colortex1;
uniform sampler2D colortex4;
uniform sampler2D colortex5;
uniform sampler2D colortex7;
uniform sampler2D colortex10;

uniform sampler2D depthtex0;
uniform sampler2D depthtex2;

uniform sampler2D noisetex;

uniform int frameCounter;

uniform float near, far;

uniform vec2 taaOffset;
uniform vec2 pixelSize, viewSize;

uniform mat4 gbufferModelView, gbufferModelViewInverse;
uniform mat4 gbufferProjection, gbufferProjectionInverse;

/* ------ includes ------*/
#define FUTIL_LINDEPTH
#include "/lib/fUtil.glsl"
#include "/lib/util/transforms.glsl"
#include "/lib/frag/bluenoise.glsl"
#include "/lib/brdf/fresnel.glsl"
#include "/lib/brdf/hammon.glsl"
#include "/lib/atmos/project.glsl"


/* ------ DITHER ------ */
#define HASHSCALE1 .1031
float hash12(vec2 x) {
    vec3 x3  = fract(vec3(x.xyx) * HASHSCALE1);
        x3  += dot(x3, x3.yzx + 19.19);
    return fract((x3.x + x3.y) * x3.z);
}

#define HASHSCALE3 vec3(.1031, .1030, .0973)
vec2 hash22(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * HASHSCALE3);
    p3 += dot(p3, p3.yzx + 19.19);
    return fract((p3.xx + p3.yz) * p3.zy);
}
float ditherHashNoise() {
    float noise     = hash12(gl_FragCoord.xy);
        noise   = fract(noise + (frameCounter * 7.0 * rcp(255.0)) *0);

    return noise;
}
float ditherBluenoise2() {
    ivec2 uv = ivec2(fract(gl_FragCoord.xy/256.0)*256.0);
    float noise = texelFetch(noisetex, uv, 0).a;

        noise   = fract(noise + (frameCounter * 7.0 * rcp(255.0)));

    return noise;
}


vec3 genUnitVector(vec2 p) {
    p.x *= tau; p.y = p.y * 2.0 - 1.0;
    return vec3(sincos(p.x) * sqrt(1.0 - p.y * p.y), p.y);
}
vec3 GenerateCosineVectorSafe(vec3 vector, vec2 xy) {
	vec3 cosineVector = vector + genUnitVector(xy);
	float lenSq = dot(cosineVector, cosineVector);
	return lenSq > 0.0 ? cosineVector * inversesqrt(lenSq) : vector;
}

#if 1

vec3 screenspaceRT(vec3 position, vec3 direction, float noise) {
    const uint maxSteps     = 10;
    const float stepSize    = sqrPi / float(maxSteps);

    vec3 stepVector         = direction * stepSize;

    vec3 endPosition        = position + stepVector * maxSteps;
    vec3 endScreenPosition  = viewToScreenSpace(endPosition);

    vec2 maxPosXY           = max(abs(endScreenPosition.xy * 2.0 - 1.0), vec2(1.0));
    float stepMult          = minOf(vec2(1.0) / maxPosXY);
        stepVector         *= stepMult;

    // closest texel iteration
    vec3 samplePos          = position;
    
        samplePos          += stepVector / 6.0;
    vec3 screenPos          = viewToScreenSpace(samplePos);

    if (saturate(screenPos.xy) == screenPos.xy) {
        float depthSample   = texelFetch(depthtex0, ivec2(screenPos.xy * viewSize * ResolutionScale), 0).x;
        float linearSample  = depthLinear(depthSample);
        float currentDepth  = depthLinear(screenPos.z);

        if (linearSample < currentDepth) {
            float dist      = abs(linearSample - currentDepth) / currentDepth;
            if (dist <= 0.1) return vec3(screenPos.xy, depthSample);
        }
    }
    
        samplePos          += stepVector * noise;

    for (uint i = 0; i < maxSteps; ++i) {
        vec3 screenPos      = viewToScreenSpace(samplePos);
            samplePos      += stepVector;
        if (saturate(screenPos.xy) != screenPos.xy) break;

        float depthSample   = texelFetch(depthtex0, ivec2(screenPos.xy * viewSize * ResolutionScale), 0).x;
        float linearSample  = depthLinear(depthSample);
        float currentDepth  = depthLinear(screenPos.z);

        if (linearSample < currentDepth) {
            float dist      = abs(linearSample - currentDepth) / currentDepth;
            if (dist <= 0.1) return vec3(screenPos.xy, depthSample);
        }
    }

    return vec3(1.1);
}

#else

vec3 screenspaceRT(vec3 position, vec3 direction, float noise) {
    const uint maxSteps     = 16;

  	float rayLength = ((position.z + direction.z * far * sqrt3) > -sqrt3 * near) ?
                      (-sqrt3 * near - position.z) / direction.z : far * sqrt3;

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
            if (dist <= 0.1) return vec3(screenPos.xy, depthSample);
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
            if (dist <= 0.1) return vec3(screenPos.xy, depthSample);
        }

        screenPos      += screenVector;
    }

    return vec3(1.1);
}

#endif

vec3 RaytraceAO(vec3 viewPos, vec3 sceneNormal, float Occlusion, vec2 dither) {
    vec3 viewNormal     = mat3(gbufferModelView) * sceneNormal;

    vec3 radiance   = vec3(0.0);

    const float a1 = 1.0 / rho;
    const float a2 = a1 * a1;

    vec2 quasirandomCurr = 0.5 + fract(vec2(a1, a2) * frameCounter + 0.5);

    vec2 noiseCurr      = hash22(gl_FragCoord.xy + frameCounter);

    Occlusion = cube(Occlusion);

    for (uint i = 0; i < RTAO_SPP; ++i) {
        ++quasirandomCurr;
        noiseCurr      += hash22(vec2(gl_FragCoord.xy + vec2(cos(quasirandomCurr.x), sin(quasirandomCurr.y))));

        vec2 vectorXY   = fract(sqrt(2.0) * quasirandomCurr + noiseCurr);

        vec3 rayDirection   = GenerateCosineVectorSafe(sceneNormal, vectorXY);
            //rayDirection    = mix(rayDirection, vec3(0.0, 1.0, 0.0), 0.5);
            rayDirection    = normalize(mat3(gbufferModelView) * rayDirection);

        if (dot(viewNormal, rayDirection) < 0.0) rayDirection = -rayDirection;

        vec3 hitPosition    = saturate(screenspaceRT(viewPos, rayDirection, dither.y));

        float brdf          = clamp(diffuseHammon(viewNormal, -normalize(viewPos), rayDirection, 1.0) / saturate(dot(rayDirection, viewNormal)/pi), 0.0, halfPi);

        if (hitPosition.z >= 1.0) {
            vec3 worldDir   = mat3(gbufferModelViewInverse) * rayDirection;

#ifndef DIM
            radiance       += texture(colortex4, projectSky(worldDir, 2)).rgb * brdf * Occlusion;
#else
            radiance       += AmbientColor * brdf * Occlusion;
#endif

        } else {
            radiance       += texture(colortex5, hitPosition.xy * ResolutionScale).rgb * brdf;
        }
    }

    radiance /= RTAO_SPP;

    return radiance;
}

uniform vec3 cameraPosition, previousCameraPosition;
uniform mat4 gbufferPreviousProjection, gbufferPreviousModelView;

/* ------ reprojection ----- */
vec3 reproject(vec3 sceneSpace, bool hand) {
    vec3 prevScreenPos = hand ? vec3(0.0) : cameraPosition - previousCameraPosition;
    prevScreenPos = sceneSpace + prevScreenPos;
    prevScreenPos = transMAD(gbufferPreviousModelView, prevScreenPos);
    prevScreenPos = transMAD(gbufferPreviousProjection, prevScreenPos) * (0.5 / -prevScreenPos.z) + 0.5;
    //prevScreenPos.xy += previousTaaOffset * 0.5 * pixelSize;

    return prevScreenPos;
}

#define maxFrames 256.0


#include "/lib/offset/gauss.glsl"

vec3 GetBlocklightColor(vec3 Color, float Lightmap) {
    float Exponent = mix(2.0, 0.8, sqrt(Lightmap));
    vec3 ColorGradient = pow(Color / maxOf(Color), vec3(Exponent)) * maxOf(Color);

    return ColorGradient * pow5(Lightmap);
}

void main() {
    IndirectLight   = vec3(0);
    IndirectHistory = vec4(0);

    vec2 lowresUV       = uv;
    ivec2 pixelPos      = ivec2(floor(uv * viewSize));
    float sceneDepth    = texelFetch(depthtex0, pixelPos, 0).x;

    GBuffer             = vec4(0,0,1,1);
    HistoryGBuffer = vec4(1);

    if (landMask(sceneDepth) && saturate(lowresUV) == lowresUV) {
        vec2 uv     = saturate(lowresUV);

        vec3 viewPos    = screenToViewSpace(vec3(uv / ResolutionScale, sceneDepth), true);
        vec3 viewDir    = -normalize(viewPos);

        vec4 tex1       = texelFetch(colortex1, pixelPos, 0);
        vec3 sceneNormal = decodeNormal(tex1.xy);
        vec2 lightmaps  = saturate(unpack2x8(tex1.z));

        #ifdef DIM
            lightmaps.y = 1.0;
        #endif

        vec3 CurrentLight   = RaytraceAO(viewPos, sceneNormal, lightmaps.y, vec2(ditherBluenoise2(), ditherHashNoise()));

        vec3 scenePos   = viewToSceneSpace(viewPos);

        bool hand       = sceneDepth < texelFetch(depthtex2, pixelPos, 0).x;

        float currentDistance   = length(scenePos);

        vec3 reprojection   = reproject(scenePos, false);
        bool offscreen      = saturate(reprojection.xy) != reprojection.xy;

        reprojection.xy *= ResolutionScale;

        float historyDistance = texture(colortex10, reprojection.xy).x;
        HistoryGBuffer.x = currentDistance;

        vec3 cameraMovement = mat3(gbufferModelView) * (cameraPosition - previousCameraPosition);

        GBuffer             = vec4(sceneNormal * 0.5 + 0.5, sqrt(depthLinear(sceneDepth)));

        if (offscreen) {
            IndirectHistory = vec4(CurrentLight, 1.0);
        } else {
            vec4 PreviousLight  = vec4(0);

            // Sample History
            ivec2 repPixel  = ivec2(floor(reprojection.xy * viewSize - vec2(0.5)));
            vec2 subpix     = fract(reprojection.xy * viewSize - vec2(0.5) - repPixel);

            const ivec2 offset[4] = ivec2[4](
                ivec2(0, 0),
                ivec2(1, 0),
                ivec2(0, 1),
                ivec2(1, 1)
            );

            float weight[4]     = float[4](
                (1.0 - subpix.x) * (1.0 - subpix.y),
                subpix.x         * (1.0 - subpix.y),
                (1.0 - subpix.x) * subpix.y,
                subpix.x         * subpix.y
            );

            float sumWeight     = 0.0;

            
            for (uint i = 0; i < 4; ++i) {
                ivec2 UV            = repPixel + offset[i];

                float depthDelta    = distance((texelFetch(colortex10, UV, 0).x), currentDistance) - abs(cameraMovement.z);
                bool depthRejection = (depthDelta / abs(currentDistance)) < 0.1;

                if (depthRejection) {
                    PreviousLight  += clamp16F(texelFetch(colortex7, UV, 0)) * weight[i];
                    sumWeight      += weight[i];
                }
            }
            

            /*
            for (uint i = 0; i < 25; ++i) {
                ivec2 UV            = repPixel + kernelO_5x5[i];

                float depthDelta    = distance((texelFetch(colortex10, UV, 0).a), currentDistance) - abs(cameraMovement.z);
                bool depthRejection = (depthDelta / abs(currentDistance)) < 0.1;

                if (depthRejection) {
                    PreviousLight  += clamp16F(texelFetch(colortex7, UV, 0)) * kernelW_5x5[i];
                    sumWeight      += kernelW_5x5[1];
                }
            }*/

            if (sumWeight > 1e-3) {
                PreviousLight      /= sumWeight;

                float frames        = min(PreviousLight.a + 1.0, maxFrames);
                float alphaColor    = saturate(max(0.025, 1.0 / frames));

                IndirectLight       = mix(PreviousLight.rgb, CurrentLight, alphaColor);
                IndirectHistory     = vec4(IndirectLight, frames);
            } else {
                IndirectHistory     = vec4(CurrentLight, 1.0);
            }
        }


        IndirectLight = IndirectHistory.rgb;

        IndirectLight += GetBlocklightColor(BlocklightColor, lightmaps.x) * 0.71;
    }

    IndirectLight = clamp16F(IndirectLight.rgb);
    IndirectHistory = clamp16F(IndirectHistory);
}