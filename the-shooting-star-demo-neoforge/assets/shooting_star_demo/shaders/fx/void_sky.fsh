#include "grav_sky.glsl"
void main() {
vec2 uv = texCoord;
vec3 col = texture(DiffuseSampler, uv).rgb;
float depth = rawDepth(uv);
if (depth >= 0.99999) {
col = _l1iOl(normalize(unproject(uv, depth)));
}
fragColor = vec4(col, 1.0);
}