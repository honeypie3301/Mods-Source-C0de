#version 150
uniform float DhDepthReversed;
bool cmDhSurface(float depth){return DhDepthReversed>.5 ? depth>.0000001 : depth<.9999995;}
uniform sampler2D DiffuseSampler;
uniform sampler2D SceneDepthSampler;
uniform sampler2D DhDepthSampler;
uniform mat4 SceneInverse;
uniform mat4 DhInverse;
uniform vec2 OutSize;
uniform float HasDhDepth;
uniform float ZoomFactor;
uniform float Time;
in vec2 texCoord;
out vec4 fragColor;
float rangeAt(float depth,mat4 inverse,bool distant){
    if(distant ? !cmDhSurface(depth) : depth>=0.9999995)return 1e6;
    vec4 p=inverse*vec4(texCoord*2.0-1.0,depth*2.0-1.0,1.0);
    return length(p.xyz/max(abs(p.w),1e-7));
}
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
void main(){
    float distance=rangeAt(texture(SceneDepthSampler,texCoord).r,SceneInverse,false);
    if(HasDhDepth>.5)distance=min(distance,rangeAt(texture(DhDepthSampler,texCoord).r,DhInverse,true));
    float farDetail=distance>99999.0?0.0:smoothstep(180.0,600.0,distance);
    float qualityLoss=clamp(ZoomFactor*(.08+.92*farDetail),0.0,1.0);
    // Continuous optical point-spread, atmospheric contrast loss and sensor grain.
    // No quantized UV grid: detail fades smoothly instead of turning into mosaic tiles.
    vec2 radius=(.2+3.8*qualityLoss)/OutSize;
    vec3 color=vec3(0.0);
    for(int j=-1;j<=1;j++)for(int i=-1;i<=1;i++){
        float weight=(i==0?2.0:1.0)*(j==0?2.0:1.0)/16.0;
        color+=texture(DiffuseSampler,texCoord+vec2(i,j)*radius).rgb*weight;
    }
    float luminance=dot(color,vec3(.299,.587,.114));
    color=mix(color,vec3(luminance),qualityLoss*.12);
    color=mix(color,vec3(.48),qualityLoss*.10);
    float noise=(hash(floor(texCoord*OutSize)+floor(Time*18.0))-.5)*qualityLoss*.018;
    fragColor=vec4(clamp(color+noise,0.0,1.0),1.0);
}
