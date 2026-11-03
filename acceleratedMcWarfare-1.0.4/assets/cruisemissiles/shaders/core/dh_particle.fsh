#version 150
uniform float DhDepthReversed;
bool cmDhSurface(float depth){return DhDepthReversed>.5 ? depth>.0000001 : depth<.9999995;}

uniform sampler2D Sampler0;
uniform sampler2D DhDepthSampler;
uniform vec4 ColorModulator;
uniform mat4 DhInvViewProjMat;
uniform vec2 ScreenSize;
uniform float HasDhDepth;
uniform float ThermalCapture;
uniform float EmissiveSpark;
uniform int CookoffFireCount;
uniform float CookoffFirePos[12];
uniform float CookoffFireEnergyRadius[8];
uniform int CookoffCount;
uniform float CookoffPos[192];
uniform float CookoffEnergyRadius[128];
flat in int cookoffIndex;
uniform int MotorCount;
uniform float MotorPos[12];
uniform float MotorJet[12];
uniform float MotorEnergyRadius[8];

in vec2 texCoord;
in vec4 vertexColor;
in vec4 lightMapColor;
in vec3 cameraRelativePos;

out vec4 fragColor;

void main() {
    vec4 sprite = texture(Sampler0, texCoord);
    vec4 color = sprite * vertexColor * ColorModulator * lightMapColor;
    if(EmissiveSpark > 0.5 && ThermalCapture < 0.5) {
        color = sprite * vertexColor * ColorModulator;
        float core = max(sprite.r, max(sprite.g, sprite.b));
        float hot = smoothstep(0.08, 0.40, vertexColor.g);
        color.rgb *= EmissiveSpark > 2.5 ? 2.1 + max(0.0,EmissiveSpark-3.0)*3.5 : EmissiveSpark > 1.5 ? 3.5 + (7.0 + 10.0 * hot) * core * core
                                       : 1.8 + 3.2 * core * core;
        // LDR clamps radiance before blending. Encode extra night light in
        // the additive source weight, otherwise brighter RGB never reaches the scene.
        if(EmissiveSpark > 2.5) color.a=min(1.0,color.a*(1.0+clamp(EmissiveSpark-3.0,0.0,1.0)*.65));
        // Keep the warm chroma when writing to an LDR scene buffer. Independently
        // clipped red/green used to turn even orange SAM streaks flat yellow.
        if(EmissiveSpark > 1.5) {
            float peak=max(color.r,max(color.g,color.b));
            color.rgb*=min(1.0,(EmissiveSpark > 2.5 ? 1.45 + max(0.0,EmissiveSpark-3.0)*.85 : 1.6)/max(peak,0.001));
        }
    }
    if (ThermalCapture > 0.5 && vertexColor.r > 0.5
            && vertexColor.g < vertexColor.r * 0.4
            && vertexColor.b < vertexColor.r * 0.45) {
        // Decode BEFORE sprite multiplication and alpha blending. Visible-light
        // albedo/lightmap must not reduce the temperature of hot gas or metal.
        float temperature = clamp(1.0 - (vertexColor.g / vertexColor.r - 0.02) / 0.32, 0.0, 1.0);
        float structure = dot(sprite.rgb, vec3(0.299, 0.587, 0.114));
        float density = smoothstep(0.025, 0.60, structure);
        float incandescent = smoothstep(0.94, 0.995, temperature);
        // Cooler edges and hot dense folds use the sprite's own structure;
        // no screen-space noise pattern that swims when the camera moves.
        float localHeat = temperature * mix(0.60 + 0.40 * density, 1.0, incandescent);
        color.rgb = vec3(1.0, mix(0.34, 0.02, localHeat), mix(0.10, 0.01, localHeat));
        // Preserve the original silhouette and fade. The bright interior carries
        // radiance independently of dark RGB texels, while edges stay translucent.
        color.a = sprite.a * vertexColor.a * ColorModulator.a;
    }
    if (color.a < 0.004) discard;

    // Shade once, BEFORE alpha compositing. Near dust attenuates the complete
    // radiance of the plume behind it, including its engine illumination.
    if(ThermalCapture < 0.5 && EmissiveSpark < 0.5
            && (MotorCount > 0 || (cookoffIndex >= 0 && (CookoffCount > 0 || CookoffFireCount > 0)))) {
        float density=dot(sprite.rgb,vec3(0.3333))*sprite.a;
        vec3 facing=normalize(-cameraRelativePos+vec3(1e-8));
        vec3 normal=normalize(facing-normalize(dFdx(cameraRelativePos)+vec3(1e-8))*dFdx(density)*18.0
            -normalize(dFdy(cameraRelativePos)+vec3(1e-8))*dFdy(density)*18.0);
        // Same relief/scattering calculation as powered motor smoke, applied
        // only to the tagged cookoff wake and its own interpolated source.
        if(cookoffIndex>=0 && cookoffIndex<CookoffCount){
            int i=cookoffIndex;
            vec3 emitter=vec3(CookoffPos[i*3],CookoffPos[i*3+1],CookoffPos[i*3+2]);
            vec3 delta=emitter-cameraRelativePos;
            float radius=max(1.0,CookoffEnergyRadius[i*2+1]);
            float attenuation=1.0/pow(1.0+dot(delta,delta)/(radius*radius),2.0);
            vec3 toLight=delta/max(length(delta),.001);
            float relief=.16+max(dot(normal,toLight),0.0)*.64
                +pow(max(dot(-facing,toLight),0.0),3.0)*(1.0-sprite.a*.65)*.20;
            color.rgb+=mix(vec3(1.0,.38,.10),vec3(1.0,.75,.35),attenuation)
                *CookoffEnergyRadius[i*2]*attenuation*relief*.65;
        }
        if(cookoffIndex>=0)for(int i=0;i<4;i++){
            if(i>=CookoffFireCount)break;
            vec3 emitter=vec3(CookoffFirePos[i*3],CookoffFirePos[i*3+1],CookoffFirePos[i*3+2]);
            vec3 delta=emitter-cameraRelativePos;
            float radius=max(1.0,CookoffFireEnergyRadius[i*2+1]);
            float attenuation=1.0/pow(1.0+dot(delta,delta)/(radius*radius),2.0);
            vec3 toLight=delta/max(length(delta),.001);
            float relief=.16+max(dot(normal,toLight),0.0)*.64
                +pow(max(dot(-facing,toLight),0.0),3.0)*(1.0-sprite.a*.65)*.20;
            color.rgb+=vec3(1.0,.42,.08)*CookoffFireEnergyRadius[i*2]*attenuation*relief*.65;
        }
        for(int i=0;i<4;i++){
            if(i>=MotorCount)break;
            vec3 emitter=vec3(MotorPos[i*3],MotorPos[i*3+1],MotorPos[i*3+2]);
            vec3 jet=vec3(MotorJet[i*3],MotorJet[i*3+1],MotorJet[i*3+2]);
            float t=clamp(dot(cameraRelativePos-emitter,jet)/max(dot(jet,jet),.0001),0.0,1.0);
            vec3 delta=emitter+jet*t-cameraRelativePos;
            float radius=max(1.0,MotorEnergyRadius[i*2+1]);
            float attenuation=1.0/pow(1.0+dot(delta,delta)/(radius*radius),2.0);
            vec3 toLight=delta/max(length(delta),.001);
            float relief=.16+max(dot(normal,toLight),0.0)*.64
                +pow(max(dot(-facing,toLight),0.0),3.0)*(1.0-sprite.a*.65)*.20;
            color.rgb+=mix(vec3(1.0,.59,.27),vec3(1.0,.91,.76),attenuation)
                *MotorEnergyRadius[i*2]*attenuation*relief*.65;
        }
    }

    if (HasDhDepth > 0.5) {
        vec2 screenUv = gl_FragCoord.xy / max(ScreenSize, vec2(1.0));
        float dhDepth = texture(DhDepthSampler, screenUv).r;
        if (cmDhSurface(dhDepth)) {
            vec4 clip = vec4(screenUv * 2.0 - 1.0, dhDepth * 2.0 - 1.0, 1.0);
            vec4 dhH = DhInvViewProjMat * clip;
            vec3 dhPos = dhH.xyz / max(abs(dhH.w), 1e-6);
            // DH depth becomes progressively less precise at kilometre ranges.
            // A fixed sub-block bias made distant billboards disappear head-on
            // and reappear at the screen edge. Scale only the precision allowance;
            // geometry that is materially behind a LOD surface is still rejected.
            float particleDistance = length(cameraRelativePos);
            float depthTolerance = clamp(1.25 + particleDistance * 0.0045, 1.25, 12.0);
            if (length(dhPos) + depthTolerance < particleDistance) discard;
        }
    }

    fragColor = color;
}
