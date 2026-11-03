#version 150
uniform float DhDepthReversed;
bool cmDhSurface(float depth){return DhDepthReversed>.5 ? depth>.0000001 : depth<.9999995;}
uniform sampler2D DhDepthSampler;
uniform sampler2D ModelSampler;
uniform sampler2D VanillaDepthSampler;
uniform sampler2D BeforeNativeDepthSampler;
uniform mat4 VanillaInvViewProjMat;
uniform float VanillaLimit;
uniform mat4 DhInvViewProjMat;
uniform vec2 ScreenSize;
uniform float ThermalMode;
in vec4 vertexColor;
in vec3 cameraRelativePos;
in vec2 texCoord;
out vec4 fragColor;
void main() {
    vec2 uv = gl_FragCoord.xy / max(ScreenSize, vec2(1.0));
    float distance = length(cameraRelativePos);
    float nearDepth=texture(VanillaDepthSampler,uv).r;
    float beforeDepth=texture(BeforeNativeDepthSampler,uv).r;
    bool nativeTerrain=VanillaLimit>0.0 && nearDepth<1.0 && abs(nearDepth-beforeDepth)>1e-7;
    float coverage=vertexColor.a;
    // Only pixels changed by the native solid pass contain native depth.
    // Chunk readiness says nothing about who wrote the depth at this pixel.
    if (nativeTerrain) {
        if (nearDepth < 1.0) {
            vec4 p = VanillaInvViewProjMat * vec4(uv * 2.0 - 1.0, nearDepth * 2.0 - 1.0, 1.0);
            if (abs(p.w) > 1e-7 && length(p.xyz / p.w) + 0.3 < distance) discard;
        }
    }
    float depth = texture(DhDepthSampler, uv).r;
    if (!nativeTerrain && cmDhSurface(depth)) {
        vec4 h = DhInvViewProjMat * vec4(uv * 2.0 - 1.0, depth * 2.0 - 1.0, 1.0);
        vec3 terrain = h.xyz / max(abs(h.w), 1e-6);
        // Limited bias for coarser terrain, rather than drawing through hills.
        float tolerance = clamp(1.0 + distance * 0.0015, 1.0, 4.0);
        if (length(terrain) + tolerance < distance) discard;
    }
    // Stable screen-door coverage avoids transparent cuboid sorting and extra draws.
    int x=int(gl_FragCoord.x)&3, y=int(gl_FragCoord.y)&3;
    int bayer[16]=int[16](0,8,2,10,12,4,14,6,3,11,1,9,15,7,13,5);
    if(coverage<(float(bayer[y*4+x])+.5)/16.0)discard;
    vec4 material=texture(ModelSampler,texCoord);
    if(material.a<.1)discard;
    if(ThermalMode>.5){
        float temperature=200.+vertexColor.r*600.;
        float code=clamp((temperature-200.)/1200.,0.,1.)*32767.;
        // Direct component temperature; tag 29 bypasses the native entity conduction field.
        fragColor=vec4((128.+floor(code/256.))/255.,mod(code,256.)/255.,29./255.,1.);
    }else fragColor = vec4(material.rgb*vertexColor.rgb,1.0);
}
