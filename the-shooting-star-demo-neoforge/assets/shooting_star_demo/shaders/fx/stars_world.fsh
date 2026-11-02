#include "star.glsl"
const vec3 _lOO0i = vec3(0.62, 0.48, 1.0);
const vec3 _l0O0i = vec3(0.86, 0.8, 1.0);
const vec3 _llI1I = vec3(0.97, 0.95, 1.0);
int _lO1lO(int k) { return k == 0 ? 0 : k == 1 ? 1 : k == 2 ? 2 : k == 3 ? 3 : k == 4 ? 3 : k == 5 ? 4 : 5; }
int _l01lO(int k) { return k == 0 ? 1 : k == 1 ? 2 : k == 2 ? 3 : k == 3 ? 0 : k == 4 ? 4 : k == 5 ? 5 : 6; }
float _liiI1(vec2 p, float r) {
const vec3 k = vec3(-0.866025404, 0.5, 0.577350269);
p = abs(p);
p -= 2.0 * min(dot(k.xy, p), 0.0) * k.xy;
p -= vec2(clamp(p.x, -k.z * r, k.z * r), r);
return abs(length(p) * sign(p.y));
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
float _llilO(int i) {
return i == 0 ? 123.0 : i == 1 ? 79.0 : i == 2 ? 83.0 : i == 3 ? 81.0 : i == 4 ? 83.0 : i == 5 ? 83.0 : 104.0;
}
vec3 _lO0O1(vec3 at, float size, float sceneT, vec3 tint) {
vec3 _l01Il = project(at);
if (_l01Il.z <= 0.0 || length(at) > sceneT + 5.0) return vec3(0.0);
vec2 dd = (texCoord - _l01Il.xy) * vec2(OutSize.x / OutSize.y, 1.0);
float _l1lll = 1.0 / OutSize.y;
float _li1i1 = 0.8 + 0.2 * sin(_l100l * 47.0 + size * 13.0);
float _lll0I = (0.02 + 0.22 * size) * _li1i1;
float core = exp(-dot(dd, dd) / sqr(_l1lll * (1.5 + 4.0 * size)));
float cross = exp(-abs(dd.y) / (_l1lll * 0.8)) * exp(-abs(dd.x) / _lll0I) + exp(-abs(dd.x) / (_l1lll * 0.8)) * exp(-abs(dd.y) / _lll0I);
vec2 _lO1i1 = mat2(0.7071, 0.7071, -0.7071, 0.7071) * dd;
float _l01i1 = exp(-abs(_lO1i1.y) / (_l1lll * 0.6)) * exp(-abs(_lO1i1.x) / (_lll0I * 0.3)) + exp(-abs(_lO1i1.x) / (_l1lll * 0.6)) * exp(-abs(_lO1i1.y) / (_lll0I * 0.3));
float halo = exp(-length(dd) / (_l1lll * (6.0 + 40.0 * size)));
return _llI1I * core * 5.0 + tint * (cross * 2.2 + _l01i1 * 0.9 + halo * 0.7);
}
void main() {
initPixel(texCoord);
_l100l = P0.x;
_li00l = P0.y;
vec3 rd = viewDir(texCoord);
vec3 _l1O0I = scenePosAt(texCoord);
bool sky = skyAt(texCoord);
float sceneT = sky ? FAR : length(_l1O0I);
vec3 base = sampleScene(texCoord);
vec3 glow = vec3(0.0);
float _lIilO = P1.z;
float _l1ilO = P1.x;
float _liilO = P1.y;
float _lOilO = P2.w;
float _lIOi1 = gPix * sceneT / max(abs(rd.y), 0.08);
gAA = _lIOi1;
if (sky && P0.w > 0.001) {
float _llii1 = smoothstep(0.05, 0.75, rd.y);
float _liOl1 = P0.w * _llii1;
base = mix(base, base * 0.06 + vec3(0.012, 0.01, 0.03), _liOl1 * 0.94);
glow += _l00Ol(rd, gPix, 0.9) * _liOl1;
}
for (int i = 0; i < 7; i++) {
vec3 _l0ilO = Pts[i].xyz;
float _lIllI = Pts[i].w;
float R = Pts[7 + i].x;
float _lOili = Pts[7 + i].z;
float _llOlO = Pts[7 + i].w;
vec3 _lIOlO = _l0ilO + vec3(0.0, _lIilO, 0.0);
if (_lOili < 0.001 && _lIllI < 0.0 && _llOlO > 0.001) {
glow += _lO0O1(_lIOlO, 0.08 + 0.12 * _llOlO, sceneT, _lOO0i) * _llOlO * 0.8;
}
if (_lOili > 0.001 && _lIllI < 0.0) {
float h = 12.0 * _lOilO + (_lIilO - 12.0 * _lOilO) * pow(max(1.0 - _lOili, 0.0), 0.75);
vec3 _li0OI = _l0ilO + vec3(0.0, h, 0.0);
float tRay;
float d = raySegmentDist(vec3(0.0), rd, _li0OI, _lIOlO, tRay);
if (tRay < sceneT) {
vec3 at = rd * tRay;
float up = saturate((at.y - _li0OI.y) / max(_lIilO - h, 1.0));
float w = max(0.4 * _lOilO + h * 0.003, tRay * gPix * 0.8);
glow += (mix(_llI1I, _lOO0i, saturate(up * 3.0)) * exp(-d / w) * 2.2 + _lOO0i * exp(-d / (w * 8.0 + 2.0)) * 0.4)
* exp(-up * 1.5);
}
for (int r = 0; r < 3; r++) {
float _lI1i1 = h * (0.02 + float(r) * 0.035) + float(r) * 2.0 * _lOilO;
float tp = (_li0OI.y + _lI1i1) / rd.y;
if (abs(rd.y) < 1e-4 || tp <= 0.0 || tp > sceneT) continue;
vec3 q = rd * tp;
float rr = length(q.xz - _l0ilO.xz);
glow += vec3(0.9, 0.9, 1.0) * exp(-sqr((rr - _lI1i1 * 0.32) / max(0.3 * _lOilO + _lI1i1 * 0.02, tp * gPix))) * (0.8 - float(r) * 0.2)
* smoothstep(0.3, 0.8, _lOili);
}
glow += _lO0O1(_li0OI, 0.3 + 0.7 * _lOili, sceneT, _l0O0i) * (0.5 + _lOili);
if (!sky) {
float _l0iI1 = length(_l1O0I.xz - _l0ilO.xz);
base += base * _l0O0i * _lOili * _lOili * 1.6 * exp(-_l0iI1 / (R * 2.5));
}
}
if (_lIllI >= 0.0) {
float _li0l1;
float _lOil1 = rayPointDist(vec3(0.0), rd, _l0ilO + vec3(0.0, 3.0 * _lOilO, 0.0), _li0l1);
glow += _llI1I * exp(-_lOil1 / ((4.0 + _lIllI * 50.0) * _lOilO)) * exp(-_lIllI * 8.0) * 6.0 * step(_li0l1, sceneT + 20.0 * _lOilO);
float _l1OlO;
float _liOlO = raySegmentDist(vec3(0.0), rd, _l0ilO, _l0ilO + vec3(0.0, _lIilO, 0.0), _l1OlO);
float _l01li = max(R * 0.25, _l1OlO * gPix);
glow += (_llI1I * exp(-_liOlO / _l01li) * 2.5 + _lOO0i * exp(-_liOlO / (_l01li * 5.0)) * 0.5) * exp(-_lIllI * 3.5)
* step(_l1OlO, sceneT + 10.0 * _lOilO);
if (!sky && abs(_l1O0I.y - _l0ilO.y) < R + 30.0 * _lOilO) {
vec2 q = _l1O0I.xz - _l0ilO.xz;
float _l0iI1 = length(q);
float _l0I1l = R * 0.9 + _lIllI * 150.0 * _lOilO;
float ring = exp(-sqr((_l0iI1 - _l0I1l) / ((2.0 + _lIllI * 6.0) * _lOilO))) * exp(-_lIllI * 1.2);
glow += mix(_llI1I, _lOO0i, saturate(_lIllI)) * ring * 2.6;
if (_l0iI1 < R * 1.05) {
float _l0ii1 = fbm2(_l1O0I.xz * 0.3 / _lOilO + float(i) * 5.0);
float _lllOI = exp(-_lIllI / 20.0) * exp(-_l0iI1 / (R * 0.45)) * (0.4 + 0.9 * smoothstep(0.45, 0.7, _l0ii1));
glow += mix(_lOO0i, _llI1I, saturate(_lllOI * 1.2)) * _lllOI * 2.4 + _l0IOI(0.3) * _lllOI * _lllOI * 0.3;
}
float _lOOlO = smoothstep(0.0, 0.25, _lIllI);
float _ll111 = exp(-_lIllI / 14.0);
float _l0OlO = line(_liiI1(rot(_lIllI * 0.25 + float(i)) * q, R * 1.25), 0.4 * _lOilO)
* step(0.35, abs(fract(atan(q.y, q.x) / TAU * 6.0 + _lIllI * 0.04) - 0.5) * 2.0);
float _ll0lO = line(abs(_l0iI1 - R * 1.45), 0.3 * _lOilO) * step(0.4, fract(atan(q.y, q.x) / TAU * 60.0))
+ line(abs(_l0iI1 - R * 1.55), 0.18 * _lOilO);
vec2 _lI0lO = q - vec2(R * 1.7, -R * 0.2);
float _l10lO = _l1OI1(_lI0lO, vec2(0.0), 6.0 * _lOilO, _llilO(i), 3, _lIOi1 / (3.0 * _lOilO))
+ _l1OI1(q - vec2(-R * 1.7 - 6.0 * _lOilO, -R * 0.2), vec2(0.0), 6.0 * _lOilO, float(i + 1), 1, _lIOi1 / (3.0 * _lOilO));
glow += mix(_lOO0i * 0.6, _l0O0i, _ll111) * (_l0OlO + _ll0lO + _l10lO * 1.4) * _lOOlO * (0.3 + 1.4 * _ll111);
}
}
}
if (P0.z > 0.001 && !sky) {
for (int i = 0; i < 7; i++) {
vec3 _l0ilO = Pts[i].xyz;
if (Pts[i].w >= 0.0 || abs(_l1O0I.y - _l0ilO.y) > 40.0 * _lOilO) continue;
vec2 q = _l1O0I.xz - _l0ilO.xz;
float R = Pts[7 + i].x;
float spin = _l100l * 0.5 + float(i);
float _lIIi1 = mix(R * 1.8, R * 0.9, P2.x);
float _l10II = line(_liiI1(rot(spin) * q, _lIIi1), 0.4 * _lOilO) * step(0.3, abs(fract(atan(q.y, q.x) / TAU * 6.0) - 0.5) * 2.0);
float inner = line(abs(length(q) - 3.0 * _lOilO), 0.25 * _lOilO) + step(length(q), _lOilO);
float _li0lO = _l1OI1(q - vec2(_lIIi1 + 4.0 * _lOilO, -3.0 * _lOilO), vec2(0.0), 6.0 * _lOilO, float(i + 1), 1, _lIOi1 / (3.0 * _lOilO));
glow += _lOO0i * (_l10II * 2.0 + inner * 1.6 + _li0lO * 2.0) * P0.z;
}
for (int k = 0; k < 7; k++) {
vec3 a = Pts[_lO1lO(k)].xyz;
vec3 b = Pts[_l01lO(k)].xyz;
float d = sdSegment2(_l1O0I.xz, a.xz, b.xz);
vec2 ab = b.xz - a.xz;
float u = dot(_l1O0I.xz - a.xz, ab) / dot(ab, ab);
float _liOII = step(0.45, fract(u * length(ab) / (10.0 * _lOilO) - _l100l * 1.5));
float y = mix(a.y, b.y, saturate(u));
glow += _lOO0i * line(d, 0.35 * _lOilO) * _liOII * step(abs(_l1O0I.y - y), 40.0 * _lOilO) * P0.z * 1.2;
}
}
if (_l1ilO >= 0.0 && !sky) {
for (int k = 0; k < 7; k++) {
float s = _l1ilO - float(k) * 0.25;
if (s < 0.0) continue;
vec3 a = Pts[_lO1lO(k)].xyz;
vec3 b = Pts[_l01lO(k)].xyz;
vec2 ab = b.xz - a.xz;
float _lll0I = length(ab);
vec2 _lIIll = ab / _lll0I;
vec2 q = _l1O0I.xz - a.xz;
float along = dot(q, _lIIll);
float off = dot(q, vec2(-_lIIll.y, _lIIll.x));
float y = mix(a.y, b.y, saturate(along / _lll0I));
if (abs(_l1O0I.y - y) > 40.0 * _lOilO || along < -8.0 * _lOilO || along > _lll0I + 8.0 * _lOilO) continue;
float _li0OI = _lll0I * saturate(s / 0.4);
float _lO0lO = step(along, _li0OI);
float hot = exp(-sqr((along - _li0OI) / (6.0 * _lOilO))) * step(s, 0.5);
float _ll111 = exp(-max(s - 0.4, 0.0) / 10.0);
float _l00I1 = line(abs(off), 1.1 * _lOilO) * _lO0lO;
float cell = floor(along / (14.0 * _lOilO));
float side = mod(cell, 2.0) < 1.0 ? 1.0 : -1.0;
float _l00lO = along - (cell + 0.5) * 14.0 * _lOilO;
float _lllIO = line(abs(_l00lO), 0.35 * _lOilO) * step(0.0, off * side) * step(abs(off), 10.0 * _lOilO) * step(3.0 * _lOilO, abs(off))
* step(0.4, hash11(cell + float(k) * 13.0));
float via = line(abs(length(vec2(_l00lO, off - side * 10.0 * _lOilO)) - 1.5 * _lOilO), 0.3 * _lOilO) * step(0.4, hash11(cell + float(k) * 13.0));
float _l1iIl = _l00I1 * 2.4 + (_lllIO + via) * _lO0lO * 1.2;
glow += mix(_lOO0i * 0.7, _l0O0i, _ll111) * _l1iIl * (0.4 + 1.6 * _ll111) + _llI1I * hot * exp(-abs(off) / (3.0 * _lOilO)) * 6.0;
}
}
if (_liilO >= 0.0) {
float f = exp(-_liilO * 1.2);
for (int i = 0; i < 7; i++) {
vec3 _l0ilO = Pts[i].xyz;
float _l1OlO;
float _liOlO = raySegmentDist(vec3(0.0), rd, _l0ilO, _l0ilO + vec3(0.0, _lIilO, 0.0), _l1OlO);
float _l01li = max((2.5 + _liilO * 1.5) * _lOilO, _l1OlO * gPix);
glow += (_llI1I * exp(-_liOlO / _l01li) * 2.2 + _lOO0i * exp(-_liOlO / (_l01li * 4.0)) * 0.35) * f * step(_l1OlO, sceneT + 10.0 * _lOilO);
glow += _lO0O1(_l0ilO + vec3(0.0, _lIilO, 0.0), 1.0, sceneT, _l0O0i) * f;
}
for (int k = 0; k < 7; k++) {
vec3 a = Pts[_lO1lO(k)].xyz + vec3(0.0, _lIilO, 0.0);
vec3 b = Pts[_l01lO(k)].xyz + vec3(0.0, _lIilO, 0.0);
float tRay;
float d = raySegmentDist(vec3(0.0), rd, a, b, tRay);
float w = max(1.5 * _lOilO, tRay * gPix);
glow += (_l0O0i * exp(-d / w) * 1.6 + _lOO0i * exp(-d / (w * 6.0)) * 0.3) * f * step(tRay, sceneT);
}
if (!sky) {
for (int k = 0; k < 7; k++) {
vec3 a = Pts[_lO1lO(k)].xyz;
vec3 b = Pts[_l01lO(k)].xyz;
float d = sdSegment2(_l1O0I.xz, a.xz, b.xz);
glow += _llI1I * exp(-d / (2.5 * _lOilO)) * f * 3.0;
}
}
}
if (P3.z > 0.001) {
for (int i = 0; i < 7; i++) {
glow += _lO0O1(Pts[i].xyz + vec3(0.0, _lIilO, 0.0), 0.3, sceneT, _lOO0i) * P3.z;
}
}
fragColor = vec4(tonemap(base + glow), 1.0);
}