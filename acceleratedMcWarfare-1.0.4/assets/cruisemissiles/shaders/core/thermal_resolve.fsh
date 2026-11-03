#version 150
uniform float DhDepthReversed;
bool cmDhSurface(float depth){return DhDepthReversed>.5 ? depth>.0000001 : depth<.9999995;}
uniform sampler2D DiffuseSampler;
uniform sampler2D HeatSampler;
uniform sampler2D SceneDepthSampler;
uniform sampler2D DhDepthSampler;
uniform float HasDhDepth;
uniform float LodKelvin;
uniform vec2 OutSize;
uniform mat4 SceneInverse;
uniform mat4 DhInverse;
uniform int SurfaceCount;
uniform float SurfaceCenters[32];
uniform float SurfaceHeat[8];
uniform float SurfaceAxes[32];
uniform int VehicleCount;
uniform float VehicleCenters[128];
uniform float VehicleAxes[128];
uniform float VehicleRotations[128];
uniform float VehicleSensors[128];
uniform sampler2D VehicleFieldSampler;
in vec2 texCoord;
out vec4 fragColor;
float rad(float t){return 120./(exp(1438.8/t)-1.);}
float terrainNoise(vec2 p){
 vec2 i=floor(p),f=fract(p);f=f*f*(3.-2.*f);
 float a=fract(sin(dot(i,vec2(127.1,311.7)))*43758.5453);
 float b=fract(sin(dot(i+vec2(1,0),vec2(127.1,311.7)))*43758.5453);
 float c=fract(sin(dot(i+vec2(0,1),vec2(127.1,311.7)))*43758.5453);
 float d=fract(sin(dot(i+vec2(1),vec2(127.1,311.7)))*43758.5453);
 return mix(mix(a,b,f.x),mix(c,d,f.x),f.y);
}
void main(){
 vec2 uv=texCoord;
 float sky=step(.9999995,texture(SceneDepthSampler,uv).r);
 if(HasDhDepth>.5)sky*=cmDhSurface(texture(DhDepthSampler,uv).r)?0.:1.;
 // Reconstruct the visible surface, never paint a projected heat circle over the sky.
 float depth=texture(SceneDepthSampler,uv).r;
 vec4 point=SceneInverse*vec4(uv*2.-1.,depth*2.-1.,1.);
 if(depth>=.9999995 && HasDhDepth>.5){depth=texture(DhDepthSampler,uv).r;point=DhInverse*vec4(uv*2.-1.,depth*2.-1.,1.);}
 vec3 position=point.xyz/max(abs(point.w),.000001);
 // Exact raster material marker, read without interpolating identities across silhouettes.
 vec3 surfacePixel=texelFetch(DiffuseSampler,clamp(ivec2(uv*vec2(textureSize(DiffuseSampler,0))),ivec2(0),textureSize(DiffuseSampler,0)-1),0).rgb;
 bool terrain=surfacePixel.r>=.5 && abs(surfacePixel.b-82./255.)<.002;
 float t=sky>.5?248.:(terrain?200.+((surfacePixel.r*255.-128.)*256.+surfacePixel.g*255.)/32767.*1200.:LodKelvin);
 float emissivity=.96;
 float warmed=0.;
 for(int k=0;k<8;k++)if(k<SurfaceCount && sky<.5){
  vec3 delta=position-vec3(SurfaceCenters[k*4],SurfaceCenters[k*4+1],SurfaceCenters[k*4+2]);
  float radius=SurfaceCenters[k*4+3];
  // Impact-relative multi-scale structure remains fixed as the camera moves.
  vec2 q=delta.xz/max(radius,1.);
  vec2 warp=vec2(terrainNoise(q*4.1+3.7),terrainNoise(q*4.1+19.3))-.5;
  vec2 distorted=q+warp*.45;
  vec2 axis=vec2(SurfaceAxes[k*4],SurfaceAxes[k*4+1]);
  float along=dot(distorted,axis)/max(1.,SurfaceAxes[k*4+2]);
  float across=dot(distorted,vec2(-axis.y,axis.x));
  float r2=along*along+across*across;
  float textureHeat=.40+.36*terrainNoise(q*7.7)+.24*terrainNoise(q*18.3);
  float skirt=exp(-r2/ .32)*textureHeat;
  float core=exp(-dot(q,q)/.032);
  float footprint=skirt*.50+core*1.10;
  float contact=1.-smoothstep(2.,max(7.,radius*.55),abs(delta.y));
  // Heat follows continuous world distance, not individual cube face orientation.
  float facing=1.;
  warmed=max(warmed,SurfaceHeat[k]*footprint*contact*facing);
 }
 t+=warmed;
 float background=emissivity*rad(t)+(1.-emissivity)*rad(t-5.);
 // Real missile models still supply the existing heat attribute in scene RGB.
 // Fetch source pixels before reduction so distant silhouettes are retained.
 float body=0.;float vehicleGlare=0.;float entityRadiance=0.;bool entityFound=false;bool vehicleFound=false;
 ivec2 size=textureSize(DiffuseSampler,0);
  // Examine the native source footprint before reducing radiance: small targets cannot
 // vanish merely because their skin fell between four downsample taps (up to 4K input).
 ivec2 outputPixel=ivec2(floor(uv*OutSize));
 ivec2 first=ivec2(floor(vec2(outputPixel)*vec2(size)/OutSize));
 ivec2 last=ivec2(ceil(vec2(outputPixel+1)*vec2(size)/OutSize));
 ivec2 span=min(ivec2(6),max(ivec2(1),last-first));
 for(int j=0;j<6;j++)for(int i=0;i<6;i++)if(i<span.x && j<span.y){
  vec3 m=texelFetch(DiffuseSampler,clamp(first+ivec2(i,j),ivec2(0),size-1),0).rgb;
  // Stable vertex marker: model skins and world light cannot change body temperature.
  float gr=m.g/max(m.r,.00001),br=m.b/max(m.r,.00001);
  if(m.r>.995 && gr>.825 && gr<.865 && br>.003 && br<.015){
   background=max(background,rad(310.));body=1.;
  }
  bool hull=m.r>=.5 && abs(m.b-26./255.)<.0015;
  int role=int(round(m.b*255.));
  bool vehicle=m.r>=.5 && role>=26 && role<=32;
  bool warmBody=m.r>=.5 && abs(m.b-46./255.)<.0015;
  bool living=warmBody || (m.r>=.5 && abs(m.b-47./255.)<.0015);
  bool missile=m.r>=.5 && role==48;
  if(vehicle || living || missile){
   if(vehicle)vehicleFound=true;
   float temperature=200.+((m.r*255.-128.)*256.+m.g*255.)/32767.*1200.;
   if(hull || role==27 || role==28 || role==30 || role==31 || role==32){
    for(int k=0;k<32;k++)if(k<VehicleCount){
     vec3 delta=position-vec3(VehicleCenters[k*4],VehicleCenters[k*4+1],VehicleCenters[k*4+2]);
     vec4 q=vec4(-VehicleRotations[k*4],-VehicleRotations[k*4+1],-VehicleRotations[k*4+2],VehicleRotations[k*4+3]);
     vec3 local=delta+2.*cross(q.xyz,cross(q.xyz,delta)+q.w*delta);
     if(role==28){
      vec3 sensor=vec3(VehicleSensors[k*4],VehicleSensors[k*4+1],VehicleSensors[k*4+2]);
      vec3 d=(local-sensor)/vec3(.85,.65,.85);
      if(length(local-sensor)>8.5)continue;
      temperature+=VehicleSensors[k*4+3]*(.045+.90*exp(-length(d)*.75));break;
     }
     local.x-=VehicleAxes[k*4];local.z-=VehicleAxes[k*4+1];
     float width=VehicleAxes[k*4+2],height=VehicleAxes[k*4+3],halfLength=VehicleCenters[k*4+3];
     // Mounted parts inherit heat across the edge; there is no hard cold-box cutoff.
     vec3 outside=max(vec3(abs(local.x)-width,-local.y,abs(local.z)-halfLength),vec3(0));
     outside.y=max(outside.y,local.y-height);
     if(length(outside)>3.)continue;
     float attachment=exp(-length(outside)*1.4);
     vec3 grid=clamp(vec3((local.x/width+1.)*4.,local.y/height*8.,(1.-local.z/halfLength)*12.),vec3(0),vec3(8,8,24));
     ivec3 base=min(ivec3(floor(grid)),ivec3(7,7,23));vec3 f=grid-vec3(base);float rise=0.;
     for(int z=0;z<2;z++)for(int y=0;y<2;y++)for(int x=0;x<2;x++){
      ivec3 node=base+ivec3(x,y,z);float weight=(x==0?1.-f.x:f.x)*(y==0?1.-f.y:f.y)*(z==0?1.-f.z:f.z);
      vec2 field=texelFetch(VehicleFieldSampler,ivec2((node.z*9+node.y)*9+node.x,k),0).rg;
      rise+=weight*(role==27?field.g:field.r);
     }
     // Thin shields and reflective glazing do not share a thick steel panel's response.
     rise*=attachment;
     if(role==30)rise*=.72;
     if(role==31)rise=rise*.25-3.;
     temperature+=rise;break;
    }
   }
   if(vehicle && role!=27)vehicleGlare=max(vehicleGlare,max(temperature-t-25.,0.)*.006);
   entityRadiance=max(entityRadiance,rad(temperature));entityFound=true;
   if(living)body=max(body,warmBody&&temperature>=300.?1.:clamp((temperature-t)/18.,0.,1.));
  }
  else if(m.r>.008 && m.g/m.r<.4 && m.b/m.r<.05)
   background=max(background,rad(330.+250.*clamp(1.-(m.g/m.r-.02)/.32,0.,1.)));
 }
 if(entityFound)background=entityRadiance;
 vec4 gas=texture(HeatSampler,uv);
 float transmission=exp(-max(gas.a,0.));
 float opacity=1.-transmission;
 float source=gas.r/max(gas.a,.00001);
 float signal=background*transmission+source*opacity;
 fragColor=vec4(signal,gas.g/max(gas.a,.00001)*opacity+vehicleGlare*transmission,(body>0.?body:vehicleFound?-1.:0.)*transmission,max(opacity,smoothstep(1.,12.,warmed)));
}
