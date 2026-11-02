uniform vec2 TexelSize;
uniform float Prefilter;
#include "dim_common.glsl"
vec3 _lOIIlI(vec2 uv) {
vec3 c = texture(DiffuseSampler, uv).rgb;
if (Prefilter > 0.5) {
c = _l0IIlI(c);
float _ll0ll = lum(c);
c *= smoothstep(0.85, 2.4, _ll0ll);
c = min(c, vec3(24.0));
}
return c;
}
void main() {
vec2 uv = texCoord;
vec2 ts = TexelSize;
vec3 a = _lOIIlI(uv + ts * vec2(-2.0, 2.0));
vec3 b = _lOIIlI(uv + ts * vec2(0.0, 2.0));
vec3 c = _lOIIlI(uv + ts * vec2(2.0, 2.0));
vec3 d = _lOIIlI(uv + ts * vec2(-2.0, 0.0));
vec3 e = _lOIIlI(uv);
vec3 f = _lOIIlI(uv + ts * vec2(2.0, 0.0));
vec3 g = _lOIIlI(uv + ts * vec2(-2.0, -2.0));
vec3 h = _lOIIlI(uv + ts * vec2(0.0, -2.0));
vec3 i = _lOIIlI(uv + ts * vec2(2.0, -2.0));
vec3 _liOil = _lOIIlI(uv + ts * vec2(-1.0, 1.0));
vec3 k = _lOIIlI(uv + ts * vec2(1.0, 1.0));
vec3 _ll0ll = _lOIIlI(uv + ts * vec2(-1.0, -1.0));
vec3 _l00II = _lOIIlI(uv + ts * vec2(1.0, -1.0));
vec3 col = e * 0.125 + (a + c + g + i) * 0.03125 + (b + d + f + h) * 0.0625 + (_liOil + k + _ll0ll + _l00II) * 0.125;
fragColor = vec4(col, 1.0);
}