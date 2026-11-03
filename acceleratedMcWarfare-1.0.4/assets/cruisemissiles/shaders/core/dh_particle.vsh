#version 150

in vec3 Position;
in vec2 UV0;
in vec4 Color;
in ivec2 UV2;

uniform sampler2D Sampler2;
uniform mat4 ModelViewMat;
uniform mat4 ProjMat;

out vec2 texCoord;
out vec4 vertexColor;
out vec4 lightMapColor;
out vec3 cameraRelativePos;
flat out int cookoffIndex;

void main() {
    gl_Position = ProjMat * ModelViewMat * vec4(Position, 1.0);
    texCoord = UV0;
    vertexColor = Color;
    cookoffIndex=UV2.x>=256?UV2.x-256:-1;
    lightMapColor = cookoffIndex>=0?vec4(1.0):texelFetch(Sampler2, UV2 / 16, 0);
    cameraRelativePos = Position;
}
