#version 150
uniform sampler2D Sampler0;
uniform sampler2D MaterialSampler;
uniform float Temperatures[64];
uniform sampler2D ClimateSampler;
uniform vec2 ClimateOrigin;
uniform vec2 CameraXZ;
uniform float CameraBiome;
uniform float ShadeTemperatures[64];
in vec2 localXZ;
in float skyExposure;
in vec2 texCoord;
in vec3 faceNormal;
in float heightOffset;
out vec4 fragColor;
void main(){
 vec4 skin=texture(Sampler0,texCoord);if(skin.a<.1)discard;
 int material=clamp(int(texture(MaterialSampler,texCoord).r+.5),0,63);
 float t=mix(ShadeTemperatures[material],Temperatures[material],skyExposure)-heightOffset*.0065;
 if(t<400.)t+=(texture(ClimateSampler,(localXZ+CameraXZ-ClimateOrigin)/2048.).r-CameraBiome)*6.;
 // Small, stable directional emissivity contrast preserves faces without visible-light shadows.
 t+=dot(normalize(faceNormal+vec3(.00001)),normalize(vec3(.4,.8,.3)))*1.2;
 float code=clamp((t-200.)/1200.,0.,1.)*32767.;
 fragColor=vec4((128.+floor(code/256.))/255.,mod(code,256.)/255.,82./255.,1.);
}
