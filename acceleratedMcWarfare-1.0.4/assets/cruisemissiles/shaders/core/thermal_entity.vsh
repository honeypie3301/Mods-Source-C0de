#version 150
in vec3 Position;
in vec4 Color;
in vec3 Normal;
in vec2 UV0;
uniform mat4 ModelViewMat;
uniform mat4 ProjMat;
out vec4 thermalColor;
out vec2 texCoord;
out float facing;
void main(){
 gl_Position=ProjMat*ModelViewMat*vec4(Position,1.);thermalColor=Color;texCoord=UV0;
 facing=abs(normalize(mat3(ModelViewMat)*Normal).z);
}
