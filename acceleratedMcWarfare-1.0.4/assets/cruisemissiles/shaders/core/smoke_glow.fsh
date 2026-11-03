#version 150
uniform float DhDepthReversed;
bool cmDhSurface(float depth){return DhDepthReversed>.5 ? depth>.0000001 : depth<.9999995;}

uniform sampler2D Sampler0;
uniform sampler2D DhDepthSampler;
uniform mat4 DhInvViewProjMat;
uniform vec2 ScreenSize;
uniform float HasDhDepth;
uniform vec3 GlowColor;
uniform float GlowStrength;
uniform vec3 LightPos;
uniform float NightFactor;

in vec2 texCoord;
in vec4 vertexColor;
in vec3 worldPos;

out vec4 fragColor;

void main() {
    vec4 smoke = texture(Sampler0, texCoord);
    float alpha = smoke.a * vertexColor.a;
    if (alpha < 0.01) {
        discard;
    }
    // Match the ordinary smoke pass: illuminated particles behind DH terrain
    // must not show through while their unlit silhouettes are occluded.
    if (HasDhDepth > 0.5) {
        vec2 screenUv = gl_FragCoord.xy / max(ScreenSize, vec2(1.0));
        float dhDepth = texture(DhDepthSampler, screenUv).r;
        if (cmDhSurface(dhDepth)) {
            vec4 clip = vec4(screenUv * 2.0 - 1.0, dhDepth * 2.0 - 1.0, 1.0);
            vec4 dhH = DhInvViewProjMat * clip;
            vec3 dhPos = dhH.xyz / max(abs(dhH.w), 1e-6);
            float particleDistance = length(worldPos);
            float tolerance = clamp(1.0 + particleDistance * 0.0025, 1.0, 6.0);
            if (length(dhPos) + tolerance < particleDistance) discard;
        }
    }

    float texLuma = dot(smoke.rgb, vec3(0.2126, 0.7152, 0.0722));
    float detail = 0.45 + texLuma * 0.55;

    // Reconstruct a soft relief normal from the actual smoke silhouette. This makes
    // one side of every lobe receive the world-space explosion light instead of
    // uniformly recolouring the whole billboard.
    vec2 texel = 1.0 / vec2(textureSize(Sampler0, 0));
    float ax0 = texture(Sampler0, texCoord - vec2(texel.x, 0.0)).a;
    float ax1 = texture(Sampler0, texCoord + vec2(texel.x, 0.0)).a;
    float ay0 = texture(Sampler0, texCoord - vec2(0.0, texel.y)).a;
    float ay1 = texture(Sampler0, texCoord + vec2(0.0, texel.y)).a;
    vec2 relief = vec2(ax0 - ax1, ay0 - ay1);

    vec3 tangent = normalize(dFdx(worldPos));
    vec3 bitangent = normalize(dFdy(worldPos));
    vec3 facing = normalize(-worldPos);
    vec3 normal = normalize(facing + tangent * relief.x * 3.2 + bitangent * relief.y * 3.2);
    vec3 toLight = normalize(LightPos - worldPos);
    float diffuse = max(dot(normal, toLight), 0.0);
    float isotropic = 0.72 + 0.28 * abs(dot(normal, toLight));
    float rim = pow(1.0 - abs(dot(normal, facing)), 2.0);
    // Smoke is a participating volume, not an opaque billboard surface. Keep a
    // strong isotropic term so rotating the camera cannot switch its light off;
    // relief/diffuse only shapes the lobes on top of that stable illumination.
    float volumeLight = isotropic * 0.70 + diffuse * 0.48 + rim * 0.10;
    float lighting = mix(detail, detail * volumeLight, clamp(NightFactor, 0.0, 1.0));

    vec3 glow = GlowColor * vertexColor.rgb * (GlowStrength * alpha * lighting);
    fragColor = vec4(glow, alpha);
}
