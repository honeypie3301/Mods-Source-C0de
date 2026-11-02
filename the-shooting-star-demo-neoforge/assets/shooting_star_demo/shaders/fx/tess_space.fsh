int gZero = 0;
#define LOOP_ZERO gZero
#include "star.glsl"
#include "title.glsl"
uniform sampler2D EarthDay;
uniform sampler2D EarthAux;
uniform sampler2D MoonColor;
uniform sampler2D MilkyWay;
uniform sampler2D MilkyTop;
uniform sampler2D Planets;
uniform sampler2D Rings;
uniform vec3 CamFwd;
uniform vec3 CamUp;
uniform vec3 CamRight;
uniform vec3 EarthRel;
uniform vec3 MoonRel;
uniform vec3 EarthX;
uniform vec3 EarthY;
uniform vec3 EarthZ;
uniform vec3 SunDir;
uniform vec3 SiteN;
uniform vec3 SunRelS;
uniform vec4 Planet[8];
uniform vec3 Ecliptic;
uniform vec3 SaturnPole;
uniform vec3 GalaxyN;
uniform vec3 ToCentre;
uniform vec3 CentreRel;
uniform vec3 SunRelG;
uniform vec3 FloorRel;
uniform vec3 BulkX;
uniform vec3 BulkZ;
uniform vec3 MapX;
uniform vec3 MapY;
uniform vec3 MapZ;
uniform vec3 MouthE;
uniform vec3 MouthRel;
uniform vec4 EngC;
uniform vec3 EngX;
uniform vec3 EngY;
uniform vec3 EngZ;
uniform vec4 T0;
uniform vec4 T1;
uniform vec4 T2;
uniform vec4 T3;
uniform vec4 T4;
uniform vec4 T5;
uniform vec4 T6;
#include "space.glsl"
#include "tess_engine.glsl"
#define FUNNEL_GRID_IN 10.3
vec3 _lOO0I(vec3 v) {
return vec3(dot(v, EarthX), dot(v, EarthY), dot(v, EarthZ));
}
vec3 _l1OOl(vec3 n) {
vec3 _l0O0I = _lOO0I(SiteN);
vec3 d = n - _l0O0I;
float near = length(d);
vec3 _lI1l1, _l11l1;
_l01O1(_l0O0I, _lI1l1, _l11l1);
float _l10ll = atan(dot(d, _l11l1), dot(d, _lI1l1));
vec3 ring = prism7(_l10ll / TAU + _l100l * 0.3);
float _lI1i0 = smoothstep(0.002, 0.03, length(EarthRel) - 1.0);
return (vec3(1.0) * exp(-near / 0.00015) * 3.0 + ring * exp(-sqr((near - 0.0012) / 0.0005)) * 1.4
+ ring * exp(-near / 0.006) * 0.15) * (0.25 + 0.75 * T2.w) * _lI1i0;
}
vec3 _liOOl(vec3 p) {
return vec3(0.0);
}
vec3 _l11i0(vec3 ro, vec3 rd, vec3 _lIl0l, bool _li1i0, out float _lO1i0) {
bool _lliIl = _lOII1(-ro, 1.0);
vec2 _lIiil = _lliIl ? raySphere(ro, rd, vec3(0.0), 1.0) : vec2(-1.0);
vec3 _l01i0 = MoonRel - EarthRel - ro;
vec2 _lO1I1 = _li1i0 && _lOII1(_l01i0, T1.w) ? raySphere(vec3(0.0), rd, _l01i0, T1.w) : vec2(-1.0);
float _ll0lI = _lIiil.x > 0.0 ? _lIiil.x : _liilI;
float _l01I1 = _lO1I1.x > 0.0 ? _lO1I1.x : _liilI;
vec3 near = _lIl0l;
if (_l01I1 < _ll0lI) {
near = _lIiI1(rd * _l01I1, _l01i0, T1.w, rd, _l01I1);
} else if (_ll0lI < _liilI) {
near = _lI0lI(ro + rd * _ll0lI, rd, _ll0lI);
}
if (_lliIl) {
vec3 through;
vec3 _l10lI = _li0lI(ro, rd, min(_ll0lI, _l01I1), through);
near = near * through + _l10lI;
} else {
near += vec3(0.55, 0.75, 1.0) * _liO0I(length(rd - normalize(-ro)), _lI0Ol, 1.2) * 1.4;
}
_lO1i0 = min(_ll0lI, _l01I1);
return near;
}
vec3 _llii0(vec3 v) {
return vec3(dot(v, BulkX), dot(v, GalaxyN), dot(v, BulkZ));
}
vec3 _lIii0(vec2 q, float _lIlO1, float R) {
vec2 _l1lIl = normalize(vec2(dot(ToCentre, BulkX), dot(ToCentre, BulkZ)));
vec2 _lIlIl = vec2(-_l1lIl.y, _l1lIl.x);
vec2 uv = vec2(dot(q, _lIlIl), dot(q, _l1lIl)) / (2.0 * R) + 0.5;
vec3 col = vec3(0.0);
if (uv.x > 0.0 && uv.y > 0.0 && uv.x < 1.0 && uv.y < 1.0) {
float _ll0Ol = log2(max(_lIlO1 / (2.0 * R) * 2048.0, 1e-3));
col = _l10Ol(textureLod(MilkyTop, vec2(uv.x, 1.0 - uv.y), _ll0Ol).rgb) * 0.9;
}
col += vec3(1.0, 0.86, 0.62) * exp(-sqr(length(q) / max(_lIlO1 * 1.2, 1e-4))) * 1.4 * smoothstep(R * 0.1, R * 0.5, _lIlO1);
return col;
}
float _l1ii0 = 0.0;
float _liii0 = 0.0;
float _lOii0 = 0.0;
float _l0ii0(float r) {
float f = -_lOii0 + 2.0 * sqrt(_l1ii0 * max(r - _l1ii0, 0.0));
return smin(f, 0.0, 0.08 * _liii0 + 1e-3);
}
float _llOi0(float r) {
float a = max(r, _l1ii0 + 1e-4);
float b = max(_liii0, _l1ii0 + 1e-4);
float _lIOi0 = sqrt(a * (a - _l1ii0)) + _l1ii0 * log(sqrt(a) + sqrt(a - _l1ii0));
float _l1Oi0 = sqrt(b * (b - _l1ii0)) + _l1ii0 * log(sqrt(b) + sqrt(b - _l1ii0));
return max(_l1Oi0 - _lIOi0, 0.0);
}
struct _liOi0 {
float t;
vec2 q;
float _lIlO1;
float _lOOi0;
vec3 p;
float depth;
};
_liOi0 _l0Oi0(vec3 ro, vec3 rd) {
_liOi0 s;
s.t = -1.0;
s.q = vec2(0.0);
s._lIlO1 = 1.0;
s._lOOi0 = 0.0;
s.p = vec3(0.0);
s.depth = 0.0;
float _llO0I = -1.0;
if (_lOii0 > 1e-3) {
float R = _liii0 * 1.2 + 1.0;
vec2 _ll0i0 = rayCylinderY(ro, rd, vec3(0.0), R);
float _lI0i0 = abs(rd.y) > 1e-6 ? (0.5 - ro.y) / rd.y : (ro.y < 0.5 ? -_liilI : _liilI);
float _l10i0 = abs(rd.y) > 1e-6 ? (-_lOii0 - 0.5 - ro.y) / rd.y : (ro.y > -_lOii0 - 0.5 ? _liilI : -_liilI);
float _li0i0 = max(max(_ll0i0.x, min(_lI0i0, _l10i0)), 0.0);
float _lO0i0 = min(_ll0i0.y, max(_lI0i0, _l10i0));
if (_ll0i0.y > 0.0 && _lO0i0 > _li0i0) {
int _lllOl = 56 + gZero;
float _l0I0I = (_lO0i0 - _li0i0) / float(_lllOl);
float _l00i0 = _li0i0;
vec3 _lllO0 = ro + rd * _li0i0;
float _lIlO0 = _lllO0.y - _l0ii0(length(_lllO0.xz));
for (int i = 1; i <= _lllOl; i++) {
float t = _li0i0 + _l0I0I * float(i);
vec3 p = ro + rd * t;
float f = p.y - _l0ii0(length(p.xz));
if (f < 0.0 && _lIlO0 >= 0.0) {
float a = _l00i0;
float b = t;
for (int k = 0; k < 8 + gZero; k++) {
float _l00II = 0.5 * (a + b);
vec3 _lilOO = ro + rd * _l00II;
if (_lilOO.y - _l0ii0(length(_lilOO.xz)) < 0.0) {
b = _l00II;
} else {
a = _l00II;
}
}
_llO0I = 0.5 * (a + b);
break;
}
_l00i0 = t;
_lIlO0 = f;
}
if (_llO0I < 0.0 && rd.y < 0.0) {
float t = -ro.y / rd.y;
vec3 p = ro + rd * t;
if (t > 0.0 && length(p.xz) >= R) _llO0I = t;
}
} else if (rd.y < 0.0 && ro.y > 0.0) {
_llO0I = -ro.y / rd.y;
}
} else if (abs(rd.y) > 1e-6) {
float t = -ro.y / rd.y;
if (t > 0.0) _llO0I = t;
}
if (_llO0I <= 0.0) return s;
vec3 p = ro + rd * _llO0I;
float r = length(p.xz);
float _li001 = atan(p.z, p.x);
s.t = _llO0I;
s.p = p;
float _llIli = max(abs(rd.y), 0.06);
float _lIlO1 = _lI0Ol * _llO0I / _llIli;
if (_lOii0 > 1e-3 && r < _l1ii0 * 1.0005 && p.y < -_lOii0 + 0.6) {
s._lOOi0 = 1.0;
s.q = p.xz;
s._lIlO1 = _lIlO1;
s.depth = 1.0;
return s;
}
if (_lOii0 > 1e-3 && r < _liii0) {
float _lll0I = _llOi0(r);
float r0 = _liii0 - _lll0I;
float _l1lO0 = 0.9 * sqr(_lll0I / max(_liii0, 1e-3));
float _lilO0 = _li001 + _l1lO0;
float _lOlO0 = abs(r0);
s.q = _lOlO0 * vec2(cos(_lilO0), sin(_lilO0));
s._lIlO1 = _lIlO1 * max(_lOlO0 / max(r, 1e-3), 1.0) / max(sqrt(r / max(r - _l1ii0, 1e-3)), 1.0);
s.depth = saturate(-p.y / max(_lOii0, 1e-3));
} else {
s.q = p.xz;
s._lIlO1 = _lIlO1;
}
return s;
}
vec3 _l0lO0(vec2 q, float _lIlO1, float _llIO0) {
if (_llIO0 < 0.001) return vec3(0.0);
float r0 = length(q);
float _li001 = atan(q.y, q.x);
gAA = _lIlO1 * 1.2;
float ring = abs(r0 - 4.0 * floor(r0 / 4.0 + 0.5));
float _lIIO0 = TAU / 24.0;
float _l1iIi = abs(_li001 - _lIIO0 * floor(_li001 / _lIIO0 + 0.5)) * r0;
float w = 0.03 + _lIlO1 * 0.2;
float lines = max(line(ring, w), line(_l1iIi, w) * smoothstep(1.0, 3.0, r0));
float fade = 1.0 - smoothstep(60.0, 150.0, r0);
vec3 _llIIl = mix(vec3(0.95, 0.96, 1.0), vec3(0.62, 0.68, 0.8), smoothstep(10.0, 50.0, r0));
return _llIIl * lines * fade * _llIO0 * 0.45;
}
bool _l1IO0 = false;
vec3 _liIO0 = vec3(0.0, 1.0, 0.0);
vec3 _lOIO0 = vec3(0.0);
float _l0IO0 = _liilI;
vec3 _ll1O0 = vec3(0.0);
vec3 _lI1O0 = vec3(0.0);
bool _l11O0 = false;
vec3 _li1O0(vec3 rd, vec3 _lIl0l) {
int _l1l0l = _lil0l();
if (_l1l0l <= 0) return _lIl0l;
vec3 glow = vec3(0.0);
float _lO1O0 = TitleB.y;
float _l01l1 = sin(saturate(TitleL[3].y) * PI) * 0.9;
for (int _liI0l = 0; _liI0l < _l1l0l; _liI0l++) {
vec4 st = TitleL[_liI0l * 4 + 3];
vec3 c = TitleL[_liI0l * 4].xyz;
float _lOi11 = TitleL[_liI0l * 4].w;
vec3 ax = TitleL[_liI0l * 4 + 1].xyz;
vec3 ay = TitleL[_liI0l * 4 + 2].xyz;
float tp = rayPlane(vec3(0.0), rd, c, cross(ax, ay));
if (tp <= 0.0) continue;
vec3 _l01Il = rd * tp - c;
vec2 p = vec2(dot(_l01Il, ax), dot(_l01Il, ay)) / _lOi11 + vec2(2.0, 3.0);
if (p.x < -2.0 || p.x > 6.0 || p.y < -1.2 || p.y > 7.2) continue;
float _lOi01 = _lI0Ol * tp / _lOi11;
int _l01O0 = int(TitleL[_liI0l * 4 + 2].w + 0.5);
int _lliO0 = int(st.w + 0.5);
float _lIiO0 = floor(p.y + 0.5);
float _l1iO0 = p.y > _lIiO0 ? 1.0 : -1.0;
for (int q = 0; q < 4 + LOOP_ZERO; q++) {
float _liiO0 = _lIiO0 + (q >= 2 ? _l1iO0 : 0.0);
if (_liiO0 < 0.0 || _liiO0 > 6.0) continue;
float _lOiO0 = _l01l1 * (_liiO0 >= 3.0 ? 1.0 : -1.0);
float _l0iO0 = floor(p.x - _lOiO0 + 0.5);
float _llOO0 = _l0iO0 + ((q == 1 || q == 3) ? (p.x - _lOiO0 > _l0iO0 ? 1.0 : -1.0) : 0.0);
if (_llOO0 < 0.0 || _llOO0 > 4.0) continue;
int bit = int(_llOO0) + 5 * int(_liiO0);
int on = bit < 20 ? (_l01O0 >> bit) & 1 : (_lliO0 >> (bit - 20)) & 1;
if (on == 0) continue;
float column = float(_liI0l) * 5.6 + _llOO0;
float _lIOO0 = saturate(st.x - column);
if (_lIOO0 <= 0.0) continue;
float _l1OO0 = saturate(st.z * 1.6 - column / _lO1O0 * 0.6);
float fade = _lIOO0 * (1.0 - _l1OO0);
if (fade <= 0.001) continue;
vec2 centre = vec2(_llOO0 + _lOiO0, _liiO0);
float _lOIil = mix(0.35, 1.0, _lIOO0) * (1.0 + _l1OO0 * 0.7);
if (length(p - centre) > 1.05 * _lOIil + _lOi01 * 6.0) continue;
float spin = sqr(1.0 - _lIOO0) * 3.0;
float a = _l100l * 0.35 + spin + st.y * PI * 0.5 + _l1OO0 * PI;
float b = 0.6 + spin * 0.7 + _l1OO0 * 1.3;
float _l1Ill = cos(a);
float _liOO0 = sin(a);
float _liliI = cos(b);
float _lOOO0 = sin(b);
vec2 v[16];
float _llOII[16];
for (int i = 0; i < 16 + LOOP_ZERO; i++) {
vec4 k = vec4((i & 1) == 0 ? -0.5 : 0.5, (i & 2) == 0 ? -0.5 : 0.5, (i & 4) == 0 ? -0.5 : 0.5,
(i & 8) == 0 ? -0.5 : 0.5);
float x = k.x * _l1Ill - k.w * _liOO0;
float w = k.x * _liOO0 + k.w * _l1Ill;
float y = k.y * _liliI - w * _lOOO0;
w = k.y * _lOOO0 + w * _liliI;
vec3 _l0OO0 = vec3(x, y, k.z) * (1.2 / (2.0 - w));
_l0OO0.xz = mat2(0.85, -0.53, 0.53, 0.85) * _l0OO0.xz;
_l0OO0.yz = mat2(0.92, 0.39, -0.39, 0.92) * _l0OO0.yz;
v[i] = centre + _l0OO0.xy * _lOIil;
_llOII[i] = w;
}
float _llIIl = column / max(_lO1O0, 1.0) + _l100l * 0.04;
for (int i = 0; i < 16 + LOOP_ZERO; i++) {
for (int e = 0; e < 4; e++) {
int _liOil = i ^ (1 << e);
if (_liOil < i) continue;
float d = sdSegment2(p, v[i], v[_liOil]);
float _lIlli = d / _lOi01;
float _l1iIl = exp(-_lIlli * _lIlli * 1.2) + exp(-_lIlli * _lIlli * 0.3) * 0.04;
float inner = 0.45 + 0.55 * saturate((_llOII[i] + _llOII[_liOil]) * 0.9 + 0.5);
glow += prism7(_llIIl + float(e) * 0.05 + (_llOII[i] + _llOII[_liOil]) * 0.08) * _l1iIl * inner * fade * 0.8;
}
}
float _lIIi1 = length(p - centre) / (0.22 * _lOIil);
float _l1ili = exp(-_lIIi1 * _lIIi1);
float _lIl1I = exp(-max(st.x - column - 1.0, 0.0) / 0.5) * step(1.0, st.x - column);
glow += vec3(1.0) * _l1ili * _lIl1I * 1.2 * fade;
}
}
return _lIl0l + glow;
}
vec3 _ll0O0(vec3 rd, vec3 _lIl0l, out float _lI0O0) {
_lI0O0 = _liilI;
if (!_l1IO0 || T4.z < 0.5) return _lIl0l;
vec3 _l0Ii0 = vec3(dot(-EngC.xyz, EngX), dot(-EngC.xyz, EngY), dot(-EngC.xyz, EngZ)) / EngC.w;
vec3 _ll1i0 = vec3(dot(rd, EngX), dot(rd, EngY), dot(rd, EngZ));
vec2 _lli1i = raySphere(_l0Ii0, _ll1i0, vec3(0.0), 2.1);
if (_lli1i.y <= 0.0) return _lIl0l;
float _li1iI = min(_l0IO0 / EngC.w, _lli1i.y);
vec3 _l10O0 = normalize(vec3(dot(_liIO0, EngX), dot(_liIO0, EngY), dot(_liIO0, EngZ)));
_liIIO h = _lOI0O(_l0Ii0, _ll1i0, _li1iI, _liI1O(_l0Ii0, _lI0Ol));
vec3 col = _lIl0l;
float _lll01 = _li1iI;
if (h.t > 0.0) {
float _li0O0 = h.t * EngC.w;
if (dot(rd * _li0O0 - _ll1O0, _lI1O0) > 0.0 && !_l11O0) return _lIl0l;
col = _llII0(h, _l0Ii0, _ll1i0, _l10O0, _lOIO0, _lI0Ol);
_lI0O0 = _li0O0;
_lll01 = h.t;
}
return col + _l0I10(_l0Ii0, _ll1i0, _lll01, _lI0Ol);
}
const float _lO0O0 = 28.0;
vec3 _l00O0(vec3 rd, float _l0iOI) {
float on = T4.w;
if (on < 0.001 || T4.z < 0.5) return vec3(0.0);
float _lll00 = Eng[1].w - Eng[0].w;
float _lIl00 = Eng[8].w - Eng[0].w;
bool _l1l00 = abs(_lll00) > abs(_lIl00);
int side = _l1l00 ? (_lll00 > 0.0 ? 1 : 0) : (_lIl00 > 0.0 ? 8 : 0);
vec3 _lil00[4];
for (int c = 0; c < 4 + gZero; c++) {
int a = (c == 1 || c == 2) ? 1 : 0;
int z = c >= 2 ? 4 : 0;
int _li0lO = (_l1l00 ? a * 8 : a) + z + side;
vec3 e = Eng[_li0lO].xyz;
_lil00[c] = EngC.xyz + (EngX * e.x + EngY * e.y + EngZ * e.z) * EngC.w;
}
float _lOl00 = _lO0O0;
float _l1lO0 = 0.0;
if (_lOii0 > 1e-3 && _lO0O0 < _liii0) {
float _l0l00 = _liii0 - _lO0O0;
float lo = _l1ii0 + 1e-4;
float hi = _liii0;
for (int k = 0; k < 14 + gZero; k++) {
float _l00ll = 0.5 * (lo + hi);
if (_llOi0(_l00ll) > _l0l00) {
lo = _l00ll;
} else {
hi = _l00ll;
}
}
_lOl00 = 0.5 * (lo + hi);
_l1lO0 = 0.9 * sqr(_l0l00 / max(_liii0, 1e-3));
}
vec3 lift = GalaxyN * _l0ii0(_lOl00);
float _lIIO0 = TAU / 24.0;
vec3 col = vec3(0.0);
int n = 24 + gZero;
vec3 _llI00 = (_lil00[0] + _lil00[1] + _lil00[2] + _lil00[3]) * 0.25;
vec3 _l0i11 = _lil00[0] - _llI00;
vec3 _llO11 = _lil00[1] - _llI00;
float a0 = atan(dot(_l0i11, BulkZ), dot(_l0i11, BulkX));
float a1 = atan(dot(_llO11, BulkZ), dot(_llO11, BulkX));
float _lII00 = sin(a1 - a0) > 0.0 ? 1.0 : -1.0;
float _l1I00 = floor(a0 / _lIIO0 + 0.5);
for (int i = 0; i < n; i++) {
int e = i / 6;
vec3 top = mix(_lil00[e], _lil00[(e + 1) & 3], float(i - e * 6) / 6.0);
float _l1iIi = (_l1I00 + float(i) * _lII00) * _lIIO0 - _l1lO0;
vec3 _liI00 = FloorRel + (BulkX * cos(_l1iIi) + BulkZ * sin(_l1iIi)) * _lOl00 + lift;
float tRay;
float d = raySegmentDist(vec3(0.0), rd, top, _liI00, tRay);
if (tRay <= 0.0 || tRay > _l0iOI) continue;
float width = max(_lI0Ol * tRay * 0.9, 0.012);
vec3 _l0O1I = _liI00 - top;
float s = saturate(dot(rd * tRay - top, _l0O1I) / dot(_l0O1I, _l0O1I));
float _lil11 = exp(-sqr((fract(s * 3.0 - _l100l * 1.6 + float(i) * 0.37) - 0.5) / 0.05));
col += prism7(float(i) / float(n) + _l100l * 0.05) * (exp(-sqr(d / width)) * (0.9 + 2.2 * _lil11)
+ exp(-d / (width * 8.0)) * 0.08);
}
return col * on;
}
vec3 _lOI00(float r, float R, float _l10ll, float _l0I00) {
float x = (r - R * 1.04) / max(R * 0.012, _l0I00);
float _l1i0O = (r - R * 1.11) / max(R * 0.008, _l0I00);
float _ll1Oi = 0.75 + 0.25 * vnoise2(vec2(_l10ll * 40.0, _l100l * 0.2));
vec3 white = vec3(0.95, 0.97, 1.0);
return white * (exp(-x * x) * 1.8 * _ll1Oi + exp(-_l1i0O * _l1i0O) * 0.35 + exp(-abs(r - R) / (R * 0.12)) * 0.18);
}
vec3 _ll100(vec3 rd, vec3 _lI100, vec3 _llOi1) {
float h = abs(dot(-CentreRel, GalaxyN));
float _l0IOi = smoothstep(0.6, 4.0, h);
vec3 col = _lOll1(rd) * 0.8 * (1.0 - _l0IOi) + _lI100 * (0.45 * (1.0 - _l0IOi) + 0.12) + _llOi1 * _l0IOi;
float _lIO0I;
float _lIi0i;
vec3 _l001i = _l0lli(rd, CentreRel, GalaxyN, ToCentre, 60.0, MilkyTop, _lI0Ol, _liilI, _lIO0I, _lIi0i);
float _l1l0I;
float _lil0I = rayPointDist(vec3(0.0), rd, CentreRel, _l1l0I);
float _lllii = _l1l0I > 0.0 ? exp(-sqr(_lil0I / 4.5)) : 0.0;
col = col * (1.0 - _lIO0I * 0.85 * _l0IOi) + (_l001i * 0.62 + vec3(1.0, 0.82, 0.55) * _lllii * 0.22) * _l0IOi;
col += vec3(1.0, 0.9, 0.75) * _liO0I(length(rd - normalize(SunRelG)), _lI0Ol, 1.3) * 3.0;
return col;
}
vec3 _l1100(vec3 rd, vec3 _lI100) {
vec3 col = _lOll1(rd) * 0.8 + _lI100 * 0.5;
float _l1ilI = _liilI;
vec3 _l1II1 = vec3(0.0);
vec2 hs = _lOII1(SunRelS, T2.x) ? raySphere(vec3(0.0), rd, SunRelS, T2.x) : vec2(-1.0);
if (hs.x > 0.0) {
_l1ilI = hs.x;
_l1II1 = _l0II1(rd * hs.x, SunRelS, T2.x, rd, hs.x);
}
for (int i = 0; i < 8 + gZero; i++) {
if (i == 2) continue;
vec3 c = Planet[i].xyz;
float R = Planet[i].w;
vec2 h = _lOII1(c, R) ? raySphere(vec3(0.0), rd, c, R) : vec2(-1.0);
if (h.x > 0.0 && h.x < _l1ilI) {
_l1ilI = h.x;
_l1II1 = _ll1I1(i, rd * h.x, c, R, rd, h.x);
} else if (h.x <= 0.0 && T1.x > 0.5) {
float _l1iIl = 0.5 + 0.5 * dot(normalize(c - SunRelS), normalize(-c));
col += vec3(1.0, 0.95, 0.85) * _liO0I(length(rd - normalize(c)), _lI0Ol, 1.1) * (0.5 + _l1iIl) * 0.9;
}
}
if (_l1ilI < _liilI) {
col = _l1II1;
}
if (length(SunRelS) < 200.0) {
col += _li1I1(rd, SunRelS, T2.x);
} else {
col += vec3(1.0, 0.95, 0.85) * _liO0I(length(rd - normalize(SunRelS)), _lI0Ol, 1.4) * 2.0;
}
return col;
}
bool _li100 = false;
vec3 _lO100 = vec3(0.0);
vec3 _l0100(vec3 ro, vec3 _lIIII, vec3 rd, vec3 _lI100, vec3 _llOi1, bool _lli00, out float _llli0) {
float _l01l1 = T2.z;
bool above = ro.y > _l01l1 || !_lli00 || T5.w > 0.5;
float _lliIl = above ? T6.x : 0.0;
vec3 col = _lI100 * mix(0.24, 0.5, _lliIl) + _llOi1 * mix(1.0, 0.3, _lliIl);
_llli0 = _liilI;
_liOi0 s = _l0Oi0(ro, _lIIII);
if (s.t > 0.0) {
float r = length(s.p.xz);
if (s._lOOi0 > 0.5) {
_llli0 = s.t;
_li100 = true;
_lO100 = s.p;
col = vec3(0.0);
} else {
if (_lliIl > 0.5) {
_llli0 = s.t;
}
col += _l0lO0(s.q, s._lIlO1, _lliIl);
float _lIi00 = mix(0.06, 5.0, _lliIl);
if (length(s.q) < _lIi00 * 1.05) {
col += _lIii0(s.q, s._lIlO1, _lIi00);
}
if (T4.w > 0.001) {
float r0 = length(s.q);
float _l1i00 = mix(_liii0 * 1.3, 0.0, fract(_l100l * 0.45));
col += prism7(r0 * 0.02 + _l100l * 0.1) * exp(-sqr((r0 - _l1i00) / (0.4 + s._lIlO1))) * 1.4 * T4.w;
}
}
if (_lOii0 > 1e-3) {
col += _lOI00(r, _l1ii0, atan(s.p.z, s.p.x), s._lIlO1) * T3.w * (s._lOOi0 > 0.5 ? 0.6 : 1.0);
}
}
return col;
}
void main() {
gZero = int(step(1e30, abs(T0.z)));
_l100l = T0.y;
_li00l = T0.z;
float _liO0l = T0.x;
_lI0Ol = 2.0 * _liO0l / OutSize.y;
gPix = _lI0Ol;
_l1ii0 = T3.x;
_liii0 = T3.y;
_lOii0 = T3.z;
vec2 _lO00l = texCoord * 2.0 - 1.0;
vec2 _l000l = vec2(_lO00l.x * OutSize.x / OutSize.y, _lO00l.y);
vec3 rd = normalize(CamFwd + (CamRight * _l000l.x + CamUp * _l000l.y) * _liO0l);
float frame = T1.x;
vec3 _lI100 = _l00Ol(rd, _lI0Ol, 1.0);
vec3 _llOi1 = frame > 1.5 ? _l1O01(rd, _lI0Ol) : vec3(0.0);
vec3 col = vec3(0.0);
bool _lii00 = false;
bool _lOi00 = false;
vec3 _l0i00 = vec3(0.0);
vec3 _llO00 = vec3(0.0, 1.0, 0.0);
bool _lIO00 = false;
vec3 _l1O00 = -EarthRel;
vec3 _liO00 = rd;
bool through = false;
float _lOO00 = _liilI;
vec3 ring = vec3(0.0);
float _l0O00 = T4.y;
if (frame < 1.5) {
col = _l1100(rd, _lI100);
_lIO00 = true;
if (frame < 0.5) {
vec2 _lIiil = raySphere(-EarthRel, rd, vec3(0.0), 1.0);
_lOO00 = _lIiil.x > 0.0 ? _lIiil.x : _liilI;
float _l1lOO = _l0O00 > 1e-4 ? rayPlane(vec3(0.0), rd, MouthRel, MapY) : -1.0;
if (_l1lOO > 0.0 && _l1lOO < _lOO00) {
vec3 q = rd * _l1lOO - MouthRel;
float r = length(q);
ring = _lOI00(r, _l0O00, atan(dot(q, MapZ), dot(q, MapX)), _lI0Ol * _l1lOO);
if (r < _l0O00) {
through = true;
_lii00 = true;
_lIO00 = false;
_l0i00 = vec3(dot(q, MapX), dot(q, MapY), dot(q, MapZ)) / T4.x + vec3(0.0, -_lOii0 + 0.02, 0.0);
_llO00 = vec3(dot(rd, MapX), dot(rd, MapY), dot(rd, MapZ));
}
}
}
} else if (frame < 2.5) {
col = _ll100(rd, _lI100, _llOi1);
} else {
_lii00 = true;
_lOi00 = true;
_l0i00 = _llii0(-FloorRel);
_llO00 = _llii0(rd);
}
float _llli0 = _liilI;
if (_lii00) {
col = _l0100(_l0i00, _llO00, rd, _lI100, _llOi1, _lOi00, _llli0);
if (_lOi00 && _li100) {
vec3 off = _lO100 - vec3(0.0, -_lOii0, 0.0);
_l1O00 = MouthE + (MapX * off.x + MapY * off.y + MapZ * off.z) * T4.x;
_liO00 = MapX * _llO00.x + MapY * _llO00.y + MapZ * _llO00.z;
_lIO00 = true;
}
}
if (_lIO00) {
float _ll000;
vec3 _lIl0l = _lOi00 ? _lOll1(_liO00) * 0.8 : col;
vec3 _lIO0i = _l11i0(_l1O00, _liO00, _lIl0l, !_lOi00, _ll000);
if (_lOi00) {
col += _lIO0i * T3.w * (1.0 - smoothstep(_l1ii0 * 0.92, _l1ii0, length(_lO100.xz)));
} else {
col = _lIO0i;
}
}
col += ring;
if (frame < 0.5) {
_l1IO0 = true;
_liIO0 = SunDir;
_lOIO0 = vec3(1.0, 0.96, 0.9) * 2.4;
_l0IO0 = _lOO00 < _liilI ? _lOO00 : 1e6;
_ll1O0 = MouthRel;
_lI1O0 = _l0O00 > 1e-4 ? MapY : vec3(0.0);
_l11O0 = through;
} else if (frame > 2.5) {
_l1IO0 = _l0i00.y > T2.z || T5.w > 0.5;
_liIO0 = -GalaxyN + BulkX * 0.18 + BulkZ * 0.12;
_lOIO0 = vec3(0.78, 0.82, 1.0) * 1.1;
_l0IO0 = _li100 ? 1e30 : _llli0;
_ll1O0 = FloorRel - GalaxyN * _lOii0;
_lI1O0 = _lOii0 > 1e-3 ? -GalaxyN : vec3(0.0);
_l11O0 = _li100;
}
col = _li1O0(rd, col);
float _lI000;
col = _ll0O0(rd, col, _lI000);
if (frame > 2.5 && _l1IO0) {
col += _l00O0(rd, min(_l0IO0, _lI000));
}
if (T5.y > 0.001) {
col += _lIII1(rd, CamFwd, -_l100l * 7.0, 1.4, _lI0Ol, vec3(0.82, 0.88, 1.0), vec3(1.0, 0.95, 0.86)) * 0.8 * T5.y;
}
col = 1.0 - exp(-col * 1.1);
col = pow(col, vec3(1.0 / 2.2));
float _lOIII = T1.z;
float _l0III = T0.w;
float _ll1II = sin(saturate(_lOIII) * PI) * (1.0 - step(0.999, _lOIII)) * step(frame, 0.5);
float _l11II = 1.0;
vec3 _lI1II = col;
if (_l0III < 0.999 || _ll1II > 0.001) {
vec3 world = texture(DiffuseSampler, texCoord).rgb;
float r = length(_l000l);
float an = atan(_l000l.y, _l000l.x);
float _li1II = fbm2(vec2(an * 2.5, log(r + 0.03) * 2.2 - _lOIII * 7.0) + _li00l);
_l11II = smoothstep(_li1II - 0.12, _li1II + 0.12, _l0III * 1.35 - 0.2);
_lI1II = mix(world, col, _l11II);
float _lO1II = smoothstep(0.35, 0.8, vnoise2(_l000l * 2.2 + vec2(0.0, -_lOIII * 5.0) + _li1II) * 0.6 + _li1II * 0.4);
_lI1II = mix(_lI1II, vec3(0.92, 0.94, 1.0), _ll1II * (0.35 + 0.65 * _lO1II) * 0.95);
}
fragColor = vec4(_lI1II, 1.0 - _l11II);
}