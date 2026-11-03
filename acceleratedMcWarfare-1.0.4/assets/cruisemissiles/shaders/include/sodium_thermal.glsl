uniform sampler2D MaterialSampler;
uniform sampler2D ClimateSampler;
uniform float Temperatures[64];
uniform float ShadeTemperatures[64];
uniform vec2 ClimateOrigin;
uniform vec2 CameraXZ;
uniform float CameraBiome;

vec4 cmTerrainTemperature(vec2 uv,vec3 position,float skyExposure){
    int material=clamp(int(texture(MaterialSampler,uv).r+.5),0,63);
    float t=mix(ShadeTemperatures[material],Temperatures[material],skyExposure)-position.y*.0065;
    if(t<400.)t+=(texture(ClimateSampler,(position.xz+CameraXZ-ClimateOrigin)/2048.).r-CameraBiome)*6.;
    // Compressed Sodium vertices carry no normal; derive the same world-space face direction.
    float faceSign=1.0;
    if(!gl_FrontFacing)faceSign=-1.0;
    vec3 faceNormal=normalize(cross(dFdx(position),dFdy(position))*faceSign+vec3(.00001));
    t+=dot(faceNormal,normalize(vec3(.4,.8,.3)))*1.2;
    float code=clamp((t-200.)/1200.,0.,1.)*32767.;
    return vec4((128.+floor(code/256.))/255.,mod(code,256.)/255.,82./255.,1.);
}
