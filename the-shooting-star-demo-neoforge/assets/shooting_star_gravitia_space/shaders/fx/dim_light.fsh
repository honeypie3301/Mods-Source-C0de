#include "dim_common.glsl"
#include "dim_star.glsl"
const float _lIOIlI = 2.42;
const vec2 _l1OIlI = vec2(0.0, 0.255);
vec3 _liOIlI(vec2 uv) {
return _l0IIlI(texture(DiffuseSampler, clamp(uv, vec2(0.001), vec2(0.999))).rgb);
}
float _lOOIlI(float a) {
return a < 0.5 ? 3.0 * (0.5 / max(a, 0.002) - 1.0) : 1.0e4;
}
void main() {
vec2 uv = texCoord;
vec2 _lll1i = P1.xy;
float _l11ll = OutSize.x / OutSize.y;
float _l1iOi = P2.x;
float _l0iIl = P2.y;
vec4 _l0OIlI = texture(DiffuseSampler, uv);
vec3 col = _l0IIlI(_l0OIlI.rgb);
vec2 q = (uv - _lll1i) * 2.0;
vec3 rd = normalize(vec3(q.x * _l11ll * P0.z, q.y * P0.z, 1.0));
float _ll0IlI = 2.0 * P0.z / OutSize.y;
vec2 _li1li = (uv - _lll1i) * vec2(_l11ll, 1.0);
float _l0lOl = length(_li1li);
float _lIiOi = P3.y;
vec3 soft = col;
float _lOIl1 = mix(P2.z * smoothstep(0.12, 0.85, _l0lOl), Pts[0].z, _lIiOi);
if (_lOIl1 > 0.0005) {
float _lI0IlI = fract(52.9829189 * fract(dot(gl_FragCoord.xy, vec2(0.06711056, 0.00583715))));
float _lI1Il = 0.0025 * smoothstep(0.5, 1.0, _l0lOl);
vec3 _li1ll = vec3(0.0);
float _l1IlI = 0.0;
for (int k = 0; k < 24; k++) {
float _lO11l = (float(k) + _lI0IlI) / 24.0;
float _llili = 1.0 - _lO11l * _lOIl1;
vec3 c;
c.r = _liOIlI(_lll1i + (uv - _lll1i) * (_llili + _lI1Il)).r;
c.g = _liOIlI(_lll1i + (uv - _lll1i) * _llili).g;
c.b = _liOIlI(_lll1i + (uv - _lll1i) * (_llili - _lI1Il)).b;
float w = 1.0 - _lO11l * 0.4;
_li1ll += c * w;
_l1IlI += w;
}
soft = _li1ll / _l1IlI;
}
vec3 _l10IlI = col;
if (_lIiOi > 0.001) {
vec3 _li1ll = vec3(0.0);
for (int k = 0; k < 7; k++) {
float _lO11l = float(k) / 6.0;
vec3 c = _liOIlI(_lll1i + (uv - _lll1i) * (1.0 - _lO11l * P2.z));
_li1ll = k == 0 ? c : max(_li1ll, c * exp(-_lO11l * 1.6));
}
_l10IlI = _li1ll;
float inner = 1.0 - smoothstep(0.42, 0.62, _l0lOl);
_l10IlI += max(soft - vec3(0.55), vec3(0.0)) * inner * 0.9;
}
col = mix(soft, _l10IlI, _lIiOi * 0.6);
float _lO0il = P0.w;
if (_lO0il > 0.001) {
float _l1iIl = 0.0;
float _liOil = hash12(gl_FragCoord.xy + 7.0);
float _lilOl = 1.0;
for (int k = 0; k < 28; k++) {
float _lO11l = (float(k) + _liOil) / 28.0;
vec2 s = uv + (_lll1i - uv) * _lO11l * 0.92;
float a = texture(DiffuseSampler, clamp(s, vec2(0.001), vec2(0.999))).a;
_l1iIl += max(a * 2.0 - 1.0, 0.0) * _lilOl;
_lilOl *= 0.955;
}
_l1iIl /= 14.0;
vec3 _li0IlI = mix(mix(vec3(1.0, 0.18, 0.32), vec3(1.0, 0.7, 0.36), _l0iIl), vec3(1.0, 0.66, 0.92), _l1iOi);
col += _li0IlI * _l1iIl * _lO0il * mix(2.2, 3.6, _l1iOi);
}
float _l00iI = P0.y;
if (_l00iI > 0.05) {
float _lO0IlI = _l00iI / max(rd.z, 1.0e-3);
vec2 at = rd.xy * _lO0IlI - _l1OIlI;
float rr = length(at);
vec2 _l00IlI = at / max(rr, 1.0e-3);
float _lll1lI = rr - _lIOIlI;
float _li111 = _lO0IlI * _ll0IlI;
float _l01l0 = 0.11 * (1.0 + 0.12 * _l00IlI.x);
float _l0IOi = smoothstep(_l01l0 * 0.5, _l01l0 + 0.12, _lll1lI);
col = mix(col, vec3(0.008, 0.008, 0.025), _l0IOi * 0.9);
float inside = smoothstep(-_l01l0 - 0.5, -_l01l0 - 0.03, _lll1lI) * (1.0 - smoothstep(-_l01l0 - 0.02, -_l01l0 + 0.02, _lll1lI));
col = mix(col, vec3(0.08, 0.1, 0.31), inside * 0.7);
float _lI1lI = 0.0;
float _liIlI = 0.0;
for (int k = 0; k < 8; k++) {
float d = rr * (1.0 - float(k) * 0.004) - _lIOIlI;
_lI1lI += 1.0 - smoothstep(_l01l0 - 0.06, _l01l0 + 0.06 + _li111, abs(d));
_liIlI += exp(-abs(d + _l01l0 * 0.85) / 0.02);
}
_lI1lI /= 8.0;
_liIlI /= 8.0;
float _lIl1lI = exp(-abs(_lll1lI) / (0.14 + _li111 * 2.0)) * (1.0 - _lI1lI);
float _lII00 = smoothstep(0.6, 0.95, dot(_l00IlI, vec2(0.7, -0.71)));
vec3 ring = mix(vec3(0.19, 0.91, 0.41), vec3(0.15, 0.6, 1.0), _lII00);
col = mix(col, ring * 0.95, clamp(_lI1lI * 1.1, 0.0, 1.0));
col += ring * _lIl1lI * 0.4 + vec3(0.37, 0.9, 1.0) * _liIlI * 0.75;
}
float star = P1.z;
if (star > 0.001) {
vec2 d = (uv - _lll1i) * vec2(_l11ll, 1.0);
col += _l1l1lI(d, Pts[0].y, Pts[0].y, P3.w, _l0iIl, P1.w, Pts[0].x) * star;
}
float _l010l = Pts[0].y;
if (_l010l > 1.95) {
vec2 d = (uv - _lll1i) * vec2(_l11ll, 1.0);
float _lil1lI = mix(mix(0.1, 0.22, smoothstep(2.0, 2.3, _l010l)), mix(0.34, 0.7, smoothstep(2.62, 2.84, _l010l)), smoothstep(2.3, 2.62, _l010l));
float _lI1lI = exp(-length(d * vec2(0.5, 1.0)) / _lil1lI);
float on = smoothstep(1.95, 2.1, _l010l);
vec3 _lOl1lI = mix(vec3(1.0, 0.6, 0.31), vec3(1.0, 0.85, 0.66), smoothstep(0.35, 0.85, _lI1lI));
_lOl1lI = mix(_lOl1lI, vec3(1.0, 0.957, 0.878), smoothstep(0.75, 1.0, _lI1lI) * smoothstep(2.6, 2.85, _l010l));
col = mix(col, col * 0.4, _lI1lI * on * 0.5);
col += _lOl1lI * _lI1lI * 1.1 * on * (1.0 + 0.55 * smoothstep(2.6, 2.84, _l010l));
float _l10ll = atan(d.y, d.x);
float ray = fbm2(vec2(_l10ll * 6.0 + 3.0, _l010l * 0.8));
float _lII0I = smoothstep(0.45, 0.8, ray) * smoothstep(0.4, 1.0, length(d));
float _l0l1lI = smoothstep(2.45, 2.85, _l010l);
col += vec3(1.0, 0.55, 0.3) * _lII0I * _l0l1lI * 1.6;
float _l1lOI = smoothstep(0.45, 0.95, length(d * vec2(0.85, 1.0)));
col = mix(col, vec3(0.91, 0.44, 0.29) * 1.1, _l1lOI * smoothstep(2.6, 2.8, _l010l) * 0.85);
}
col *= P2.w;
fragColor = vec4(_lOiIlI(_liiIlI(col), gl_FragCoord.xy), 1.0);
}