#version 150
in vec3 Position;
in vec2 UV0;
in vec4 Color;
in ivec2 UV2;
uniform mat4 ModelViewMat;
uniform mat4 ProjMat;
out vec2 texCoord;
out vec2 particleCoord;
out vec2 thermalMeta;
out vec4 vertexColor;
out vec3 cameraRelativePos;
void main(){
 gl_Position=ProjMat*ModelViewMat*vec4(Position,1);
 int corner=gl_VertexID%4;
 particleCoord=corner==0?vec2(1,1):corner==1?vec2(1,0):corner==2?vec2(0,0):vec2(0,1);
 thermalMeta=vec2(UV2);
 texCoord=UV0; vertexColor=Color; cameraRelativePos=Position;
}
