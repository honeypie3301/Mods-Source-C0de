#version 150
uniform float DhDepthReversed;
bool cmDhSurface(float depth){return DhDepthReversed>.5 ? depth>.0000001 : depth<.9999995;}
uniform sampler2D Sampler0;
uniform sampler2D SceneDepthSampler;
uniform sampler2D DhDepthSampler;
uniform mat4 SceneInverse;
uniform mat4 DhInverse;
uniform vec2 ScreenSize;
uniform vec3 CameraOrigin;
uniform float HasDhDepth;
uniform float Time;
in vec2 texCoord;
in vec2 particleCoord;
in vec2 thermalMeta;
in vec4 vertexColor;
in vec3 cameraRelativePos;
out vec4 fragColor;
// Keep custom helpers distinct from GLSL's built-in vec3 noise3(genType).
float cmThermalValueNoise3(vec3 p){
 vec3 i=floor(p),f=fract(p); f=f*f*(3.-2.*f);
 vec4 n=vec4(dot(i,vec3(1,57,113)))+vec4(0,1,57,58);
 vec4 a=fract(sin(n)*43758.5453),b=fract(sin(n+113.)*43758.5453);
 vec4 c=mix(a,b,f.z); return mix(mix(c.x,c.y,f.x),mix(c.z,c.w,f.x),f.y);
}
float radiance(float kelvin){return 120.0/(exp(1438.8/max(kelvin,150.))-1.0);}
bool blocked(float depth,mat4 inverse,vec2 uv,bool distant){
 if(distant ? !cmDhSurface(depth) : depth>=0.9999995)return false;
 vec4 h=inverse*vec4(uv*2.-1.,depth*2.-1.,1);
 float distance=length(h.xyz/h.w);
 bool nozzle=abs(thermalMeta.y-30002.)<.5;
 float tolerance=nozzle?clamp(length(cameraRelativePos)*.00002,.05,.4):clamp(length(cameraRelativePos)*.001,.5,8.);
 return distance+tolerance<length(cameraRelativePos);
}
// Reconstruct the particle atlas continuously even when Minecraft uses nearest
// filtering for pixel-art textures. This prevents blocky gas/flash silhouettes.
vec4 smoothSprite(vec2 uv){
 ivec2 size=textureSize(Sampler0,0);
 vec2 pixel=uv*vec2(size)-.5;
 ivec2 base=ivec2(floor(pixel));vec2 f=fract(pixel);
 vec4 a=texelFetch(Sampler0,clamp(base,ivec2(0),size-1),0);
 vec4 b=texelFetch(Sampler0,clamp(base+ivec2(1,0),ivec2(0),size-1),0);
 vec4 c=texelFetch(Sampler0,clamp(base+ivec2(0,1),ivec2(0),size-1),0);
 vec4 d=texelFetch(Sampler0,clamp(base+ivec2(1),ivec2(0),size-1),0);
 return mix(mix(a,b,f.x),mix(c,d,f.x),f.y);
}
float nozzleProfile(vec2 p){
 float r=length(p);
 return exp(-r*r*5.)*(1.-smoothstep(.65,1.,r));
}
void main(){
 vec2 screen=gl_FragCoord.xy/ScreenSize;
 if(blocked(texture(SceneDepthSampler,screen).r,SceneInverse,screen,false))discard;
 if(HasDhDepth>.5 && blocked(texture(DhDepthSampler,screen).r,DhInverse,screen,true))discard;
 bool nozzle=abs(thermalMeta.y-30002.)<.5;
 vec4 s;
 if(nozzle){
  vec2 p=particleCoord*2.-1.;
  vec2 footprint=fwidth(p)*.25;
  // Integrate the smooth source over the pixel, especially at distant/subpixel sizes.
  float alpha=(nozzleProfile(p+footprint)+nozzleProfile(p-footprint)
       +nozzleProfile(p+vec2(footprint.x,-footprint.y))
       +nozzleProfile(p+vec2(-footprint.x,footprint.y)))*.25;
  s=vec4(1.,1.,1.,alpha);
 }else s=smoothSprite(texCoord);
 float heat=clamp(1.-(vertexColor.g/max(vertexColor.r,.001)-.02)/.32,0.,1.);
 float density=dot(s.rgb,vec3(.299,.587,.114));
 // World anchored turbulence modulates gas temperature and optical thickness.
 // Opaque incandescent shards retain their real sprite silhouette.
 // Blue is a material tag in this dedicated pass, never a visible tint.
 float solid=1.-step(.4,vertexColor.b);
 // Gas tag .5..1 carries the short initial energy pulse independently of
 // cooling temperature. It cannot turn the entire cloud into one clipped value.
 bool groundGas=solid<.5 && vertexColor.b<.49;
 float pulse=solid>.5 ? 0. : (groundGas ? clamp((vertexColor.b-.40)/.08,0.,1.) : clamp((vertexColor.b-.5)*2.,0.,1.));
 if(thermalMeta.y>29999.5 && thermalMeta.y<30001.5){
  solid=0.;groundGas=thermalMeta.y>30000.5;
  pulse=clamp(thermalMeta.x/32767.,0.,1.);
 }
 vec3 world=cameraRelativePos+CameraOrigin;
 float emission=0.;
 float impulseEmission=0.;
 float transmission=1.;
 if(solid>.5){
  transmission=exp(-s.a*vertexColor.a*7.);
  emission=radiance(nozzle ? clamp(thermalMeta.x,300.,3800.) : 293.+heat*heat*1350.)*(1.-transmission);
  impulseEmission=emission*(nozzle?4.5:pow(heat,6.)*1.4);
 }else{
  // Integrate five emitting/absorbing layers through a turbulent gas slab.
  // The sprite bounds the plume; temperature and density vary within it.
  vec3 ray=normalize(cameraRelativePos+vec3(0,0,.0001));
  for(int layer=0;layer<5;layer++){
   vec3 point=world+ray*(float(layer)-2.)*1.6;
   vec3 stablePoint=vec3(particleCoord*3.7,float(layer)*.4);
   float eddy=.72*cmThermalValueNoise3(stablePoint)+.28*cmThermalValueNoise3(stablePoint*2.1); // Smooth, spatially coherent structure, no rapid texture shimmer.
   float filament=smoothstep(.22,.78,eddy);
   // Hot ground gas radiates independently of the short optical impulse.
   // Preserve turbulent detail while avoiding an artificially cold mean cloud.
   float localHeat=heat*(groundGas ? .46+.14*density+.40*filament : .40+.15*density+.45*filament);
   float baseKelvin=293.+localHeat*localHeat*2200.;
   float kelvin=baseKelvin+pulse*(4800.+10500.*filament);
   float opticalDepth=s.a*vertexColor.a*(.15+.85*density)*(.20+filament)*.42;
   float absorption=1.-exp(-opticalDepth);
   emission+=transmission*absorption*radiance(kelvin);
   impulseEmission+=transmission*absorption*(max(0.,radiance(kelvin)-radiance(baseKelvin))+radiance(baseKelvin)*pow(heat,4.)*.16);
   transmission*=1.-absorption;
  }
 }
 float opacity=1.-transmission;
 if(opacity<(nozzle ? .000001 : .002))discard;
 // Radiance remains HDR; alpha is absorption, independent of temperature.
 float opticalDepth=-log(max(transmission,.00001));
 fragColor=vec4(emission/max(opacity,.00001)*opticalDepth,
                impulseEmission/max(opacity,.00001)*opticalDepth,0.,opticalDepth);
}
