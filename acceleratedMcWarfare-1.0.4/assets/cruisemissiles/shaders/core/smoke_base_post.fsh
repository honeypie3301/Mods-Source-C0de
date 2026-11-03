#version 150
uniform float DhDepthReversed;
bool cmDhSurface(float depth){return DhDepthReversed>.5 ? depth>.0000001 : depth<.9999995;}

uniform sampler2D Sampler0;
uniform sampler2D DhDepthSampler;
uniform mat4 DhInvViewProjMat;
uniform vec2 ScreenSize;
uniform float HasDhDepth;

in vec2 texCoord;
in vec4 vertexColor;
in vec3 cameraRelativePos;

out vec4 fragColor;

void main() {
    vec4 smoke = texture(Sampler0, texCoord) * vertexColor;
    // Remove the nearly transparent rectangular outskirts of large atlas
    // sprites; they otherwise read as holes over denser smoke behind them.
    if (smoke.a < 0.035) discard;
    if (HasDhDepth > 0.5) {
        vec2 screenUv = gl_FragCoord.xy / max(ScreenSize, vec2(1.0));
        float dhDepth = texture(DhDepthSampler, screenUv).r;
        if (cmDhSurface(dhDepth)) {
            vec4 clip = vec4(screenUv * 2.0 - 1.0, dhDepth * 2.0 - 1.0, 1.0);
            vec4 dhH = DhInvViewProjMat * clip;
            vec3 dhPos = dhH.xyz / max(abs(dhH.w), 1e-6);
            float particleDistance = length(cameraRelativePos);
            float tolerance = clamp(1.0 + particleDistance * 0.0025, 1.0, 6.0);
            if (length(dhPos) + tolerance < particleDistance) discard;
        }
    }
    fragColor = smoke;
}
