#include "star.glsl"
uniform vec3 Grid;
uniform vec4 Cubes[64];
uniform vec4 P4;
float _l1000 = 256.0;
float _li000 = 32.0;
float _lO000 = 1.0;
const vec3 _llI1I = vec3(1.0, 0.98, 1.0);
float _l0000(vec3 p) {
vec3 g = p - Grid;
return (g.x + g.z) / (2.0 * _l1000) * (6.0 / 7.0) + g.y / _l1000 * 0.18 + _l100l * 0.035;
}
float _lIOI1(vec2 p, int n) {
int _l00II = n == 0 ? 63 : n == 1 ? 6 : n == 2 ? 91 : n == 3 ? 79 : n == 4 ? 102 : n == 5 ? 109 : n == 6 ? 125
: n == 7 ? 7 : n == 8 ? 127 : 111;
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
float _l1OI1(vec2 uv, vec2 at, float h, float value, int count, float aa) {
vec2 p = (uv - at) / (h * 0.5);
float _liOI1 = 1.35;
if (p.y < -0.2 || p.y > 2.2 || p.x < -0.2 || p.x > _liOI1 * float(count)) return 0.0;
float i = floor(p.x / _liOI1);
int _lOOI1 = int(mod(floor(value / pow(10.0, float(count) - 1.0 - i) + 0.001), 10.0));
return smoothstep(0.1 + aa, 0.1 - aa, _lIOI1(vec2(p.x - i * _liOI1, p.y), _lOOI1));
}
float _lllllI(vec3 rd, vec3 a, vec3 b, out float tRay, out float s) {
vec3 ba = b - a;
float baba = dot(ba, ba);
float bard = dot(ba, rd);
float baoa = dot(ba, -a);
float rdoa = dot(rd, -a);
float denom = baba - bard * bard;
s = denom > 1e-9 ? saturate((baoa - bard * rdoa) / denom) : 0.0;
vec3 q = a + ba * s;
tRay = max(dot(q, rd), 0.0);
return length(rd * tRay - q);
}
vec2 _lIlllI(vec3 rd, vec3 lo, vec3 hi) {
vec3 r = rd + vec3(equal(rd, vec3(0.0))) * 1e-6;
vec3 inv = 1.0 / r;
vec3 t0 = lo * inv;
vec3 t1 = hi * inv;
vec3 _lOi1i = min(t0, t1);
vec3 _l0i1i = max(t0, t1);
return vec2(max(max(_lOi1i.x, _lOi1i.y), _lOi1i.z), min(min(_l0i1i.x, _l0i1i.y), _l0i1i.z));
}
float _l1lllI(vec3 p, vec3 lo, vec3 hi) {
vec3 e = min(p - lo, hi - p);
float a = min(min(e.x, e.y), e.z);
float b = max(max(e.x, e.y), e.z);
return e.x + e.y + e.z - a - b;
}
vec3 _lO0O1(vec3 at, float size, float sceneT, vec3 tint) {
vec3 _l01Il = project(at);
if (_l01Il.z <= 0.0 || length(at) > sceneT + 5.0) return vec3(0.0);
vec2 dd = (texCoord - _l01Il.xy) * vec2(OutSize.x / OutSize.y, 1.0);
float _l1lll = 1.0 / OutSize.y;
float _lll0I = 0.02 + 0.2 * size;
float core = exp(-dot(dd, dd) / sqr(_l1lll * (1.5 + 4.0 * size)));
float cross = exp(-abs(dd.y) / (_l1lll * 0.8)) * exp(-abs(dd.x) / _lll0I) + exp(-abs(dd.x) / (_l1lll * 0.8)) * exp(-abs(dd.y) / _lll0I);
float halo = exp(-length(dd) / (_l1lll * (6.0 + 40.0 * size)));
return _llI1I * core * 4.0 + tint * (cross * 1.8 + halo * 0.6);
}
float _lilllI(int i) {
int n = (i & 1) + ((i >> 1) & 1) + ((i >> 2) & 1) + ((i >> 3) & 1);
return float(n) * (1.5 / 7.0) + _l100l * 0.05;
}
void main() {
initPixel(texCoord);
_l100l = P0.x;
_li00l = P0.y;
_lO000 = P3.w > 0.001 ? P3.w : 1.0;
_l1000 = P3.y > 0.5 ? P3.y : 256.0 * _lO000;
_li000 = _l1000 / 8.0;
vec3 rd = viewDir(texCoord);
vec3 _l1O0I = scenePosAt(texCoord);
bool sky = skyAt(texCoord);
float sceneT = sky ? FAR : length(_l1O0I);
vec3 glow = vec3(0.0);
float _ll00I = P0.z;
float _l0ii1 = P1.x;
float _lOlllI = P1.y;
float fold = P1.z;
float _l0lllI = P2.z;
float _llIllI = P2.x;
vec3 _lIIllI = vec3(Grid.x + _l1000 * 0.5, P3.x, Grid.z + _l1000 * 0.5);
vec3 _l1IllI = mix(Grid + vec3(_l1000 * 0.5), _lIIllI, _l0lllI);
float _liIllI = mix(_l1000 * 0.5, 13.0, _l0lllI * _l0lllI * (3.0 - 2.0 * _l0lllI));
vec3 lo = _l1IllI - _liIllI;
vec3 hi = _l1IllI + _liIllI;
vec2 _lOIllI = _lIlllI(rd, lo, hi);
bool _l0IllI = _lOIllI.y > max(_lOIllI.x, 0.0) && max(_lOIllI.x, 0.0) < sceneT;
float _ll1llI = P4.x;
float _lI1llI = P4.y;
float _l11llI = _ll1llI * (fold < 0.0 ? 1.0 : 1.0 - smoothstep(0.9, 1.4, fold));
float _li1llI = _lI1llI >= 0.0 ? exp(-_lI1llI * 3.0) : 0.0;
vec3 base = sampleScene(texCoord);
if (_l0IllI && P2.y > 0.001) {
float through = min(_lOIllI.y, sceneT) - max(_lOIllI.x, 0.0);
vec3 _l00ll = rd * (max(_lOIllI.x, 0.0) + through * 0.5);
float n = vnoise2(texCoord * vec2(OutSize.x / OutSize.y, 1.0) * 30.0 + vec2(0.0, -_l100l * 2.5));
vec2 off = (vec2(n, vnoise2(texCoord * 41.0 - _l100l * 1.7)) - 0.5) * 0.004 * P2.y * saturate(through / 60.0);
base = sampleScene(texCoord + off);
float _l0lII = pow(vnoise2(vec2(texCoord.x * OutSize.x / 9.0, _l00ll.y * 0.05 - _l100l * 1.3)), 8.0);
glow += prism7(_l0000(_l00ll) + n * 0.2) * saturate(through / _l1000) * (0.03 + 0.25 * _l0lII) * P2.y;
}
float _l01l1 = P3.z;
if (_l01l1 > 0.001) {
float _llii1 = sky ? smoothstep(-0.05, 0.55, rd.y) : 0.0;
float k = _l01l1 * (_l0IllI ? 0.8 : 0.55) * (1.0 - 0.25 * _llii1) + _l01l1 * _llii1 * 0.2;
base = mix(base, base * vec3(0.3, 0.29, 0.44) + vec3(0.004, 0.003, 0.012), k);
if (sky) {
glow += _l00Ol(rd, gPix, 0.8) * _l01l1 * _llii1;
}
}
if (fold >= 0.0 && fold < 3.0) {
vec3 _l01Il = project(_lIIllI);
if (_l01Il.z > 0.0) {
vec2 _l11ll = vec2(OutSize.x / OutSize.y, 1.0);
vec2 dd = (texCoord - _l01Il.xy) * _l11ll;
float r = length(dd);
float _l0I1l = fold * 1.1;
float _l0IlI = sin((r - _l0I1l) * 60.0) * exp(-sqr((r - _l0I1l) / 0.08)) * exp(-fold * 1.2);
vec2 off = dd / max(r, 1e-4) * _l0IlI * 0.02 / _l11ll;
base = sampleScene(texCoord + off);
glow += prism7((r - _l0I1l) * 4.0 + 0.5) * abs(_l0IlI) * 0.9;
}
}
if (_l11llI > 0.001) {
for (int k = 0; k < 12; k++) {
int axis = k / 4;
int c = k - axis * 4;
vec3 a, b;
vec2 o = vec2(float(c & 1), float((c >> 1) & 1));
if (axis == 0) { a = vec3(lo.x, mix(lo.y, hi.y, o.x), mix(lo.z, hi.z, o.y)); b = vec3(hi.x, a.y, a.z); }
else if (axis == 1) { a = vec3(mix(lo.x, hi.x, o.x), lo.y, mix(lo.z, hi.z, o.y)); b = vec3(a.x, hi.y, a.z); }
else { a = vec3(mix(lo.x, hi.x, o.x), mix(lo.y, hi.y, o.y), lo.z); b = vec3(a.x, a.y, hi.z); }
float _l1iIl = saturate(P0.w * 12.0 - float(k));
if (_l1iIl <= 0.0) continue;
float tRay, s;
float d = _lllllI(rd, a, b, tRay, s);
if (tRay <= 0.0 || tRay > sceneT + 2.0 || s > _l1iIl) continue;
float w = max(0.45 + _l0lllI * 0.4, tRay * gPix * 1.1);
vec3 at = a + (b - a) * s;
vec3 hc = prism7(_l0000(at));
float _lIIlI = fract(s * 3.0 - _l100l * 0.9 + float(k) * 0.29);
float _lil11 = exp(-sqr((_lIIlI - 0.5) / 0.03));
float _li0OI = exp(-sqr((s - _l1iIl) * 40.0)) * step(_l1iIl, 0.999);
glow += (mix(hc, _llI1I, 0.3 + 0.5 * _lil11 + 0.2 * _li1llI) * exp(-sqr(d / w)) * (2.0 + 2.5 * _lil11 + 3.0 * _l0lllI + 6.0 * _li1llI)
+ hc * exp(-d / (w * 8.0)) * 0.35 + _llI1I * _li0OI * exp(-d / (w * 3.0)) * 4.0) * _l11llI;
}
if (_l0IllI && _l0lllI < 0.5) {
for (int k = 0; k < 2; k++) {
float t = k == 0 ? _lOIllI.x : _lOIllI.y;
if (t <= 0.0 || t > sceneT) continue;
vec3 p = rd * t;
vec3 g = (p - lo) / (2.0 * _liIllI) * 8.0;
vec3 f = abs(fract(g + 0.5) - 0.5);
vec3 _lO1llI = min(p - lo, hi - p);
float _l01llI = 1e3;
if (_lO1llI.x > 0.5) _l01llI = min(_l01llI, f.x);
if (_lO1llI.y > 0.5) _l01llI = min(_l01llI, f.y);
if (_lO1llI.z > 0.5) _l01llI = min(_l01llI, f.z);
float _l1lll = gPix * t / (2.0 * _liIllI) * 8.0;
float grid = exp(-sqr(_l01llI / (_l1lll + 0.012)));
float _llillI = fract(_l100l * 0.22) * 2.0 * _liIllI + lo.y;
float _l1111 = exp(-sqr((p.y - _llillI) / 1.5)) + exp(-sqr((p.y - _llillI + 6.0) / 0.6)) * 0.5;
glow += prism7(_l0000(p)) * (grid * 0.22 + _l1111 * 0.5) * _l11llI * (1.0 - _l0lllI * 2.0) * (k == 0 ? 1.0 : 0.6);
}
}
}
if (_ll1llI > 0.001) {
float _lIillI = fold >= 0.0 ? P2.w : 1.0;
for (int i = 0; i < 16; i++) {
vec3 a = Pts[i].xyz;
float _l1illI = Pts[i].w;
for (int k = 0; k < 4; k++) {
int bit = 1 << k;
if ((i & bit) != 0) continue;
int _liOil = i | bit;
float tRay, s;
float d = _lllllI(rd, a, Pts[_liOil].xyz, tRay, s);
if (tRay <= 0.0 || tRay > sceneT + 2.0) continue;
float _liillI = mix(_l1illI, Pts[_liOil].w, s);
float _lOillI = 0.62 + 0.38 * _liillI;
float w = max(0.35 * _lOillI, tRay * gPix * 0.9);
vec3 hc = prism7(mix(_lilllI(i), _lilllI(_liOil), s));
float _lIIlI = fract(s - _l100l * 0.8 + float(i) * 0.137 + float(k) * 0.31);
float _lil11 = exp(-sqr((_lIIlI - 0.5) / 0.05));
glow += (mix(hc, _llI1I, 0.35 + 0.4 * _lil11) * exp(-sqr(d / w)) * (1.6 + 2.0 * _lil11)
+ hc * exp(-d / (w * 7.0)) * 0.3) * _lOillI * _ll1llI * _lIillI;
}
glow += _lO0O1(a, 0.12 + 0.1 * _l1illI, sceneT, prism7(_lilllI(i))) * _ll1llI * _lIillI;
}
}
vec3 g = _l1O0I - Grid;
bool _l0illI = !sky && g.x >= -2.0 && g.z >= -2.0 && g.x <= _l1000 + 2.0 && g.z <= _l1000 + 2.0 && abs(g.y) < 70.0 * max(_lO000, 0.5);
if (_l0illI) {
vec2 cell = clamp(floor(g.xz / _li000), 0.0, 7.0);
int _li0lO = int(cell.y) * 8 + int(cell.x);
vec2 _llOllI = g.xz - cell * _li000;
bool _lIOllI = Cubes[_li0lO].x >= 0.0;
float aa = gPix * sceneT / max(abs(rd.y), 0.1);
gAA = aa;
float _l1OllI = min(min(_llOllI.x, _li000 - _llOllI.x), min(_llOllI.y, _li000 - _llOllI.y));
vec3 hc = prism7(_l0000(_l1O0I));
float _lil11 = 0.6 + 0.4 * (1.0 - fract(P1.w));
if (_ll00I > 0.001 && !_lIOllI && _lOlllI < 0.0) {
float lines = line(_l1OllI, 0.28);
vec2 _liOllI = vec2(_llOllI.x < _li000 * 0.5 ? 2.0 : _li000 - 2.0, _llOllI.y < _li000 * 0.5 ? 2.0 : _li000 - 2.0);
vec2 _lIiOI = sign(vec2(_li000 * 0.5) - _liOllI);
vec2 a = (_llOllI - _liOllI) * _lIiOI;
float _l0Ili = line(min(sdSegment2(a, vec2(0.0), vec2(6.0, 0.0)), sdSegment2(a, vec2(0.0), vec2(0.0, 6.0))), 0.3);
float _lOOllI = _l1OI1(_llOllI, vec2(4.0, _li000 - 10.0), 5.0, cell.y * 10.0 + cell.x + 11.0, 2, aa / 2.5);
float _l0OllI = step(length(_llOllI - vec2(_li000 * 0.5)), 0.9);
glow += (hc * (lines * 1.6 + _l0Ili * 2.2) + mix(hc, _llI1I, 0.6) * (_lOOllI * 1.8 + _l0OllI)) * _ll00I * _lil11;
}
if (_l0ii1 >= 0.0 && (!_lIOllI || Cubes[_li0lO].x < 0.4)) {
float _l00II = abs(g.x - _l1000 * 0.5) + abs(g.z - _l1000 * 0.5);
float _l0I1l = _l0ii1 * 215.0 * _lO000;
float along = _llOllI.x < _llOllI.y ? g.z : g.x;
float _ll0llI = (vnoise2(vec2(along * 0.35, cell.x * 7.0 + cell.y)) - 0.5) * 2.4;
float _lI0llI = abs(_l1OllI - max(_ll0llI, 0.0) * 0.8);
float _lO0lO = step(_l00II, _l0I1l);
float _li0OI = exp(-sqr((_l00II - _l0I1l) / 8.0)) * step(_l0ii1, 1.6);
float _l10llI = line(_lI0llI, 0.55 + _li0OI * 0.8) * _lO0lO;
float hot = exp(-max(_l0I1l - _l00II, 0.0) / (60.0 * _lO000));
float fade = _lOlllI < 0.0 ? 1.0 : exp(-_lOlllI * 0.6);
glow += (mix(hc, _llI1I, hot * 0.7) * _l10llI * (2.2 + 3.0 * hot) + _llI1I * _li0OI * exp(-_lI0llI / 2.0) * 3.0
+ hc * exp(-_lI0llI / 4.0) * _lO0lO * 0.35) * fade;
}
if (_lOlllI >= 0.0 && _lOlllI < 1.0) {
glow += _llI1I * line(_l1OllI, 0.8) * exp(-_lOlllI * 4.0) * 5.0;
}
}
if (_lOlllI >= 0.0 && _lOlllI < 4.0) {
float _lO01I = (16.0 + _lOlllI * 140.0) * max(_lO000, 0.5);
float fade = exp(-_lOlllI * 1.1);
for (int k = 0; k < 4; k++) {
vec3 n = k < 2 ? vec3(1.0, 0.0, 0.0) : vec3(0.0, 0.0, 1.0);
vec3 at = Grid + (k == 1 ? vec3(_l1000, 0.0, 0.0) : k == 3 ? vec3(0.0, 0.0, _l1000) : vec3(0.0));
float t = rayPlane(vec3(0.0), rd, at, n);
if (t <= 0.0 || t > sceneT) continue;
vec3 p = rd * t - Grid;
float along = k < 2 ? p.z : p.x;
if (along < 0.0 || along > _l1000) continue;
float up = p.y - (_llIllI - Grid.y);
if (up < 0.0 || up > _lO01I) continue;
float _li0llI = up / _lO01I;
float _lO0llI = 0.6 + 0.4 * step(0.4, hash11(floor(along / 4.0) + float(k) * 71.0));
glow += prism7(_l0000(rd * t) + _li0llI * 0.3) * (1.0 - _li0llI) * _lO0llI * fade * 1.4
+ _llI1I * exp(-up / 3.0) * fade * 2.5;
}
}
if (_lOlllI >= 0.0) {
for (int i = 0; i < 64; i++) {
float _lIllI = Cubes[i].x;
if (_lIllI < 0.0) continue;
float _llOO0 = float(i - (i / 8) * 8);
float _lOOIi = float(i / 8);
float _l00llI = Cubes[i].w;
vec3 _lllIlI = vec3(Grid.x + _llOO0 * _li000, Cubes[i].y, Grid.z + _lOOIi * _li000 + (_li000 - _l00llI) * 0.5);
vec3 _lIlIlI = vec3(_lllIlI.x + _li000, _lllIlI.y + Cubes[i].z, _lllIlI.z + _l00llI);
float _llIIl = (_llOO0 + _lOOIi) / 14.0 * (6.0 / 7.0) + _l100l * 0.035;
vec3 hc = prism7(_llIIl);
float _l1lIlI = exp(-_lIllI * 1.6);
if (_lIllI < 4.0) {
float ring = floor(max(abs(_llOO0 - 3.5), abs(_lOOIi - 3.5)));
float _lilIlI = max(_llIllI - (4.0 - ring) * P4.z, min(_llIllI, P4.w));
vec3 _lOlIlI = vec3(Grid.x + _llOO0 * _li000, _lilIlI, Grid.z + _lOOIi * _li000);
vec3 _li001 = vec3(_lOlIlI.x + _li000, _lllIlI.y, _lOlIlI.z + _li000);
vec2 pt = _lIlllI(rd, _lOlIlI, _li001);
if (pt.y > max(pt.x, 0.0) && max(pt.x, 0.0) < sceneT) {
float through = min(pt.y, sceneT) - max(pt.x, 0.0);
vec3 p = rd * max(pt.x, 0.0);
float e = _l1lllI(p, _lOlIlI, _li001);
float w = max(0.5, max(pt.x, 0.0) * gPix * 1.2);
float _li0llI = saturate((p.y - _lilIlI) / max(_lllIlI.y - _lilIlI, 1.0));
glow += (prism7(_llIIl + _li0llI * 0.4) * saturate(through / _li000) * 0.12 + mix(hc, _llI1I, 0.5) * exp(-sqr(e / w)) * 1.6
* step(0.0, pt.x)) * exp(-_lIllI * 1.3);
}
}
vec2 _l0lIlI = _lIlllI(rd, _lllIlI - 0.3, _lIlIlI + 0.3);
if (_l0lIlI.y > max(_l0lIlI.x, 0.0) && _l0lIlI.x > 0.0 && _l0lIlI.x < sceneT + 1.5) {
vec3 p = rd * _l0lIlI.x;
float e = _l1lllI(p, _lllIlI - 0.3, _lIlIlI + 0.3);
float w = max(0.35, _l0lIlI.x * gPix * 1.1);
float _lIl1I = exp(-_lIllI * 9.0);
glow += (mix(hc, _llI1I, 0.3 + 0.6 * _l1lIlI) * exp(-sqr(e / w)) * (1.2 + 5.0 * _l1lIlI) * max(P2.w, _l1lIlI)
+ hc * exp(-e / (w * 6.0)) * 0.25 * _l1lIlI) + _llI1I * _lIl1I * 1.5 * step(_l0lIlI.x, sceneT + 1.0);
}
}
}
if (_lI1llI >= 0.0 && _lI1llI < 3.0 && !sky) {
vec3 _l00ll = Grid + vec3(_l1000 * 0.5, 0.0, _l1000 * 0.5);
float _l0iI1 = length(_l1O0I.xz - _l00ll.xz);
float _l0I1l = _lI1llI * 420.0 * max(_lO000, 0.5);
float f = exp(-_lI1llI * 1.3);
float band = (_l0I1l - _l0iI1) / 90.0;
if (band > 0.0 && band < 1.0) {
glow += prism7(band * (6.0 / 7.0) + 0.1) * (1.0 - band) * 1.8 * f;
}
glow += _llI1I * exp(-sqr((_l0iI1 - _l0I1l) / 4.0)) * 3.5 * f;
}
if (fold >= 0.0 && fold < 8.0) {
float f = exp(-fold * 0.9);
glow += _lO0O1(_lIIllI, 1.0 + 2.0 * exp(-fold * 3.0), sceneT, prism7(_l100l * 0.5)) * f * 2.0;
float _l0I1l = fold * 190.0;
if (!sky) {
float _l0iI1 = length(_l1O0I.xz - _lIIllI.xz);
float band = (_l0I1l - _l0iI1) / 70.0;
if (band > 0.0 && band < 1.0) {
glow += prism7(band * (6.0 / 7.0)) * (1.0 - band) * 2.4 * f;
}
glow += _llI1I * exp(-sqr((_l0iI1 - _l0I1l) / 3.0)) * 3.0 * f;
}
float tp;
float _l0OiO = rayPointDist(vec3(0.0), rd, _lIIllI, tp);
if (tp < sceneT) {
float band = (_l0I1l - _l0OiO) / 50.0;
if (band > 0.0 && band < 1.0) {
glow += prism7(band * (6.0 / 7.0)) * (1.0 - band) * 0.9 * f;
}
}
}
fragColor = vec4(tonemap(base + glow), 1.0);
}