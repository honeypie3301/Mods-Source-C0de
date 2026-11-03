#version 150
uniform sampler2D Sampler0;
uniform vec3 Emitter;
uniform vec3 Jet;
uniform float Energy;
uniform float LightRadius;
in vec2 texCoord;
in vec4 vertexColor;
in vec3 worldPos;
out vec4 fragColor;
void main() {
    vec4 tex = texture(Sampler0, texCoord);
    float opacity = tex.a * vertexColor.a;
    if (opacity < 0.001) discard;
    float t = clamp(dot(worldPos - Emitter, Jet) / max(dot(Jet, Jet), 0.0001), 0.0, 1.0);
    vec3 delta = Emitter + Jet * t - worldPos;
    float distance = length(delta);
    float attenuation = 1.0 / pow(1.0 + distance * distance / (LightRadius * LightRadius), 2.0);
    // Texture relief gives each puff a lit side and a shaded side. Derivatives
    // are in screen space, so the reconstructed tangent frame rotates with it.
    float density = dot(tex.rgb, vec3(0.3333)) * tex.a;
    vec3 dx = dFdx(worldPos), dy = dFdy(worldPos);
    vec3 facing = normalize(-worldPos);
    vec3 normal = normalize(facing - normalize(dx + vec3(1e-8)) * dFdx(density) * 18.0
                                   - normalize(dy + vec3(1e-8)) * dFdy(density) * 18.0);
    vec3 toLight = delta / max(distance, 0.001);
    float diffuse = max(dot(normal, toLight), 0.0);
    float transmission = pow(max(dot(-facing, toLight), 0.0), 3.0) * (1.0 - tex.a * 0.65);
    float relief = 0.16 + diffuse * 0.64 + transmission * 0.20;
    vec3 color = mix(vec3(1.0, 0.59, 0.27), vec3(1.0, 0.87, 0.66), attenuation);
    fragColor = vec4(color * Energy * attenuation * opacity * relief * 0.14, 0.0);
}
