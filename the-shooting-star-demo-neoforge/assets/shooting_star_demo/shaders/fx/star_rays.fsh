#include "star.glsl"
uniform vec3 CamPos;
uniform vec3 CamFwd;
uniform vec3 CamUp;
uniform vec3 CamRight;
uniform vec3 KeyDir;
uniform vec3 Muzzle;
uniform vec4 R0;
vec3 _l1O0l(vec3 _lIIll) {
float z = dot(_lIIll, CamFwd);
if (z <= 0.02) return vec3(0.0, 0.0, -1.0);
vec2 s = vec2(dot(_lIIll, CamRight), dot(_lIIll, CamUp)) / (z * R0.x);
return vec3(s.x * OutSize.y / OutSize.x * 0.5 + 0.5, s.y * 0.5 + 0.5, 1.0);
}
vec3 _lO0il(vec2 light, float _l00il, float _li0Oi, float _lilOl) {
vec2 _lO0Oi = (light - texCoord) * _l00il / 40.0;
vec2 uv = texCoord;
vec3 _li11l = vec3(0.0);
float w = 1.0;
float _lI1ll = hash12(texCoord * OutSize);
uv += _lO0Oi * _lI1ll;
for (int i = 0; i < 40; i++) {
uv += _lO0Oi;
if (uv.x < 0.0 || uv.y < 0.0 || uv.x > 1.0 || uv.y > 1.0) break;
vec4 s = texture(DiffuseSampler, uv);
float bright = max(lum(s.rgb) - _li0Oi, 0.0) / (1.0 - _li0Oi);
_li11l += s.rgb * bright * s.a * w;
w *= _lilOl;
}
return _li11l / 40.0;
}
void main() {
vec4 base = texture(DiffuseSampler, texCoord);
vec3 col = base.rgb;
if (R0.y > 0.001) {
vec3 _l0lOI = _l1O0l(normalize(KeyDir));
if (_l0lOI.z > 0.0) {
col += _lO0il(_l0lOI.xy, 1.0, 0.42, 0.985) * vec3(1.0, 0.86, 0.7) * 2.4 * R0.y;
}
}
float _l10ii = R0.z * 3.0 + R0.w * R0.w * 1.4;
if (_l10ii > 0.001) {
vec3 _l00II = _l1O0l(normalize(Muzzle - CamPos));
if (_l00II.z > 0.0) {
vec3 _lII0I = _lO0il(_l00II.xy, mix(0.35, 1.0, R0.z), 0.35, mix(0.9, 0.97, R0.z));
col += _lII0I * mix(vec3(1.0, 0.25, 0.28), vec3(1.0, 0.9, 0.9), R0.z) * _l10ii;
}
}
fragColor = vec4(col, 0.0);
}