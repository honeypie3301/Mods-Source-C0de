#version 150
in vec3 Position;
in vec2 UV0;
in vec3 Normal;
in ivec2 UV2;
uniform mat4 ModelViewMat;
uniform mat4 ProjMat;
uniform vec3 ChunkOffset;
out vec2 texCoord;
out vec3 faceNormal;
out float heightOffset;
out vec2 localXZ;
out float skyExposure;
void main(){vec3 p=Position+ChunkOffset;gl_Position=ProjMat*ModelViewMat*vec4(p,1.);texCoord=UV0;faceNormal=Normal;heightOffset=p.y;localXZ=p.xz;skyExposure=clamp(float(UV2.y)/240.,0.,1.);}
