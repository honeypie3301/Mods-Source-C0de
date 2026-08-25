/* ------ functions ------ */
#define cloudVolumeSamples 40       //[20 30 40 50 60 70 80 90 100]
#define cloudTransmittanceThreshold 0.05
#define cloudVolumeClip 3e4
#define cloudCumulusAlt 350.0       //[300.0 400.0 500.0 600.0 800.0 1000.0 1200.0 1400.0]
#define cloudCumulusDepth 650.0    //[1000.0 1200.0 1400.0 1600.0 1800.0 2000.0 2200.0 2400.0 2600.0 2800.0 3000.0]
#define cloudCumulusScaleMult 1.0   //[0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5]
#define cloudCumulusCoverageBias 0.0    //[-0.5 -0.45 -0.4 -0.35 -0.3 -0.25 -0.2 -0.15 -0.1 -0.05 0.0 0.02 0.04 0.06 0.08 0.1 0.12 0.14 0.16 0.18 0.2]

const float cloudCumulusMaxY    = cloudCumulusAlt + cloudCumulusDepth;
const float cloudCumulusMidY    = cloudCumulusAlt + cloudCumulusDepth * 0.5;
const float cloudCumulusScale   = 0.0028* cloudCumulusScaleMult * (350.0 / cloudCumulusAlt);

#ifdef freezeAtmosAnim
    const float cloudTime   = float(atmosAnimOffset) * 0.003;
#else
    #ifdef volumeWorldTimeAnim
        float cloudTime     = worldAnimTime * 1.8;
    #else
        float cloudTime     = frameTimeCounter * 0.003;
    #endif
#endif

uniform vec3 volumeCloudData;

const float phaseConst  = 1.0 / (tau);

float estimateEnergy(float ratio) {
    return ratio / (1.0 - ratio);
}


float mieCloud(float cosTheta, float g) {
    float sqrG  = sqr(g);
    float a     = (1.0 - sqrG) * rcp(2.0 + sqrG);
    float b     = (1.0 + sqr(cosTheta)) * rcp((-2.0 * (g * cosTheta)) + 1.0 + sqrG);

    return max((1.5 * (a * b)) + (g * cosTheta), 0.0) * phaseConst;
}

float cloudPhase(float cosTheta, float g, vec3 gMult) {
    float x = mieCloud(cosTheta, gMult.x * g);
    float y = mieCloud(cosTheta, -gMult.y * g) * volumeCloudData.z;
    float z = mieHG(cosTheta, gMult.z * g);

    return mix(mix(x, y, 0.25), z, 0.15);    //i assume this is more energy conserving than summing them
}
float cloudSkyPhase(float cosTheta, float g, vec3 gMult) {
    float x = mieHG(cosTheta, gMult.x * g);
    float y = mieCloud(cosTheta, -gMult.y * g) * volumeCloudData.z;
    //float z = mieCloud(cosTheta, gMult.z * g);

    return mix(x, y, 0.19);    //i assume this is more energy conserving than summing them
}

float cloudPhaseNew(float cosTheta, vec3 asymmetry) {
    float x = mieHG(cosTheta, asymmetry.x);
    float y = mieHG(cosTheta, -asymmetry.y) * volumeCloudData.z;
    float z = mieCS(cosTheta, asymmetry.z);

    return 0.7 * x + 0.2 * y + 0.1 * z;
}
float cloudPhaseSky(float cosTheta, vec3 asymmetry) {
    float x = mieHG(cosTheta, asymmetry.x);
    float y = mieHG(cosTheta, -asymmetry.y) * volumeCloudData.z;

    return 0.75 * x + 0.25 * y;
}


vec3 curl3D(vec3 pos) {
    return texture(depthtex1, fract(pos)).xyz * 2.0 - 1.0;
}

vec2 noise2DCubic(sampler2D tex, vec2 pos) {
        pos        *= 256.0;
    ivec2 location  = ivec2(floor(pos));

    vec2 samples[4]    = vec2[4](
        texelFetch(tex, location                 & 255, 0).xy, texelFetch(tex, (location + ivec2(1, 0)) & 255, 0).xy,
        texelFetch(tex, (location + ivec2(0, 1)) & 255, 0).xy, texelFetch(tex, (location + ivec2(1, 1)) & 255, 0).xy
    );

    vec2 weights    = cubeSmooth(fract(pos));


    return mix(
        mix(samples[0], samples[1], weights.x),
        mix(samples[2], samples[3], weights.x), weights.y
    );
}

float noisePerlinWorleyCubic(sampler2D tex, vec2 pos) {
        pos        *= 256.0;
    ivec2 location  = ivec2(floor(pos));

    float samples[4]    = float[4](
        texelFetch(tex, location                 & 255, 0).z, texelFetch(tex, (location + ivec2(1, 0)) & 255, 0).z,
        texelFetch(tex, (location + ivec2(0, 1)) & 255, 0).z, texelFetch(tex, (location + ivec2(1, 1)) & 255, 0).z
    );

    vec2 weights    = cubeSmooth(fract(pos));


    return mix(
        mix(samples[0], samples[1], weights.x),
        mix(samples[2], samples[3], weights.x), weights.y
    );
}

float cloudCumulusShape(vec3 pos) {
    float altitude  = pos.y;
    float altRemapped = saturate((altitude - cloudCumulusAlt) * rcp(cloudCumulusDepth));

    float tick  = cloudTime * 10.0;

        pos.xz /= 1.0 + (length(pos.xz) / cloudVolumeClip) * sqrt2;
        pos         = (pos * cloudCumulusScale);
        pos.x      += tick;

    #ifdef cloudLocalCoverage
    float localCoverage = noisePerlinWorleyCubic(noisetex, pos.xz * 0.004 + vec2(tick, 0.0) * 0.02 - vec2(0.147, 0.561));
        localCoverage = sstep(localCoverage, 0.4, 0.65);
        //return localCoverage;

    float coverageBias = clamp(0.46 - volumeCloudData.x - localCoverage * 0.15, 0.1, 1.0);
    #else
    float coverageBias = clamp(0.46 - volumeCloudData.x, 0.1, 1.0);
    #endif


    vec3 curl       = curl3D(pos * 0.08) * euler;
        pos        += curl.zxy * 0.2;

    float shape     = value3D(pos * 0.9 * vec3(1.0, 0.5, 1.0) + vec3(0.0, cloudTime * 0.01, 0.0) + curl * rpi);

        pos        += curl * rpi;

    const float nf    = 1.325;
    float threshold   = (1.0 - coverageBias) * nf * 0.95;

    if (shape < (threshold - 0.325)) return 0.0;
        pos *= 3.0; pos.x -= cloudTime * 0.4;
        shape  += (1.0 - abs(value3D(pos) * 3.0 - 1.0)) * 0.2;


    if (shape < (threshold - 0.125)) return 0.0;
        pos *= 4.0; pos.x -= cloudTime * 0.3;
        shape  += (1.0 - abs(value3D(pos) * 3.0 - 1.0)) * 0.075;

    if (shape < (threshold - 0.05)) return 0.0;
        pos *= 2.5; pos.x -= cloudTime * 0.4;
        shape  += (1.0 - abs(value3D(pos) * 3.0 - 1.0)) * 0.05;

        shape  /= nf;

    float altWeight = 1.0 - saturate(abs(altRemapped * 2.0 - 1.0));
        altWeight   = sqrt(sqrt(altWeight));

        shape      *= altWeight;

        shape       = saturate(shape-(1.0-coverageBias));
        shape      *= 0.5 + cubeSmooth(altRemapped) * 1.5;

    return max(shape * volumeCloudData.y, 0.0);
}

float cloudVolumeLightOD(vec3 pos, const uint steps) {
    float basestep = 5.0;
    float exponent = 2.0;

    float stepsize  = basestep;
    float prevStep  = stepsize;

    float od = 0.0;

    for(uint i = 0; i < steps; ++i, pos += cloudLightDir * stepsize) {

        if(pos.y > cloudCumulusMaxY || pos.y < cloudCumulusAlt) continue;

            prevStep  = stepsize;
            stepsize *= exponent;
        
        float density = cloudCumulusShape(pos);
        if (density <= 0.0) continue;

            od += density * prevStep;
    }

    return od;
}
float cloudVolumeSkyOD(vec3 pos, const uint steps) {
    const vec3 dir = vec3(0.0, 1.0, 0.0);

    float stepsize = (cloudCumulusDepth / float(steps));
        stepsize  *= 1.0-linStep(pos.y, cloudCumulusAlt, cloudCumulusMaxY) * 0.9;

    float od = 0.0;

    for(uint i = 0; i < steps; ++i, pos += dir * stepsize) {

        if(pos.y > cloudCumulusMaxY || pos.y < cloudCumulusAlt) continue;
        
        float density = cloudCumulusShape(pos);
        if (density <= 0.0) continue;

            od += density * stepsize;
    }

    return od;
}

float cloudVolumeLightOD(vec3 pos, const uint steps, float noise) {
    float basestep = 5.0;
    float exponent = 2.0;

    float stepsize  = basestep;
    float prevStep  = stepsize;

    float od = 0.0;

    pos += cloudLightDir * noise * stepsize;

    for(uint i = 0; i < steps; ++i, pos += cloudLightDir * stepsize) {

        pos += cloudLightDir * noise * (stepsize - prevStep);

        if(pos.y > cloudCumulusMaxY || pos.y < cloudCumulusAlt) continue;

            prevStep  = stepsize;
            stepsize *= exponent;
        
        float density = cloudCumulusShape(pos);
        if (density <= 0.0) continue;

            od += density * prevStep;
    }

    return od;
}
float cloudVolumeSkyOD(vec3 pos, const uint steps, float noise) {
    const vec3 dir = vec3(0.0, 1.0, 0.0);

    float stepsize = (cloudCumulusDepth / float(steps));
        stepsize  *= 1.0-linStep(pos.y, cloudCumulusAlt, cloudCumulusMaxY) * 0.9;

        pos += dir * stepsize * noise;

    float od = 0.0;

    for(uint i = 0; i < steps; ++i, pos += dir * stepsize) {

        if(pos.y > cloudCumulusMaxY || pos.y < cloudCumulusAlt) continue;
        
        float density = cloudCumulusShape(pos);
        if (density <= 0.0) continue;

            od += density * stepsize;
    }

    return od;
}


/* ------ cirrus clouds ------ */
#define cloudCirrusClip 5e4
#define cloudCirrusAlt 1000.0   //[5000.0 6000.0 7000.0 8000.0 9000.0 10000.0 12000.0]
#define cloudCirrusDepth 450.0 //[2000.0 3000.0 4000.0 5000.0 6000.0]
#define cloudCirrusScale 4e-3
#define cloudCirrusCoverageBias 0.0 //[-0.5 -0.4 -0.3 -0.2 -0.1 0.0 0.1 0.2 0.3 0.4 0.5]

const float cloudCirrusMaxY     = cloudCirrusAlt + cloudCirrusDepth;
const float cloudCirrusPlaneY   = cloudCirrusAlt + cloudCirrusDepth * 0.5;

uniform vec2 volumeCirrusData;

float cloudCirrusShape(in vec3 pos) {
    float altitude  = pos.y;
    float altRemapped = saturate((altitude - cloudCirrusAlt) * rcp(cloudCirrusDepth));
        pos.xz /= 1.0 + (length(pos.xz) / cloudCirrusClip) * sqrt2;
        pos    *= cloudCirrusScale;

    float tick  = -cloudTime * 100.0;

    #ifdef cloudLocalCoverage
    float localCoverage = noisePerlinWorleyCubic(noisetex, pos.xz * 0.002 + vec2(tick, 0.0) * 0.004 + vec2(0.871, 0.1974));
        localCoverage = linStep(localCoverage, 0.4, 0.65);
        //return localCoverage;

        //localCoverage = mix(0.57, 0.66, sqr(localCoverage));

    float coverageBias = clamp(0.4 - volumeCloudData.x - localCoverage * 0.2, 0.01, 1.0);
    #else
    float coverageBias = clamp(0.5 - volumeCloudData.x, 0.1, 1.0);
    #endif

    pos    += (value3D(pos*2.0 + vec3(0.0, tick*0.01, 0.0))*2.0-1.0)*0.1;
    pos.x  -= (value3D(pos*0.125 + vec3(0.0, tick*0.01, 0.0))*2.0-1.0)*1.2;

    pos.x  *= 0.25;
    pos.x  -= tick*0.01;

    //vec3 pos1   = pos*vec3(1.0, 0.5, 1.0)+vec3(0.0, tick*0.01, 0.0);

    float noise = value3D(pos * vec3(1.0, 0.5, 1.0) + vec3(0.0, tick * 0.01, 0.0));
            pos *= 2.0; pos.x -= tick * 0.017; pos.z += noise * 1.35; pos.x += noise * 0.5;

        noise  += (2.0 - abs(value3D(pos) * 2.0)) * 0.35;
            pos *= 3.0; pos.xz -= tick * 0.3; pos.z += noise * 1.35; pos.x += noise * 0.5; pos.x *= 3.0; pos.z *= 0.55;
            pos.z  -= (value3D(pos * 0.25 + vec3(0.0, tick * 0.01, 0.0)) * 2.0 - 1.0) * 0.4;

        noise  += (3.0 - abs(value3D(pos) * 3.0)) * 0.035;
            pos *= 3.0; pos.z *= 0.5; pos.xz -= tick * 0.75;

        noise  += (3.0 - abs(value3D(pos) * 3.0)) * 0.035;
            pos *= 3.0; pos.xz -= tick * 0.75;

        noise  += (3.0 - abs(value3D(pos) * 3.0)) * 0.025;
            pos *= 4.0; pos.xz -= tick * 0.4;

        noise  += value3D(pos) * 0.054;
            //pos *= 3.0;

        //noise  += value_3d(pos)*0.024;

        noise  /= 1.575;
        
    float shape = noise;

    float altWeight = 1.0 - saturate(abs(altRemapped * 2.0 - 1.0) * 1.04);
        altWeight   = sqrt(sqrt(altWeight));

        shape       = saturate(max(shape - (1.0 - coverageBias), 0.0) / coverageBias);
        shape       = sqr(shape);

        shape *= sqrt(altWeight);

    return max(shape * volumeCirrusData.y, 0.0);
}

float cloudCirrusLightOD(vec3 pos, const uint steps, vec3 dir) {
    float stepsize = (cloudCirrusDepth / float(steps));
        stepsize  *= 1.0 - linStep(pos.y, cloudCirrusAlt, cloudCirrusMaxY) * 0.9;

    float od = 0.0;

    for(uint i = 0; i < steps; ++i, pos += dir * stepsize) {

        if(pos.y > cloudCirrusMaxY || pos.y < cloudCirrusAlt) continue;
        
        float density = cloudCirrusShape(pos);
        if (density <= 0.0) continue;

            od += density * stepsize;
    }

    return od;
}