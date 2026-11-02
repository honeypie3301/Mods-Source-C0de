#include "star.glsl"
#include "title.glsl"
uniform sampler2D MilkyTop;
uniform vec3 CamPos;
uniform vec3 CamFwd;
uniform vec3 CamUp;
uniform vec3 CamRight;
uniform vec3 GunX;
uniform vec3 GunY;
uniform vec3 GunZ;
uniform vec3 CentreRel;
uniform vec3 SunRelG;
uniform vec3 GalaxyN;
uniform vec3 ToCentre;
uniform vec4 S0;
uniform vec4 S1;
#define M_HULL 1.0
#define M_METAL 2.0
#define M_DARK 3.0
#define M_RAD 4.0
#define M_GOLD 5.0
#define M_LENS 6.0
#define M_BRIDGE 7.0
#define M_NAV 8.0
#define M_COIL 10.0
const int _l0Oli = 17;
const float _ll0li = -14.5;
const float _lI0li = 1.05;
const float _l10li = -17.4;
const float _li0li = -19.2;
float _lI0Ol = 0.0;
float _lO0li = 0.0;
float _l00li = 0.0;
float _lllIi = 0.0;
float _lIlIi = 0.0;
float _l1lIi = 0.0;
bool _lilIi = false;
float _lOlIi = 0.0;
float _l0lIi = 0.0;
vec3 _llIIi = vec3(0.0);
vec3 _lIIIi = vec3(0.0);
vec3 _l1IIi = vec3(0.0);
vec3 _liIIi(vec3 v) {
return GunX * v.x + GunY * v.y + GunZ * v.z;
}
vec3 _lOIIi(vec3 v) {
return vec3(dot(v, GunX), dot(v, GunY), dot(v, GunZ));
}
float _l011I(vec3 p, vec3 b) {
vec3 q = abs(p) - b;
return length(max(q, 0.0)) + min(max(q.x, max(q.y, q.z)), 0.0);
}
float _l0IIi(vec3 p, vec3 b, float r) {
vec3 q = abs(p) - b + r;
return length(max(q, 0.0)) + min(max(q.x, max(q.y, q.z)), 0.0) - r;
}
float _ll1Ii(vec2 p, float r) {
const vec3 k = vec3(-0.9238795325, 0.3826834323, 0.4142135623);
p = abs(p);
p -= 2.0 * min(dot(vec2(k.x, k.y), p), 0.0) * vec2(k.x, k.y);
p -= 2.0 * min(dot(vec2(-k.x, k.y), p), 0.0) * vec2(-k.x, k.y);
p -= vec2(clamp(p.x, -k.z * r, k.z * r), r);
return length(p) * sign(p.y);
}
float _lli1I(vec2 p, float r) {
const vec3 k = vec3(-0.866025404, 0.5, 0.577350269);
p = abs(p);
p -= 2.0 * min(dot(k.xy, p), 0.0) * k.xy;
p -= vec2(clamp(p.x, -k.z * r, k.z * r), r);
return length(p) * sign(p.y);
}
float _lI1Ii(vec3 p, float r, float h) {
vec2 d = vec2(length(p.xy) - r, abs(p.z) - h);
return min(max(d.x, d.y), 0.0) + length(max(d, 0.0));
}
float _l11Ii(vec3 p, float R, float r) {
return length(vec2(length(p.xy) - R, p.z)) - r;
}
vec2 _li1Ii(vec2 a, vec2 b) {
return a.x < b.x ? a : b;
}
vec2 _lO1Ii(vec2 p, float count, float offset, out float id) {
float _l1Oll = TAU / count;
id = floor((atan(p.y, p.x) - offset) / _l1Oll + 0.5);
return rot(id * _l1Oll + offset) * p;
}
vec2 _l01Ii(vec2 p) {
vec2 q = abs(p);
return vec2(q.x + q.y, abs(q.x - q.y)) * 0.70710678;
}
vec2 _l101I(vec3 p, float k) {
vec3 _lii1l = vec3(p.xy, p.z - (_ll0li + k * _lI0li));
if (abs(_lii1l.z) > 0.9) return vec2(abs(_lii1l.z) - 0.4, 0.0);
float _lliIi = mod(k, 4.0) < 0.5 ? 1.0 : 0.0;
float _lIiIi = mix(1.38, 1.62, _lliIi);
float _llO1I = mix(0.11, 0.24, _lliIi);
float ring = max(max(_ll1Ii(_lii1l.xy, _lIiIi), -_ll1Ii(_lii1l.xy, 1.0)), abs(_lii1l.z) - _llO1I) - 0.02;
vec2 _lii1I = vec2(ring, M_COIL + k);
vec2 _l01i1 = _l01Ii(_lii1l.xy);
if (!_lilIi) {
float _l1iIi = _l011I(vec3(_l01i1.x - 0.98, _l01i1.y, _lii1l.z), vec3(0.14, 0.07, _llO1I * 0.6));
_lii1I = _li1Ii(_lii1I, vec2(_l1iIi, M_METAL));
}
if (_lliIi > 0.5) {
vec2 ax = abs(_lii1l.xy);
ax = ax.x > ax.y ? ax : ax.yx;
float _liiIi = min(_l0IIi(vec3(ax.x - _lIiIi - 0.08, ax.y, _lii1l.z), vec3(0.16, 0.2, _llO1I + 0.07), 0.03),
_l0IIi(vec3(_l01i1.x - _lIiIi - 0.08, _l01i1.y, _lii1l.z), vec3(0.16, 0.2, _llO1I + 0.07), 0.03));
if (!_lilIi) {
_liiIi = min(_liiIi, min(_lI1Ii(vec3(ax.x - _lIiIi - 0.1, ax.y, _lii1l.z), 0.07, _llO1I + 0.16),
_lI1Ii(vec3(_l01i1.x - _lIiIi - 0.1, _l01i1.y, _lii1l.z), 0.07, _llO1I + 0.16)));
}
_lii1I = _li1Ii(_lii1I, vec2(_liiIi, M_METAL));
}
return _lii1I;
}
vec2 _lOiIi(vec3 p) {
vec2 _lii1I = vec2(1e5, 0.0);
float core = max(_ll1Ii(p.xy, 0.66), abs(p.z + 6.3) - 9.6) - 0.02;
_lii1I = _li1Ii(_lii1I, vec2(core, M_HULL));
vec3 q = vec3(p.x, abs(p.y), p.z);
float _l0iIi = _l0IIi(q - vec3(0.0, 0.8, -6.55), vec3(0.3, 0.16, 9.95), 0.035);
if (!_lilIi) {
_l0iIi = max(_l0iIi, -_l011I(q - vec3(0.0, 0.97, -6.55), vec3(0.055, 0.045, 9.8)));
}
_lii1I = _li1Ii(_lii1I, vec2(_l0iIi, M_METAL));
vec3 s = vec3(abs(p.x), p.y, p.z);
float r = length(p.xy);
if (!_lilIi && r < 1.7) {
float _lO0iI = mod(p.z - _ll0li + _lI0li * 0.5, _lI0li) - _lI0li * 0.5;
float _llOIi = _l0IIi(vec3(s.x - 0.7, s.y, abs(_lO0iI) - 0.36), vec3(0.08, 0.36, 0.13), 0.02);
_llOIi = max(_llOIi, abs(p.z + 6.1) - 9.3);
_lii1I = _li1Ii(_lii1I, vec2(_llOIi, M_DARK));
vec2 c = vec2(s.x - 1.5, abs(p.y) - 0.52);
float _lIOIi = max(length(c) - 0.075, abs(p.z + 5.8) - 9.2);
_lii1I = _li1Ii(_lii1I, vec2(_lIOIi, M_DARK));
} else if (!_lilIi) {
_lii1I.x = min(_lii1I.x, r - 1.62);
}
if (r > 0.78 && r < 2.0) {
float _l1OIi = (p.z - _ll0li) / _lI0li;
float _lO01l = clamp(floor(_l1OIi + 0.5), 0.0, float(_l0Oli - 1));
_lii1I = _li1Ii(_lii1I, _l101I(p, _lO01l));
float _li1il = clamp(_lO01l + (_l1OIi > _lO01l ? 1.0 : -1.0), 0.0, float(_l0Oli - 1));
float _l00il = abs(p.z - (_ll0li + _li1il * _lI0li)) - 0.32;
if (!_lilIi && _li1il != _lO01l && _l00il < _lii1I.x) {
_lii1I = _li1Ii(_lii1I, _l101I(p, _li1il));
}
} else {
_lii1I.x = min(_lii1I.x, r < 0.78 ? 0.82 - r : r - 1.97);
}
if (abs(p.y) < 1.3) {
return vec2(min(_lii1I.x, 1.34 - abs(p.y)), _lii1I.x < 1.34 - abs(p.y) ? _lii1I.y : 0.0);
}
vec3 t = vec3(abs(p.x), abs(p.y), p.z);
float _l0i1I = abs(p.z + 6.1) - 9.1;
float _liOIi = min(length(t.xy - vec2(0.55, 1.95)), length(vec2(p.x, t.y - 2.55))) - 0.07;
float _lOOIi = mod(p.z - _ll0li + _lI0li * 0.5, _lI0li) - _lI0li * 0.5;
float _l01i1 = sdCapsule(vec3(t.x, t.y, abs(_lOOIi)), vec3(0.0, 2.55, 0.0), vec3(0.55, 1.95, _lI0li * 0.5), 0.042);
float _l0OIi = min(_liOIi, _l01i1);
if (!_lilIi) {
float _ll0Ii = sdCapsule(vec3(t.x, t.y, _lOOIi), vec3(0.0, 1.95, 0.0), vec3(0.55, 1.95, 0.0), 0.04);
float _lI0Ii = _l011I(vec3(t.x - 0.55, t.y - 1.66, _lOOIi), vec3(0.05, 0.3, 0.05));
_l0OIi = min(_l0OIi, min(_ll0Ii, _lI0Ii));
}
_l0OIi = max(_l0OIi, _l0i1I);
_lii1I = _li1Ii(_lii1I, vec2(_l0OIi, M_DARK));
return _lii1I;
}
vec2 _l10Ii(vec3 p) {
vec2 _lii1I = vec2(1e5, 0.0);
float _li0Ii = max(max(_ll1Ii(p.xy, 1.55), -_ll1Ii(p.xy, 0.62)), abs(p.z + 16.1) - 0.45) - 0.03;
float id;
float _l10ll = atan(p.y, p.x);
float _lO0Ii = length(p.xy);
if (!_lilIi) {
float _l00Ii = _l10ll - floor(_l10ll / (TAU / 16.0) + 0.5) * (TAU / 16.0);
vec2 _lll1i = vec2(_lO0Ii, _lO0Ii * _l00Ii);
float _lIl1i = _l011I(vec3(_lll1i.x - 1.5, _lll1i.y, p.z + 16.1), vec3(0.22, 0.09, 0.3));
_li0Ii = max(_li0Ii, -_lIl1i);
_li0Ii = max(_li0Ii, -max(_ll1Ii(p.xy, 1.3), -(p.z + 16.45)));
float _l1Oll = max(max(_ll1Ii(p.xy, 1.3), -_ll1Ii(p.xy, 0.62)), abs(p.z + 16.35) - 0.1) - 0.015;
float _l1l1i = _l10ll - floor(_l10ll / (TAU / 24.0) + 0.5) * (TAU / 24.0);
vec2 _li111 = vec2(_lO0Ii, _lO0Ii * _l1l1i);
float _li011 = max(_l011I(vec3(_li111.x - 0.95, _li111.y, p.z + 16.48), vec3(0.32, 0.018, 0.06)), -p.z - 16.6);
_lii1I = _li1Ii(_lii1I, vec2(min(_l1Oll, _li011), M_DARK));
_lii1I = _li1Ii(_lii1I, vec2(_lI1Ii(p - vec3(0.0, 0.0, -15.75), 0.6, 0.05), M_LENS));
}
_lii1I = _li1Ii(_lii1I, vec2(_li0Ii, M_HULL));
float _lil1i = _l10ll - PI / 6.0 - floor((_l10ll - PI / 6.0) / (TAU / 6.0) + 0.5) * (TAU / 6.0);
vec2 pp = _lO0Ii * vec2(cos(_lil1i), sin(_lil1i));
float along = saturate((-p.z - 16.4) / 2.8);
float rr = mix(1.08, 0.66, along * along);
float w = mix(0.17, 0.07, along);
float _lOl1i = _l0IIi(vec3(pp.x - rr, pp.y, p.z + 17.8), vec3(w, mix(0.13, 0.05, along), 1.4), 0.025) * 0.8;
_lii1I = _li1Ii(_lii1I, vec2(_lOl1i, M_METAL));
_lii1I = _li1Ii(_lii1I, vec2(_l11Ii(p - vec3(0.0, 0.0, _li0li + 0.1), 0.7, 0.05), M_METAL));
return _lii1I;
}
vec2 _lI1lI(vec3 p) {
vec2 _lii1I = vec2(1e5, 0.0);
float _l0l1i = max(max(_ll1Ii(p.xy, 1.5), -_ll1Ii(p.xy, 0.5)), abs(p.z - 3.35) - 0.2) - 0.02;
_lii1I = _li1Ii(_lii1I, vec2(_l0l1i, M_METAL));
float _l10II = max(_lli1I(p.xy, 1.9), abs(p.z - 5.75) - 2.4) - 0.08;
float band = max(_lli1I(p.xy, 2.0), abs(p.z - 6.9) - 0.18) - 0.02;
if (!_lilIi) {
_l10II = max(_l10II, -max(_lli1I(p.xy, 1.86), abs(p.z - 4.6) - 0.03));
}
_lii1I = _li1Ii(_lii1I, vec2(min(_l10II, band), M_HULL));
float _llI1i = _l0IIi(p - vec3(0.0, 2.3, 5.1), vec3(0.72, 0.48, 1.35), 0.14);
_lii1I = _li1Ii(_lii1I, vec2(_llI1i, M_BRIDGE));
if (!_lilIi) {
float _lII1i = min(sdCapsule(p, vec3(0.35, 2.7, 4.4), vec3(0.35, 4.1, 4.4), 0.03),
sdCapsule(p, vec3(-0.4, 2.7, 5.9), vec3(-0.4, 3.5, 5.9), 0.025));
_lii1I = _li1Ii(_lii1I, vec2(_lII1i, M_DARK));
}
vec3 c = vec3(abs(p.x) - 2.55, p.y - clamp(floor(p.y / 0.74 + 0.5), -1.0, 1.0) * 0.74, p.z - 5.6);
float _l1I1i = _lI1Ii(c, 0.3, 2.05);
if (!_lilIi) {
float _liI1i = _lI1Ii(vec3(c.xy, mod(c.z + 0.18, 0.36) - 0.18), 0.335, 0.045);
_l1I1i = min(_l1I1i, max(_liI1i, abs(c.z) - 1.9));
float _lOI1i = _l011I(vec3(abs(p.x) - 2.3, p.y, abs(p.z - 5.6) - 2.1), vec3(0.42, 1.15, 0.07));
_lii1I = _li1Ii(_lii1I, vec2(_lOI1i, M_DARK));
}
_lii1I = _li1Ii(_lii1I, vec2(_l1I1i, M_METAL));
vec3 r = p - vec3(0.0, 0.0, 10.0);
_lii1I = _li1Ii(_lii1I, vec2(length(r) - 1.05, M_GOLD));
_lii1I = _li1Ii(_lii1I, vec2(_l11Ii(r, 1.75, 0.42), M_METAL));
float id;
vec2 sp = _lO1Ii(p.xy, 6.0, 0.0, id);
float _li01I = max(length(vec2(sp.x - 2.35, sp.y)) - 0.1, abs(p.z - 10.0) - 1.85);
float _l0I1i = sdCapsule(vec3(sp, p.z), vec3(1.2, 0.0, 10.0), vec3(2.35, 0.0, 10.0), 0.06);
_lii1I = _li1Ii(_lii1I, vec2(min(_li01I, _l0I1i), M_DARK));
float _ll11i = max(_ll1Ii(p.xy, 2.2), abs(p.z - 12.0) - 0.22) - 0.04;
_lii1I = _li1Ii(_lii1I, vec2(_ll11i, M_HULL));
if (!_lilIi) {
vec3 n = vec3(abs(p.xy) - vec2(1.3), p.z);
float _lI11i = sdRoundCone(n, vec3(0.0, 0.0, 12.2), vec3(0.0, 0.0, 12.85), 0.22, 0.4);
_lI11i = max(_lI11i, -_lI1Ii(n - vec3(0.0, 0.0, 12.95), 0.33, 0.28));
_lii1I = _li1Ii(_lii1I, vec2(_lI11i, M_DARK));
}
return _lii1I;
}
vec2 _l111i(vec3 p) {
vec2 _llllI = _l01Ii(p.xy);
vec3 q = vec3(_llllI.x - 5.15, _llllI.y, p.z - 8.1);
float _lIiIi = _l011I(q, vec3(2.5, 0.05, 3.5));
float _lOI1i = max(_lIiIi, -_l011I(q, vec3(2.36, 1.0, 3.36)));
float _lO0iI = mod(q.z + 0.25, 0.5) - 0.25;
float _li11i = max(_l011I(vec3(q.x, q.y, _lO0iI), vec3(2.4, 0.025, 0.17)), abs(q.z) - 3.4);
float _llliI = _l011I(q, vec3(0.06, 0.06, 3.45));
vec2 _lii1I = vec2(min(_lOI1i, _llliI), M_DARK);
_lii1I = _li1Ii(_lii1I, vec2(_li11i, M_RAD));
float _li01I = min(sdCapsule(vec3(_llllI, p.z), vec3(1.7, 0.0, 6.2), vec3(2.8, 0.0, 6.2), 0.07),
sdCapsule(vec3(_llllI, p.z), vec3(2.0, 0.0, 10.0), vec3(2.8, 0.0, 10.0), 0.07));
_lii1I = _li1Ii(_lii1I, vec2(_li01I, M_DARK));
if (!_lilIi) {
vec3 _lO11i = vec3(_llllI.x - 7.68, _llllI.y, abs(p.z - 8.1) - 3.5);
_lii1I = _li1Ii(_lii1I, vec2(length(_lO11i) - 0.1, M_NAV + 0.01));
}
return _lii1I;
}
vec2 _l011i(vec3 p) {
p.z -= _lllIi;
float _lli1i = _l011I(p - vec3(0.0, 0.0, -3.1), vec3(7.9, 7.9, 16.3));
if (_lli1i > 1.0) return vec2(_lli1i, 0.0);
vec2 _lii1I = vec2(1e5, 0.0);
float b = _l011I(p - vec3(0.0, 0.0, -6.2), vec3(2.8, 2.8, 9.9));
_lii1I = _li1Ii(_lii1I, b > 0.6 ? vec2(b, 0.0) : _lOiIi(p));
b = _l011I(p - vec3(0.0, 0.0, -17.45), vec3(1.7, 1.7, 1.9));
_lii1I = _li1Ii(_lii1I, b > 0.6 ? vec2(b, 0.0) : _l10Ii(p));
b = _l011I(p - vec3(0.0, 0.3, 8.1), vec3(3.2, 4.3, 5.0));
_lii1I = _li1Ii(_lii1I, b > 0.6 ? vec2(b, 0.0) : _lI1lI(p));
float r = length(p.xy);
b = max(max(2.2 - r, r - 7.9), abs(p.z - 8.1) - 3.7);
_lii1I = _li1Ii(_lii1I, b > 0.6 ? vec2(b, 0.0) : _l111i(p));
return _lii1I;
}
float _lIi1i(vec3 p) {
return _l011i(p).x;
}
vec3 _l1i1i(vec3 p) {
const vec2 e = vec2(0.0012, -0.0012);
return normalize(e.xyy * _lIi1i(p + e.xyy) + e.yyx * _lIi1i(p + e.yyx) + e.yxy * _lIi1i(p + e.yxy)
+ e.xxx * _lIi1i(p + e.xxx));
}
vec2 _lii1i(vec3 ro, vec3 rd, vec3 lo, vec3 hi) {
vec3 inv = 1.0 / rd;
vec3 t0 = (lo - ro) * inv;
vec3 t1 = (hi - ro) * inv;
vec3 _lOi1i = min(t0, t1);
vec3 _l0i1i = max(t0, t1);
return vec2(max(max(_lOi1i.x, _lOi1i.y), _lOi1i.z), min(min(_l0i1i.x, _l0i1i.y), _l0i1i.z));
}
vec2 _l11iI(vec3 ro, vec3 rd, int _lllOl, float _li1iI) {
vec2 _ll10l = _lii1i(ro, rd, vec3(-7.9, -7.9, -19.5 + _lllIi), vec3(7.9, 7.9, 13.3 + _lllIi));
if (_ll10l.y < max(_ll10l.x, 0.0)) return vec2(-1.0, 0.0);
float t = max(_ll10l.x, 0.0);
float end = min(_ll10l.y, _li1iI);
float _llO1i = 1.35;
float _lIO1i = 0.0;
float _l1O1i = 0.0;
for (int i = 0; i < 180; i++) {
if (i >= _lllOl) break;
vec2 h = _l011i(ro + rd * t);
float radius = h.x * 0.92;
bool _liO1i = _llO1i > 1.0 && radius + _l1O1i < _lIO1i;
if (_liO1i) {
_lIO1i -= _llO1i * _lIO1i;
_llO1i = 1.0;
} else {
if (h.x < max(_lI0Ol * t * (_lilIi ? 1.5 : 0.45), 0.0008)) return vec2(t, h.y);
_lIO1i = radius * _llO1i;
}
_l1O1i = radius;
t += _lIO1i;
if (t > end) break;
}
return vec2(-1.0, 0.0);
}
vec2 _lOO1i(vec3 ro, vec3 rd) {
_lilIi = true;
vec2 h = _l11iI(ro, rd, 36, 18.0);
_lilIi = false;
return h;
}
float _l0O1i(vec3 p, vec3 _ll0ll, float k) {
float _l1Oli = _lii1i(p, _ll0ll, vec3(-7.9, -7.9, -19.5 + _lllIi), vec3(7.9, 7.9, 13.3 + _lllIi)).y;
_lilIi = true;
float s = 1.0;
float t = 0.03;
float _ll01i = 1e10;
for (int i = 0; i < 36; i++) {
float h = _lIi1i(p + _ll0ll * t);
float y = h * h / (2.0 * _ll01i);
float d = sqrt(max(h * h - y * y, 0.0));
s = min(s, k * d / max(t - y, 1e-4));
_ll01i = h;
t += clamp(h, 0.03, 0.9);
if (s < 0.005 || t > _l1Oli) break;
}
_lilIi = false;
return smoothstep(0.0, 1.0, saturate(s));
}
float _lI01i(vec3 p, vec3 light) {
_lilIi = true;
vec3 _ll0ll = light - p;
float far = length(_ll0ll);
_ll0ll /= far;
float s = 1.0;
float t = 0.04;
for (int i = 0; i < 32; i++) {
float h = _lIi1i(p + _ll0ll * t);
s = min(s, 14.0 * h / t);
t += clamp(h, 0.04, 0.8);
if (s < 0.01 || t > far - 0.1) break;
}
_lilIi = false;
return saturate(s);
}
float _l101i(vec3 p, vec3 n) {
_lilIi = true;
float o = 0.0;
float w = 1.0;
for (int i = 1; i <= 5; i++) {
float d = 0.06 * float(i) * float(i) * 0.5 + 0.02;
o += (d - _lIi1i(p + n * d)) * w;
w *= 0.75;
}
_lilIi = false;
return saturate(1.0 - o * 2.2);
}
vec3 _li01i(vec3 w, float _lO01i, out float _lIO0I) {
float _llO0I;
vec3 _l001i = _l0lli(w, CentreRel, GalaxyN, ToCentre, 60.0, MilkyTop, _lI0Ol * _lO01i, 1e9, _lIO0I, _llO0I);
float _l1l0I;
float _lil0I = rayPointDist(vec3(0.0), w, CentreRel, _l1l0I);
float _lllii = _l1l0I > 0.0 ? exp(-sqr(_lil0I / (5.0 + _lO01i * 0.02))) : 0.0;
return _l001i * 0.7 + vec3(1.0, 0.82, 0.55) * _lllii * 0.18;
}
vec3 _lIlii(vec3 rd) {
vec3 w = _liIIi(rd);
vec3 col = _l00Ol(w, _lI0Ol, 0.9) + _l1O01(w, _lI0Ol) * 0.5;
float _lIO0I;
vec3 _l001i = _li01i(w, 1.0, _lIO0I);
col = col * (1.0 - _lIO0I * 0.85) + _l001i;
vec3 _lIOlI = normalize(SunRelG);
float _l1lii = length(w - _lIOlI);
col += vec3(1.0, 0.9, 0.75) * _liO0I(_l1lii, _lI0Ol, 1.2) * 2.5;
float ring = abs(_l1lii - _lI0Ol * 9.0) / _lI0Ol;
col += _lIi01 * saturate(1.2 - ring) * step(0.5, fract(atan(dot(w - _lIOlI, CamUp), dot(w - _lIOlI, CamRight)) / TAU * 4.0 + 0.125))
* 1.5 * _lIlIi;
return col;
}
vec3 _l10iI(vec3 _lIIll, float _lOOiI) {
float _lIO0I;
return _li01i(_liIIi(_lIIll), 1.0 + _lOOiI * 600.0, _lIO0I) * (1.0 - _lOOiI * 0.5) + vec3(0.004, 0.005, 0.008);
}
float _lIlOI(vec3 p, vec3 n, out float _l1IOI) {
vec3 a = abs(n);
vec2 uv = a.x > a.y && a.x > a.z ? p.yz : a.y > a.z ? p.xz : p.xy;
vec2 cell = vec2(0.64, 0.42);
vec2 g = abs(fract(uv / cell) - 0.5) * cell;
vec2 id = floor(uv / cell);
_l1IOI = hash12(id + 7.0);
float line = 1.0 - smoothstep(0.004, 0.009, min(g.x, g.y));
float _lilii = step(0.88, hash12(id)) * (1.0 - smoothstep(0.004, 0.009, abs(max(g.x - 0.12, g.y - 0.07))));
return max(line, _lilii * 0.8);
}
float _lIOiI(float _lOi0l, float a) {
float _l0Oil = a * a;
float d = _lOi0l * _lOi0l * (_l0Oil - 1.0) + 1.0;
return _l0Oil / (PI * d * d);
}
float _lOlii(float _l0OiI, float _lii0l, float a) {
float k = sqr(a + 1.0) / 8.0;
return _l0OiI / (_l0OiI * (1.0 - k) + k) * _lii0l / (_lii0l * (1.0 - k) + k);
}
vec3 _l00O1(float c, vec3 _liOiI) {
return _liOiI + (1.0 - _liOiI) * pow(1.0 - c, 5.0);
}
vec3 _l0lii(vec3 n, vec3 v, vec3 _ll0ll, vec3 _l11OI, vec3 _liOiI, float _lOOiI, float _llIii) {
float _lii0l = max(dot(n, _ll0ll), 0.0);
if (_lii0l <= 0.0) return vec3(0.0);
vec3 h = normalize(_ll0ll + v);
float _l0OiI = max(dot(n, v), 1e-3);
float _lOi0l = max(dot(n, h), 0.0);
float a = max(_lOOiI * _lOOiI, 0.002);
vec3 _ll0iI = _l00O1(max(dot(h, v), 0.0), _liOiI);
vec3 _llI1l = _ll0iI * _lIOiI(_lOi0l, a) * _lOlii(_l0OiI, _lii0l, a) / (4.0 * _l0OiI * _lii0l + 1e-4);
vec3 _lIIii = _l11OI * (1.0 - _llIii) * (1.0 - _ll0iI) / PI;
return (_lIIii + _llI1l) * _lii0l;
}
struct _l1Iii {
vec3 _l11OI;
vec3 _liOiI;
float _lOOiI;
float _llIii;
vec3 _liIii;
};
vec2 _liiII(float z) {
float _l0I1l = mix(3.4, -16.4, _lOlIi);
float _l1iIl = smoothstep(_l0I1l - 0.3, _l0I1l + 0.6, z) * step(0.001, _lOlIi);
return vec2(_l1iIl, exp(-sqr((z - _l0I1l) / 0.7)) * step(0.001, _lOlIi) * step(_lOlIi, 0.999));
}
_l1Iii _lOIii(vec3 _lI01I, vec3 n, float _l0Iii) {
_l1Iii s;
s._l11OI = vec3(0.05);
s._liOiI = vec3(0.04);
s._lOOiI = 0.5;
s._llIii = 0.0;
s._liIii = vec3(0.0);
float _l1IOI;
float _l0lI1 = _lIlOI(_lI01I, n, _l1IOI);
float _ll1ii = _lilIi ? vnoise3(_lI01I * 1.7) : fbm3(_lI01I * 1.7);
float _lI1ii = _l00li >= 0.0 ? 4.0 * exp(-_l00li * 3.0) : 0.0;
vec2 _l0IlI = _liiII(_lI01I.z);
float _l11ii = 1.0 - 0.8 * _l0lIi;
if (_l0Iii == M_HULL) {
s._l11OI = vec3(0.075, 0.078, 0.086) * (0.75 + 0.5 * _l1IOI) * (0.85 + 0.3 * _ll1ii);
s._lOOiI = 0.42 + 0.2 * _l1IOI;
s._llIii = 0.25;
float _li1ii = step(0.5, fract((_lI01I.x + _lI01I.y + _lI01I.z) * 2.4));
float _lO1ii = step(-15.62, _lI01I.z) * step(_lI01I.z, -15.2) + step(6.72, _lI01I.z) * step(_lI01I.z, 7.08);
s._l11OI = mix(s._l11OI, mix(vec3(0.5, 0.03, 0.04), vec3(0.8, 0.75, 0.7), _li1ii * 0.0) * (0.8 + 0.2 * _li1ii), _lO1ii * _li1ii);
float _l01ii = step(length(_lI01I.xy), 0.72) * step(_lI01I.z, 3.4) * step(-16.0, _lI01I.z);
float current = 0.5 + 0.5 * sin(_lI01I.z * 5.0 + _l100l * 40.0);
s._liIii += _lIi01 * _l0lI1 * _l01ii * (_l0IlI.x * (0.6 + 0.8 * current) * _l11ii + _l0IlI.y * 5.0);
} else if (_l0Iii == M_METAL) {
float _lliii = vnoise2(vec2(_lI01I.z * 40.0, (_lI01I.x + _lI01I.y) * 1200.0));
s._l11OI = vec3(0.62, 0.63, 0.66);
s._liOiI = vec3(0.56, 0.57, 0.6) * (0.9 + 0.1 * _lliii);
s._lOOiI = 0.16 + 0.12 * _lliii + 0.1 * _ll1ii;
s._llIii = 1.0;
float inner = step(0.62, abs(_lI01I.y)) * step(abs(_lI01I.y), 0.68) * step(0.5, -sign(_lI01I.y) * n.y);
float _lil11 = fract(_l100l * 2.5 + _lI01I.z * 0.18);
s._liIii += _lIi01 * inner * (0.08 * _lIlIi + (0.5 + 2.5 * exp(-_lil11 * 7.0)) * _l0IlI.x * _l11ii + _l0IlI.y * 6.0 + 6.0 * _lI1ii);
float _lIiii = step(_lI01I.z, _li0li + 0.3) * step(0.55, length(_lI01I.xy)) * step(length(_lI01I.xy), 0.85);
s._liIii += mix(_lIi01, _l1i01, _lO0li * _lO0li) * _lIiii * smoothstep(0.4, 1.0, _lO0li) * (2.0 + 2.0 * sin(_l100l * 70.0)) * _l11ii;
} else if (_l0Iii == M_DARK) {
s._l11OI = vec3(0.022, 0.023, 0.026) * (0.8 + 0.4 * _ll1ii);
s._lOOiI = 0.55;
s._llIii = 0.5;
s._liOiI = vec3(0.08);
} else if (_l0Iii == M_RAD) {
s._l11OI = vec3(0.16, 0.155, 0.15) * (0.8 + 0.3 * _ll1ii);
s._lOOiI = 0.7;
float _l1iii = 1.0 - smoothstep(0.015, 0.035, abs(fract((_lI01I.z - 8.1) * 2.0 + 0.5) - 0.5) * 0.5);
s._liIii += _l0IOI(0.3 + 0.2 * _lIlIi) * _l1iii * (0.05 + 0.25 * _lIlIi) * (0.7 + 0.3 * sin(_l100l * 1.3 + _lI01I.z));
} else if (_l0Iii == M_GOLD) {
float _liiii = fbm3(_lI01I * 9.0);
s._l11OI = vec3(1.0, 0.72, 0.3);
s._liOiI = vec3(1.0, 0.71, 0.29) * (0.75 + 0.35 * _liiii);
s._lOOiI = 0.22 + 0.25 * _liiii;
s._llIii = 1.0;
} else if (_l0Iii == M_LENS) {
s._l11OI = vec3(0.01);
s._liOiI = vec3(0.06);
s._lOOiI = 0.04;
float r = length(_lI01I.xy);
s._liIii += _lIi01 * (0.05 * _lIlIi + 2.5 * _lO0li * _l11ii) * (0.4 + 0.6 * smoothstep(0.6, 0.0, r)) + _l1i01 * _lI1ii * 4.0;
} else if (_l0Iii == M_BRIDGE) {
s._l11OI = vec3(0.09, 0.092, 0.1);
s._lOOiI = 0.35;
s._llIii = 0.3;
vec2 _lOiii = abs(n.x) > 0.6 ? _lI01I.zy : _lI01I.xy;
vec2 _l01li = vec2(_lOiii.x * 6.0, (_lOiii.y - 2.3) * 5.0);
vec2 _l0O1l = floor(_l01li);
vec2 _liii1 = fract(_l01li) - 0.5;
float row = step(abs(_lI01I.y - 2.3), 0.3);
float _l0iii = step(abs(_liii1.x), 0.32) * step(abs(_liii1.y), 0.18) * row * step(abs(n.y), 0.5);
float _l1iIl = step(0.35, hash12(_l0O1l + 3.0));
s._liIii += mix(vec3(1.0, 0.72, 0.42), vec3(0.6, 0.85, 1.0), step(0.85, hash12(_l0O1l))) * _l0iii * _l1iIl * 1.4 * (0.3 + 0.7 * _lIlIi);
} else if (_l0Iii >= M_NAV && _l0Iii < M_COIL) {
float side = sign(_lI01I.x);
vec3 c = side > 0.0 ? vec3(0.2, 1.0, 0.4) : vec3(1.0, 0.1, 0.1);
float _llOii = step(0.94, fract(_l100l * 0.9));
s._liIii += mix(c * (0.6 + 0.4 * step(0.4, fract(_l100l * 0.7))), vec3(1.0), _llOii) * 6.0;
s._l11OI = vec3(0.1);
} else if (_l0Iii >= M_COIL) {
float k = _l0Iii - M_COIL;
s._l11OI = vec3(0.3, 0.3, 0.32);
s._liOiI = vec3(0.45, 0.44, 0.46);
s._lOOiI = 0.24 + 0.1 * _ll1ii;
s._llIii = 1.0;
float _lIOII = 1.0 - smoothstep(0.0, 0.025, _ll1Ii(_lI01I.xy, 1.0) + 0.012);
float _lliIi = mod(k, 4.0) < 0.5 ? 1.0 : 0.0;
float _lIOii = (1.0 - smoothstep(0.012, 0.03, abs(_ll1Ii(_lI01I.xy, mix(1.19, 1.31, _lliIi)))))
* smoothstep(0.85, 1.0, abs(n.z));
float _l1Oii = _l00li >= 0.0 ? exp(-sqr((_l00li * 90.0 - k) / 2.0)) * 8.0 : 0.0;
float _liOii = 0.8 + 0.2 * sin(_l100l * 30.0 + k * 1.7);
float _l1iIl = _l0IlI.x * _liOii * _l11ii;
s._liIii += _lIi01 * _lIOII * (0.1 * _lIlIi + _l1iIl * 3.0 + _l0IlI.y * 10.0 + _l1Oii + _lI1ii * 2.0);
s._liIii += _lIi01 * _lIOii * (_l1iIl * 2.2 + _l0IlI.y * 8.0 + _l1Oii * 0.5);
s._liIii += _l1i01 * (_lIOII + _lIOii) * _l0IlI.y * 4.0;
}
s._l11OI *= 1.0 - _l0lI1 * 0.5;
s._lOOiI = min(s._lOOiI + _l0lI1 * 0.3, 1.0);
s._liOiI = mix(vec3(0.04), s._liOiI, 1.0 - _l0lI1 * 0.6);
return s;
}
vec3 lighting(vec3 p, vec3 n, vec3 v, _l1Iii s, float _lOOii, bool _lOlll) {
vec3 _lI01I = p - vec3(0.0, 0.0, _lllIi);
vec3 col = vec3(0.0);
float _lIIOI = _lOlll && dot(n, _llIIi) > 0.0 ? _l0O1i(p + n * 0.01, _llIIi, 10.0) : 1.0;
vec3 _llIOI = vec3(1.0, 0.84, 0.64) * 3.6 * (1.0 - 0.75 * _l0lIi);
col += _l0lii(n, v, _llIIi, s._l11OI, s._liOiI, s._lOOiI, s._llIii) * _llIOI * _lIIOI;
float _li1OI = saturate(dot(n, _lIIIi) * 0.5 + 0.5);
col += s._l11OI * (1.0 - s._llIii * 0.6) * vec3(0.55, 0.62, 0.8) * _li1OI * _li1OI * 0.35 * _lOOii * (1.0 - 0.75 * _l0lIi);
col += s._l11OI * vec3(0.012, 0.014, 0.022) * _lOOii;
vec3 _lII01 = vec3(0.0, 0.0, _l10li + _lllIi);
vec3 _l0Oii = _lII01 - p;
float _ll0ii = length(_l0Oii);
vec3 _lI0ii = _l0Oii / _ll0ii;
float _l10ii = smoothstep(0.45, 1.0, _lO0li) * 7.0 * (1.0 - 0.7 * _l0lIi) + _l1lIi * 2600.0;
if (_l10ii > 0.001) {
float _li0ii = _lOlll && _l1lIi > 0.01 ? _lI01i(p + n * 0.02, _lII01) : 1.0;
vec3 _llIII = mix(_lIi01, vec3(1.0, 0.85, 0.82), saturate(_l1lIi * 3.0));
col += _l0lii(n, v, _lI0ii, s._l11OI, s._liOiI, max(s._lOOiI, 0.15), s._llIii) * _llIII * _l10ii / (_ll0ii * _ll0ii + 0.2) * _li0ii;
}
if (_l00li >= 0.0) {
vec3 _lO0ii = vec3(0.0, 0.0, min(_lI01I.z, _li0li) + _lllIi);
vec3 _l1l0I = _lO0ii - p;
float _lil0I = length(_l1l0I);
col += _l0lii(n, v, _l1l0I / _lil0I, s._l11OI, s._liOiI, max(s._lOOiI, 0.2), s._llIii) * _lIi01 * 30.0 / (_lil0I * _lil0I + 0.5);
}
return col * mix(1.0, _lOOii, 0.35) + s._liIii;
}
vec3 _ll1OI(vec3 p, vec3 rd, float _l0Iii) {
vec3 n = _l1i1i(p);
vec3 _lI01I = p - vec3(0.0, 0.0, _lllIi);
_l1Iii s = _lOIii(_lI01I, n, _l0Iii);
if (_l0Iii == M_GOLD) {
n = normalize(n + (vec3(fbm3(_lI01I * 14.0), fbm3(_lI01I * 14.0 + 3.1), fbm3(_lI01I * 14.0 + 7.3)) - 0.5) * 0.35);
}
vec3 v = -rd;
float _lOOii = _l101i(p, n);
vec3 col = lighting(p, n, v, s, _lOOii, true);
float _l0OiI = max(dot(n, v), 0.0);
vec3 _ll0iI = _l00O1(_l0OiI, s._liOiI);
vec3 r = reflect(rd, n);
vec3 _l00ii;
float _lllOi = max(_ll0iI.r, max(_ll0iI.g, _ll0iI.b)) * (1.0 - s._lOOiI * 0.85);
vec2 h = s._lOOiI < 0.55 && _lllOi > 0.12 ? _lOO1i(p + n * 0.02, r) : vec2(-1.0, 0.0);
if (h.x > 0.0) {
vec3 q = p + n * 0.02 + r * h.x;
_lilIi = true;
vec3 _lIlOi = _l1i1i(q);
_l1Iii qs = _lOIii(q - vec3(0.0, 0.0, _lllIi), _lIlOi, h.y);
_lilIi = false;
_l00ii = lighting(q, _lIlOi, -r, qs, 1.0, false);
} else {
_l00ii = _l10iI(r, s._lOOiI);
}
col += _l00ii * _ll0iI * (1.0 - s._lOOiI * 0.85) * mix(0.5, 1.0, _lOOii);
return col;
}
vec3 _l1lOi(vec3 rd, float _l0iOI) {
float _lilOi = smoothstep(0.42, 0.6, _lO0li);
if (_lilOi <= 0.001 || _l00li >= 0.0) return vec3(0.0);
vec3 c = vec3(0.0, 0.0, _l10li + _lllIi) - CamPos;
float t = dot(c, rd);
if (t <= 0.0 || t > _l0iOI + 0.6) return vec3(0.0);
vec3 _lIIll = normalize(c);
vec3 off = rd - _lIIll * dot(rd, _lIIll);
float d = length(off);
float _lOlOi = 0.8 + 0.2 * sin(_l100l * 97.0) * sin(_l100l * 61.0 + 1.0);
float size = mix(0.6, 2.0, _lO0li) * _lOlOi * mix(1.0, 0.45, _l0lIi);
float x = dot(off, CamRight);
float y = dot(off, CamUp);
float _l0lII = exp(-abs(y) / (_lI0Ol * 0.9)) * exp(-abs(x) / (0.02 + 0.1 * _lO0li)) * (1.0 - _l0lIi);
vec3 hot = mix(vec3(1.0, 0.8, 0.8), vec3(1.0), _l0lIi);
return (hot * _liO0I(d, _lI0Ol, size) * (3.0 + 4.0 * _l0lIi) + _lIi01 * _liO0I(d, _lI0Ol, size * 5.0) * 1.3
* (1.0 - 0.6 * _l0lIi) + _lIi01 * _l0lII * 0.9) * _lilOi;
}
vec3 _l0lOi(vec3 rd, float _l0iOI) {
if (_lOlIi <= 0.001 || _l00li >= 0.0) return vec3(0.0);
vec2 o = CamPos.xy;
vec2 _liI0I = rd.xy;
float a = dot(_liI0I, _liI0I);
float b = dot(o, _liI0I);
float c = dot(o, o) - 9.0;
float _llIOi = b * b - a * c;
if (_llIOi <= 0.0 && c > 0.0) return vec3(0.0);
float sq = sqrt(max(_llIOi, 0.0));
float t0 = a > 1e-8 ? max((-b - sq) / a, 0.0) : 0.0;
float t1 = a > 1e-8 ? min((-b + sq) / a, _l0iOI) : _l0iOI;
if (t1 <= t0) return vec3(0.0);
float _lIIOi = CamPos.z + rd.z * t0 - _lllIi;
float _l1IOi = CamPos.z + rd.z * t1 - _lllIi;
float _liIOi = clamp(floor((min(_lIIOi, _l1IOi) - _ll0li) / _lI0li), 0.0, float(_l0Oli - 1));
float _lOIOi = clamp(ceil((max(_lIIOi, _l1IOi) - _ll0li) / _lI0li), 0.0, float(_l0Oli - 1));
vec3 col = vec3(0.0);
float _l11ii = 1.0 - 0.85 * _l0lIi;
for (int i = 0; i < _l0Oli; i++) {
float k = float(i);
if (k < _liIOi || k > _lOIOi) continue;
float z = _ll0li + k * _lI0li + _lllIi;
float t = rayPlane(CamPos, rd, vec3(0.0, 0.0, z), vec3(0.0, 0.0, 1.0));
if (t <= 0.0 || t > _l0iOI) continue;
vec2 _l0IlI = _liiII(z - _lllIi);
if (_l0IlI.x + _l0IlI.y < 0.01) continue;
vec2 q = (CamPos + rd * t).xy;
float d = _ll1Ii(q, 1.0);
float _llIli = min(1.0 / max(abs(rd.z), 0.08), 5.0);
float inside = exp(-max(-d, 0.0) / 0.12) * step(d, 0.0);
float _l0IOi = exp(-max(d, 0.0) / 0.35) * step(0.0, d) * 0.4;
col += (_lIi01 * (_l0IlI.x * 0.18 * _l11ii + _l0IlI.y * 0.9) + _l1i01 * _l0IlI.y * 0.4) * (inside + _l0IOi) * _llIli;
}
return col;
}
vec3 _ll1Oi(vec3 rd, float _l0iOI) {
float _lilOi = smoothstep(0.5, 0.75, _lO0li) * (1.0 - _l0lIi);
if (_lilOi <= 0.001 || _l00li >= 0.0) return vec3(0.0);
vec3 c = vec3(0.0, 0.0, _l10li + _lllIi);
float _li0l1;
float _lI1Oi = rayPointDist(CamPos, rd, c, _li0l1);
if (_lI1Oi > 1.6 + _lI0Ol * _li0l1 * 40.0) return vec3(0.0);
float strike = floor(_l100l * 24.0);
float core = 0.0;
float halo = 0.0;
for (int i = 0; i < 6; i++) {
float _l1Iil = float(i);
if (hash11(strike * 1.7 + _l1Iil * 3.1) < 0.3) continue;
float a = (_l1Iil + 0.5) * TAU / 6.0;
vec3 from = vec3(cos(a) * 0.82, sin(a) * 0.82, _l10li + (hash11(strike + _l1Iil * 5.0) - 0.5) * 1.8 + _lllIi);
vec3 _l11Oi = from;
for (int _liOil = 1; _liOil <= 4; _liOil++) {
float u = float(_liOil) / 4.0;
vec3 q = mix(from, c, u);
if (_liOil < 4) {
q += (vec3(hash11(strike * 3.1 + _l1Iil * 7.0 + float(_liOil)), hash11(strike * 5.3 + _l1Iil * 11.0 + float(_liOil)),
hash11(strike * 2.2 + _l1Iil * 13.0 + float(_liOil))) - 0.5) * 0.4 * (1.0 - u * 0.6);
}
float tRay;
float d = raySegmentDist(CamPos, rd, _l11Oi, q, tRay);
if (tRay < _l0iOI) {
float w = max(_lI0Ol * tRay, 0.002);
core += saturate(1.0 - d / (w * 0.9));
halo += exp(-d / (w * 6.0));
}
_l11Oi = q;
}
}
return (vec3(1.0, 0.82, 0.84) * min(core, 1.5) * 2.0 + _lIi01 * halo * 0.5) * _lilOi;
}
vec3 _li1Oi(vec3 rd, float _l0iOI) {
float _lilOi = smoothstep(0.5, 0.62, _lO0li);
if (_lilOi <= 0.001 || _l00li >= 0.0) return vec3(0.0);
vec3 col = vec3(0.0);
float _li0l1;
float _lI1Oi = rayPointDist(CamPos, rd, vec3(0.0, 0.0, _l10li + _lllIi), _li0l1);
bool near = _lI1Oi < 6.8 + _lI0Ol * _li0l1 * 6.0;
for (int i = 0; i < 26; i++) {
if (!near) break;
float _l1Iil = float(i);
float seed = hash11(_l1Iil * 1.37 + 0.5);
float speed = (0.3 + 1.3 * _lO0li) * (0.7 + 0.6 * hash11(_l1Iil * 2.1));
float r0 = 4.5 + 2.0 * hash11(_l1Iil * 3.3);
float _lO1Oi = 5.0 + 3.0 * hash11(_l1Iil * 5.7);
float _l011l = (hash11(_l1Iil * 9.1) - 0.5) * 4.0;
for (int k = 0; k < 3; k++) {
float _l01Oi = fract(seed + _l100l * speed - float(k) * 0.025);
_l01Oi = mix(_l01Oi, 1.0, _l0lIi);
float r = mix(r0, 0.03, _l01Oi * _l01Oi);
float _l10ll = seed * TAU + _l01Oi * _lO1Oi;
float z = _l10li + _l011l * (1.0 - _l01Oi) + _lllIi;
vec3 _l1I1l = vec3(cos(_l10ll) * r, sin(_l10ll) * r, z) - CamPos;
float t = dot(_l1I1l, rd);
if (t <= 0.0 || t > _l0iOI) {
if (k == 0) break;
continue;
}
float d = length(_l1I1l - rd * t) / t;
if (k == 0 && d > _lI0Ol * 40.0) break;
float fade = k == 0 ? 1.0 : 0.45 / float(k);
col += mix(_lIi01, vec3(1.0, 0.82, 0.82), _l01Oi) * _liO0I(d, _lI0Ol, mix(1.3, 2.4, _l01Oi)) * (0.25 + _l01Oi) * fade;
}
}
col *= _lilOi * (1.0 - smoothstep(0.7, 1.0, _l0lIi));
if (_l0lIi > 0.001 && _l0lIi < 0.999) {
float _llOil = rayPlane(CamPos, rd, vec3(0.0, 0.0, _l10li + _lllIi), vec3(0.0, 0.0, 1.0));
if (_llOil > 0.0 && _llOil < _l0iOI) {
float r = length((CamPos + rd * _llOil).xy);
float R = mix(5.0, 0.0, _l0lIi);
col += mix(_lIi01, vec3(1.0, 0.85, 0.85), _l0lIi) * exp(-sqr((r - R) / (0.04 + 0.1 * (1.0 - _l0lIi)))) * 2.5;
}
}
return col;
}
vec3 _lIl1I(vec3 rd, float _l0iOI) {
if (_l00li < 0.0 || _l00li > 0.5) return vec3(0.0);
vec3 c = vec3(0.0, 0.0, _l10li - 0.4 + _lllIi) - CamPos;
float dist = length(c);
vec3 _lIIll = c / dist;
vec3 off = rd - _lIIll * dot(rd, _lIIll);
float d = length(off);
float _lliOi = d * dist;
float x = dot(off, CamRight);
float y = dot(off, CamUp);
float _lIiOi = exp(-_l00li * 70.0);
float soft = exp(-_l00li * 30.0);
float seen = _l0iOI > dist - 1.2 ? 1.0 : 0.0;
float _l1iOi = (exp(-_lliOi / (0.45 + _l00li * 6.0)) * 40.0 * soft + exp(-_lliOi / 5.0) * 6.0 * _lIiOi) * seen
+ exp(-_lliOi / 14.0) * 3.0 * _lIiOi;
float _l10ll = atan(y, x);
float _liiOi = pow(abs(cos(_l10ll * 3.0 + 0.4)), 80.0) * exp(-d / (0.3 + _l00li * 1.5)) * 8.0 * soft;
float _l0lII = exp(-abs(y) / (_lI0Ol * 2.0)) * exp(-abs(x) / 1.2) * 10.0 * soft;
vec3 col = vec3(1.0, 0.95, 0.93) * (_l1iOi + _liiOi) + mix(_lIi01, vec3(1.0, 0.7, 0.7), 0.25) * _l0lII;
float _llOil = rayPlane(vec3(0.0), rd, vec3(0.0, 0.0, _li0li - 0.4 - _l00li * 40.0 + _lllIi) - CamPos, vec3(0.0, 0.0, 1.0));
if (_llOil > 0.0 && _llOil < _l0iOI) {
float r = length((rd * _llOil + CamPos).xy);
float R = 1.0 + _l00li * 90.0;
col += mix(vec3(1.0, 0.9, 0.9), _lIi01, saturate(_l00li * 6.0)) * exp(-sqr((r - R) / (0.3 + _l00li * 8.0))) * 4.0 * soft;
}
return col;
}
vec3 _lOiOi(vec3 rd, float _l0iOI) {
if (_l00li < 0.0) return vec3(0.0);
vec3 a = vec3(0.0, 0.0, _li0li + _lllIi) - CamPos;
float _l00il = 9000.0 * saturate(_l00li * 30.0);
float tRay;
float d = raySegmentDist(vec3(0.0), rd, a, a + vec3(0.0, 0.0, -_l00il), tRay);
if (tRay > _l0iOI) return vec3(0.0);
float w = max(_lI0Ol * tRay, 0.004);
float core = saturate(1.0 - d / (w * 1.1)) * saturate(0.35 / w + 0.4);
float _lI1lI = saturate(1.0 - d / 0.2);
float _l010I = exp(-d / (w * 2.4)) * 0.9 + exp(-d / 0.5) * 0.25;
return vec3(1.0, 0.92, 0.92) * (core * 5.0 + _lI1lI * 4.0) + _lIi01 * (_l010I * 4.0 + _lI1lI * 2.0);
}
vec4 _l0iOi(float r, float z, float along, out float ga) {
ga = 0.0;
vec3 _llOOi = _lli0l(vec2(r - 0.36, z), vec2(0.07, 0.37));
_llOOi.x -= 0.03;
vec4 best = vec4(_llOOi, 0.0);
vec3 _llliI = _lli0l(vec2(r, z), vec2(0.16, 0.15));
if (_llliI.x < best.x) best = vec4(_llliI, 1.0);
vec3 _lIOOi = _lli0l(vec2(r, z), vec2(0.38, 0.05));
if (_lIOOi.x < best.x) best = vec4(_lIOOi, 2.0);
vec3 band = _lli0l(vec2(r, z), vec2(0.48, 0.45));
band.x -= 0.02;
float c = (fract(along / 1.05 + 0.25) - 0.5) * 1.05;
float slab = abs(c) - 0.045;
float _li0Ii = max(band.x, slab);
if (_li0Ii < best.x) {
best = slab > band.x ? vec4(slab, 0.0, 0.0, 3.0) : vec4(band, 3.0);
ga = slab > band.x ? (c < 0.0 ? -1.0 : 1.0) : 0.0;
}
return best;
}
vec4 _l1OOi(vec3 ro, vec3 rd, out vec3 glow) {
glow = vec3(0.0);
int _l1l0l = _lil0l();
if (_l1l0l <= 0) return vec4(0.0);
float _lOl0l = 1e9;
int _l0l0l = -1;
vec3 _llI0l = vec3(0.0);
float _liOOi = 0.0;
float _lII0l = 0.0;
float _l1I0l = 0.0;
for (int _liI0l = 0; _liI0l < _l1l0l; _liI0l++) {
vec4 st = TitleL[_liI0l * 4 + 3];
float _lOOOi = TitleL[_liI0l * 4 + 2].w;
if (_lOOOi <= 0.0) continue;
vec3 c = TitleL[_liI0l * 4].xyz;
float s = TitleL[_liI0l * 4].w;
vec3 ax = TitleL[_liI0l * 4 + 1].xyz;
if (st.y > 0.05) {
float _llOil;
float d = raySegmentDist(ro, rd, c - ax * s * 1.5, c - ax * s * (1.5 + st.y), _llOil);
float w = s * 0.22;
glow += (_lIi01 * (exp(-d / w) * 1.2 + exp(-d / (w * 3.0)) * 0.12) + vec3(1.0, 0.8, 0.8) * exp(-d / (w * 0.2)) * 1.0)
* saturate(st.y / 14.0);
}
if (st.w >= 0.0 && st.w < 4.5) {
vec3 zx = cross(ax, TitleL[_liI0l * 4 + 2].xyz);
float tp = rayPlane(ro, rd, c, zx);
if (tp > 0.0) {
float rr = length(ro + rd * tp - c) / s;
float R = 2.0 + st.w * 1.1;
glow += mix(vec3(1.0, 0.9, 0.9), _lIi01, saturate(st.w / 2.0)) * exp(-sqr((rr - R) / (0.12 + st.w * 0.05)))
* exp(-st.w / 1.4) * 1.6;
}
}
vec3 lo;
vec3 _lOI0l;
_l0I0l(_liI0l, ro, rd, lo, _lOI0l);
vec2 _ll10l = _lI10l(lo, _lOI0l, vec3(-0.7, -0.7, -0.6), vec3(4.7, 6.7, 0.6));
if (_ll10l.y < max(_ll10l.x, 0.0) || _ll10l.x * s > _lOl0l) continue;
float t = max(_ll10l.x, 0.0);
float _lIi0l = max(_lI0Ol * (t * s + 1.0) / s * 0.6, 0.004);
for (int i = 0; i < 56 + int(TitleA.w); i++) {
vec3 p = lo + _lOI0l * t;
float along;
float _l110l;
vec2 away;
vec2 _li10l;
float r = _lO10l(_liI0l, p.xy, along, _l110l, away, _li10l);
float ga;
vec4 _l010l = _l0iOi(r, p.z, along, ga);
if (_l010l.x < _lIi0l) {
if (t * s < _lOl0l) {
_lOl0l = t * s;
_l0l0l = _liI0l;
_llI0l = _l1i0l(_liI0l, normalize(vec3(away * _l010l.y + _li10l * ga, _l010l.z)));
_liOOi = _l010l.w;
_lII0l = along;
_l1I0l = r;
}
break;
}
t += max(_l010l.x * 0.9, _lIi0l * 0.5);
_lIi0l = max(_lI0Ol * (t * s + 1.0) / s * 0.6, 0.004);
if (t > _ll10l.y) break;
}
}
if (_l0l0l < 0) return vec4(0.0);
vec4 st = TitleL[_l0l0l * 4 + 3];
vec3 n = _llI0l;
vec3 v = -rd;
if (dot(n, v) < 0.0) n = -n;
vec3 _l11OI = vec3(0.035);
vec3 _liOiI = vec3(0.42, 0.42, 0.45);
float _lOOiI = 0.3;
float _llIii = 1.0;
if (_liOOi == 1.0) {
_l11OI = vec3(0.012);
_liOiI = vec3(0.04);
_lOOiI = 0.55;
_llIii = 0.0;
} else if (_liOOi == 2.0) {
_liOiI = vec3(0.32, 0.32, 0.34);
_lOOiI = 0.42;
} else if (_liOOi == 3.0) {
_liOiI = vec3(0.86, 0.83, 0.78);
_lOOiI = 0.16;
}
vec3 _llIOI = vec3(1.0, 0.84, 0.64) * 3.6;
vec3 col = _l0lii(n, v, _llIIi, _l11OI, _liOiI, _lOOiI, _llIii) * _llIOI;
float _li1OI = saturate(dot(n, _lIIIi) * 0.5 + 0.5);
col += (_l11OI + _liOiI * 0.12) * vec3(0.55, 0.62, 0.8) * _li1OI * _li1OI * 0.35;
vec3 _l0OOi = reflect(rd, n);
vec3 _ll0Oi = _llIOI * 0.16 * pow(saturate(dot(_l0OOi, _llIIi) * 0.5 + 0.5), 10.0) + vec3(0.02, 0.024, 0.04);
col += _ll0Oi * _l00O1(max(dot(n, v), 0.0), _liOiI) * (1.0 - _lOOiI * 0.7);
float _l1iIl = smoothstep(st.z + 0.05, st.z - 0.6, _lII0l);
float _l0I1l = exp(-abs(_lII0l - st.z) / 0.22) * step(0.0, st.z) * (1.0 - smoothstep(0.0, 1.0, st.z - 30.0));
float _lI0Oi = _liOOi == 1.0 ? 1.0 : _liOOi == 0.0 ? exp(-max(_l1I0l - 0.29, 0.0) / 0.025) * 0.12 : 0.03;
col += (_lIi01 * 1.8 * _l1iIl + _l1i01 * 4.0 * _l0I1l) * _lI0Oi;
col = mix(col, vec3(1.0, 0.9, 0.9) * 2.2, st.x * st.x * 0.6) + _lIi01 * st.x * 0.8;
return vec4(col, 1.0);
}
void main() {
_l100l = S0.y;
_li00l = S0.z;
float _liO0l = S0.x;
_lI0Ol = 2.0 * _liO0l / OutSize.y;
gPix = _lI0Ol;
_lO0li = S1.x;
_l00li = S1.y;
_lIlIi = S1.w;
_lOlIi = saturate(_lO0li * 2.0);
_l0lIi = S0.w;
_lllIi = _l00li >= 0.0 ? 1.4 * (1.0 - exp(-_l00li * 14.0)) * exp(-_l00li * 0.8) : 0.0;
_l1lIi = _l00li >= 0.0 ? exp(-_l00li * 28.0) : 0.0;
_l1IIi = CentreRel;
_llIIi = normalize(_lOIIi(normalize(CentreRel)));
_lIIIi = normalize(_lOIIi(-GalaxyN) + _llIIi * 0.6);
vec2 _lO00l = texCoord * 2.0 - 1.0;
vec2 _l000l = vec2(_lO00l.x * OutSize.x / OutSize.y, _lO00l.y);
vec3 rd = normalize(CamFwd + (CamRight * _l000l.x + CamUp * _l000l.y) * _liO0l);
vec2 _l0i0I = _l11iI(CamPos, rd, 170, 1e9);
float _llO0I = _l0i0I.x > 0.0 ? _l0i0I.x : 1e9;
vec3 col;
float sky = 1.0;
if (_l0i0I.x > 0.0) {
col = _ll1OI(CamPos + rd * _l0i0I.x, rd, _l0i0I.y);
sky = 0.0;
} else {
col = _lIlii(rd) * (1.0 - 0.85 * _l0lIi);
vec3 _l10Oi;
vec4 title = _l1OOi(CamPos, rd, _l10Oi);
col = mix(col, title.rgb, title.a) + _l10Oi;
sky = 1.0 - title.a;
}
if (_l0i0I.x > 0.0) {
col *= mix(0.12, 1.0, S1.z);
}
vec3 light = _l0lOi(rd, _llO0I) + _l1lOi(rd, _llO0I) + _ll1Oi(rd, _llO0I) + _li1Oi(rd, _llO0I) + _lIl1I(rd, _llO0I)
+ _lOiOi(rd, _llO0I);
col += light;
col = 1.0 - exp(-col * 1.15);
col = pow(col, vec3(1.0 / 2.2));
fragColor = vec4(col, saturate(sky + lum(light) * 0.5));
}