#include "star.glsl"
uniform vec3 CamPos;
uniform vec3 CamFwd;
uniform vec3 CamUp;
uniform vec3 CamRight;
uniform vec3 KeyDir;
uniform vec4 KeyCol;
uniform vec3 FillDir;
uniform vec4 FillCol;
uniform vec4 JupC;
uniform vec4 EarthC;
uniform vec3 RingU;
uniform vec3 RingV;
uniform vec3 RingN;
uniform vec4 N0;
uniform vec4 N1;
uniform vec4 N2;
uniform vec4 N3;
uniform vec4 N4;
uniform vec4 N5;
uniform vec4 N6;
#define M_HULL 1.0
#define M_FIN 2.0
#define M_HOOP 4.0
#define M_COIL 5.0
#define M_SPINE 6.0
#define M_CLAMP 7.0
#define M_ROCK 8.0
#define M_RING 9.0
#define M_BREECH 10.0
const vec3 _lOl1I = vec3(1.0, 0.3, 0.06);
const vec3 _l0l1I = vec3(1.0, 0.62, 0.3);
const vec3 _llI1I = vec3(1.0, 0.94, 0.86);
const vec3 _lII1I = vec3(0.02, 0.008, 0.01);
const float _liilI = 1e30;
const float _l1I1I = 0.5;
float _lI0Ol = 0.0;
float _liI1I = 0.0;
float _lOI1I = 0.0;
float _l0I1I = 0.0;
float _ll11I = 0.0;
int _lI11I = 0;
float _l111I = 0.0;
float _li11I = 0.0;
float _lO11I = 0.0;
float _l011I(vec3 p, vec3 b) {
vec3 q = abs(p) - b;
return length(max(q, 0.0)) + min(max(q.x, max(q.y, q.z)), 0.0);
}
float _lli1I(vec2 p, float r) {
const vec3 k = vec3(-0.866025404, 0.5, 0.577350269);
p = abs(p);
p -= 2.0 * min(dot(k.xy, p), 0.0) * k.xy;
p -= vec2(clamp(p.x, -k.z * r, k.z * r), r);
return length(p) * sign(p.y);
}
float _lIi1I(float z) {
float _lI1lI = 0.018;
if (z > 0.04) {
float k = saturate((z - 0.04) / 0.46);
return _lI1lI * (1.0 - k) * (1.0 - 0.15 * k * (1.0 - k));
}
if (z < -0.42) {
return mix(0.0135, _lI1lI, saturate((z + 0.5) / 0.08));
}
return _lI1lI * (1.0 - 0.06 * exp(-sqr((z + 0.1) / 0.05)));
}
vec2 _l1i1I(vec3 p) {
float z = p.z;
float r = _lIi1I(clamp(z, -_l1I1I, _l1I1I));
float d = _lli1I(p.xy, r) * 0.9;
d = max(d, abs(z) - _l1I1I);
vec2 _lii1I = vec2(d, M_HULL);
float _lOi1I = z + _l1I1I;
if (_lOi1I < 0.26) {
vec2 q = abs(p.xy);
float _l0i1I = mix(0.062, r * 0.9, smoothstep(0.0, 0.24, _lOi1I));
float _llO1I = 0.0016;
float _lIO1I = max(q.y - _llO1I, q.x - _l0i1I);
float _l1O1I = max(q.x - _llO1I, q.y - _l0i1I);
float _liO1I = max(min(_lIO1I, _l1O1I), max(-_lOi1I, _lOi1I - 0.24)) * 0.85;
if (_liO1I < _lii1I.x) _lii1I = vec2(_liO1I, M_FIN);
}
return _lii1I;
}
vec2 _lOO1I(vec3 p) {
float stretch = min(_lO11I * 0.5, N6.x * 0.3);
p.z = sign(p.z) * max(abs(p.z) - stretch, 0.0);
float rr = length(p.xy);
vec2 band = abs(vec2(rr - 0.07, p.z)) - vec2(0.0035, 0.009);
vec2 _lii1I = vec2(length(max(band, 0.0)) + min(max(band.x, band.y), 0.0) - 0.0008, M_HOOP);
float a = atan(p.y, p.x);
float _l0O1I = TAU / 8.0;
float ai = (floor(a / _l0O1I + 0.5)) * _l0O1I;
vec2 _ll01I = vec2(cos(ai), sin(ai));
vec3 _lI01I = vec3(dot(p.xy, _ll01I) - 0.07, dot(p.xy, vec2(-_ll01I.y, _ll01I.x)), p.z);
float _l101I = _l011I(_lI01I, vec3(0.0065, 0.0075, 0.012)) - 0.0008;
if (_l101I < _lii1I.x) _lii1I = vec2(_l101I, M_COIL);
float _li01I = _l011I(p - vec3(0.0, -0.09, 0.0), vec3(0.004, 0.018, 0.004));
if (_li01I < _lii1I.x) _lii1I = vec2(_li01I, M_SPINE);
return _lii1I;
}
vec2 track(vec3 p) {
float _lO01I = N6.x;
float _l001I = p.z + N4.x;
float cell = floor(_l001I / _lO01I + 0.5);
_l111I = cell + N4.y;
vec3 q = vec3(p.xy, _l001I - cell * _lO01I);
vec2 _lii1I = _lOO1I(q);
vec2 sp = abs(p.xy - vec2(0.0, -0.11)) - vec2(0.012, 0.007);
float _llliI = length(max(sp, 0.0)) + min(max(sp.x, sp.y), 0.0);
if (_llliI < _lii1I.x) _lii1I = vec2(_llliI, M_SPINE);
if (N6.z > 0.5) {
float _lIliI = N3.y >= 0.0 ? 1.0 : 0.0;
float _l1liI = mix(0.05, 0.026, _lIliI);
for (int i = -1; i <= 1; i++) {
vec3 c = p - vec3(0.0, 0.0, float(i) * 0.3);
vec2 _liliI = abs(vec2(length(c.xy) - _l1liI - 0.004, c.z)) - vec2(0.006, 0.012);
float _lOliI = length(max(_liliI, 0.0)) + min(max(_liliI.x, _liliI.y), 0.0) - 0.001;
if (_lOliI < _lii1I.x) _lii1I = vec2(_lOliI, M_CLAMP);
}
}
return _lii1I;
}
vec2 _l0liI(vec3 p) {
const float _llIiI = 2.4;
vec3 q = p + vec3(0.0, 0.0, N5.y);
vec3 cell = floor(q / _llIiI + 0.5);
vec3 c = q - cell * _llIiI;
float h = hash13(cell + _li00l * 13.0);
vec2 far = vec2(_llIiI * 0.45, M_ROCK);
if (h > 0.045 * N5.x) return far;
vec3 off = (vec3(hash13(cell + 1.7), hash13(cell + 3.1), hash13(cell + 5.3)) - 0.5) * _llIiI * 0.55;
if (length(cell.xy * _llIiI + off.xy) < 0.45) return far;
vec3 _lI01I = c - off;
float r = mix(0.05, 0.34, sqr(hash13(cell + 7.1)));
_lI01I.z = sign(_lI01I.z) * max(abs(_lI01I.z) - N6.w * r * 0.8, 0.0);
float d = length(_lI01I) - r;
d += (vnoise3(_lI01I / r * 2.3 + cell) - 0.5) * r * 0.5;
return vec2(min(d * 0.7, _llIiI * 0.45), M_ROCK);
}
vec2 ring(vec3 p, float _lIIiI) {
vec3 q = vec3(dot(p, RingU), dot(p, RingN), dot(p, RingV));
float R = N1.x;
vec2 _lii1I = vec2(length(vec2(length(q.xz) - R, q.y)) - _lIIiI, M_RING);
vec3 b = vec3(cos(N1.z), 0.0, sin(N1.z)) * R;
vec3 _l1IiI = vec3(cos(N1.z), 0.0, sin(N1.z));
vec3 _liIiI = vec3(-sin(N1.z), 0.0, cos(N1.z));
vec3 _lI01I = vec3(dot(q - b, _l1IiI), q.y, dot(q - b, _liIiI));
float _lOIiI = _l011I(_lI01I, vec3(0.006, 0.005, 0.018) + _lIIiI * 0.5);
_lOIiI = min(_lOIiI, _l011I(_lI01I - vec3(0.0, 0.0, 0.0), vec3(0.011, 0.0025, 0.006) + _lIIiI * 0.4));
if (_lOIiI < _lii1I.x) _lii1I = vec2(_lOIiI, M_BREECH);
return _lii1I;
}
vec2 scene(vec3 p) {
if (_lI11I == 1) {
return ring(p, max(N1.y, 0.0));
}
if (_lI11I == 2) {
vec2 _lii1I = _l1i1I(p - vec3(0.0, 0.0, N4.w));
vec2 _llOil = track(p);
return _llOil.x < _lii1I.x ? _llOil : _lii1I;
}
vec2 _lii1I = _l1i1I(p);
if (N5.x > 0.001) {
vec2 _lIO1l = _l0liI(p);
if (_lIO1l.x < _lii1I.x) _lii1I = _lIO1l;
}
return _lii1I;
}
float _l0IiI = 0.0;
vec2 _ll1iI(vec3 p, float t) {
if (_lI11I == 1) {
return ring(p, max(N1.y, _lI0Ol * t * 0.75));
}
return scene(p);
}
float _lI1iI(float _l1lll) {
float w = max(1.0, OutSize.y / 640.0);
return 1.0 - smoothstep(1.8 * w, 3.6 * w, _l1lll);
}
vec2 _l11iI(vec3 ro, vec3 rd, float _li1iI) {
_liI1I = 0.0;
_lOI1I = _liilI;
_l0I1I = 0.0;
_ll11I = _liilI;
float t = 0.0;
if (_lI11I == 1) {
vec2 _lO1iI = raySphere(ro, rd, vec3(0.0), N1.x + 0.08);
if (_lO1iI.y <= 0.0) return vec2(-1.0, 0.0);
t = max(_lO1iI.x, 0.0);
_li1iI = min(_li1iI, _lO1iI.y);
}
float _l01iI = _liilI;
float _lliiI = _liilI;
float _lIiiI = t;
float _l1iiI = _liilI;
float _liiiI = 0.0;
float _lOiiI = _lI11I == 2 ? N6.x * 0.3 : _lI11I == 3 ? 0.9 : 1e9;
_lOI1I = _liilI;
for (int i = 0; i < 160; i++) {
vec2 h = _ll1iI(ro + rd * t, t);
if (_lI11I == 1) {
vec3 _l0iiI = ro + rd * t;
vec3 q = vec3(dot(_l0iiI, RingU), dot(_l0iiI, RingN), dot(_l0iiI, RingV));
float core = length(vec2(length(q.xz) - N1.x, q.y)) / (_lI0Ol * max(t, 1e-6));
if (core < _lOI1I) {
_lOI1I = core;
_l0I1I = atan(q.z, q.x);
_ll11I = t;
}
}
float _l1lll = h.x / (_lI0Ol * max(t, 1e-6));
if (h.x > _l01iI && _lliiI < _l1iiI) {
_l1iiI = _lliiI;
_liiiI = _lIiiI;
}
if (h.x < max(_lI0Ol * t * 0.35, 1e-6)) {
if (t - _liiiI > t * 0.03 + 0.002) {
_liI1I = _lI1iI(_l1iiI);
}
return vec2(t, h.y);
}
_l01iI = h.x;
_lliiI = _l1lll;
_lIiiI = t;
t += min(h.x * 0.9, _lOiiI);
if (t > _li1iI) break;
}
_liI1I = _lI1iI(min(_l1iiI, _lliiI));
return vec2(-1.0, 0.0);
}
vec3 _llOiI(vec3 p, float t) {
float h = max(_lI0Ol * t * 0.5, 2e-6);
vec2 e = vec2(1.0, -1.0) * h;
return normalize(e.xyy * scene(p + e.xyy).x + e.yyx * scene(p + e.yyx).x
+ e.yxy * scene(p + e.yxy).x + e.xxx * scene(p + e.xxx).x);
}
float shadow(vec3 p, vec3 _ll0ll) {
float s = 1.0;
float t = 0.002;
for (int i = 0; i < 24; i++) {
float h = scene(p + _ll0ll * t).x;
s = min(s, 12.0 * h / t);
t += clamp(h, 0.002, 0.08);
if (s < 0.01 || t > 1.5) break;
}
return smoothstep(0.0, 1.0, saturate(s));
}
float _lIOiI(float _lOi0l, float a) {
float _l0Oil = a * a;
float d = _lOi0l * _lOi0l * (_l0Oil - 1.0) + 1.0;
return _l0Oil / (PI * d * d);
}
vec3 _l1OiI(vec3 n, vec3 v, vec3 _ll0ll, vec3 _liOiI, float _lOOiI) {
float _lii0l = max(dot(n, _ll0ll), 0.0);
if (_lii0l <= 0.0) return vec3(0.0);
vec3 h = normalize(_ll0ll + v);
float _l0OiI = max(dot(n, v), 1e-3);
float a = max(_lOOiI * _lOOiI, 0.004);
vec3 _ll0iI = _liOiI + (1.0 - _liOiI) * pow(1.0 - max(dot(h, v), 0.0), 5.0);
float k = sqr(a + 1.0) / 8.0;
float _lI0iI = _l0OiI / (_l0OiI * (1.0 - k) + k) * _lii0l / (_lii0l * (1.0 - k) + k);
return _ll0iI * _lIOiI(max(dot(n, h), 0.0), a) * _lI0iI / (4.0 * _l0OiI * _lii0l + 1e-4) * _lii0l;
}
vec3 _l10iI(vec3 _lIIll) {
float toward = dot(_lIIll, FillDir);
vec3 col = FillCol.rgb * FillCol.a * smoothstep(-0.15, 0.7, toward) * 0.5;
col += vec3(0.01, 0.012, 0.02);
return col;
}
vec3 _li0iI(float _lO0iI) {
float spin = N6.y;
vec3 col = _lOl1I * 0.25;
if (spin > 0.5) {
float _l00iI = exp(-sqr((_lO0iI - 0.35) / 0.5));
float behind = exp(-max(-_lO0iI, 0.0) / 2.5) * step(_lO0iI, 0.35);
float _lllOI = N2.z;
col = _lOl1I * (0.3 + 0.9 * behind) + mix(_l0l1I, _llI1I, _lllOI * _lllOI) * _l00iI * (1.6 + 3.5 * _lllOI);
}
if (N6.z > 0.5 && N3.y >= 0.0) {
col += _llI1I * exp(-N3.y * 6.0) * 6.0 * exp(-abs(_lO0iI) / 0.5);
}
return col;
}
float _lIlOI(vec3 p) {
float r = _lIi1I(clamp(p.z, -_l1I1I, _l1I1I));
float a = atan(p.y, p.x);
float _l1lOI = abs(fract(a / (TAU / 6.0)) - 0.5) * (TAU / 6.0) * r;
float edge = exp(-sqr(_l1lOI / 0.0005));
float band = abs(fract(p.z / 0.1 + 0.5) - 0.5) * 0.1;
float _lilOI = exp(-sqr(band / 0.0007)) * step(p.z, 0.3);
return saturate(edge + _lilOI);
}
vec3 _lOlOI(vec3 p, vec3 n, vec3 v, float id, vec3 _l0lOI, vec3 _llIOI, float _lIIOI) {
float _lllOI = _li11I;
vec3 base = vec3(0.028, 0.026, 0.03);
float _lOOiI = id == M_FIN ? 0.42 : 0.34;
vec3 _liOiI = vec3(0.07, 0.068, 0.072);
float _l1IOI = abs(fract(p.z / 0.025) - 0.5);
base *= 0.85 + 0.3 * step(0.47, _l1IOI);
vec3 col = base * (_llIOI * max(dot(n, _l0lOI), 0.0) * _lIIOI + FillCol.rgb * FillCol.a * max(dot(n, FillDir), 0.0) * 0.5);
col += _l1OiI(n, v, _l0lOI, _liOiI, _lOOiI) * _llIOI * _lIIOI;
col += _l1OiI(n, v, FillDir, _liOiI, _lOOiI) * FillCol.rgb * FillCol.a * 0.5;
vec3 r = reflect(-v, n);
col += _l10iI(r) * (_liOiI + (1.0 - _liOiI) * pow(1.0 - max(dot(n, v), 0.0), 5.0)) * 0.45;
if (_lI11I == 2) {
vec3 around = normalize(vec3(p.xy, 0.0) + 1e-6);
float _lO01I = N6.x;
float _l001I = p.z + N4.x;
float near = _l001I - floor(_l001I / _lO01I + 0.5) * _lO01I;
vec3 _lOliI = _li0iI(p.z - near) * exp(-sqr(near / 0.05));
col += _lOliI * (base * 3.0 + _liOiI * 0.4) * (0.35 + 0.65 * max(dot(n, around), 0.0));
}
float s = id == M_FIN ? 0.0 : _lIlOI(p);
float _liIOI = id == M_FIN ? exp(-sqr((max(abs(p.x), abs(p.y)) - mix(0.062, 0.016, smoothstep(0.0, 0.24, p.z + _l1I1I))) / 0.0015)) : 0.0;
vec3 _liiil = mix(_lOl1I, mix(_l0l1I, _llI1I, saturate(_lllOI - 0.5) * 2.0), saturate(_lllOI * 1.3));
col += _liiil * (s + _liIOI) * (0.45 + 5.0 * _lllOI);
float _lOIOI = smoothstep(0.18, 0.5, p.z);
col += _l0IOI(0.3 + 0.9 * _lllOI * _lOIOI) * _lOIOI * _lllOI * _lllOI * 9.0;
col += _l0IOI(0.2 + 0.5 * _lllOI) * saturate(_lllOI - 0.75) * 1.6;
return col;
}
vec3 _ll1OI(vec3 p, vec3 rd, float id, float t) {
vec3 n = _llOiI(p, t);
vec3 v = -rd;
vec3 _l0lOI = normalize(KeyDir);
vec3 _llIOI = KeyCol.rgb * KeyCol.a;
float _lIIOI = _lI11I == 1 ? 1.0 : shadow(p + n * max(_lI0Ol * t, 0.0004), _l0lOI);
if (id == M_HULL || id == M_FIN) {
vec3 _lI1OI = _lI11I == 2 ? p - vec3(0.0, 0.0, N4.w) : p;
return _lOlOI(_lI1OI, n, v, id, _l0lOI, _llIOI, _lIIOI);
}
if (id == M_ROCK) {
vec3 _l11OI = vec3(0.2, 0.16, 0.13) * (0.6 + 0.8 * vnoise3(p * 30.0));
float _li1OI = saturate((dot(n, _l0lOI) + 0.35) / 1.35);
vec3 col = _l11OI * (_llIOI * 1.4 * _li1OI * _lIIOI + vec3(0.05, 0.055, 0.07));
col += _lOl1I * _l11OI * 4.0 * _li11I * exp(-length(p.xy) / 0.4);
return col;
}
if (id == M_RING || id == M_BREECH) {
return vec3(0.02) * _llIOI * max(dot(n, _l0lOI), 0.0) + _l1OiI(n, v, _l0lOI, vec3(0.3), 0.3) * _llIOI;
}
float _lO01I = N6.x;
float _l001I = p.z + N4.x;
float _lO0iI = floor(_l001I / _lO01I + 0.5) * _lO01I - N4.x;
vec3 _l11OI = id == M_CLAMP ? vec3(0.022, 0.02, 0.02) : vec3(0.014, 0.014, 0.017);
float _lO1OI = step(0.08, abs(fract(atan(p.y, p.x) / TAU * 48.0) - 0.5) * 2.0);
_l11OI *= 0.7 + 0.3 * _lO1OI;
float _lOOiI = 0.32;
vec3 _liOiI = vec3(0.16, 0.15, 0.15);
vec3 col = _l11OI * (_llIOI * max(dot(n, _l0lOI), 0.0) * _lIIOI + FillCol.rgb * FillCol.a * max(dot(n, FillDir), 0.0) * 0.15 + 0.003);
col += _l1OiI(n, v, _l0lOI, _liOiI, _lOOiI) * _llIOI * _lIIOI * 0.6;
col += _l10iI(reflect(-v, n)) * 0.08;
if (id == M_HOOP) {
float inner = saturate(-dot(n, normalize(vec3(p.xy, 0.0))));
float _l01OI = step(0.7, fract(atan(p.y, p.x) / TAU * 96.0)) * step(abs(p.z - _lO0iI), 0.006);
col += _li0iI(_lO0iI) * _l01OI * inner * 0.9;
}
if (id == M_COIL || id == M_HOOP) {
vec3 _lOliI = _li0iI(_lO0iI);
float _lliOI;
if (id == M_COIL) {
float _lIiOI = saturate(-dot(n, normalize(vec3(p.xy, 0.0))));
float _l1iOI = step(0.55, fract((p.z - _lO0iI) / 0.004));
_lliOI = _lIiOI * (0.35 + 0.65 * _l1iOI);
} else {
_lliOI = exp(-sqr(abs(p.z - _lO0iI) / 0.0015)) * 0.6;
}
float _liiOI = 0.85 + 0.15 * sin(_l100l * 90.0 + hash11(_l111I) * 40.0);
col += _lOliI * _lliOI * _liiOI;
}
if (id == M_CLAMP) {
float _l10ll = atan(p.y, p.x) / TAU * 12.0;
col += _lOl1I * 0.7 * exp(-sqr((fract(_l10ll) - 0.5) / 0.04));
if (N3.y >= 0.0) {
col += _llI1I * exp(-N3.y * 8.0) * 4.0;
}
}
col += _l0IOI(0.4 + 0.5 * _li11I) * _l11OI * 8.0 * _li11I * exp(-length(p - vec3(0.0, 0.0, N4.w)) / 0.08);
return col;
}
vec3 _lOiOI(vec3 ro, vec3 rd, float _l0iOI) {
float speed = saturate(_lO11I / (N6.x * 0.8) - 0.3);
if (speed <= 0.001) return vec3(0.0);
vec3 col = vec3(0.0);
for (int i = 0; i < 16; i++) {
float a = float(i / 2) * TAU / 8.0 + (float(i - (i / 2) * 2) - 0.5) * 0.05;
vec3 at = vec3(cos(a) * 0.066, sin(a) * 0.066, 0.0);
float tRay;
float d = raySegmentDist(ro, rd, at + vec3(0.0, 0.0, -6.0), at + vec3(0.0, 0.0, 80.0), tRay);
if (tRay > _l0iOI) continue;
float w = max(0.0012, tRay * _lI0Ol * 0.8);
vec3 p = ro + rd * tRay;
vec3 c = _li0iI(p.z) * vec3(1.0, 0.8, 0.7);
col += c * (exp(-d / w) * 0.25 + exp(-d / (w * 6.0)) * 0.035) * exp(-max(p.z, 0.0) / 30.0);
}
return col * speed;
}
vec3 _llOOI(vec3 ro, vec3 rd, float _l0iOI, float _lIOOI) {
if (N6.y < 0.5 && N3.x < 0.0) return vec3(0.0);
vec3 col = vec3(0.0);
float R = N1.x;
float _lllOI = N2.z;
if (N3.x < 0.0) {
float a = N1.w;
vec3 p = (RingU * cos(a) + RingV * sin(a)) * R;
float tp;
float d = rayPointDist(ro, rd, p, tp);
float _l1OOI = min(_l0iOI + 0.08, _lIOOI);
if (tp < _l1OOI) {
float x = d / max(tp, 1e-6) / _lI0Ol;
vec3 hot = mix(_l0l1I, _llI1I, 0.4 + 0.6 * _lllOI);
col += hot * (exp(-sqr(x / (2.5 + 3.0 * _lllOI))) * (6.0 + 14.0 * _lllOI) + exp(-x / (14.0 + 20.0 * _lllOI)) * 1.2);
vec3 _lIIll = normalize(p - ro);
vec3 off = rd - _lIIll * dot(rd, _lIIll);
vec2 sq = vec2(dot(off, CamRight), dot(off, CamUp)) / _lI0Ol;
col += hot * exp(-abs(sq.y) / 1.2) * exp(-abs(sq.x) / (60.0 + 140.0 * _lllOI)) * (0.6 + _lllOI);
}
if (_lOI1I < 40.0 && _ll11I < _l1OOI) {
float behind = mod(a - _l0I1I, TAU);
float _liOOI = N3.z;
float along = exp(-behind / max(_liOOI * 0.35, 1e-3)) * step(behind, _liOOI);
float width = 1.5 + 4.0 * _lllOI;
col += mix(_lOl1I, mix(_l0l1I, _llI1I, _lllOI), along) * along
* (exp(-sqr(_lOI1I / width)) * (3.0 + 6.0 * _lllOI) + exp(-_lOI1I / (width * 5.0)) * 0.6);
}
}
return col;
}
vec3 _lOOOI(vec3 p, float _l0OOI, float _ll0OI) {
vec3 q = vec3(dot(p, RingU), dot(p, RingN), dot(p, RingV));
float a = atan(q.z, q.x);
float _lI0OI = mod(a - N1.z, TAU);
float _l10OI = N2.x * TAU;
float _l1iIl = step(_lI0OI, _l10OI);
float _l0O1I = step(0.3, fract(_lI0OI * 180.0 / PI));
float _li0OI = exp(-sqr((_lI0OI - _l10OI) / 0.05)) * step(0.001, N2.x) * (1.0 - step(0.999, N2.x));
vec3 col = _lOl1I * _l1iIl * (0.6 + 0.4 * _l0O1I) * 1.2 + _llI1I * _li0OI * 12.0;
col += _l0IOI(0.3 + 0.7 * N2.y) * N2.y * (0.8 + 4.0 * N2.y);
col *= _l0OOI / max(_ll0OI, 1e-6);
return col;
}
vec3 _lO0OI(vec3 ro, vec3 rd, vec2 _l000l, float _lIOOI) {
float s = N3.x;
if (s < 0.0 || _lI11I != 1) return vec3(0.0);
vec3 col = vec3(0.0);
vec3 b = (RingU * cos(N1.z) + RingV * sin(N1.z)) * N1.x;
vec3 _l00OI = RingU;
float _lll0I = 0.02 + s * 300.0;
float _llOil;
float d = raySegmentDist(ro, rd, b, b + _l00OI * _lll0I, _llOil);
float w = max(0.0006, _llOil * _lI0Ol * 0.8);
float _lIl0I = exp(-s * 3.0);
col += (_llI1I * exp(-d / w) * 8.0 + _l0l1I * exp(-d / (w * 8.0)) * 1.5) * _lIl0I;
float _l1l0I;
float _lil0I = rayPointDist(ro, rd, b, _l1l0I);
if (_l1l0I < _lIOOI) {
vec3 _lOl0I = normalize(b - ro);
vec3 off = rd - _lOl0I * dot(rd, _lOl0I);
vec2 q = vec2(dot(off, CamRight), dot(off, CamUp)) / _lI0Ol;
float r = length(q);
float _l10ll = atan(q.y, q.x);
float k = floor(_l10ll / TAU * 22.0);
float _l0l0I = (40.0 + 160.0 * hash11(k + _li00l * 7.0)) * (0.4 + 0.6 * exp(-s * 1.5));
float _llI0I = exp(-sqr((fract(_l10ll / TAU * 22.0) - 0.5) / 0.08));
float _lII0I = _llI0I * exp(-r / _l0l0I) * step(0.4, hash11(k * 3.3 + 1.0));
float _lIl1I = exp(-s * 5.0);
col += (_llI1I * (exp(-r / 6.0) * 30.0 + _lII0I * 4.0) + _l0l1I * exp(-r / 60.0) * 2.0) * _lIl1I;
float tp = rayPlane(ro, rd, b, _l00OI);
if (tp > 0.0 && tp < _lIOOI) {
float rr = length(ro + rd * tp - b);
float _l0I1l = 0.01 + s * 0.35;
float ring = exp(-sqr((rr - _l0I1l) / (0.004 + s * 0.03))) * exp(-s * 1.8);
col += mix(_llI1I, _lOl1I, saturate(s * 1.5)) * ring * 6.0;
}
}
return col;
}
vec3 _l1I0I(vec3 ro, vec3 rd, float _l0iOI) {
float k = N5.z;
if (k < 0.001 || _lI11I != 3) return vec3(0.0);
vec2 o = ro.xy;
vec2 _liI0I = rd.xy;
float a = dot(_liI0I, _liI0I);
float bb = dot(o, _liI0I);
float c = dot(o, o) - 0.3 * 0.3;
float h = bb * bb - a * c;
if (h < 0.0 || a < 1e-8) return vec3(0.0);
h = sqrt(h);
float t0 = max((-bb - h) / a, 0.0);
float t1 = min((-bb + h) / a, _l0iOI);
if (t1 <= t0) return vec3(0.0);
vec3 col = vec3(0.0);
const int _lOI0I = 28;
float _l0I0I = (t1 - t0) / float(_lOI0I);
float _lI1ll = hash12(gl_FragCoord.xy + _l100l);
for (int i = 0; i < _lOI0I; i++) {
vec3 p = ro + rd * (t0 + _l0I0I * (float(i) + _lI1ll));
float z = p.z;
if (z > 0.6 || z < -3.0) continue;
float r = length(p.xy);
float _ll10I = _lIi1I(clamp(z, -_l1I1I, _l1I1I));
float _lI10I = _l1I1I + 0.014;
float _l110I = sqrt(max(_lI10I - z, 0.0) * 0.016);
float _li10I = exp(-sqr((r - _l110I) / 0.004)) * step(z, _lI10I) * smoothstep(-0.9, 0.35, z);
float _lO10I = 0.6 + 0.8 * vnoise3(vec3(atan(p.y, p.x) * 6.0, r * 300.0, z * 8.0 + _l100l * 60.0));
float _l010I = exp(-max(r - _ll10I, 0.0) / 0.005) * step(-_l1I1I - 0.02, z) * step(z, _l1I1I) * _lO10I;
float wz = -_l1I1I - z;
float _lli0I = 0.02 + max(wz, 0.0) * 0.07;
float _lIi0I = vnoise3(vec3(p.xy * 35.0, z * 5.0 + _l100l * 40.0));
float _l1i0I = step(0.0, wz) * exp(-sqr(r / _lli0I)) * exp(-wz / 1.1) * (0.3 + 1.2 * _lIi0I);
vec3 hot = mix(vec3(1.0, 0.5, 0.55), _llI1I, smoothstep(0.0, 0.5, z));
col += (_llI1I * _li10I * 8.0 + hot * _l010I * 3.0 + mix(vec3(1.0, 0.35, 0.2), vec3(0.75, 0.3, 1.0), saturate(wz / 2.0)) * _l1i0I * 2.5) * _l0I0I;
}
return col * k * 7.0;
}
void main() {
_l100l = N0.y;
_li00l = N0.z;
_lI11I = int(N0.w + 0.5);
float _liO0l = N0.x;
_lI0Ol = 2.0 * _liO0l / OutSize.y;
gPix = _lI0Ol;
_li11I = N2.z;
_lO11I = N4.z;
vec2 _lO00l = texCoord * 2.0 - 1.0;
vec2 _l000l = vec2(_lO00l.x * OutSize.x / OutSize.y, _lO00l.y);
vec3 rd = normalize(CamFwd + (CamRight * _l000l.x + CamUp * _l000l.y) * _liO0l);
vec3 bg = texture(DiffuseSampler, texCoord).rgb;
if (_lI11I < 1) {
fragColor = vec4(bg, 1.0);
return;
}
vec3 _lii0I = -log(max(1.0 - min(pow(bg, vec3(2.2)), vec3(0.999)), 1e-4)) / 1.1;
vec3 ro = CamPos;
float _lIOOI = _liilI;
if (_lI11I == 1) {
vec2 _lOi0I = raySphere(ro, rd, vec3(0.0), 1.0);
if (_lOi0I.x > 0.0) _lIOOI = _lOi0I.x;
}
float _li1iI = _lI11I == 1 ? _lIOOI : _lI11I == 2 ? 60.0 : 40.0;
vec2 _l0i0I = _l11iI(ro, rd, _li1iI);
float _llO0I = _l0i0I.x > 0.0 ? _l0i0I.x : _liilI;
vec3 col = _lii0I;
float _l0Oll = _liI1I;
if (_l0i0I.x > 0.0) {
vec3 p = ro + rd * _l0i0I.x;
if (_lI11I == 1) {
float drawn = max(N1.y, _lI0Ol * _l0i0I.x * 0.75);
float _lIO0I = saturate(N1.y / drawn);
vec3 _l1O0I = _ll1OI(p, rd, _l0i0I.y, _l0i0I.x);
col = mix(col, _l1O0I, _lIO0I * (_l0i0I.y == M_BREECH ? 1.0 : 0.95)) + _lOOOI(p, N1.y, drawn) * (_l0i0I.y == M_BREECH ? 0.3 : 1.0);
if (_l0i0I.y == M_BREECH) {
col += _lOl1I * 0.6 * (0.3 + N2.x) + _llI1I * 2.0 * step(0.5, fract(_l100l * 1.5)) * N2.x;
}
} else {
col = _ll1OI(p, rd, _l0i0I.y, _l0i0I.x);
if (_lI11I == 2) {
col = mix(col, _lii0I, smoothstep(12.0, 45.0, _l0i0I.x));
}
}
}
float footprint = _lI0Ol * (_l0i0I.x > 0.0 ? _l0i0I.x : 1.0);
if (_lI11I != 1) {
col = mix(col, _lII1I, _l0Oll * (1.0 - smoothstep(0.0015, 0.006, footprint)) * 0.85);
}
float sky = _l0i0I.x > 0.0 ? 0.0 : 1.0;
vec3 light = vec3(0.0);
if (_lI11I == 1) {
light += _llOOI(ro, rd, _llO0I, _lIOOI) + _lO0OI(ro, rd, _l000l, _lIOOI);
} else if (_lI11I == 2) {
light += _lOiOI(ro, rd, _llO0I);
float tp;
float d = rayPointDist(ro, rd, vec3(0.0, 0.0, N4.w + _l1I1I), tp);
if (tp < _llO0I + 0.05) {
light += _l0IOI(0.5 + 0.6 * _li11I) * _liO0I(d / max(tp, 1e-6), _lI0Ol, 3.0 + 10.0 * _li11I) * _li11I * _li11I * 3.0;
}
} else {
light += _l1I0I(ro, rd, _llO0I);
float tp;
float d = rayPointDist(ro, rd, vec3(0.0, 0.0, _l1I1I), tp);
if (tp < _llO0I + 0.05) {
float glow = _li11I * _li11I + N5.z * 2.0;
light += _l0IOI(0.5 + 0.6 * _li11I) * _liO0I(d / max(tp, 1e-6), _lI0Ol, 3.0 + 12.0 * glow) * glow * 2.0;
}
}
col += light;
col = 1.0 - exp(-col * 1.1);
col = pow(col, vec3(1.0 / 2.2));
fragColor = vec4(col, saturate(sky + lum(light) * 0.5));
}