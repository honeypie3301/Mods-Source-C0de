#version 150
uniform sampler2D Sampler0;
in vec4 thermalColor;
in vec2 texCoord;
in float facing;
out vec4 fragColor;
float roughness(vec2 uv){return dot(texture(Sampler0,uv).rgb,vec3(.299,.587,.114));}
void main(){
 if(thermalColor.a<.1)discard;
 vec4 sample=texture(Sampler0,texCoord);if(sample.a<.1)discard;
 vec2 px=1./vec2(textureSize(Sampler0,0));
 float mean=(roughness(texCoord+vec2(px.x*2.,0))+roughness(texCoord-vec2(px.x*2.,0))+roughness(texCoord+vec2(0,px.y*2.))+roughness(texCoord-vec2(0,px.y*2.)))*.25;
 // Base temperature still comes only from components. Texture high-pass supplies
 // microstructure; viewing angle models a weak emissivity/reflection change.
 float variation=(facing-.5)*5.+clamp(roughness(texCoord)-mean,-.5,.5)*5.;
 float t=240.+thermalColor.g/max(thermalColor.r,.001)*600.+variation;
 float code=clamp((t-200.)/1200.,0.,1.)*32767.;
 fragColor=vec4((128.+floor(code/256.))/255.,mod(code,256.)/255.,thermalColor.b,thermalColor.a);
}
