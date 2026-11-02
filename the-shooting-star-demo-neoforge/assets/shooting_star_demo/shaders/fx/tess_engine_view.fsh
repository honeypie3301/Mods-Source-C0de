#include "star.glsl"
uniform vec3 CamPos;
uniform vec3 CamFwd;
uniform vec3 CamUp;
uniform vec3 CamRight;
uniform vec3 KeyDir;
uniform vec4 KeyCol;
uniform vec4 V0;
uniform vec4 V1;
uniform vec4 V2;
uniform sampler2D MilkyTop;
uniform sampler2D EarthDay;
#include "tess_engine.glsl"
vec3 _l1010(vec3 ro, vec3 rd, float _lOi01, out float _llO0I) {
_llO0I = 1e9;
if (rd.y >= -1e-4) return vec3(0.0);
float t = (V1.w - ro.y) / rd.y;
if (t <= 0.0) return vec3(0.0);
_llO0I = t;
vec3 q = ro + rd * t;
vec2 xz = q.xz;
float _llIli = max(-rd.y, 0.04);
float _li010 = _lOi01 * t / _llIli;
vec3 col = vec3(0.35, 0.42, 0.7) * 0.018 * (0.4 + fbm2(xz * 0.9)) + vec3(0.6, 0.5, 0.45) * 0.008;
for (int _llO01 = 0; _llO01 < 2; _llO01++) {
float cell = _llO01 == 0 ? 0.16 : 0.07;
vec2 id = floor(xz / cell);
vec2 f = xz / cell - id;
float h = hash12(id + 7.0 + float(_llO01) * 13.0);
if (h > 0.55) continue;
vec2 c = 0.3 + 0.4 * hash22(id + 3.1);
float r = (_llO01 == 0 ? 0.25 : 0.18) * (0.4 + 0.6 * hash12(id + 9.4));
vec2 uv = (f - c) / r;
if (dot(uv, uv) >= 1.0) continue;
uv = rot(h * 40.0) * uv;
float _ll0Ol = log2(max(_li010 / (2.0 * r * cell) * 2048.0, 1e-3));
vec3 g = _l10Ol(textureLod(MilkyTop, uv * 0.5 + 0.5, _ll0Ol).rgb);
g *= mix(vec3(1.0, 0.82, 0.66), vec3(0.72, 0.84, 1.0), hash12(id + 1.7)) * (0.5 + 0.9 * hash12(id + 2.2));
col += g * (_llO01 == 0 ? 1.4 : 0.8);
}
return col * exp(-t * 0.04);
}
vec3 _lIO0i(vec3 ro, vec3 rd, float _lOi01, out float _llO0I) {
_llO0I = 1e9;
vec3 c = vec3(0.0, V2.w, 0.0);
float R = V2.z;
vec2 hs = raySphere(ro, rd, c, R);
vec3 col = vec3(0.0);
float tp;
float d = rayPointDist(ro, rd, c, tp);
if (hs.x > 0.0) {
_llO0I = hs.x;
vec3 n = normalize(ro + rd * hs.x - c);
vec3 _lOilI = _l10Ol(textureLod(EarthDay, _li0Ol(vec3(n.x, n.z, -n.y)), 0.0).rgb);
float _lii0l = dot(n, KeyDir);
col = _lOilI * KeyCol.rgb * KeyCol.a * max(_lii0l, 0.0) * 0.8 + _lOilI * 0.002;
float _lOllO = 1.0 - max(dot(n, -rd), 0.0);
col += vec3(0.25, 0.5, 1.0) * _lOllO * _lOllO * smoothstep(-0.2, 0.4, _lii0l) * KeyCol.a * 0.25;
} else if (tp > 0.0) {
float x = (d - R) / (R * 0.025);
col += vec3(0.3, 0.55, 1.0) * exp(-x) * 0.25 * KeyCol.a * step(0.0, x);
}
return col;
}
vec3 _lO010(vec3 rd, float _lOi01, out float _l10i1, out vec3 space) {
float up = max(rd.y, 0.0);
float day = V2.y;
vec3 _llii1 = vec3(0.07, 0.2, 0.55);
vec3 _l0010 = vec3(0.45, 0.6, 0.82);
vec3 sky = mix(_l0010, _llii1, sqrt(up)) * day * 1.2;
float _liIl1 = max(dot(rd, KeyDir), 0.0);
sky += vec3(1.0, 0.9, 0.7) * (pow(_liIl1, 8.0) * 0.25 + pow(_liIl1, 600.0) * 30.0) * day;
_l10i1 = exp(-0.12 / max(rd.y, 0.03));
space = _l00Ol(rd, _lOi01, 1.0) * (1.0 - day * 0.97);
return sky;
}
vec3 ground(vec3 ro, vec3 rd, float _lOi01, out float _llO0I) {
_llO0I = 1e9;
if (rd.y >= -1e-5) return vec3(0.0);
float t = (V1.w - ro.y) / rd.y;
if (t <= 0.0) return vec3(0.0);
_llO0I = t;
vec3 q = ro + rd * t;
float _li010 = _lOi01 * t / max(-rd.y, 0.05);
vec3 _l010O = mix(vec3(0.09, 0.16, 0.05), vec3(0.13, 0.12, 0.09), vnoise2(q.xz * 40.0));
vec3 col = _l010O * KeyCol.rgb * KeyCol.a * max(KeyDir.y, 0.0) * 0.8 + _l010O * 0.05 * V2.y + _l010O * 0.01;
if (max(abs(q.x), abs(q.z)) < 1.0) {
vec2 g = abs(fract(q.xz * 4.0 + 0.5) - 0.5) / 4.0;
float _l1Il1 = _l0I1O(min(g.x, g.y), 0.002, _li010);
col += prism7(_li01O(q)) * _l1Il1 * 0.6;
}
return col * exp(-t * 0.08) + vec3(0.4, 0.55, 0.8) * V2.y * 0.2 * (1.0 - exp(-t * 0.08));
}
void main() {
float _liO0l = V0.x;
float _lOi01 = 2.0 * _liO0l / OutSize.y;
gPix = _lOi01;
_l100l = V0.y;
_li00l = 0.37;
vec2 _lO00l = texCoord * 2.0 - 1.0;
vec2 _llili = vec2(_lO00l.x * OutSize.x / OutSize.y, _lO00l.y);
vec3 rd = normalize(CamFwd + (CamRight * _llili.x + CamUp * _llili.y) * _liO0l);
vec3 ro = CamPos;
int _lOill = int(V0.z + 0.5);
vec3 _llIOI = KeyCol.rgb * KeyCol.a;
float _llli0 = 1e9;
vec3 bg;
float _l10i1 = 1.0;
vec3 _lIli0 = vec3(0.0);
vec3 space = vec3(0.0);
bool _l1li0 = _lOill == 2 || _lOill == 3;
if (_lOill == 0) {
bg = _l1010(ro, rd, _lOi01, _llli0) + _l1O01(rd, _lOi01) * 0.12 + vec3(0.004, 0.005, 0.009);
} else if (_lOill == 1) {
bg = _l00Ol(rd, _lOi01, 0.8) + _l1O01(rd, _lOi01) * 0.25;
float _lili0;
vec3 e = _lIO0i(ro, rd, _lOi01, _lili0);
bg = _lili0 < 1e8 ? e : bg + e;
_llli0 = _lili0;
} else if (_l1li0) {
_lIli0 = _lO010(rd, _lOi01, _l10i1, space);
bg = _lIli0 + space * _l10i1;
float _lOli0;
vec3 _l0li0 = ground(ro, rd, _lOi01, _lOli0);
if (_lOli0 < 1e8) {
bg = _l0li0;
_llli0 = _lOli0;
_l10i1 = 1.0;
}
} else {
bg = _l00Ol(rd, _lOi01, 0.7) + vec3(0.006, 0.006, 0.01) * (0.6 + 0.4 * rd.y);
}
vec3 col;
_l1l1O = int(V1.y + 0.5);
if (_l1li0) _llI1O(vec3(0.16, 0.25, 0.42) * V2.y + vec3(0.004, 0.005, 0.01), 0.22);
if (V1.x > 0.5) {
_lOl1O(KeyDir, _llIOI);
vec4 far = _lI110(ro, rd, _llli0, _lOi01);
if (_l1li0 && _llli0 > 1e8) {
float _l10lI = exp(-0.1 / max(rd.y, 0.02));
col = bg * (1.0 - far.a * _l10lI * V2.x) + far.rgb * _l10lI;
} else {
col = bg * (1.0 - far.a) + far.rgb;
}
} else {
_liIIO h = _lOI0O(ro, rd, _llli0, V0.w);
col = h.t > 0.0 ? _llII0(h, ro, rd, KeyDir, _llIOI, _lOi01) : bg;
col += _l0I10(ro, rd, h.t > 0.0 ? h.t : _llli0, _lOi01);
}
col = max(col, vec3(0.0));
if (col.r != col.r || col.g != col.g || col.b != col.b) col = vec3(1.0, 0.0, 1.0);
col = 1.0 - exp(-col * 1.1);
col = pow(col, vec3(1.0 / 2.2));
fragColor = vec4(col, 1.0);
}