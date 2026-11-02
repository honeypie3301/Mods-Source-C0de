// The hidden frame mark: under the mask's letters every pixel moves Strength (1/255) away from the nearer end of the
// range, so nothing clips and nobody sees it. Levels/Curves bring it out. DiffuseSampler holds this frame under the
// box (copied just before), AuxSampler the mask; the viewport is the box.
uniform vec4 Box;
uniform float Strength;

void main() {
    vec2 local = gl_FragCoord.xy - Box.xy;
    vec4 color = texelFetch(DiffuseSampler, ivec2(local), 0);
    float mask = texture(AuxSampler, vec2(local.x / Box.z, 1.0 - local.y / Box.w)).r;
    float y = dot(color.rgb, vec3(0.2126, 0.7152, 0.0722));
    float shift = Strength * mask * (y > 0.5 ? -1.0 : 1.0);
    fragColor = vec4(clamp(color.rgb + shift, 0.0, 1.0), color.a);
}
