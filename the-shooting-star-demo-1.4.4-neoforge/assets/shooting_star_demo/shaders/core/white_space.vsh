#version 150

// White Space (WhiteSpace, SaoUi): one quad a shape; its uv carries the quad's size and its colour the shape (see the
// fragment shader).
uniform mat4 ModelViewMat;
uniform mat4 ProjMat;

in vec3 Position;
in vec2 UV0;
in vec4 Color;

out vec2 texCoord0;
out vec4 vertexColor;

void main() {
    gl_Position = ProjMat * ModelViewMat * vec4(Position, 1.0);
    texCoord0 = UV0;
    vertexColor = Color;
}
