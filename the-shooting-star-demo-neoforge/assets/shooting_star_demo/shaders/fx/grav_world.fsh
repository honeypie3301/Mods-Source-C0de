#include "grav_sky.glsl"
uniform sampler2D MeshColor;
uniform sampler2D MeshDist;
uniform vec4 S0;
uniform vec4 S1;
uniform vec4 W0;
uniform vec4 W1;
uniform vec3 DropAt;
const vec3 _l01II = vec3(0.7, 0.86, 1.0);
const vec3 _lliII = vec3(0.16, 0.5, 1.0);
const vec3 _lIiII = vec3(0.82, 0.94, 1.0);
float _l1iII(float d, float w) {
return 1.0 - smoothstep(w * 0.5, w, abs(d));
}
vec2 _liiII(int i) {
return i == 0 ? W0.xy : i == 1 ? W0.zw : W1.xy;
}
void main() {
vec2 uv = texCoord;
float depth = rawDepth(uv);
vec3 p = unproject(uv, depth);
bool sky = depth >= 0.99999;
vec3 rd = normalize(p);
float sceneT = sky ? 1.0e9 : length(p);
float space = S0.y;
vec2 _l0i1l = vec2(0.0);
vec3 _lOiII = vec3(0.0);
vec3 _l0iII = project(DropAt);
for (int i = 0; i < 3; i++) {
vec2 _llOII = _liiII(i);
if (_llOII.y > 0.001 && _llOII.x > 0.5) {
vec2 h = raySphere(vec3(0.0), rd, DropAt, _llOII.x);
for (int s = 0; s < 2; s++) {
float tt = s == 0 ? h.x : h.y;
if (tt > 0.0 && tt < sceneT) {
vec3 q = rd * tt;
if (q.y > DropAt.y - 0.5) {
vec3 n = (q - DropAt) / _llOII.x;
float _lIOII = pow(1.0 - min(abs(dot(n, rd)), 1.0), 3.0);
float _l0lll = 1.0 - saturate((q.y - DropAt.y) / (_llOII.x * 0.9));
_lOiII += mix(_lliII, _lIiII, _lIOII) * _lIOII * _llOII.y * (0.45 + 1.2 * _l0lll) * (s == 0 ? 1.0 : 0.5);
_l0i1l += normalize(uv - _l0iII.xy + 1.0e-5) * _lIOII * _llOII.y * 0.012;
}
}
}
}
}
vec3 col = texture(DiffuseSampler, clamp(uv + _l0i1l, 0.001, 0.999)).rgb;
float _l1OII = P0.x;
if (_l1OII > 0.001 && !sky) {
vec2 q = (p - Target).xz;
float r = length(q);
float _l10ll = atan(q.y, q.x);
float _lIllI = P0.y;
float _l1lll = max(length(fwidth(q)), 0.02);
float rings = 0.0;
for (int i = 0; i < 5; i++) {
float _l1Iil = float(i);
float at = (6.0 + _l1Iil * 8.0) * smoothstep(0.0, 0.6 + _l1Iil * 0.15, _lIllI);
float _liOII = step(0.35, fract(_l10ll * (8.0 + _l1Iil * 6.0) / TAU + _l1Iil * 0.13));
rings += _l1iII(r - at, _l1lll * 2.5) * mix(1.0, _liOII, step(1.0, _l1Iil)) * (1.0 - _l1Iil * 0.12);
float tick = _l1iII(fract(_l10ll * (24.0 + _l1Iil * 12.0) / TAU) - 0.5, 0.06) * _l1iII(r - at - 0.9, 1.2);
rings += tick * 0.6;
}
float _lOOII = fract((_l10ll / TAU) - _lIllI * 0.6);
float _l0OII = smoothstep(0.85, 1.0, _lOOII) * smoothstep(40.0, 0.0, r) * step(1.0, r);
vec2 _ll0II = q / 3.0;
vec2 _lI0II = vec2(_ll0II.x + _ll0II.y * 0.57735, _ll0II.y * 1.1547);
vec2 cell = fract(_lI0II) - 0.5;
float _l10II = _l1iII(max(abs(cell.x), abs(cell.y)) - 0.48, 0.06) * smoothstep(42.0, 4.0, r) * 0.35;
float fade = smoothstep(46.0, 30.0, r);
col += _l01II * (rings + _l0OII * 0.5 + _l10II) * fade * _l1OII * 0.9;
}
if (sky) {
if (space > 0.001) {
col = mix(col, _l1iOl(rd), space);
}
float _ll00l = P1.x;
if (_ll00l > 0.001) {
float c = acos(clamp(rd.y, -1.0, 1.0));
float _li0II = clamp(P1.y * 0.45, 0.0, 1.6);
float ring = exp(-sqr((c - _li0II) / 0.02)) + 0.3 * exp(-sqr((c - _li0II) / 0.12));
col += mix(_lIiII, _lliII, 0.35) * ring * _ll00l * 1.3;
}
float _lO0II = S0.x;
if (_lO0II > 0.001) {
vec4 _l00II = texture(MeshColor, uv);
if (_l00II.a > 0.001) {
vec3 _l00lI = sqrt(1.0 - exp(-max(_l00II.rgb, vec3(0.0)) * 1.2));
float _lll1I = texture(MeshDist, uv).r * (1.0 + 3.0 * (1.0 - min(abs(rd.y), 1.0)));
_l00lI = mix(_l00lI, col, (1.0 - space) * (1.0 - exp(-_lll1I * 1.6)) * 0.92);
col = mix(col, _l00lI, saturate(_l00II.a) * _lO0II);
}
}
} else {
col *= 1.0 - 0.25 * space;
float over = S1.x;
if (over > 0.001) {
col = mix(col, vec3(lum(col)) * vec3(0.5, 0.66, 1.0), over * 0.6);
}
float _lIl1I = S0.w;
if (_lIl1I > 0.001) {
col += col * _lliII * _lIl1I * 2.4 + _lIiII * _lIl1I * 0.06;
}
float r = length((p - DropAt).xz);
for (int i = 0; i < 3; i++) {
vec2 _llOII = _liiII(i);
if (_llOII.y > 0.001 && _llOII.x > 0.5) {
float w = 2.0 + _llOII.x * 0.012;
float _l1l1I = exp(-sqr((r - _llOII.x) / w));
float glow = exp(-sqr((r - _llOII.x) / (w * 5.0)));
col += (_lIiII * _l1l1I * 4.0 + _lliII * glow * 1.2) * _llOII.y;
}
}
float _lil1I = P1.z;
if (space > 0.001 && _lil1I > 1.0) {
float f = smoothstep(_lil1I * 0.55, _lil1I, sceneT) * space;
col = mix(col, vec3(0.012, 0.016, 0.034), f);
}
}
col += _lOiII;
fragColor = vec4(col, 1.0);
}