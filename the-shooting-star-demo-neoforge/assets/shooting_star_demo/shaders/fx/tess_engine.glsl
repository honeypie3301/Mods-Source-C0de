#define ENG_POSE 48
uniform vec4 Eng[ENG_POSE];
#define ENG_M_HULL 1.0
#define ENG_M_INNER 2.0
#define ENG_M_CONDUIT 3.0
#define ENG_M_NODE 4.0
#define ENG_M_CORE 5.0
#define ENG_M_GUSSET 6.0
const float _lIlIO = 0.05;
const float _l1lIO = 0.105;
const float _lilIO = 1.2;
const float _lOlIO = 1.34;
const float _l0lIO = 4.4;
const vec3 _llIIO = vec3(1.0, 0.97, 1.0);
const vec3 _lIIIO = vec3(0.62, 0.92, 1.0);
const vec3 _l1IIO = vec3(1.0, 0.78, 0.5);
struct _liIIO {
float t;
vec3 n;
vec3 p;
float _l0Iii;
float id;
vec4 _lO1Il;
};
int _lOIIO = 0;
float _l0IIO = 0.0;
float _ll1IO = 1.0;
float _lI1IO = 1.0;
float _l11IO = 1.9;
float _li1IO = 9.0;
float _lO1IO = 0.0;
float _l01IO = 0.0;
float _lliIO = 0.0;
float _lIiIO = 0.0;
float _l1iIO = 0.0;
float _liiIO = 0.0;
float _lOiIO = 0.0;
vec4 _l0iIO = vec4(0.0);
float _llOIO = 1.0;
float _lIOIO = 0.0;
float _l1OIO = 0.0;
float _liOIO = 0.0;
vec3 _lOOIO = vec3(0.0);
float _l0OIO = 0.062;
float _ll0IO = 0.058;
float _lI0IO = 1.0;
vec4 _l10IO = vec4(1.0);
vec4 _li0IO = vec4(0.0);
vec3 _lO0IO = vec3(0.0, 1.0, 0.0);
vec3 _l00IO = vec3(0.0);
vec3 _lll1O = vec3(0.0);
float _lIl1O = 0.0;
int _l1l1O = 0;
void _lil1O() {
_lOIIO = int(Eng[47].y);
_l0IIO = Eng[42].x;
_ll1IO = Eng[42].y;
_lI1IO = Eng[42].z;
_l11IO = Eng[42].w;
_li1IO = Eng[43].x;
_lO1IO = Eng[43].y;
_l01IO = Eng[43].z;
_lliIO = Eng[43].w;
_lIiIO = Eng[44].x;
_l1iIO = Eng[44].y;
_liiIO = Eng[44].z;
_lOiIO = Eng[44].w;
_l0iIO = Eng[45];
_llOIO = Eng[46].x;
_lIOIO = Eng[46].y;
_l1OIO = Eng[46].z;
_liOIO = Eng[46].w;
_lOOIO = vec3(0.0, Eng[41].x, 0.0);
_l0OIO = Eng[41].y;
_ll0IO = Eng[41].z;
_lI0IO = Eng[41].w;
_l10IO = cos(Eng[40]);
_li0IO = sin(Eng[40]);
}
void _lOl1O(vec3 _l0l1O, vec3 _llIOI) {
_lO0IO = _l0l1O;
_l00IO = _llIOI;
}
void _llI1O(vec3 _lII1O, float _l1I1O) {
_lll1O = _lII1O;
_lIl1O = _l1I1O;
}
float _liI1O(vec3 ro, float _lOi01) {
return smoothstep(0.0045, 0.012, _lOi01 * max(length(ro) - 1.0, 0.3));
}
float _lOI1O(float t) {
return _lIl1O > 0.0 ? 1.0 - exp(-max(t, 0.0) * _lIl1O) : 0.0;
}
float _l0I1O(float d, float w, float aa) {
return 1.0 - smoothstep(w - aa, w + aa, d);
}
float _ll11O(float size, float _li111) {
return 1.0 - smoothstep(0.4, 1.0, _li111 / max(size, 1e-6));
}
float _lI11O(vec3 n, vec3 v, vec3 _ll0ll, float _lOOiI) {
vec3 _l111O = normalize(_ll0ll + v);
float _lii0l = max(dot(n, _ll0ll), 0.0);
float _l0OiI = max(dot(n, v), 1e-3);
float a = max(_lOOiI * _lOOiI, 0.003);
float _l0Oil = a * a;
float _lOi0l = max(dot(n, _l111O), 0.0);
float dd = _lOi0l * _lOi0l * (_l0Oil - 1.0) + 1.0;
float _li11O = _l0Oil / (PI * dd * dd);
float _lO11O = sqr(a + 1.0) / 8.0;
float _lI0iI = _l0OiI / (_l0OiI * (1.0 - _lO11O) + _lO11O) * _lii0l / (_lii0l * (1.0 - _lO11O) + _lO11O);
return _li11O * _lI0iI / (4.0 * _l0OiI * _lii0l + 1e-4) * _lii0l;
}
vec3 _l011O(float _l0OiI, float _llIIl) {
return mix(vec3(0.62), prism7(_llIIl + 0.62 * (1.0 - _l0OiI)), 0.32);
}
vec3 _lli1O(vec3 n, vec3 v, vec3 _ll0ll, vec3 u) {
float _lii0l = dot(n, _ll0ll);
if (_lii0l <= 0.0) return vec3(0.0);
vec3 _lIi1O = _ll0ll + v;
vec3 _l1i1O = cross(n, u);
float _lii1O = length(_l1i1O);
if (_lii1O < 1e-4) return vec3(0.0);
float across = dot(_lIi1O, _l1i1O / _lii1O);
float _lOi1O = exp(-across * across / 0.02) * _lii0l;
float along = abs(dot(_lIi1O, u));
vec3 c = vec3(0.0);
for (int _l00II = 1; _l00II <= 2 + _lOIIO; _l00II++) {
float _l0i1O = along * 1.6 / float(_l00II);
float w = smoothstep(0.38, 0.42, _l0i1O) * (1.0 - smoothstep(0.66, 0.72, _l0i1O));
c += prism7((0.70 - _l0i1O) / 0.32 * (6.0 / 7.0)) * w / float(_l00II);
}
return c * _lOi1O;
}
vec3 _llO1O(vec3 r, vec3 _l0l1O, vec3 _llIOI) {
float k = max(dot(r, _l0l1O), 0.0);
return _llIOI * (0.025 + 0.14 * k * k * k) + vec3(0.004, 0.0045, 0.007) + _lll1O * 0.25 * saturate(r.y + 0.5);
}
vec3 _lIO1O(vec2 p, float size) {
vec2 q = p / size;
vec2 rr = vec2(1.0, 1.7320508);
vec2 _lI0II = rr * 0.5;
vec2 a = mod(q, rr) - _lI0II;
vec2 b = mod(q - _lI0II, rr) - _lI0II;
vec2 g = dot(a, a) < dot(b, b) ? a : b;
vec2 id = q - g;
float e = 0.5 - max(abs(g.x), dot(abs(g), vec2(0.5, 0.8660254)));
return vec3(e * size, id);
}
float _l1O1O(float u, float seed) {
float id = floor(u);
float _lI0II = hash11(id * 1.37 + seed * 17.0);
float w = _lI0II < 0.35 ? 0.25 : _lI0II < 0.7 ? 0.5 : 0.75;
return step(0.18, _lI0II) * step(fract(u), w);
}
int _liO1O(int n) {
return n == 0 ? 63 : n == 1 ? 6 : n == 2 ? 91 : n == 3 ? 79 : n == 4 ? 102 : n == 5 ? 109 : n == 6 ? 125
: n == 7 ? 7 : n == 8 ? 127 : n == 9 ? 111 : n == 10 ? 57 : n == 11 ? 64 : 0;
}
float _lOO1O(vec2 p, int _l00II) {
float d = 1e3;
if ((_l00II & 1) != 0) d = min(d, sdSegment2(p, vec2(0.15, 1.85), vec2(0.85, 1.85)));
if ((_l00II & 2) != 0) d = min(d, sdSegment2(p, vec2(0.9, 1.78), vec2(0.9, 1.07)));
if ((_l00II & 4) != 0) d = min(d, sdSegment2(p, vec2(0.9, 0.93), vec2(0.9, 0.22)));
if ((_l00II & 8) != 0) d = min(d, sdSegment2(p, vec2(0.15, 0.15), vec2(0.85, 0.15)));
if ((_l00II & 16) != 0) d = min(d, sdSegment2(p, vec2(0.1, 0.93), vec2(0.1, 0.22)));
if ((_l00II & 32) != 0) d = min(d, sdSegment2(p, vec2(0.1, 1.78), vec2(0.1, 1.07)));
if ((_l00II & 64) != 0) d = min(d, sdSegment2(p, vec2(0.15, 1.0), vec2(0.85, 1.0)));
return d;
}
float _l0O1O(vec2 uv, vec2 at, float _ll01O, ivec4 _lI01O, int count, float aa) {
vec2 p = (uv - at) / (_ll01O * 0.5);
float _liOI1 = 1.35;
if (p.y < -0.2 || p.y > 2.2 || p.x < -0.2 || p.x > _liOI1 * float(count)) return 0.0;
float _l1Iil = clamp(floor(p.x / _liOI1), 0.0, float(count - 1));
int i = int(_l1Iil);
int g = i == 0 ? _lI01O.x : i == 1 ? _lI01O.y : i == 2 ? _lI01O.z : _lI01O.w;
float d = _lOO1O(vec2(p.x - _l1Iil * _liOI1, p.y), _liO1O(g));
float a = aa / (_ll01O * 0.5);
return smoothstep(0.12 + a, 0.12 - a, d);
}
float _l101O(int i) {
int n = (i & 1) + ((i >> 1) & 1) + ((i >> 2) & 1) + ((i >> 3) & 1);
return float(n) * (1.5 / 7.0) + _l1iIO;
}
float _li01O(vec3 p) {
return (p.x + p.z + 2.0) * 0.25 * (6.0 / 7.0) + (p.y + 1.0) * 0.5 * 0.18 + _l1iIO;
}
float _lO01O(int i, int _liOil, float s, vec3 p) {
return mix(mix(_l101O(i), _l101O(_liOil), s), _li01O(p), _liOIO);
}
vec3 _l001O(float _llliO) {
vec3 c = mix(vec3(1.0, 0.15, 0.0), vec3(1.0, 0.3, 0.05), saturate((_llliO - 3500.0) / 800.0));
c = mix(c, vec3(1.0, 0.8, 0.6), saturate((_llliO - 4300.0) / 1700.0));
c = mix(c, vec3(0.55, 0.68, 1.0), saturate((_llliO - 6000.0) / 3700.0));
return mix(c, vec3(0.35, 0.5, 1.0), saturate((_llliO - 9700.0) / 2400.0));
}
vec3 _lIliO(int c) {
float v = Eng[17 + 3 * c].w;
return vec3(floor(v / 1000.0), floor(mod(v, 1000.0)) * 100.0, fract(v));
}
vec3 _l1liO(int c) {
return _l001O(_lIliO(c).y);
}
vec3 _liliO(vec3 ro, vec3 rd) {
if (_lliIO <= 0.001) return ro;
float _li0l1 = max(-dot(ro, rd), 0.0);
float _l11i1 = ro.y + rd.y * _li0l1;
float band = floor(_l11i1 / 0.055);
float tq = floor(_l0IIO * 24.0);
float on = step(1.0 - 0.45 * _lliIO, hash12(vec2(band, tq)));
float off = (hash12(vec2(band * 1.7 + 3.0, tq + 3.1)) - 0.5) * 0.16 * _lliIO * on;
vec3 side = cross(rd, vec3(0.0, 1.0, 0.0));
float _lOliO = length(side);
side = _lOliO > 1e-3 ? side / _lOliO : vec3(1.0, 0.0, 0.0);
return ro + side * off;
}
void _l0liO(int b, out int i, out int _liOil, out int k) {
k = b >> 3;
int _l00II = b & 7;
int _l0lll = (1 << k) - 1;
i = (_l00II & _l0lll) | ((_l00II & (7 - _l0lll)) << 1);
_liOil = i | (1 << k);
}
void _llIiO(int b, out int i, out int _liOil, out vec3 a, out vec3 u, out vec3 _lIIiO, out vec3 _l1IiO, out float _lll0I,
out float _lIl01, out float _lO1iI) {
int k;
_l0liO(b, i, _liOil, k);
a = Eng[i].xyz;
vec3 ab = Eng[_liOil].xyz - a;
_lll0I = length(ab);
u = ab / max(_lll0I, 1e-6);
int _liIiO = k == 0 ? 1 : k == 1 ? 2 : k == 2 ? 0 : 1;
vec3 r = Eng[i ^ (1 << _liIiO)].xyz - a;
r -= u * dot(r, u);
float _lIIII = length(r);
_lIIiO = _lIIII > 1e-5 ? r / _lIIII : normalize(cross(u, vec3(0.31, 0.83, 0.47)));
_l1IiO = cross(u, _lIIiO);
_lIl01 = _lIlIO * Eng[i].w * _ll1IO;
_lO1iI = _lIlIO * Eng[_liOil].w * _ll1IO;
}
float _lOIiO(int i, int _liOil, float _lll0I) {
return min(_l1lIO * max(Eng[i].w, Eng[_liOil].w) * _ll1IO * 1.95, _lll0I * 0.28);
}
void _l0IiO(float _lll0I, float _ll1iO, float _lO1I1, out float _lI1OI, out float _lIll1) {
float _l0i1I = max(_lll0I - 2.0 * _ll1iO, 1e-4);
_lI1OI = max(1.0, floor(_l0i1I / (2.1 * max(_lO1I1, 1e-5)) + 0.5));
_lIll1 = _l0i1I / _lI1OI;
}
float _lI1iO(int b, float k, float _lI1OI) {
float _l00II = min(k, _lI1OI - 1.0 - k);
return step(hash12(vec2(float(b) * 1.73 + 0.5, _l00II * 3.1 + 0.7)), 0.5);
}
void _l11iO(vec3 n, float c, vec3 lo, vec3 _lOI0l, int id, inout vec2 tt, inout ivec2 pp) {
float _liOiI = dot(n, lo) - c;
float _li1iO = dot(n, _lOI0l);
if (abs(_li1iO) < 1e-9) {
if (_liOiI > 0.0) tt.x = 1e30;
return;
}
float t = -_liOiI / _li1iO;
if (_li1iO < 0.0) {
if (t > tt.x) {
tt.x = t;
pp.x = id;
}
} else if (t < tt.y) {
tt.y = t;
pp.y = id;
}
}
vec3 _lO1iO(int id, float g) {
if (id >= 8) return vec3(0.0, 0.0, id == 8 ? -1.0 : 1.0);
if (id >= 4) {
float _l01iO = (id & 2) == 0 ? 0.70710678 : -0.70710678;
float _lliiO = (id & 1) == 0 ? 0.70710678 : -0.70710678;
return vec3(_l01iO, _lliiO, -g * _lilIO);
}
float _lIiiO = (id & 1) == 0 ? 1.0 : -1.0;
return id < 2 ? vec3(_lIiiO, 0.0, -g) : vec3(0.0, _lIiiO, -g);
}
void _l1iiO(vec3 lo, vec3 _lOI0l, float _liiiO, float g, float _lIIOi, float _l1IOi, int base, float _lOiiO, out vec2 tt, out ivec2 pp) {
tt = vec2(-1e30, 1e30);
pp = ivec2(-1);
int _lI1OI = (_lOiiO > 0.5 ? 10 : 8) + _lOIIO;
for (int k = 0; k < _lI1OI; k++) {
float c = k < 4 ? _liiiO : k < 8 ? _liiiO * _lilIO : k == 8 ? -_lIIOi : _l1IOi;
_l11iO(_lO1iO(k, g), c, lo, _lOI0l, base + k, tt, pp);
}
}
float _l0iiO(vec3 q, int _lliOI, float _lIl01, float g, float _lll0I, float _ll1iO, int b, float _ll0Ol) {
if (_ll0Ol > 0.7) return -1.0;
float h = _lIl01 + g * q.z;
float c = _lliOI < 2 ? q.y : q.x;
if ((_lliOI & 1) == 1) c = -c;
float _lO1I1 = _lIl01 + g * _lll0I * 0.5;
float _lI1OI, _lIll1;
_l0IiO(_lll0I, _ll1iO, _lO1I1, _lI1OI, _lIll1);
float z = q.z - _ll1iO;
if (z < 0.0 || z > _lI1OI * _lIll1) return -1.0;
float _llOiO = z / _lIll1;
float _lIOiO = min(floor(_llOiO), _lI1OI - 1.0);
if (_lI1iO(b, _lIOiO, _lI1OI) < 0.5) return -1.0;
float _l1OiO = _llOiO - _lIOiO;
float R = 0.44 * h;
float _lIIll = mod(_lIOiO, 2.0) < 0.5 ? 1.0 : -1.0;
vec2 _liOiO = vec2(_l1OiO * _lIll1, c * _lIIll);
float _lillI = sdSegment2(_liOiO, vec2(0.0, -R), vec2(_lIll1, R));
float _lOOiO = h * (0.1 + 0.4 * _ll0Ol);
float _l0OiO = min(_l1OiO, 1.0 - _l1OiO) * _lIll1;
float _ll0iO = h * (0.1 + 0.35 * _ll0Ol);
return min(min(0.46 * h - abs(c), _lillI - _lOOiO), _l0OiO - _ll0iO);
}
float _lI0iO(vec3 lo, vec3 _lOI0l, float rc, float _lll0I, float t0, float t1) {
float A = dot(_lOI0l.xy, _lOI0l.xy);
if (A < 1e-9) return -1.0;
float _l10iO = dot(lo.xy, _lOI0l.xy);
float _li0iO = dot(lo.xy, lo.xy) - rc * rc;
float _li11O = _l10iO * _l10iO - A * _li0iO;
if (_li11O < 0.0) return -1.0;
float t = (-_l10iO - sqrt(_li11O)) / A;
if (t < t0 || t > t1) return -1.0;
float z = lo.z + _lOI0l.z * t;
if (z < 0.0 || z > _lll0I) return -1.0;
return t;
}
void _lO0iO(int b, vec3 ro, vec3 rd, float _ll0Ol, inout float best, inout _liIIO h) {
int i, _liOil;
vec3 a, u, _lIIiO, _l1IiO;
float _lll0I, _lIl01, _lO1iI;
_llIiO(b, i, _liOil, a, u, _lIIiO, _l1IiO, _lll0I, _lIl01, _lO1iI);
if (_lll0I < 1e-4 || max(_lIl01, _lO1iI) < 1e-5) return;
float _l00iO = max(_lIl01, _lO1iI) * _lOlIO * 1.22;
vec3 o = ro - a;
vec3 _lllOO = cross(rd, u);
float _lOliI = length(_lllOO);
if (_lOliI > 1e-5 && abs(dot(o, _lllOO)) > _l00iO * _lOliI) return;
vec3 oc = o - u * (_lll0I * 0.5);
float bb = dot(oc, rd);
float _lO0Ii = _lll0I * 0.5 + _l00iO;
float _llIOi = bb * bb - dot(oc, oc) + _lO0Ii * _lO0Ii;
if (_llIOi < 0.0 || -bb - sqrt(_llIOi) > best) return;
vec3 lo = vec3(dot(o, _lIIiO), dot(o, _l1IiO), dot(o, u));
vec3 _lOI0l = vec3(dot(rd, _lIIiO), dot(rd, _l1IiO), dot(rd, u));
float g = (_lO1iI - _lIl01) / _lll0I;
float _ll1iO = _lOIiO(i, _liOil, _lll0I);
float _llO0I = best;
int plane = -1;
float _l0Iii = ENG_M_HULL;
for (int _lIlOO = 0; _lIlOO < 3 + _lOIIO; _lIlOO++) {
vec2 tt;
ivec2 pp;
_l1iiO(lo, _lOI0l, _lIlOO == 0 ? _lIl01 * _lOlIO : _lIlOO == 1 ? _lO1iI * _lOlIO : _lIl01, _lIlOO == 2 ? g : 0.0,
_lIlOO == 1 ? _lll0I - _ll1iO : 0.0, _lIlOO == 0 ? _ll1iO : _lll0I, _lIlOO == 0 ? 10 : _lIlOO == 1 ? 20 : 0, 1.0, tt, pp);
if (tt.x >= tt.y || tt.x <= 0.0 || tt.x >= _llO0I) continue;
float _l1lOO = tt.x;
int _lilOO = pp.x;
float _lOlOO = ENG_M_HULL;
if (_lIlOO == 2 && _lilOO < 4) {
float _l0lOO = -1.0;
float _l10il = -1.0;
for (int e = 0; e < 2 + _lOIIO; e++) {
int _llIOO = e == 0 ? pp.x : pp.y;
float _l00II = _llIOO < 4 ? _l0iiO(lo + _lOI0l * (e == 0 ? tt.x : tt.y), _llIOO, _lIl01, g, _lll0I, _ll1iO, b, _ll0Ol) : -1.0;
if (e == 0) _l0lOO = _l00II; else _l10il = _l00II;
if (_l0lOO <= 0.0) break;
}
if (_l0lOO > 0.0) {
float _li0l1 = _lI0iO(lo, _lOI0l, 0.17 * min(_lIl01, _lO1iI), _lll0I, tt.x, tt.y);
if (_li0l1 > 0.0) {
_l1lOO = _li0l1;
_lOlOO = ENG_M_CONDUIT;
} else if (_l10il > 0.0) {
continue;
} else {
_l1lOO = tt.y;
_lilOO = pp.y;
_lOlOO = ENG_M_INNER;
}
}
}
_llO0I = _l1lOO;
plane = _lilOO;
_l0Iii = _lOlOO;
}
if (plane < 0) return;
best = _llO0I;
vec3 q = lo + _lOI0l * _llO0I;
vec3 _lii0l;
if (_l0Iii == ENG_M_CONDUIT) {
_lii0l = vec3(q.xy, 0.0);
} else {
_lii0l = _lO1iO(plane - (plane >= 20 ? 20 : plane >= 10 ? 10 : 0), plane >= 10 ? 0.0 : g);
if (_l0Iii == ENG_M_INNER) _lii0l = -_lii0l;
}
h.t = _llO0I;
h.n = normalize(_lIIiO * _lii0l.x + _l1IiO * _lii0l.y + u * _lii0l.z);
h.p = ro + rd * _llO0I;
h._l0Iii = _l0Iii;
h.id = float(b);
h._lO1Il = vec4(q, float(plane));
}
void _lIIOO(float o, float d, float c, int id, inout vec2 tt, inout int _l1IOO, inout float _liIOO) {
if (abs(d) < 1e-9) {
if (abs(o) > c) tt.x = 1e30;
return;
}
float inv = 1.0 / d;
float t0 = (-c - o) * inv;
float t1 = (c - o) * inv;
float tn = min(t0, t1);
if (tn > tt.x) {
tt.x = tn;
_l1IOO = id;
_liIOO = d > 0.0 ? -1.0 : 1.0;
}
tt.y = min(tt.y, max(t0, t1));
}
vec3 _lOIOO(int id) {
if (id < 3) return vec3(id == 0 ? 1.0 : 0.0, id == 1 ? 1.0 : 0.0, id == 2 ? 1.0 : 0.0);
if (id < 9) {
int q = id - 3;
float _lIiiO = (q & 1) == 0 ? 1.0 : -1.0;
return q < 2 ? vec3(1.0, _lIiiO, 0.0) : q < 4 ? vec3(1.0, 0.0, _lIiiO) : vec3(0.0, 1.0, _lIiiO);
}
return vec3(id == 12 ? -1.0 : 1.0, id == 11 ? -1.0 : 1.0, id == 10 ? -1.0 : 1.0);
}
void _l0IOO(int i, vec3 ro, vec3 rd, inout float best, inout _liIIO h) {
float _lOi0l = _l1lIO * Eng[i].w * _ll1IO;
if (_lOi0l < 1e-5) return;
vec3 o = ro - Eng[i].xyz;
float bb = dot(o, rd);
float _lO0Ii = _lOi0l * 1.62;
float _llIOi = bb * bb - dot(o, o) + _lO0Ii * _lO0Ii;
if (_llIOi < 0.0 || -bb - sqrt(_llIOi) > best) return;
vec2 tt = vec2(-1e30, 1e30);
int _l1IOO = -1;
float _liIOO = 1.0;
for (int k = 0; k < 13 + _lOIIO; k++) {
vec3 _ll1OO = _lOIOO(k);
_lIIOO(dot(o, _ll1OO), dot(rd, _ll1OO), (k < 3 ? 1.0 : k < 9 ? 1.75 : 2.3) * _lOi0l, k, tt, _l1IOO, _liIOO);
}
if (tt.x >= tt.y || tt.x <= 0.0 || tt.x >= best) return;
best = tt.x;
h.t = tt.x;
h.n = normalize(_lOIOO(_l1IOO) * _liIOO);
h.p = ro + rd * tt.x;
h._l0Iii = ENG_M_NODE;
h.id = float(i);
h._lO1Il = vec4(0.0, 0.0, 0.0, float(_l1IOO));
}
void _lI1OO(int f, out int _l11OO, out int _l11lO, out int _li1lO) {
int _l0iiI = f >> 2;
int _li1OO = f & 3;
int ax = _l0iiI < 3 ? 0 : _l0iiI < 5 ? 1 : 2;
int ay = _l0iiI == 0 ? 1 : _l0iiI == 1 ? 2 : _l0iiI == 3 ? 2 : 3;
int r0 = _l0iiI == 0 ? 2 : _l0iiI < 3 ? 1 : 0;
int r1 = _l0iiI == 0 ? 3 : _l0iiI == 1 ? 3 : _l0iiI == 2 ? 2 : _l0iiI == 3 ? 3 : _l0iiI == 4 ? 2 : 1;
_l11OO = ((_li1OO & 1) << r0) | ((_li1OO >> 1) << r1);
_l11lO = 1 << ax;
_li1lO = 1 << ay;
}
float _lO1OO(int f, vec3 ro, vec3 rd, float _li1iI, out vec4 d, out float _l01OO, out int _l1lOI, out vec3 n) {
int _l11OO, _l11lO, _li1lO;
_lI1OO(f, _l11OO, _l11lO, _li1lO);
d = vec4(-1.0);
_l01OO = -1.0;
_l1lOI = 0;
vec3 _lliOO = Eng[_l11OO].xyz;
vec3 _lIiOO = Eng[_l11OO | _l11lO].xyz;
vec3 _l1iOO = Eng[_l11OO | _li1lO].xyz;
vec3 _liiOO = Eng[_l11OO | _l11lO | _li1lO].xyz;
n = vec3(0.0, 1.0, 0.0);
vec3 _l00lI = (_lliOO + _lIiOO + _l1iOO + _liiOO) * 0.25;
float r2 = max(max(dot(_lliOO - _l00lI, _lliOO - _l00lI), dot(_lIiOO - _l00lI, _lIiOO - _l00lI)), max(dot(_l1iOO - _l00lI, _l1iOO - _l00lI), dot(_liiOO - _l00lI, _liiOO - _l00lI)));
vec3 _lOiOO = ro - _l00lI;
float _l0iOO = dot(_lOiOO, rd);
float _llOOO = dot(_lOiOO, _lOiOO) - r2;
if (_llOOO > 0.0 && (_l0iOO > 0.0 || _l0iOO * _l0iOO < _llOOO)) return -1.0;
n = cross(_lIiOO - _lliOO, _l1iOO - _lliOO);
float _lii0l = length(n);
if (_lii0l < 1e-7) return -1.0;
n /= _lii0l;
float _lIOOO = dot(rd, n);
if (abs(_lIOOO) < 1e-5) return -1.0;
float t = dot(_lliOO - ro, n) / _lIOOO;
if (t <= 0.0 || t >= _li1iI) return -1.0;
vec3 q = ro + rd * t;
vec3 _l1OOO = _lIiOO - _lliOO;
vec3 _liOOO = _liiOO - _lIiOO;
vec3 _lOOOO = _l1iOO - _liiOO;
vec3 _l0OOO = _lliOO - _l1iOO;
d.x = dot(cross(_l1OOO, q - _lliOO), n) * inversesqrt(dot(_l1OOO, _l1OOO) + 1e-12);
d.y = dot(cross(_liOOO, q - _lIiOO), n) * inversesqrt(dot(_liOOO, _liOOO) + 1e-12);
d.z = dot(cross(_lOOOO, q - _liiOO), n) * inversesqrt(dot(_lOOOO, _lOOOO) + 1e-12);
d.w = dot(cross(_l0OOO, q - _l1iOO), n) * inversesqrt(dot(_l0OOO, _l0OOO) + 1e-12);
if (min(min(d.x, d.y), min(d.z, d.w)) <= 0.0) return -1.0;
float k = _lIlIO * _l0lIO * _ll1IO;
vec4 _lI0iI = vec4(Eng[_l11OO].w, Eng[_l11OO | _l11lO].w, Eng[_l11OO | _l11lO | _li1lO].w, Eng[_l11OO | _li1lO].w) * k;
vec4 _ll0OO = vec4(d.w, d.x, d.y, d.z);
vec4 _lI0OO = vec4(d.x, d.y, d.z, d.w);
vec4 _l00II = _lI0iI - (_ll0OO + _lI0OO);
_l1lOI = _l00II.x >= max(_l00II.y, max(_l00II.z, _l00II.w)) ? 0 : _l00II.y >= max(_l00II.z, _l00II.w) ? 1 : _l00II.z >= _l00II.w ? 2 : 3;
float _l10OO = _l1lOI == 0 ? _lI0iI.x : _l1lOI == 1 ? _lI0iI.y : _l1lOI == 2 ? _lI0iI.z : _lI0iI.w;
float _li0OO = _l1lOI == 0 ? _ll0OO.x : _l1lOI == 1 ? _ll0OO.y : _l1lOI == 2 ? _ll0OO.z : _ll0OO.w;
float _lO0OO = _l1lOI == 0 ? _lI0OO.x : _l1lOI == 1 ? _lI0OO.y : _l1lOI == 2 ? _lI0OO.z : _lI0OO.w;
_l01OO = _l10OO - _li0OO - _lO0OO;
vec2 hc = vec2(_li0OO, _lO0OO) - _l10OO * 0.3;
float _l00OO = max(max(abs(hc.x), abs(hc.y)), abs(hc.x + hc.y) * 0.75);
_l01OO = min(_l01OO, _l00OO - _l10OO * 0.1);
return t;
}
void _lll0O(vec3 ro, vec3 rd, inout float best, inout _liIIO h) {
int _lIl0O = 16 + _lOIIO;
for (int i = 0; i < _lIl0O; i++) {
float _lI0iI = _lIlIO * _l0lIO * Eng[i].w * _ll1IO;
if (_lI0iI < 1e-5) continue;
vec3 _liOiO = Eng[i].xyz;
vec3 o = ro - _liOiO;
float bb = dot(o, rd);
float cc = dot(o, o) - _lI0iI * _lI0iI;
float _llIOi = bb * bb - cc;
if (_llIOi < 0.0 || (cc > 0.0 && bb > 0.0)) continue;
if (-bb - sqrt(_llIOi) > best) continue;
for (int k = 0; k < 6 + _lOIIO; k++) {
int _liIiO = k < 3 ? 0 : k < 5 ? 1 : 2;
int _l1l0O = k == 0 ? 1 : k == 1 ? 2 : k == 2 ? 3 : k == 3 ? 2 : 3;
vec3 A = Eng[i ^ (1 << _liIiO)].xyz - _liOiO;
vec3 _l10iO = Eng[i ^ (1 << _l1l0O)].xyz - _liOiO;
float _li0OO = length(A);
float _lO0OO = length(_l10iO);
if (_li0OO < 1e-4 || _lO0OO < 1e-4) continue;
vec3 _lil0O = A / _li0OO;
vec3 _lOl0O = _l10iO / _lO0OO;
vec3 n = cross(_lil0O, _lOl0O);
float _lii0l = length(n);
if (_lii0l < 1e-3) continue;
n /= _lii0l;
float _lIOOO = dot(rd, n);
if (abs(_lIOOO) < 1e-5) continue;
float t = -dot(o, n) / _lIOOO;
if (t <= 0.0 || t >= best) continue;
vec3 q = o + rd * t;
float _l0l0O = dot(q, _lil0O);
float _llI0O = dot(q, _lOl0O);
float ab = dot(_lil0O, _lOl0O);
float _lII0O = max(1.0 - ab * ab, 1e-4);
float _liIII = (_l0l0O - ab * _llI0O) / _lII0O;
float _l1I0O = (_llI0O - ab * _l0l0O) / _lII0O;
float _liI0O = min(_lI0iI, min(_li0OO, _lO0OO) * 0.45);
float _l01OO = min(min(_liIII, _l1I0O), _liI0O - _liIII - _l1I0O);
vec2 hc = vec2(_liIII, _l1I0O) - _liI0O * 0.3;
float _l00OO = max(max(abs(hc.x), abs(hc.y)), abs(hc.x + hc.y) * 0.75);
_l01OO = min(_l01OO, _l00OO - _liI0O * 0.1);
if (_l01OO <= 0.0) continue;
best = t;
h.t = t;
h.n = _lIOOO < 0.0 ? n : -n;
h.p = ro + rd * t;
h._l0Iii = ENG_M_GUSSET;
h.id = float(i);
h._lO1Il = vec4(_liIII, _l1I0O, _liI0O - _liIII - _l1I0O, _liI0O);
}
}
}
_liIIO _lOI0O(vec3 ro, vec3 rd, float _li1iI, float _ll0Ol) {
_lil1O();
_liIIO h;
h.t = -1.0;
h.n = vec3(0.0, 1.0, 0.0);
h.p = vec3(0.0);
h._l0Iii = 0.0;
h.id = 0.0;
h._lO1Il = vec4(0.0);
ro = _liliO(ro, rd);
vec2 _l0I0O = raySphere(ro, rd, vec3(0.0), _l11IO);
if (_l0I0O.y <= 0.0 || _l0I0O.x > _li1iI) return h;
float best = _li1iI;
if (_ll1IO > 0.001) {
int _l0OO1 = 32 + _lOIIO;
for (int b = 0; b < _l0OO1; b++) _lO0iO(b, ro, rd, _ll0Ol, best, h);
int _lIl0O = 16 + _lOIIO;
if ((_l1l1O & 4096) == 0) for (int i = 0; i < _lIl0O; i++) _l0IOO(i, ro, rd, best, h);
if ((_l1l1O & 2048) == 0) _lll0O(ro, rd, best, h);
}
if (_ll0IO > 1e-4) {
vec2 hc = raySphere(ro, rd, _lOOIO, _ll0IO);
if (hc.x > 0.0 && hc.x < best) {
best = hc.x;
h.t = hc.x;
h.p = ro + rd * hc.x;
h.n = normalize(h.p - _lOOIO);
h._l0Iii = ENG_M_CORE;
h.id = 0.0;
h._lO1Il = vec4(0.0);
}
}
return h;
}
void _ll10O(vec3 p, vec3 n, vec3 r, out vec3 _lIIii, out vec3 _lI10O) {
_lIIii = vec3(0.0);
_lI10O = vec3(0.0);
int _l110O = 8 + _lOIIO;
for (int c = 0; c < _l110O; c++) {
vec4 A = Eng[16 + 3 * c];
float br = Eng[18 + 3 * c].w;
if (A.w <= 0.0 || br <= 0.0) continue;
vec3 _liI0l = A.xyz - p;
float _liI0I = dot(_liI0l, _liI0l);
float r2 = A.w * A.w;
vec3 _li10O = _liI0l * inversesqrt(_liI0I + 1e-8);
float _lOili = br * r2 / (_liI0I + r2 * 0.5);
vec3 tint = _l1liO(c);
_lIIii += tint * _lOili * saturate(dot(n, _li10O) * 0.8 + 0.2);
float _lIIII = max(dot(r, _li10O), 0.0);
_lI10O += tint * _lOili * pow(_lIIII, 14.0);
}
vec3 _liI0l = _lOOIO - p;
float _liI0I = dot(_liI0l, _liI0l);
vec3 _li10O = _liI0l * inversesqrt(_liI0I + 1e-8);
vec3 cc = mix(vec3(0.8, 0.86, 1.0), _l0iIO.rgb, saturate(_l0iIO.w * 0.5)) * _lI0IO;
float _lOili = 0.01 / (_liI0I + 0.01) * (1.0 + _l0iIO.w * 0.6);
_lIIii += cc * _lOili * saturate(dot(n, _li10O) * 0.8 + 0.2);
_lI10O += cc * _lOili * pow(max(dot(r, _li10O), 0.0), 14.0);
}
vec3 _lO10O(vec3 p, vec3 n, vec3 v, vec3 _l0l1O, vec3 _llIOI, vec3 _l010O, float _lOOiI, float _llIIl, vec3 u, float _lli0O) {
float _l0OiI = saturate(dot(n, v));
vec3 r = reflect(-v, n);
float _lii0l = dot(n, _l0l1O);
vec3 _lIi0O = _l011O(_l0OiI, _llIIl);
float x = 1.0 - _l0OiI;
float _l1i0O = x * x;
vec3 _ll0iI = (0.06 + 0.5 * _l1i0O * _l1i0O * x) * _lIi0O;
vec3 col = _l010O * _llIOI * (max((_lii0l + 0.2) / 1.2, 0.0) + 0.06);
col += _ll0iI * _llIOI * _lI11O(n, v, _l0l1O, _lOOiI) * 1.4;
if ((_l1l1O & 1024) != 0) return vec3(0.0);
if (_lli0O > 0.0 && (_l1l1O & 512) == 0) col += _lli1O(n, v, _l0l1O, u) * _llIOI * 0.35 * _lli0O;
col += _ll0iI * _llO1O(r, _l0l1O, _llIOI);
col += _lIi0O * _llIOI * _l1i0O * x * saturate(dot(-v, _l0l1O)) * 0.35;
col += _l010O * _lll1O * 0.5 * (0.55 + 0.45 * n.y);
if ((_l1l1O & 256) == 0) {
vec3 _lii0O, _lOi0O;
_ll10O(p, n, r, _lii0O, _lOi0O);
col += _l010O * _lii0O * 2.2 + _ll0iI * _lOi0O * 1.5;
}
return col;
}
vec3 _l0i0O(int b, float s, float _llIIl, float _lll0I) {
float _llO0O = s * _lll0I / 0.32 + _lIiIO * 2.2 + hash11(float(b) * 3.7);
float _lil11 = exp(-sqr((fract(_llO0O) - 0.5) / 0.07));
vec3 hc = prism7(_llIIl);
vec3 c = hc * (0.35 + 1.4 * _llOIO) + _llIIO * _lil11 * 2.4 * _llOIO;
return c * (1.0 + 1.6 * _l01IO + 1.5 * _lIOIO + 2.0 * _lOiIO);
}
struct _lIO0O {
vec2 uv;
vec2 at;
float _ll01O;
ivec4 _lI01O;
int count;
float aa;
float _lilOi;
};
float _l1O0O(vec2 w, float seed, float _liO0O) {
float sp = 0.075;
float id = floor(w.x / sp);
float on = step(hash12(vec2(id, seed)), 0.55);
float _lOO0O = step(abs((fract(w.x / sp) - 0.5) * sp), 0.022) * step(abs(w.y), 0.03);
float _lIOli = 0.8 + 0.2 * sin(_l0IIO * (0.7 + hash12(vec2(id, seed + 3.0)) * 2.0) + id);
float _lI0ll = step(abs(w.y), 0.03) * 0.55 * 0.59;
return mix(_lI0ll, _lOO0O * on * _lIOli, _ll11O(0.03, _liO0O));
}
void _l0O0O(int b, vec3 q, int _lIll1, float h, float _lll0I, float _ll1iO, float _lO1I1, float _li111, float _llIIl, vec3 _ll00O,
out vec3 _l010O, out vec3 _liIii, out float _lOOiI, out float _lI00O, out float _lOOii, out float _l100O, out vec2 _li00O,
inout _lIO0O _lO00O) {
int base = _lIll1 >= 20 ? 20 : _lIll1 >= 10 ? 10 : 0;
int id = _lIll1 - base;
vec3 hc = prism7(_llIIl);
float _liO0O = _li111 / max(h, 1e-6);
_l010O = vec3(0.075, 0.077, 0.086) * (0.8 + 0.4 * vnoise2(vec2(q.z / h * 1.3, (q.x + q.y) / h * 2.0 + float(b) * 7.0)));
_liIii = vec3(0.0);
_lOOiI = 0.42;
_lI00O = 0.0;
_lOOii = 1.0;
_l100O = 0.0;
_li00O = vec2(0.0);
if (id < 4) {
float c = (id < 2 ? q.y : q.x) / h;
float _l000O = abs(c);
_l100O = smoothstep(0.55, 0.67, _l000O) * sign(c);
if (base > 0) {
float zz = base == 10 ? q.z : _lll0I - q.z;
vec3 _ll0II = _lIO1O(vec2(zz / h, c), 0.13);
float _l0lI1 = _l0I1O(_ll0II.x, 0.012, _liO0O * 0.6) * _ll11O(0.03, _liO0O);
_l010O *= (1.0 - 0.55 * _l0lI1) * (0.85 + 0.3 * hash12(_ll0II.yz + float(b)));
_li00O = (hash22(_ll0II.yz + float(b) * 1.3) - 0.5) * 0.1 * _ll11O(0.08, _liO0O);
float _li0Ii = _l0I1O(abs(zz / max(_ll1iO, 1e-6) - 0.82), 0.014, _liO0O * 0.8 / max(_ll1iO / h, 1e-3));
_liIii += hc * _li0Ii * (0.45 + 1.2 * _l01IO) * _llOIO;
float _l1iIl = step(0.95, hash12(_ll0II.yz + float(b) * 7.1)) * smoothstep(0.012, 0.03, _ll0II.x) * _ll11O(0.05, _liO0O);
_liIii += _l1IIO * _l1iIl * 0.22 * _llOIO;
if (id == 0 || id == 2) {
int _l0OO1 = b + 1;
_lO00O.uv = vec2(zz / h, c);
_lO00O.at = vec2(0.45, -0.3);
_lO00O._ll01O = 0.55;
_lO00O._lI01O = ivec4(_l0OO1 / 10, _l0OO1 - (_l0OO1 / 10) * 10, 0, 0);
_lO00O.count = 2;
_lO00O.aa = _liO0O * 0.7;
_lO00O._lilOi = _ll11O(0.05, _liO0O);
}
_lI00O = 0.5;
_lOOiI = 0.36;
} else {
float _lI1OI, _llll0;
_l0IiO(_lll0I, _ll1iO, _lO1I1, _lI1OI, _llll0);
float _llOiO = (q.z - _ll1iO) / _llll0;
float _lIOiO = clamp(floor(_llOiO), 0.0, _lI1OI - 1.0);
float _lIll0 = _llOiO - _lIOiO;
float _l1ll0 = _lIll0 * _llll0 / h;
float _lIl1l = _lI1iO(b, _lIOiO, _lI1OI);
float _lill0 = _l0I1O(min(_lIll0, 1.0 - _lIll0) * _llll0 / h, 0.012, _liO0O * 0.6) * _ll11O(0.025, _liO0O);
_lOOii = 0.45 + 0.55 * smoothstep(0.0, 1.4 * h, min(q.z - _ll1iO, _lll0I - _ll1iO - q.z));
if (_l000O > 0.46) {
float _lOll0 = length(vec2((fract(q.z / (0.12 * h)) - 0.5) * 0.12, _l000O - 0.56));
float _l0ll0 = _l0I1O(_lOll0, 0.011, _liO0O * 0.6) * _ll11O(0.03, _liO0O);
_l010O = mix(_l010O * 0.8, vec3(0.13), _l0ll0) * (1.0 - 0.6 * _lill0);
if (id < 2 && mod(_lIOiO, 3.0) < 0.5) {
float _llIl0 = length(vec2(min(_lIll0, 1.0 - _lIll0) * _llll0 / h, _l000O - 0.57));
float w = max(0.04, _liO0O * 0.8);
float _ll01i = fract(_l0IIO * 0.5 + float(b) * 0.21 + _lIOiO * 0.13);
float _llOii = exp(-sqr((_ll01i - 0.1) / 0.03));
vec3 _llIII = c > 0.0 ? vec3(1.0, 0.12, 0.06) : _llIIO;
_liIii += _llIII * exp(-sqr(_llIl0 / w)) * (0.35 + 6.0 * _llOii) * _llOIO;
}
_lI00O = 1.0;
_lOOiI = 0.38;
} else if (_lIl1l > 0.5) {
vec3 _lIIl0 = id < 2 ? vec3(0.0, c * h, q.z) : vec3(c * h, 0.0, q.z);
float _l1Il0 = _l0iiO(_lIIl0, id, h, 0.0, _lll0I, _ll1iO, b, 0.0);
float _lIliI = smoothstep(-_li111 * 0.6, _li111 * 0.6, _l1Il0);
_l010O *= 0.8 * (1.0 - _lIliI);
_liIii += (vec3(0.002) + _ll00O * 0.045) * _lIliI;
_lI00O = 0.6;
} else {
float _lO1iI = hash12(vec2(float(b) * 3.7, _lIOiO * 1.3));
float _liIl0 = max(_l000O - 0.38, abs(_lIll0 - 0.5) * _llll0 / h - (_llll0 / h * 0.5 - 0.08));
float edge = _l0I1O(abs(_liIl0), 0.012, _liO0O * 0.6) * _ll11O(0.025, _liO0O);
float _lI1Il = fract(_lO1iI * 7.0) < 0.5 ? 0.5 : 0.36;
float _lO1il = _l0I1O(abs(_lIll0 - _lI1Il) * _llll0 / h, 0.01, _liO0O * 0.6) * _ll11O(0.025, _liO0O) * step(_liIl0, 0.0);
vec2 _lOIl0 = vec2(_lIOiO, float(b) + step(_lI1Il, _lIll0) * 5.0);
float _li0ll = 0.8 + 0.45 * hash12(_lOIl0);
_li00O = (hash22(_lOIl0 + 3.7) - 0.5) * 0.16 * step(_liIl0, 0.0);
_l010O *= _li0ll * (1.0 - 0.6 * max(edge, _lO1il)) * (1.0 - 0.45 * _lill0);
_lOOii *= 1.0 - 0.35 * smoothstep(-0.08, 0.0, _liIl0) * step(_liIl0, 0.0);
float _l0Il0 = (fract(_lO1iI * 13.0) - 0.5) * 0.4;
float _ll1i1 = _l1O0O(vec2(_l1ll0, c - _l0Il0), float(b) * 5.0 + _lIOiO, _liO0O) * step(_liIl0, -0.02) * step(0.25, _lO1iI);
vec3 _l01li = fract(_lO1iI * 31.0) < 0.6 ? _l1IIO : _lIIIO;
_liIii += _l01li * _ll1i1 * 0.9 * _llOIO;
if (fract(_lO1iI * 19.0) < 0.35) {
float _ll1l0 = _l1ll0 - 0.35;
float _lI1l0 = step(abs(fract(_ll1l0 / 0.06) - 0.5), 0.22) * step(abs(c + _l0Il0 * 0.5), 0.2) * step(0.0, _ll1l0)
* step(_ll1l0, 0.42);
_l010O *= 1.0 - 0.75 * _lI1l0 * _ll11O(0.03, _liO0O);
}
_lI00O = 0.25;
_lOOiI = 0.5;
}
}
} else if (id < 8) {
float _l11l0 = (id == 4 || id == 5) ? 1.0 : -1.0;
float _li1l0 = (id == 4 || id == 6) ? 1.0 : -1.0;
float _lO1l0 = dot(q.xy, vec2(_l11l0, -_li1l0)) * 0.70710678 / h;
float _l01li = max(0.022, _liO0O * 0.7);
float _l01l0 = exp(-sqr(_lO1l0 / _l01li)) * (0.022 / _l01li) * 1.6 + exp(-abs(_lO1l0) / 0.07) * 0.1;
float _ll011 = _l0I1O(abs(abs(_lO1l0) - 0.2), 0.012, max(_liO0O, 0.01)) * _ll11O(0.03, _liO0O);
_liIii += _ll00O * _l01l0;
_l010O *= 1.0 - 0.6 * _ll011;
_lI00O = 0.8;
_lOOiI = 0.32;
} else if (base > 0) {
_liIii += hc * 0.25 * _llOIO;
}
}
bool _llil0(_liIIO h, vec3 rd, vec3 _llIOI, float _li111, inout vec3 n, out vec3 _l010O, out vec3 _liIii, out float _lOOiI,
out float _lI00O, out float _lOOii, out float _llIIl, out vec3 u, inout _lIO0O _lO00O, out vec3 _lIil0) {
int b = int(h.id + 0.5);
int i, _liOil;
vec3 a, _lIIiO, _l1IiO;
float _lll0I, _lIl01, _lO1iI;
_llIiO(b, i, _liOil, a, u, _lIIiO, _l1IiO, _lll0I, _lIl01, _lO1iI);
_lll0I = max(_lll0I, 1e-5);
vec3 q = h._lO1Il.xyz;
int plane = int(h._lO1Il.w + 0.5);
float g = (_lO1iI - _lIl01) / _lll0I;
float _l1il0 = max(_lIl01 + g * q.z, 1e-6);
float s = saturate(q.z / _lll0I);
_llIIl = _lO01O(i, _liOil, s, h.p);
vec3 _ll00O = _l0i0O(b, s, _llIIl, _lll0I);
_l010O = vec3(0.0);
_liIii = vec3(0.0);
_lOOiI = 0.4;
_lI00O = 0.0;
_lOOii = 1.0;
_lIil0 = vec3(0.0);
if (h._l0Iii == ENG_M_CONDUIT) {
float _l0OiI = saturate(dot(n, -rd));
_lIil0 = _ll00O * (0.35 + 0.6 * _l0OiI) + _llIIO * _l0OiI * _l0OiI * _l0OiI * _l0OiI * 1.2 * _llOIO;
return true;
}
if (h._l0Iii == ENG_M_INNER) {
_lIil0 = vec3(0.002) + _ll00O * 0.05 * exp(-length(q.xy) / _l1il0 * 1.5) + _llIOI * 0.003;
return true;
}
float _ll1iO = _lOIiO(i, _liOil, _lll0I);
float _liil0 = plane >= 20 ? _lO1iI * _lOlIO : plane >= 10 ? _lIl01 * _lOlIO : _l1il0;
float _l100O;
vec2 _li00O;
_l0O0O(b, q, plane, _liil0, _lll0I, _ll1iO, _lIl01 + g * _lll0I * 0.5, _li111, _llIIl, _ll00O, _l010O, _liIii, _lOOiI, _lI00O, _lOOii, _l100O, _li00O, _lO00O);
int _lliOI = plane - (plane >= 20 ? 20 : plane >= 10 ? 10 : 0);
if (_lliOI < 4) n = normalize(n + (_lliOI < 2 ? _l1IiO : _lIIiO) * (_l100O * 0.9 + _li00O.x) + u * _li00O.y);
_liIii += _ll00O * (1.0 - _ll1IO) * 1.4;
_llIIl += 0.25;
return false;
}
void _lOil0(_liIIO h, float _li111, inout vec3 n, out vec3 _l010O, out vec3 _liIii, out float _lOOiI, out float _llIIl,
inout _lIO0O _lO00O) {
int i = int(h.id + 0.5);
float _lOi0l = max(_l1lIO * Eng[i].w * _ll1IO, 1e-6);
vec3 q = (h.p - Eng[i].xyz) / _lOi0l;
int _lIll1 = int(h._lO1Il.w + 0.5);
_llIIl = mix(_l101O(i), _li01O(h.p), _liOIO);
vec3 hc = prism7(_llIIl);
_l010O = vec3(0.075, 0.077, 0.086);
_lOOiI = 0.42;
_liIii = hc * (1.0 - _ll1IO) * 2.0;
float _lO0Il = _li111 / _lOi0l;
if (_lIll1 < 3) {
vec2 uv = (_lIll1 == 0 ? q.yz : _lIll1 == 1 ? q.xz : q.xy) / 0.75;
_lO0Il /= 0.75;
vec2 _l0il0 = abs(uv);
float sq = max(_l0il0.x, _l0il0.y);
float _llOl0 = 1.0 - smoothstep(0.3 - _lO0Il, 0.3 + _lO0Il, sq);
float _lIOl0 = _l0I1O(abs(sq - 0.3), 0.012, _lO0Il * 0.7) + _l0I1O(abs(sq - 0.23), 0.008, _lO0Il * 0.7) * 0.6
+ _l0I1O(abs(sq - 0.16), 0.006, _lO0Il * 0.7) * 0.4;
float _llOi1 = 1.0 - smoothstep(0.15, 0.16 + _lO0Il, sq);
float _l1Ol0 = _l0I1O(abs(sq - 0.38), 0.01, _lO0Il * 0.7) * step(0.3, min(_l0il0.x, _l0il0.y));
vec2 _liOl0 = floor((uv + 1.0) * 2.0);
vec2 _l0lIl = fract((uv + 1.0) * 2.0) - 0.5;
float _l01Il = hash12(_liOl0 + float(i) * 3.3 + float(_lIll1) * 11.0);
vec2 _lOOl0 = _l01Il < 0.4 ? vec2(fract(_l0lIl.x * 2.0 + 0.5) - 0.5, _l0lIl.y) : _l0lIl;
float _l0lI1 = _l0I1O(0.5 - max(abs(_lOOl0.x), abs(_lOOl0.y)), 0.025, _lO0Il * 2.0) * _ll11O(0.02 * _lOi0l, _li111) * (1.0 - _llOl0);
float _li0ll = 0.75 + 0.5 * hash12(_liOl0 * 1.7 + float(i) + float(_lIll1) * 5.0 + step(0.0, _l0lIl.x) * step(_l01Il, 0.4));
_l010O *= _li0ll * (1.0 - 0.6 * _l0lI1) * (1.0 - 0.95 * _llOl0);
_lOOiI = 0.32 + 0.25 * _l01Il;
vec2 _l0Ol0 = smoothstep(0.86, 1.0, _l0il0) * sign(uv) * 0.9 + (hash22(_liOl0 * 2.3 + float(i) + float(_lIll1) * 7.0) - 0.5) * 0.14 * (1.0 - _llOl0);
n = normalize(n + (_lIll1 == 0 ? vec3(0.0, _l0Ol0.x, _l0Ol0.y) : _lIll1 == 1 ? vec3(_l0Ol0.x, 0.0, _l0Ol0.y) : vec3(_l0Ol0.x, _l0Ol0.y, 0.0)));
float _ll0l0 = step(abs(_l0lIl.y + 0.28), 0.03) * step(abs(_l0lIl.x), 0.4) * step(0.42, sq) * step(0.55, _l01Il);
float _lI0l0 = _ll0l0 * step(hash12(vec2(floor(_l0lIl.x * 16.0), _liOl0.x * 7.0 + _liOl0.y + float(i))), 0.6);
_liIii += mix(_l1IIO, _lIIIO, step(0.8, _l01Il)) * mix(_ll0l0 * 0.33, _lI0l0, _ll11O(0.025 * _lOi0l, _li111)) * 0.8 * _llOIO;
float _l10l0 = step(abs(fract(_l0lIl.x * 7.0) - 0.5), 0.2) * step(abs(_l0lIl.y), 0.3) * step(abs(_l0lIl.x), 0.38)
* step(0.42, sq) * step(_l01Il, 0.18);
_l010O *= 1.0 - 0.8 * _l10l0 * _ll11O(0.02 * _lOi0l, _li111);
_liIii += hc * (_lIOl0 * 1.1 + _l1Ol0 * 0.5) * _llOIO;
_liIii += mix(hc, _llIIO, 0.5) * _llOi1 * (0.35 + 1.2 * _l01IO) * _llOIO;
_lO00O.uv = uv;
_lO00O.at = vec2(-0.82, 0.66);
_lO00O._ll01O = 0.2;
_lO00O._lI01O = ivec4(i & 1, (i >> 1) & 1, (i >> 2) & 1, (i >> 3) & 1);
_lO00O.count = 4;
_lO00O.aa = _lO0Il * 0.7;
_lO00O._lilOi = _ll11O(0.05 * _lOi0l, _li111);
} else if (_lIll1 < 9) {
vec3 ax = _lOIOO(_lIll1);
vec3 along = ax.x == 0.0 ? vec3(1.0, 0.0, 0.0) : ax.y == 0.0 ? vec3(0.0, 1.0, 0.0) : vec3(0.0, 0.0, 1.0);
float _lO1l0 = dot(q, normalize(cross(along, ax)));
float _l01li = max(0.012, _lO0Il * 0.7);
_liIii += hc * (exp(-sqr(_lO1l0 / _l01li)) * (0.012 / _l01li) * 1.4 + exp(-abs(_lO1l0) / 0.05) * 0.06) * _llOIO;
_l010O *= 0.85 * (1.0 - 0.6 * _l0I1O(abs(abs(_lO1l0) - 0.12), 0.006, _lO0Il * 0.6) * _ll11O(0.02 * _lOi0l, _li111));
} else {
vec3 _li0l0 = normalize(_lOIOO(_lIll1));
float _lOil1 = length(q - _li0l0 * dot(q, _li0l0));
float _ll01i = fract(_l0IIO * 0.45 + float(i) * 0.37 + float(_lIll1) * 0.11);
float _lOl0i = exp(-sqr((_ll01i - 0.05) / 0.02)) + exp(-sqr((_ll01i - 0.13) / 0.02));
_liIii += mix(hc, _llIIO, 0.5) * exp(-sqr(_lOil1 / max(0.06, _lO0Il * 0.8))) * (0.4 + 5.0 * _lOl0i) * _llOIO;
_l010O *= 0.7;
}
_llIIl += 0.4;
}
void _lO0l0(_liIIO h, float _li111, out vec3 _l010O, out vec3 _liIii, out float _llIIl) {
int _l00l0 = int(h.id + 0.5);
_llIIl = mix(_l101O(_l00l0), _li01O(h.p), _liOIO);
vec3 hc = prism7(_llIIl);
float _lI0iI = max(h._lO1Il.w, 1e-6);
vec2 _lllI0 = h._lO1Il.xy / _lI0iI;
float _lIlI0 = _li111 / _lI0iI;
vec3 _ll0II = _lIO1O(_lllI0, 0.1);
float _l0lI1 = _l0I1O(_ll0II.x, 0.006, _lIlI0 * 0.6) * _ll11O(0.015 * _lI0iI, _li111);
float _lOll0 = min(length(vec2((fract(_lllI0.x / 0.07) - 0.5) * 0.07, _lllI0.y - 0.08)),
length(vec2(_lllI0.x - 0.08, (fract(_lllI0.y / 0.07) - 0.5) * 0.07)));
float _l0ll0 = _l0I1O(_lOll0, 0.01, _lIlI0 * 0.6) * _ll11O(0.02 * _lI0iI, _li111);
_l010O = vec3(0.07, 0.072, 0.08) * (0.8 + 0.35 * vnoise2(_lllI0 * 6.0 + h.id)) * (1.0 - 0.5 * _l0lI1) + vec3(0.06) * _l0ll0;
vec2 _l1lI0 = _lllI0 - 0.3;
float _l00OO = max(max(abs(_l1lI0.x), abs(_l1lI0.y)), abs(_l1lI0.x + _l1lI0.y) * 0.75);
_liIii = hc * (_l0I1O(h._lO1Il.z / _lI0iI, 0.015, _lIlI0) * 0.9 + _l0I1O(abs(_l00OO - 0.1), 0.008, _lIlI0) * 0.5) * _llOIO
+ hc * (1.0 - _ll1IO) * 2.0;
_llIIl += 0.3;
}
vec3 _lilI0(_liIIO h, vec3 rd, vec3 _l0l1O, vec3 _llIOI) {
vec3 n = h.n;
vec3 v = -rd;
float _l0OiI = saturate(dot(n, v));
float x = 1.0 - _l0OiI;
float _l0I11 = x * x * x;
float _l10ll = atan(n.z, n.x);
vec3 _lIOII = prism7(_l10ll / TAU + n.y * 0.35 + _l1iIO * 3.0 + _l0IIO * 0.12);
vec3 held = mix(vec3(0.85, 0.9, 1.0), _l0iIO.rgb, saturate(_l0iIO.w));
float _li1l1 = asin(clamp(n.y, -1.0, 1.0));
float _l0Oil = _l10ll - _l0IIO * 0.7 + _li1l1 * 2.2;
vec2 _lIiiO = vec2(_l0Oil * 3.0, _li1l1 * 3.5);
vec2 sq = fract(_lIiiO) - 0.5;
float hs = hash12(floor(_lIiiO) + 7.0);
float _lOlI0 = step(0.45, hs) * exp(-dot(sq, sq) / 0.012) * (0.55 + 0.45 * sin(_l0IIO * 3.0 + hs * 40.0));
float _l0lI0 = 0.5 + 0.5 * sin(_l0Oil * 2.0 + _li1l1 * 3.0);
vec3 col = vec3(0.003) + _lIOII * _l0I11 * 2.4 * _lI0IO;
col += held * (_lOlI0 * 1.4 + _l0lI0 * _l0lI0 * 0.08) * _l0OiI * saturate(_l0iIO.w * 0.6) * _lI0IO;
col += _llIOI * _lI11O(n, v, _l0l1O, 0.08) * 0.4;
col += _llO1O(reflect(rd, n), _l0l1O, _llIOI) * (0.04 + 0.6 * _l0I11);
return col;
}
vec3 _llII0(_liIIO h, vec3 ro, vec3 rd, vec3 _l0l1O, vec3 _llIOI, float _lOi01) {
_lil1O();
float _li111 = _lOi01 * max(h.t, 1e-4);
if (h._l0Iii == ENG_M_CORE) return _lilI0(h, rd, _l0l1O, _llIOI);
vec3 n = h.n;
vec3 _l010O = vec3(0.07);
vec3 _liIii = vec3(0.0);
float _lOOiI = 0.45;
float _lI00O = 0.0;
float _lOOii = 1.0;
float _llIIl = 0.0;
vec3 u = vec3(0.0, 1.0, 0.0);
_lIO0O _lO00O;
_lO00O.uv = vec2(0.0);
_lO00O.at = vec2(0.0);
_lO00O._ll01O = 1.0;
_lO00O._lI01O = ivec4(0);
_lO00O.count = 1;
_lO00O.aa = 0.01;
_lO00O._lilOi = 0.0;
if (h._l0Iii == ENG_M_NODE) {
_lOil0(h, _li111, n, _l010O, _liIii, _lOOiI, _llIIl, _lO00O);
} else if (h._l0Iii == ENG_M_GUSSET) {
_lO0l0(h, _li111, _l010O, _liIii, _llIIl);
} else {
vec3 _lIil0;
if (_llil0(h, rd, _llIOI, _li111, n, _l010O, _liIii, _lOOiI, _lI00O, _lOOii, _llIIl, u, _lO00O, _lIil0)) return _lIil0;
}
if (_lO00O._lilOi > 0.001) {
float _lIII0 = _l0O1O(_lO00O.uv, _lO00O.at, _lO00O._ll01O, _lO00O._lI01O, _lO00O.count, _lO00O.aa) * _lO00O._lilOi;
_liIii += _lIIIO * _lIII0 * 0.8 * _llOIO;
_l010O *= 1.0 - 0.5 * _lIII0;
}
if (_lO1IO > 0.001) {
float _lI1i1 = h.p.y - _li1IO;
float w = max(0.004, _li111 * 1.2);
_liIii += _lIIIO * _lO1IO * (exp(-sqr(_lI1i1 / w)) * 5.0 + (_lI1i1 > 0.0 ? exp(-_lI1i1 / 0.15) * 0.15 : 0.0));
}
_liIii += prism7(_llIIl) * _l01IO * 0.2;
vec3 col = _lO10O(h.p, n, -rd, _l0l1O, _llIOI, _l010O, _lOOiI, _llIIl, u, _lI00O) * _lOOii + _liIii;
return mix(col, _lll1O, _lOI1O(h.t));
}
int _l1II0(int _liII0) {
return _liII0 == 1 ? 975
: _liII0 == 2 ? 19007
: _liII0 == 3 ? 243
: _liII0 == 4 ? 18495
: _liII0 == 5 ? 499
: _liII0 == 6 ? 451
: _liII0 == 7 ? 763
: _liII0 == 8 ? 972
: _liII0 == 9 ? 18483
: _liII0 == 10 ? 124
: _liII0 == 11 ? 37312
: _liII0 == 12 ? 240
: _liII0 == 13 ? 5324
: _liII0 == 14 ? 33996
: _liII0 == 15 ? 255
: _liII0 == 16 ? 967
: _liII0 == 17 ? 33023
: _liII0 == 18 ? 33735
: _liII0 == 19 ? 955
: _liII0 == 20 ? 18435
: _liII0 == 21 ? 252
: _liII0 == 22 ? 12480
: _liII0 == 23 ? 41164
: _liII0 == 24 ? 46080
: _liII0 == 25 ? 21504
: _liII0 == 26 ? 12339
: _liII0 == 27 ? 12543
: _liII0 == 28 ? 12
: _liII0 == 29 ? 887
: _liII0 == 30 ? 575
: _liII0 == 31 ? 908
: _liII0 == 32 ? 955
: _liII0 == 33 ? 1019
: _liII0 == 34 ? 15
: _liII0 == 35 ? 1023
: _liII0 == 36 ? 959
: _liII0 == 37 ? 65536
: 0;
}
float _lOII0(vec2 p, int _l00II) {
float d = 1e3;
if ((_l00II & 1) != 0) d = min(d, sdSegment2(p, vec2(0.1, 1.9), vec2(0.48, 1.9)));
if ((_l00II & 2) != 0) d = min(d, sdSegment2(p, vec2(0.52, 1.9), vec2(0.9, 1.9)));
if ((_l00II & 4) != 0) d = min(d, sdSegment2(p, vec2(0.9, 1.88), vec2(0.9, 1.04)));
if ((_l00II & 8) != 0) d = min(d, sdSegment2(p, vec2(0.9, 0.96), vec2(0.9, 0.12)));
if ((_l00II & 16) != 0) d = min(d, sdSegment2(p, vec2(0.52, 0.1), vec2(0.9, 0.1)));
if ((_l00II & 32) != 0) d = min(d, sdSegment2(p, vec2(0.1, 0.1), vec2(0.48, 0.1)));
if ((_l00II & 64) != 0) d = min(d, sdSegment2(p, vec2(0.1, 0.96), vec2(0.1, 0.12)));
if ((_l00II & 128) != 0) d = min(d, sdSegment2(p, vec2(0.1, 1.88), vec2(0.1, 1.04)));
if ((_l00II & 256) != 0) d = min(d, sdSegment2(p, vec2(0.12, 1.0), vec2(0.48, 1.0)));
if ((_l00II & 512) != 0) d = min(d, sdSegment2(p, vec2(0.52, 1.0), vec2(0.88, 1.0)));
if ((_l00II & 1024) != 0) d = min(d, sdSegment2(p, vec2(0.16, 1.82), vec2(0.46, 1.08)));
if ((_l00II & 2048) != 0) d = min(d, sdSegment2(p, vec2(0.5, 1.88), vec2(0.5, 1.04)));
if ((_l00II & 4096) != 0) d = min(d, sdSegment2(p, vec2(0.84, 1.82), vec2(0.54, 1.08)));
if ((_l00II & 8192) != 0) d = min(d, sdSegment2(p, vec2(0.46, 0.92), vec2(0.16, 0.18)));
if ((_l00II & 16384) != 0) d = min(d, sdSegment2(p, vec2(0.5, 0.96), vec2(0.5, 0.12)));
if ((_l00II & 32768) != 0) d = min(d, sdSegment2(p, vec2(0.54, 0.92), vec2(0.84, 0.18)));
if ((_l00II & 65536) != 0) d = min(d, sdSegment2(p, vec2(0.45, 0.1), vec2(0.55, 0.1)));
return d;
}
int _l0II0(int i) {
return i == 0 ? 84412163
: i == 1 ? 85770580
: i == 2 ? 21717
: i == 3 ? 19138317
: i == 4 ? 460195712
: i == 5 ? 11
: i == 6 ? 235145027
: i == 7 ? 320151636
: i == 8 ? 0
: i == 9 ? 8541965
: i == 10 ? 503324745
: i == 11 ? 2995937
: i == 12 ? 201590659
: i == 13 ? 302260548
: i == 14 ? 897
: i == 15 ? 153356299
: i == 16 ? 462544905
: i == 17 ? 731
: i == 18 ? 302254019
: i == 19 ? 357127427
: i == 20 ? 19
: i == 21 ? 8541963
: i == 22 ? 520131145
: i == 23 ? 2995934
: i == 24 ? 255854595
: i == 25 ? 321200204
: i == 26 ? 0
: i == 27 ? 35915910
: i == 28 ? 460175424
: i == 29 ? 11
: i == 30 ? 155977795
: i == 31 ? 5067346
: i == 32 ? 1
: i == 33 ? 5768961
: i == 34 ? 191740196
: i == 35 ? 0
: i == 36 ? 89655427
: i == 37 ? 71
: i == 38 ? 0
: i == 39 ? 5768897
: i == 40 ? 191740004
: i == 41 ? 0
: i == 42 ? 155715779
: i == 43 ? 49479
: i == 44 ? 0
: i == 45 ? 19138754
: i == 46 ? 460445440
: 731;
}
float _ll1I0(vec2 uv, vec2 at, float _ll01O, int k, int line, float aa) {
vec2 p = (uv - at) / (_ll01O * 0.5);
float _lI1I0 = 1.3;
if (p.y < -0.2 || p.y > 2.2 || p.x < -0.2 || p.x > _lI1I0 * 15.0) return 0.0;
float _l1Iil = clamp(floor(p.x / _lI1I0), 0.0, 14.0);
int i = int(_l1Iil);
int w = i / 5;
int _liII0 = (_l0II0(k * 6 + line * 3 + w) >> (6 * (i - w * 5))) & 63;
if (_liII0 == 0) return 0.0;
float d = _lOII0(vec2(p.x - _l1Iil * _lI1I0, p.y), _l1II0(_liII0));
float a = aa / (_ll01O * 0.5);
return smoothstep(0.1 + a, 0.1 - a, d);
}
float _l11I0(vec2 uv, int k, float aa) {
vec2 _l0il0 = abs(uv);
float sq = 1.12;
if (_l0il0.x > 2.1 || uv.y > 1.5 || uv.y < -2.1) return 0.0;
float d = min(sdSegment2(_l0il0, vec2(sq, sq), vec2(sq - 0.26, sq)), sdSegment2(_l0il0, vec2(sq, sq), vec2(sq, sq - 0.26)));
float v = _l0I1O(d, 0.012, aa) * step(_l0il0.x, 1.2) * step(_l0il0.y, 1.2);
float _li1I0 = abs(fract(uv.x * 5.0) - 0.5) / 5.0;
v += _l0I1O(_li1I0, 0.006, aa) * _l0I1O(abs(_l0il0.y - sq), 0.03, aa) * step(_l0il0.x, sq - 0.36) * 0.5;
v += _ll1I0(uv, vec2(-1.12, -1.5), 0.2, k, 0, aa);
v += _ll1I0(uv, vec2(-1.12, -1.8), 0.13, k, 1, aa) * 0.8;
float _lO1I0 = _l1O1O((uv.x - 0.55) / 0.022, float(k) * 3.1) * step(0.55, uv.x) * step(uv.x, 1.12)
* step(-1.86, uv.y) * step(uv.y, -1.76);
v += _lO1I0 * 0.6 * _ll11O(0.022, aa);
return saturate(v) * _ll11O(0.02, aa);
}
vec3 _l01I0(int k) {
return k == 7 ? vec3(0.85, 0.9, 1.0) : prism7(float(k) / 7.0);
}
vec3 _lliI0(int c, vec3 ro, vec3 rd, float _li1iI, float _lOi01, float far, inout float _lIO0I) {
vec4 A = Eng[16 + 3 * c];
vec4 _l10iO = Eng[17 + 3 * c];
vec4 _li0iO = Eng[18 + 3 * c];
float R = A.w;
float br = _li0iO.w;
if (R <= 1e-4 || br <= 1e-3) return vec3(0.0);
vec3 _llili = _lIliO(c);
int k = int(_llili.x + 0.5);
float _liO1l = R * _llili.z;
vec3 oc = ro - A.xyz;
float bb = dot(oc, rd);
float cc = dot(oc, oc) - sqr(R * 1.5 + _liO1l);
if (cc > 0.0 && (bb > 0.0 || bb * bb < cc)) return vec3(0.0);
vec3 _lIiI0 = _l001O(_llili.y);
float _l1iI0 = br * (0.9 + 0.1 * sin(_l0IIO * (0.9 + 0.11 * float(k)) + float(k) * 1.7));
vec3 _lIlIl = _l10iO.xyz;
vec3 _l1lIl = _li0iO.xyz;
vec3 col = vec3(0.0);
float _liiI0 = k == 0 ? 1.0 / 0.9 - 1.0 : 0.0;
vec3 _lOiI0 = oc + _l1lIl * (dot(oc, _l1lIl) * _liiI0);
vec3 _liI0I = rd + _l1lIl * (dot(rd, _l1lIl) * _liiI0);
float _l0l0O = dot(_liI0I, _liI0I);
float _llI0O = dot(_lOiI0, _liI0I);
float _llIOi = _llI0O * _llI0O - _l0l0O * (dot(_lOiI0, _lOiI0) - _liO1l * _liO1l);
float tp = -bb;
bool _l0iI0 = false;
if (_llIOi > 0.0) {
float _llO1I = (-_llI0O - sqrt(_llIOi)) / _l0l0O;
if (_llO1I > 0.0 && _llO1I < _li1iI) {
vec3 n = normalize(_lOiI0 + _liI0I * _llO1I);
vec3 _l1O0I;
if (far > 0.5) {
float _liIl1 = max(dot(n, -rd), 0.0);
_l1O0I = _lIiI0 * (0.3 + 1.1 * sqrt(_liIl1)) * (0.75 + 0.5 * vnoise3(n * 7.0 + float(k) * 3.1)) * 60.0;
} else {
_l1O0I = _lilli(n, rd, _lIiI0, float(k) * 7.3);
}
col += _l1O0I * 0.016 * _l1iI0;
_lIO0I = 1.0;
_l0iI0 = true;
}
}
if (tp > 0.0 && tp < _li1iI + _liO1l) {
vec3 off = oc + rd * tp;
float d = length(off);
float _l1lll = _lOi01 * tp;
float ar = max(_liO1l, _l1lll * 1.5);
float _lI0l0 = 1.0 - smoothstep(R * 1.05, R * 1.45, d);
float _ll101 = exp(-(d - ar) / (min(ar, R * 0.12) * 1.2)) * step(ar, d) * _lI0l0;
float bloom = ar * ar / (d * d + ar * ar) * exp(-d / (R * 0.5)) * _lI0l0;
vec3 _lO1il = normalize(-oc);
vec3 ax = normalize(cross(_lO1il, abs(_lO1il.y) < 0.95 ? vec3(0.0, 1.0, 0.0) : vec3(1.0, 0.0, 0.0)));
float x = dot(off, ax);
float y = dot(off, cross(ax, _lO1il));
float pts = min(ar / _l1lll, 30.0) * 0.02;
float _l0lII = exp(-abs(y) / (_l1lll * 1.6)) * exp(-abs(x) / (R * 0.5)) * pts;
if (far > 0.5) _l0lII += exp(-abs(x) / (_l1lll * 1.6)) * exp(-abs(y) / (R * 0.5)) * pts;
_l0lII *= _lI0l0;
float _l0iiI = max(_liO1l, _l1lll * 1.1);
float point = _l0iI0 ? 0.0 : exp(-d * d / (_l0iiI * _l0iiI)) * 3.0 * (1.0 - smoothstep(1.0, 3.0, _liO1l / _l1lll));
col += (_lIiI0 * (_ll101 * 0.22 + bloom * 0.12 + point) + mix(_lIiI0, _llIIO, 0.3) * _l0lII * 1.2) * _l1iI0;
col += _lIiI0 * _l1iI0 * exp(-sqr(d / (R * 0.8))) * 0.03 * _lI0l0;
_lIO0I = max(_lIO0I, exp(-d * d / (_l0iiI * _l0iiI)) * min(_l1iI0, 1.0));
if (k == 5) {
float an = _l0IIO * 0.35;
vec3 _llOI0 = oc + (_lIlIl * cos(an) + cross(_lIlIl, _l1lIl) * sin(an)) * (R * 0.24);
float tq = -dot(_llOI0, rd);
float _lIOI0 = length(_llOI0 + rd * tq);
float _lIOil = max(R * 0.012, _lOi01 * max(tq, 1e-4) * 1.1);
if (tq > 0.0 && tq < _li1iI) col += vec3(0.75, 0.85, 1.0) * (exp(-_lIOI0 * _lIOI0 / (_lIOil * _lIOil)) * 3.0 + _lIOil / (_lIOI0 + _lIOil) * 0.05) * _l1iI0;
}
}
if (far < 0.5) {
vec3 _lIiIl = normalize(cross(_lIlIl, _l1lIl));
float _lIOOO = dot(rd, _lIiIl);
if (abs(_lIOOO) > 1e-5) {
float t = -dot(oc, _lIiIl) / _lIOOO;
if (t > 0.0 && t < _li1iI) {
float _l0I11 = max(R * 0.42, _liO1l * 1.08);
vec3 q = oc + rd * t;
vec2 uv = vec2(dot(q, _lIlIl), dot(q, _l1lIl)) / _l0I11;
float _l1OI0 = _l11I0(uv, k, _lOi01 * t / _l0I11 / max(abs(_lIOOO), 0.15));
col += mix(_l01I0(k), _lIIIO, 0.35) * _l1OI0 * (0.5 + 0.6 * min(br, 2.5)) * 1.2 * _llOIO;
}
}
}
return col;
}
vec3 _liOI0(vec3 ro, vec3 rd, float _li1iI, float _lOi01, float far, inout float _lIO0I) {
vec3 col = vec3(0.0);
int _l110O = 8 + _lOIIO;
for (int c = 0; c < _l110O; c++) col += _lliI0(c, ro, rd, _li1iI, _lOi01, far, _lIO0I);
return col;
}
vec3 _lOOI0(int i) {
float x = (i & 1) == 0 ? -1.0 : 1.0;
float y = (i & 2) == 0 ? -1.0 : 1.0;
float z = (i & 4) == 0 ? -1.0 : 1.0;
float w = (i & 8) == 0 ? -1.0 : 1.0;
float _l0OI0 = x * _l10IO.x - w * _li0IO.x;
float _lI0il = x * _li0IO.x + w * _l10IO.x;
float _ll0i1 = y * _l10IO.y - _lI0il * _li0IO.y;
float _ll0I0 = y * _li0IO.y + _lI0il * _l10IO.y;
float _l1IOi = z * _l10IO.z - _ll0I0 * _li0IO.z;
float _lI0I0 = z * _li0IO.z + _ll0I0 * _l10IO.z;
float k = 3.2 / (3.2 - _lI0I0) * 1.1;
vec3 p = vec3(_l0OI0, _ll0i1, _l1IOi) * k;
p = vec3(p.x * _l10IO.w - p.z * _li0IO.w, p.y, p.x * _li0IO.w + p.z * _l10IO.w);
return p * _l0OIO + _lOOIO;
}
vec3 _l10I0(vec3 ro, vec3 rd, float _li1iI, float _lOi01) {
vec3 col = vec3(0.0);
vec3 held = mix(vec3(0.82, 0.88, 1.0), _l0iIO.rgb, saturate(_l0iIO.w * 0.5));
float tp;
float d = rayPointDist(ro, rd, _lOOIO, tp);
if (tp < _li1iI) {
float rr = max(_ll0IO, 0.02);
float x = max(d - rr, 0.0);
col += held * _lI0IO * (exp(-x / (rr * 0.35)) * 0.35 + exp(-x / (rr * 2.5)) * 0.05)
* (1.0 + 0.4 * _l0iIO.w);
}
float _lli1i = _l0OIO * 2.9 + 0.03;
vec2 _l0I0O = raySphere(ro, rd, _lOOIO, _lli1i);
if (_l0I0O.y <= 0.0 || _l0I0O.x > _li1iI) return col;
float _l1iIl = min(_lI0IO, 2.0) * (0.6 + 0.4 * _llOIO) * (1.0 + 0.4 * _liOIO);
int _li0I0 = 32 + _lOIIO;
for (int e = 0; e < _li0I0; e++) {
int i, _liOil, k;
_l0liO(e, i, _liOil, k);
vec3 a = _lOOI0(i);
vec3 b = _lOOI0(_liOil);
float tRay;
float dd = raySegmentDist(ro, rd, a, b, tRay);
if (tRay <= 0.0 || tRay > _li1iI) continue;
vec3 ba = b - a;
float s = saturate(dot(ro + rd * tRay - a, ba) / max(dot(ba, ba), 1e-8));
float w = max(_lOi01 * tRay * 0.8, 0.0022 * _l0OIO / 0.062);
vec3 hc = prism7(mix(_l101O(i), _l101O(_liOil), s));
col += mix(hc, _llIIO, 0.3) * (exp(-sqr(dd / w)) * 1.6 + exp(-dd / (w * 3.0)) * 0.06) * _l1iIl;
}
return col;
}
vec3 _lO0I0(vec3 ro, vec3 rd, float _li1iI, float _lOi01, float detail) {
vec3 col = vec3(0.0);
int _l00I0 = 24 + _lOIIO;
for (int f = 0; f < _l00I0; f++) {
int _l11OO, _l11lO, _li1lO;
_lI1OO(f, _l11OO, _l11lO, _li1lO);
int _l0i1I = _l11lO | _li1lO;
int r0 = (_l0i1I & 1) == 0 ? 0 : (_l0i1I & 2) == 0 ? 1 : 2;
int r1 = (_l0i1I & 8) == 0 ? 3 : (_l0i1I & 4) == 0 ? 2 : 1;
int _l1Ill = 2 * r0 + ((_l11OO >> r0) & 1);
int _liliI = 2 * r1 + ((_l11OO >> r1) & 1);
float _lll10 = Eng[18 + 3 * _l1Ill].w;
float _lIl10 = Eng[18 + 3 * _liliI].w;
float _lIl1I = max(_lll10 - 1.0, 0.0) + max(_lIl10 - 1.0, 0.0);
vec3 _l1l10 = (_l1liO(_l1Ill) * min(_lll10, 1.0) + _l1liO(_liliI) * min(_lIl10, 1.0)) * 0.5;
float base = _liiIO * 0.4 * detail;
float _l0IOl = _liiIO * 2.5 * _lIl1I + _lIOIO * 3.0 + _l1OIO * 1.5;
if (base + _l0IOl <= 0.002) continue;
vec4 d;
float _l01OO;
int _l1lOI;
vec3 n;
float t = _lO1OO(f, ro, rd, _li1iI, d, _l01OO, _l1lOI, n);
if (t < 0.0 || _l01OO > 0.0) continue;
float _ll0ii = min(min(d.x, d.y), min(d.z, d.w));
float _lOO11 = _lIlIO * 0.8 * _ll1IO;
if (_ll0ii <= _lOO11) continue;
float _li111 = _lOi01 * t;
float _llIli = abs(dot(rd, n));
float x = 1.0 - _llIli;
float _l0i0l = x * x * x * x;
vec3 _lIlIl = normalize(Eng[_l11OO | _l11lO].xyz - Eng[_l11OO].xyz);
vec3 _l1lIl = cross(n, _lIlIl);
vec3 q = ro + rd * t - Eng[_l11OO].xyz;
vec2 pp = vec2(dot(q, _lIlIl), dot(q, _l1lIl));
float _llIIl = (_l101O(_l11OO) + _l101O(_l11OO | _l11lO | _li1lO)) * 0.5 + 0.8 * x + _ll0ii * 2.0;
vec3 _lIi0O = prism7(_llIIl);
vec3 _ll0II = _lIO1O(pp, 0.045);
float _lil10 = _ll11O(0.006, _li111 / max(_llIli, 0.2));
float _li0I1 = _l0I1O(_ll0II.x, 0.0018, _li111 * 0.8) * _lil10;
float _lOl10 = exp(-(_ll0ii - _lOO11) / 0.025);
col += (_lIi0O * (_l0i0l * 0.012 + _lOl10 * 0.012) + _l1l10 * (0.002 + _lOl10 * 0.01)) * base;
col += mix(_lIi0O, _l1l10, 0.5) * (_li0I1 * 0.12 + _lOl10 * 0.08 + (1.0 - _lil10) * 0.006) * _l0IOl;
}
return col * (1.0 - _lOI1O(length(ro) - 1.0));
}
vec3 _l0l10(vec3 ro, vec3 rd, float _li1iI, float _lOi01) {
vec3 col = vec3(0.0);
if (_ll1IO <= 0.01) return col;
int _lIl0O = 16 + _lOIIO;
for (int i = 0; i < _lIl0O; i++) {
vec3 c = Eng[i].xyz;
float _lOi0l = _l1lIO * Eng[i].w * _ll1IO;
vec3 _lO0ii = c * (1.0 + _lOi0l * 2.1 * inversesqrt(dot(c, c) + 1e-8));
vec3 o = _lO0ii - ro;
float tp = dot(o, rd);
if (tp > _li1iI || tp <= 0.0) continue;
float d = length(o - rd * tp);
float w = max(_lOi01 * tp * 1.2, _lOi0l * 0.06);
if (d > w * 8.0) continue;
float _ll01i = fract(_l0IIO * 0.45 + float(i) * 0.37);
float _lOl0i = exp(-sqr((_ll01i - 0.05) / 0.025)) + exp(-sqr((_ll01i - 0.14) / 0.025));
vec3 hc = mix(prism7(_l101O(i)), _llIIO, 0.55);
col += hc * (exp(-sqr(d / w)) * (0.3 + 6.0 * _lOl0i) + exp(-d / (w * 2.5)) * 0.2 * _lOl0i) * _llOIO;
}
return col;
}
vec3 _llI10(vec3 ro, vec3 rd, float _li1iI, float _lOi01) {
vec3 col = vec3(0.0);
int _l110O = 8 + _lOIIO;
for (int c = 0; c < _l110O; c++) {
vec4 A = Eng[16 + 3 * c];
float br = Eng[18 + 3 * c].w;
if (A.w <= 0.0 || br <= 0.0) continue;
vec3 a = A.xyz;
vec3 b = _lOOIO;
float tRay;
float d = raySegmentDist(ro, rd, a, b, tRay);
if (tRay <= 0.0 || tRay > _li1iI) continue;
float w = max(_lOi01 * tRay * 0.7, 0.0018);
if (d > w * 8.0) continue;
vec3 ba = b - a;
float _liI0l = max(length(ba), 1e-4);
float s = saturate(dot(ro + rd * tRay - a, ba) / (_liI0l * _liI0l));
float _lIIlI = fract(s * _liI0l / 0.09 - _lIiIO * 3.0);
float _liOII = step(_lIIlI, 0.55);
float _lII10 = exp(-sqr((fract(s * _liI0l / 0.45 - _lIiIO * 1.2 + float(c) * 0.3) - 0.5) / 0.05));
float _l110l = smoothstep(0.0, 0.15, s) * smoothstep(1.0, 0.85, s);
float _l11ii = 1.0 + 3.0 * _liOIO;
col += mix(_l1liO(c), _llIIO, 0.3) * exp(-sqr(d / w)) * (0.05 * _liOII + 1.0 * _lII10) * _l110l * min(br, 2.0)
* _l11ii * _llOIO;
}
return col;
}
vec3 _l1I10(vec3 ro, vec3 rd, float _li1iI, float _lOi01) {
if (_lO1IO <= 0.001 || abs(rd.y) < 1e-5) return vec3(0.0);
float t = (_li1IO - ro.y) / rd.y;
if (t <= 0.0 || t >= _li1iI) return vec3(0.0);
vec3 q = ro + rd * t;
float e = max(abs(q.x), abs(q.z));
if (e > 1.15) return vec3(0.0);
float _li111 = _lOi01 * t / max(abs(rd.y), 0.15);
float inside = 1.0 - smoothstep(1.0 - _li111, 1.0 + _li111, e);
float _l0O11 = _l0I1O(abs(e - 1.0), 0.004, _li111);
float lines = _l0I1O(abs(fract(q.z * 24.0) - 0.5) / 24.0, 0.0012, _li111) * _ll11O(0.01, _li111);
float grid = _l0I1O(abs(fract(q.x * 6.0) - 0.5) / 6.0, 0.0015, _li111) * _ll11O(0.03, _li111);
float below = _li1IO < -1.0 ? exp((_li1IO + 1.0) * 1.2) : 1.0;
return _lIIIO * _lO1IO * below * (inside * (0.03 + lines * 0.22 + grid * 0.12) + _l0O11 * 1.4);
}
vec3 _liI10(vec3 ro, vec3 rd, float _li1iI, float _lOi01) {
vec3 col = vec3(0.0);
if (_lOiIO <= 0.001) return col;
int _l0OO1 = 32 + _lOIIO;
for (int b = 0; b < _l0OO1; b++) {
int i, _liOil, k;
_l0liO(b, i, _liOil, k);
vec3 a = Eng[i].xyz;
vec3 e = Eng[_liOil].xyz;
vec3 ba = e - a;
float _lOI10 = dot(ba, ba);
if (_lOI10 < 1e-8) continue;
float tRay;
float d = raySegmentDist(ro, rd, a, e, tRay);
if (tRay <= 0.0 || tRay > _li1iI) continue;
float w = max(_lOi01 * tRay * 1.1, 0.0045);
if (d > w * 10.0) continue;
float s = saturate(dot(ro + rd * tRay - a, ba) / _lOI10);
float _llIIl = _lO01O(i, _liOil, s, a + ba * s);
vec3 hc = prism7(_llIIl);
float _lIIlI = fract(s * 3.0 - _l0IIO * 0.9 + float(b) * 0.29);
float _lil11 = exp(-sqr((_lIIlI - 0.5) / 0.03));
col += (mix(hc, _llIIO, 0.3 + 0.5 * _lil11) * exp(-sqr(d / w)) * (2.0 + 2.5 * _lil11)
+ hc * exp(-d / (w * 8.0)) * 0.3) * _lOiIO;
}
return col;
}
vec3 _l0I10(vec3 ro, vec3 rd, float _li1iI, float _lOi01) {
_lil1O();
ro = _liliO(ro, rd);
vec2 _l0I0O = raySphere(ro, rd, vec3(0.0), _l11IO + 0.3);
if (_l0I0O.y <= 0.0 || _l0I0O.x > _li1iI) return vec3(0.0);
float _lIO0I = 0.0;
vec3 col = _liOI0(ro, rd, _li1iI, _lOi01, 0.0, _lIO0I);
col += _l10I0(ro, rd, _li1iI, _lOi01);
col += _lO0I0(ro, rd, _li1iI, _lOi01, 1.0);
col += _l0l10(ro, rd, _li1iI, _lOi01);
col += _llI10(ro, rd, _li1iI, _lOi01);
col += _l1I10(ro, rd, _li1iI, _lOi01);
col += _liI10(ro, rd, _li1iI, _lOi01);
return col;
}
vec3 _ll110(vec3 n, vec3 v, vec3 _l0l1O, vec3 _llIOI, float _l010O, float _llIIl) {
float _l0OiI = saturate(dot(n, v));
float x = 1.0 - _l0OiI;
vec3 _lIi0O = _l011O(_l0OiI, _llIIl);
vec3 _l111O = normalize(_l0l1O + v);
float sp = pow(max(dot(n, _l111O), 0.0), 40.0) * max(dot(n, _l0l1O), 0.0) * 3.0;
vec3 col = vec3(_l010O) * _llIOI * (max((dot(n, _l0l1O) + 0.2) / 1.2, 0.0) + 0.06);
col += _lIi0O * _llIOI * (sp * (0.06 + 0.5 * x * x * x * x * x) + x * x * x * saturate(dot(-v, _l0l1O)) * 0.35);
col += _lIi0O * (_llIOI * 0.025 + _lll1O * 0.25 * saturate(reflect(-v, n).y + 0.5)) * (0.06 + 0.5 * x * x * x);
col += vec3(_l010O) * _lll1O * 0.5 * (0.55 + 0.45 * n.y);
return col;
}
vec4 _lI110(vec3 ro, vec3 rd, float _li1iI, float _lOi01) {
_lil1O();
vec2 _l0I0O = raySphere(ro, rd, vec3(0.0), _l11IO + 0.3);
if (_l0I0O.y <= 0.0 || _l0I0O.x > _li1iI) return vec4(0.0);
vec3 _l0l1O = _lO0IO;
vec3 _llIOI = _l00IO;
vec3 v = -rd;
_liIIO hs;
hs.t = -1.0;
hs.n = vec3(0.0, 1.0, 0.0);
hs.p = vec3(0.0);
hs._l0Iii = 0.0;
hs.id = 0.0;
hs._lO1Il = vec4(0.0);
float _l1110 = _li1iI;
if (_ll1IO > 0.001) {
int _lIl0O = 16 + _lOIIO;
for (int i = 0; i < _lIl0O; i++) _l0IOO(i, ro, rd, _l1110, hs);
_lll0O(ro, rd, _l1110, hs);
}
vec3 _li110 = vec3(0.0);
float _lO110 = 0.0;
if (hs.t > 0.0) {
int _l00l0 = int(hs.id + 0.5);
float _llIIl = mix(_l101O(_l00l0), _li01O(hs.p), _liOIO);
vec3 hc = prism7(_llIIl);
vec3 _liIii = vec3(0.0);
float _l1lll = _lOi01 * hs.t;
if (hs._l0Iii == ENG_M_NODE) {
float _lOi0l = max(_l1lIO * Eng[_l00l0].w * _ll1IO, 1e-6);
vec3 _lOI11 = abs((hs.p - Eng[_l00l0].xyz) / _lOi0l);
int _lIll1 = int(hs._lO1Il.w + 0.5);
float sq = _lIll1 == 0 ? max(_lOI11.y, _lOI11.z) : _lIll1 == 1 ? max(_lOI11.x, _lOI11.z) : max(_lOI11.x, _lOI11.y);
float _lliOI = _lIll1 < 3 ? 1.0 : 0.0;
float _lOO0O = _lIll1 > 8 ? 1.0 : 0.0;
_liIii += hc * (1.0 - smoothstep(0.22, 0.24 + _l1lll / _lOi0l, sq)) * _lliOI * (0.4 + _l01IO);
_liIii += hc * (1.0 - _lliOI) * (1.0 - _lOO0O) * 0.25 + mix(hc, _llIIO, 0.5) * _lOO0O * 0.4;
} else {
_liIii += hc * _l0I1O(hs._lO1Il.z / max(hs._lO1Il.w, 1e-6), 0.02, _l1lll / max(hs._lO1Il.w, 1e-6)) * 0.8;
}
_li110 = _ll110(hs.n, v, _l0l1O, _llIOI, 0.075, _llIIl + 0.35) + _liIii * _llOIO + hc * (1.0 - _ll1IO) * 2.0;
_li110 = mix(_li110, _lll1O, _lOI1O(hs.t));
_lO110 = 1.0;
}
if (_ll0IO > 1e-4) {
vec2 _l0110 = raySphere(ro, rd, _lOOIO, _ll0IO);
if (_l0110.x > 0.0 && _l0110.x < _l1110) {
_l1110 = _l0110.x;
vec3 _l110O = normalize(ro + rd * _l0110.x - _lOOIO);
float x = 1.0 - saturate(dot(_l110O, v));
_li110 = vec3(0.003) + prism7(atan(_l110O.z, _l110O.x) / TAU + _l1iIO * 3.0 + _l0IIO * 0.12) * x * x * x * 2.4 * _lI0IO;
_lO110 = 1.0;
}
}
float t1 = 1e30;
float _l1i1O = 1e30;
vec3 c1 = vec3(0.0);
vec3 _llil1 = vec3(0.0);
float a1 = 0.0;
float _l0Oil = 0.0;
if (_ll1IO > 0.001) {
int _l0OO1 = 32 + _lOIIO;
for (int b = 0; b < _l0OO1; b++) {
int i, _liOil, k;
_l0liO(b, i, _liOil, k);
vec3 A = Eng[i].xyz;
vec3 u = Eng[_liOil].xyz - A;
float _lll0I = length(u);
if (_lll0I < 1e-4) continue;
u /= _lll0I;
float _lIl01 = _lIlIO * Eng[i].w * _ll1IO;
float _lO1iI = _lIlIO * Eng[_liOil].w * _ll1IO;
vec3 oa = ro - A;
float bard = dot(u, rd);
float _lIOOO = 1.0 - bard * bard;
float s = _lIOOO > 1e-9 ? saturate((dot(u, oa) - bard * dot(rd, oa)) / _lIOOO / _lll0I) : 0.0;
vec3 _liOiO = A + u * (s * _lll0I);
float _lli10 = dot(_liOiO - ro, rd);
if (_lli10 <= 0.0 || _lli10 > _l1110 || _lli10 > _l1i1O) continue;
vec3 off = ro + rd * _lli10 - _liOiO;
float dd = length(off);
float _ll1iO = _lOIiO(i, _liOil, _lll0I);
float z = s * _lll0I;
float _lIi10 = z < _ll1iO || z > _lll0I - _ll1iO ? 1.0 : 0.0;
float h = _lIi10 > 0.5 ? (z < _ll1iO ? _lIl01 : _lO1iI) * _lOlIO : _lIl01 + (_lO1iI - _lIl01) * s;
float _l1lll = _lOi01 * _lli10;
float _l1i10 = saturate((h * 1.12 - dd) / _l1lll + 0.5);
if (_l1i10 <= 0.0) continue;
vec3 _lIIiO = Eng[i ^ (1 << (k == 0 ? 1 : k == 1 ? 2 : k == 2 ? 0 : 1))].xyz - A;
_lIIiO -= u * dot(_lIIiO, u);
float _lii10 = length(_lIIiO);
_lIIiO = _lii10 > 1e-5 ? _lIIiO / _lii10 : normalize(cross(u, vec3(0.31, 0.83, 0.47)));
vec3 _l1IiO = cross(u, _lIIiO);
vec3 _lll1i = v - u * dot(v, u);
float _lOi10 = length(_lll1i);
_lll1i = _lOi10 > 1e-5 ? _lll1i / _lOi10 : _lIIiO;
vec3 _lO00O = cross(u, _lll1i);
float _l0i10 = dot(off, _lO00O);
float _l01iO = dot(_lll1i, _lIIiO) >= 0.0 ? 1.0 : -1.0;
float _lliiO = dot(_lll1i, _l1IiO) >= 0.0 ? 1.0 : -1.0;
float _llO10 = dot(_lIIiO, _lO00O);
float _lIO10 = dot(_l1IiO, _lO00O);
float _lO1l0 = h * (_l01iO * _llO10 + _lliiO * _lIO10);
bool _l1O10 = (_l0i10 - _lO1l0) * (-_lliiO * _lIO10) > 0.0;
vec3 _lIiIl = _l1O10 ? _lIIiO * _l01iO : _l1IiO * _lliiO;
float _liO10 = _l1O10 ? _lIO10 : _llO10;
float across = (_l0i10 - h * (_l1O10 ? _l01iO * _llO10 : _lliiO * _lIO10)) / (abs(_liO10) > 1e-3 ? _liO10 : 1e-3) / h;
float _lI1I0 = max(h * 0.06, _l1lll * 0.7);
float _l01l0 = exp(-sqr((_l0i10 - _lO1l0) / _lI1I0)) + exp(-sqr((abs(_l0i10) - h * 1.12 + _lI1I0) / _lI1I0));
float _llIIl = _lO01O(i, _liOil, s, _liOiO);
vec3 hc = prism7(_llIIl);
vec3 _ll00O = _l0i0O(b, s, _llIIl, _lll0I);
vec3 _liIii = _ll00O * _l01l0 * (h * 0.06 / _lI1I0) * 0.9;
float _l010O = 0.075;
if (_lIi10 > 0.5) {
float zz = z < _ll1iO ? z : _lll0I - z;
_liIii += hc * _l0I1O(abs(zz / max(_ll1iO, 1e-6) - 0.82), 0.02, _l1lll / max(_ll1iO, 1e-6)) * 0.45;
_l010O = 0.085;
} else {
float _lI1OI, _lIll1;
_l0IiO(_lll0I, _ll1iO, _lIl01 + (_lO1iI - _lIl01) * 0.5, _lI1OI, _lIll1);
float _llOiO = (z - _ll1iO) / _lIll1;
float _lIOiO = clamp(floor(_llOiO), 0.0, _lI1OI - 1.0);
float _l1OiO = _llOiO - _lIOiO;
float _l000O = abs(across);
if (_lI1iO(b, _lIOiO, _lI1OI) > 0.5) {
float _lillI = sdSegment2(vec2(_l1OiO * _lIll1 / h, across * (mod(_lIOiO, 2.0) < 0.5 ? 1.0 : -1.0)), vec2(0.0, -0.44),
vec2(_lIll1 / h, 0.44));
float _lI0Ii = min(_l1OiO, 1.0 - _l1OiO) * _lIll1 / h;
float _lIl1l = smoothstep(0.0, _l1lll / h + 0.02, min(min(0.46 - _l000O, _lillI - 0.1), _lI0Ii - 0.1));
_l1i10 *= 1.0 - 0.9 * _lIl1l * _ll11O(0.25 * h, _l1lll);
_liIii += _ll00O * 0.04 * _lIl1l;
} else {
float _lOO10 = hash12(vec2(float(b) * 3.7, _lIOiO * 1.3));
float row = (fract(_lOO10 * 13.0) - 0.5) * 0.4;
float _ll1i1 = _l1O0O(vec2(_l1OiO * _lIll1 / h, across - row), float(b) * 5.0 + _lIOiO, _l1lll / h) * step(0.25, _lOO10)
* step(_l000O, 0.38);
_liIii += (fract(_lOO10 * 31.0) < 0.6 ? _l1IIO : _lIIIO) * _ll1i1 * 0.9;
_l010O *= 0.8 + 0.4 * hash12(vec2(_lIOiO, float(b)));
}
}
vec3 col = _ll110(_lIiIl, v, _l0l1O, _llIOI, _l010O, _llIIl + 0.25) + _liIii * _llOIO;
col += _ll00O * (1.0 - _ll1IO) * 1.4;
if (_lO1IO > 0.001) col += _lIIIO * _lO1IO * exp(-sqr((_liOiO.y - _li1IO) / max(0.004, _l1lll))) * 4.0;
col = mix(col, _lll1O, _lOI1O(_lli10));
if (_lli10 < t1) {
_l1i1O = t1;
_llil1 = c1;
_l0Oil = a1;
t1 = _lli10;
c1 = col;
a1 = _l1i10;
} else {
_l1i1O = _lli10;
_llil1 = col;
_l0Oil = _l1i10;
}
}
}
vec3 rgb = c1 * a1 + (1.0 - a1) * (_llil1 * _l0Oil + (1.0 - _l0Oil) * _li110 * _lO110);
float _l0O10 = a1 + (1.0 - a1) * (_l0Oil + (1.0 - _l0Oil) * _lO110);
float _ll010 = a1 > 0.5 ? t1 : _l0Oil > 0.5 ? min(_l1i1O, _l1110) : _l1110;
float _lIO0I = 0.0;
vec3 _lI010 = _liOI0(ro, rd, _ll010, _lOi01, 1.0, _lIO0I);
_lI010 += _l10I0(ro, rd, _ll010, _lOi01);
_lI010 += _l0l10(ro, rd, _ll010, _lOi01);
_lI010 += _liI10(ro, rd, _ll010, _lOi01);
_lI010 *= 1.0 - _lOI1O(length(ro) - 1.0) * 0.6;
rgb += _lI010 * (1.0 - _l0O10 * 0.85);
_l0O10 = _l0O10 + (1.0 - _l0O10) * _lIO0I * 0.6;
return vec4(rgb, saturate(_l0O10));
}