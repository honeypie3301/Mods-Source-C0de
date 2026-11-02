uniform vec4 City;
const int _lO0OlI = 40;
const int _l00OlI = 36;
const int _lll0lI = 40;
const int _lIl0lI = 3;
const int _l1l0lI = 14;
const int _lil0lI = 12;
const int _lOl0lI = 14;
const int _l0l0lI = 2;
const int _llI0lI = 55;
const int _lII0lI = 22;
const int _l1I0lI = 60;
const int _liI0lI = 585;
const int _lOI0lI = 53;
const int _l0I0lI = -1000000;
uint _ll10lI() {
return (uint(City.x) << 16u) | uint(City.y);
}
uint _lI10lI(uint x) {
x ^= x >> 16u;
x *= 0x7feb352du;
x ^= x >> 15u;
x *= 0x846ca68bu;
x ^= x >> 16u;
return x;
}
uint _l110lI(uint h) {
return _lI10lI(h + 0x9e3779b9u);
}
int _li10lI(uint h, int n) {
return int(h % uint(n));
}
uint _lO10lI(ivec3 c, uint _l010lI) {
return _lI10lI(uint(c.x) * 0x8da6b343u + uint(c.y) * 0xd8163841u + uint(c.z) * 0xcb1ab31fu + _ll10lI()
+ _l010lI * 0x2545f491u);
}
int _lli0lI(int a, int b) {
return a >= 0 ? a / b : -1 - (-1 - a) / b;
}
int _lIi0lI(uint h) {
int k = _li10lI(h, 100);
return k < 85 ? 0 : (k < 97 ? 1 : 2);
}
int _l1i0lI() {
return max(int(City.w) - int(City.z), 0);
}
int _lii0lI() {
return int(City.z) + _l1i0lI() * _liI0lI / 1000;
}
int _lOi0lI() {
return max(4, _l1i0lI() * _lOI0lI / 1000);
}
int _l0i0lI() {
return max(1, _lOi0lI() * 3 / 10);
}
int _llO0lI(ivec2 c) {
int _liOil = _l0i0lI();
return _lii0lI() - _lOi0lI() + _li10lI(_lO10lI(ivec3(c.x, 0, c.y), 3u), 2 * _liOil + 1) - _liOil;
}
int _lIO0lI(ivec2 c) {
int _liOil = _l0i0lI();
return _lii0lI() + _lOi0lI() + _li10lI(_l110lI(_lO10lI(ivec3(c.x, 0, c.y), 3u)), 2 * _liOil + 1) - _liOil;
}
int _l1O0lI(ivec2 c, int y) {
int f = _llO0lI(c);
if (y < f) {
return -1 - (f - 1 - y) / _l00OlI;
}
int _liO0lI = _lIO0lI(c);
return y >= _liO0lI ? (y - _liO0lI) / _l00OlI : _l0I0lI;
}
bool _lOO0lI(inout ivec3 lo, inout ivec3 hi) {
lo.y = max(lo.y, int(City.z));
hi.y = min(hi.y, int(City.w) + 1);
return lo.y < hi.y;
}
bool _l0O0lI(ivec3 c, out ivec3 lo, out ivec3 hi, out int _ll00lI) {
lo = ivec3(0);
hi = ivec3(0);
_ll00lI = 0;
bool _lI00lI = c.y == -1 || c.y == 0;
uint h = _lO10lI(c, 1u);
if (!_lI00lI && _li10lI(h, 100) >= _llI0lI) {
return false;
}
uint r1 = _l110lI(h);
uint r2 = _l110lI(r1);
uint _l0OO0 = _l110lI(r2);
uint _l100lI = _l110lI(_l0OO0);
uint _li00lI = _l110lI(_l100lI);
uint _lO00lI = _l110lI(_li00lI);
uint _l000lI = _l110lI(_lO00lI);
uint _llllII = _l110lI(_l000lI);
uint _lIllII = _l110lI(_llllII);
int kind = _li10lI(r1, 100);
int w;
int d;
int t;
if (kind < 10) {
w = 8 + _li10lI(r2, 7);
d = 8 + _li10lI(_l0OO0, 7);
t = 22 + _li10lI(_l100lI, 9);
} else if (kind < 25) {
w = 16 + _li10lI(r2, 19);
d = 16 + _li10lI(_l0OO0, 19);
t = 2 + _li10lI(_l100lI, 3);
} else {
w = 10 + _li10lI(r2, 23);
d = 10 + _li10lI(_l0OO0, 23);
t = 6 + _li10lI(_l100lI, 25);
}
lo.x = c.x * _lO0OlI + _lIl0lI + _li10lI(_li00lI, _lO0OlI - 2 * _lIl0lI - w + 1);
lo.z = c.z * _lll0lI + _lIl0lI + _li10lI(_lO00lI, _lll0lI - 2 * _lIl0lI - d + 1);
int _l1llII = c.y < 0 ? _llO0lI(c.xz) + c.y * _l00OlI : _lIO0lI(c.xz) + c.y * _l00OlI;
lo.y = _l1llII + _lIl0lI + _li10lI(_l000lI, _l00OlI - 2 * _lIl0lI - t + 1);
if (_lI00lI && _li10lI(_lIllII, 100) < _l1I0lI) {
lo.y = c.y < 0 ? _l1llII + _l00OlI - t : _l1llII;
}
hi = lo + ivec3(w, t, d);
_ll00lI = _lIi0lI(_llllII);
return _lOO0lI(lo, hi);
}
bool _lillII(ivec3 q, ivec3 lo, ivec3 hi) {
return all(greaterThanEqual(q, lo)) && all(lessThan(q, hi));
}
bool _lOllII(ivec3 lo, ivec3 hi) {
ivec2 a = ivec2(_lli0lI(lo.x - 1, _lO0OlI), _lli0lI(lo.z - 1, _lll0lI));
ivec2 b = ivec2(_lli0lI(hi.x, _lO0OlI), _lli0lI(hi.z, _lll0lI));
for (int i = 0; i < 2; i++) {
for (int k = 0; k < 2; k++) {
ivec2 c = a + ivec2(i, k);
if (c.x > b.x || c.y > b.y) {
continue;
}
if (hi.y + 1 > _llO0lI(c) && lo.y - 1 < _lIO0lI(c)) {
return true;
}
int r0 = _l1O0lI(c, lo.y - 1);
int r1 = _l1O0lI(c, hi.y);
for (int _liOil = 0; _liOil < 2; _liOil++) {
int _liiO0 = r0 + _liOil;
if (_liiO0 > r1) {
continue;
}
ivec3 _lOI10;
ivec3 _lil1lI;
int _l00Il;
if (_l0O0lI(ivec3(c.x, _liiO0, c.y), _lOI10, _lil1lI, _l00Il) && all(lessThan(lo - 1, _lil1lI)) && all(greaterThan(hi + 1, _lOI10))) {
return true;
}
}
}
}
return false;
}
bool _l0llII(ivec3 q, out ivec3 lo, out ivec3 hi, out int _ll00lI) {
ivec3 c = ivec3(_lli0lI(q.x, _l1l0lI), _lli0lI(q.y, _lil0lI), _lli0lI(q.z, _lOl0lI));
lo = ivec3(0);
hi = ivec3(0);
_ll00lI = 0;
uint h = _lO10lI(c, 2u);
if (_li10lI(h, 100) >= _lII0lI) {
return false;
}
uint r1 = _l110lI(h);
uint r2 = _l110lI(r1);
uint _l0OO0 = _l110lI(r2);
uint _l100lI = _l110lI(_l0OO0);
uint _li00lI = _l110lI(_l100lI);
uint _lO00lI = _l110lI(_li00lI);
uint _l000lI = _l110lI(_lO00lI);
int w = 2 + _li10lI(r1, 6);
int t = 2 + _li10lI(r2, 6);
int d = 2 + _li10lI(_l0OO0, 6);
lo.x = c.x * _l1l0lI + _l0l0lI + _li10lI(_l100lI, _l1l0lI - 2 * _l0l0lI - w + 1);
lo.y = c.y * _lil0lI + _l0l0lI + _li10lI(_li00lI, _lil0lI - 2 * _l0l0lI - t + 1);
lo.z = c.z * _lOl0lI + _l0l0lI + _li10lI(_lO00lI, _lOl0lI - 2 * _l0l0lI - d + 1);
hi = lo + ivec3(w, t, d);
_ll00lI = _lIi0lI(_l000lI);
if (!_lillII(q, lo, hi) || _lOllII(lo, hi)) {
return false;
}
return _lOO0lI(lo, hi) && _lillII(q, lo, hi);
}
bool _llIlII(ivec3 q, out ivec3 lo, out ivec3 hi, out int _ll00lI) {
lo = ivec3(0);
hi = ivec3(0);
_ll00lI = 0;
if (q.y < int(City.z) || q.y > int(City.w)) {
return false;
}
ivec2 c = ivec2(_lli0lI(q.x, _lO0OlI), _lli0lI(q.z, _lll0lI));
int _liiO0 = _l1O0lI(c, q.y);
if (_liiO0 != _l0I0lI && _l0O0lI(ivec3(c.x, _liiO0, c.y), lo, hi, _ll00lI) && _lillII(q, lo, hi)) {
return true;
}
return _l0llII(q, lo, hi, _ll00lI);
}
const float _lIIlII = 2.0;
const float _l1IlII = 1.0;
const float _liIlII = 0.7;
const float _lOIlII = 0.774;
vec3 _l0IlII(int i) {
return i == 0 ? vec3(1.0, 0.0, 0.0) : (i == 1 ? vec3(-1.0, 0.0, 0.0) : (i == 2 ? vec3(0.0, 0.0, 1.0)
: vec3(0.0, 0.0, -1.0)));
}
vec3 _ll1lII(vec3 rd) {
vec3 _liOl1 = vec3(0.008, 0.01, 0.045);
float _lI1lII = exp(-abs(rd.y) * 3.0);
return mix(_liOl1, vec3(0.05, 0.06, 0.26), _lI1lII * 0.55);
}
vec3 _l11lII(vec3 rd, float _li1lII) {
float _lO1lII = asin(clamp(rd.y, -1.0, 1.0));
vec3 col = vec3(0.0);
for (int i = 0; i < 4; i++) {
vec3 _lIIll = _l0IlII(i);
vec3 _l01lII = vec3(-_lIIll.z, 0.0, _lIIll.x);
float _llilII = atan(dot(rd, _l01lII), dot(rd, _lIIll));
col += _l1l1lI(vec2(_llilII, _lO1lII) * _lOIlII, _lIIlII, _li1lII + float(i) * 7.3, _l1IlII, _liIlII, 1.0, 0.0);
}
return col * mix(0.25, 1.0, exp(-abs(_lO1lII) / 0.12));
}
vec3 _lIilII(vec3 rd, float _li1lII) {
return _ll1lII(rd) + _l11lII(rd, _li1lII);
}
vec3 _l1ilII(vec3 p, vec3 size, int _ll00lI, float _li111, float y) {
vec3 _lllilI = min(p, size - p);
int axis = _lllilI.x < _lllilI.y ? (_lllilI.x < _lllilI.z ? 0 : 2) : (_lllilI.y < _lllilI.z ? 1 : 2);
vec2 across;
vec2 _l0i1I;
float up = 0.0;
if (axis == 0) {
across = vec2(_lllilI.z, _lllilI.y);
_l0i1I = vec2(size.z, size.y);
up = p.y / size.y;
} else if (axis == 1) {
across = vec2(_lllilI.x, _lllilI.z);
_l0i1I = vec2(size.x, size.z);
up = p.y < size.y * 0.5 ? 0.0 : 1.0;
} else {
across = vec2(_lllilI.x, _lllilI.y);
_l0i1I = vec2(size.x, size.y);
up = p.y / size.y;
}
float edge = min(across.x, across.y);
float _liilII = min(_l0i1I.x, _l0i1I.y);
bool top = axis == 1 && p.y > size.y * 0.5;
bool _l1llII = axis == 1 && !top;
vec3 _lOilII = vec3(0.16, 0.25, 1.0);
vec3 _l0ilII = vec3(0.22, 0.32, 1.0);
vec3 _llOlII = vec3(0.55, 0.44, 1.0);
vec3 _lIOII = vec3(0.5, 0.85, 1.0);
if (_ll00lI == 1) {
_lOilII = vec3(0.4, 0.2, 0.95);
_l0ilII = vec3(0.5, 0.28, 1.0);
_llOlII = vec3(0.72, 0.45, 1.0);
_lIOII = vec3(1.0, 0.62, 0.95);
} else if (_ll00lI == 2) {
_lOilII = vec3(0.62, 0.12, 0.32);
_l0ilII = vec3(0.7, 0.16, 0.36);
_llOlII = vec3(0.8, 0.3, 0.45);
_lIOII = vec3(1.0, 0.45, 0.55);
}
float _lilII = 0.035 + _li111 * 1.4;
float line = 1.0 - smoothstep(_lilII, _lilII + _li111 * 1.3, edge);
float halo = exp(-edge / (0.1 + _li111 * 2.0));
vec3 base = (top ? _l0ilII : (_l1llII ? _llOlII : _lOilII)) * 1.5;
base *= axis == 1 ? 1.0 : mix(0.78, 1.08, up);
float inner = exp(-edge / (0.22 * _liilII + _li111));
base *= mix(0.72, 1.0, inner);
vec3 col = base + _lIOII * (line * 2.2 + halo * 0.2);
float band = float(_lOi0lI());
float _l0iil = exp(-abs(y - float(_lii0lI())) / (band * 0.9));
col += vec3(1.0, 0.62, 0.3) * _l0iil * (axis == 1 ? 0.35 : 0.6);
col += vec3(1.0, 0.84, 0.56) * line * _l0iil * 1.2;
return col;
}
vec3 _lIOlII(vec3 c) {
return vec3(1.0) - exp(-c * 1.1);
}