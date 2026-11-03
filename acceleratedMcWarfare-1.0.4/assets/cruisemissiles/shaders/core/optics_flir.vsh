#version 150

in vec3 Position;

out vec2 texCoord;

void main() {
    vec2 screenPos = Position.xy * 2.0 - 1.0;
    gl_Position = vec4(screenPos, 0.0, 1.0);
    // FBO → FBO post: no V flip (GUI blit handles orientation).
    texCoord = Position.xy;
}
