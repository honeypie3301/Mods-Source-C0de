#version 150

in vec2 texCoord;
in vec4 vertexColor;

out vec4 fragColor;

void main() {
    vec2 p = texCoord * 2.0 - 1.0;
    float r = length(p);
    // Soft thermal stamp — max-blend into heat mask
    float soft = 1.0 - smoothstep(0.15, 1.0, r);
    soft *= soft;
    float t = vertexColor.r * soft;
    if (t < 0.004) {
        discard;
    }
    fragColor = vec4(t, t, t, 1.0);
}
