#include "star.glsl"
uniform vec4 P4;
uniform vec4 P5;
float _l1iI1 = 1.0;
const vec3 _lOl1I = vec3(1.0, 0.3, 0.06);
const vec3 _l0l1I = vec3(1.0, 0.62, 0.3);
const vec3 _llI1I = vec3(1.0, 0.95, 0.88);
float _liiI1(vec2 p, float r) {
const vec3 k = vec3(-0.866025404, 0.5, 0.577350269);
p = abs(p);
p -= 2.0 * min(dot(k.xy, p), 0.0) * k.xy;
p -= vec2(clamp(p.x, -k.z * r, k.z * r), r);
return abs(length(p) * sign(p.y));
}
float _lOiI1(vec3 p, float _l0I1l, float _lIllI) {
float _l0iI1 = length(p.xz - Target.xz);
float g = _l0iI1 < min(_l0I1l - 10.0 * _l1iI1, P1.z) ? P3.z : P2.z;
float y = p.y - g;
if (y < -2.0) return 0.0;
float behind = _l0I1l - _l0iI1;
float _llOI1 = max(_l1iI1, 0.35);
float wall = smoothstep(-3.0, 4.0, behind) * exp(-max(behind, 0.0) / ((45.0 + _lIllI * 40.0) * _llOI1));
float h = mix(48.0, 12.0, saturate(_l0iI1 / (P1.z * 1.3))) * (1.0 + _lIllI * 0.35) * _llOI1 + max(P2.z - g, 0.0) * 0.6;
float vertical = exp(-max(y, 0.0) / h) * smoothstep(-2.0, 1.5, y);
float a = atan(p.z - Target.z, p.x - Target.x);
float roll = fbm3(vec3(a * 26.0, y * 0.06 / _llOI1 - _lIllI * 0.8, _l0iI1 * 0.035 / _llOI1 - _lIllI * 1.4) + _li00l * 7.0);
return wall * vertical * smoothstep(0.25, 0.75, roll) * 1.4;
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
float d = _lIOI1(vec2(p.x - i * _liOI1, p.y), _lOOI1);
return smoothstep(0.1 + aa, 0.1 - aa, d);
}
vec3 _l0OI1(vec2 p, float size) {
vec2 q = p / size;
const vec2 r = vec2(1.0, 1.7320508);
vec2 h = r * 0.5;
vec2 a = mod(q, r) - h;
vec2 b = mod(q - h, r) - h;
vec2 g = dot(a, a) < dot(b, b) ? a : b;
vec2 id = q - g;
vec2 ag = abs(g);
float edge = 0.5 - max(dot(ag, normalize(vec2(1.0, 1.7320508))), ag.x);
return vec3(edge * size, id);
}
vec3 _ll0I1(vec3 at, float s, float _lI0I1) {
vec2 q = at.xz - Target.xz;
float R = P1.z + 5.0;
float _l10I1 = R * 1.04 * (1.0 - exp(-s * 3.0));
float r = length(q);
float _ll10l = max(abs(q.x), abs(q.y));
if ((r > _l10I1 + 6.0 && _ll10l > _l10I1) || (abs(at.y - P2.z) > 28.0 && abs(at.y - P3.z) > 18.0)) return vec3(0.0);
gAA = _lI0I1;
vec3 _ll0II = _l0OI1(q, 9.0);
float _li0I1 = line(_ll0II.x, 0.12) * 0.45;
float _l1iIl = step(0.9, hash12(_ll0II.yz + floor(_l100l * 6.0 + hash12(_ll0II.yz) * 9.0)));
float _lO0I1 = _l1iIl * smoothstep(0.0, 0.6, _ll0II.x) * 0.35;
float c = 12.0;
vec2 cell = floor(q / c);
vec2 f = q / c - cell - 0.5;
float _l00I1 = 1e3;
float _lll11 = 0.0;
for (int k = 0; k < 4; k++) {
vec2 _lIIll = k == 0 ? vec2(1.0, 0.0) : k == 1 ? vec2(-1.0, 0.0) : k == 2 ? vec2(0.0, 1.0) : vec2(0.0, -1.0);
vec2 _lIl11 = cell * 2.0 + _lIIll + vec2(k < 2 ? 0.37 : 0.0, k < 2 ? 0.0 : 0.61);
if (hash12(_lIl11 * 1.3 + _li00l) < 0.42) {
_l00I1 = min(_l00I1, sdSegment2(f, vec2(0.0), _lIIll * 0.5));
_lll11 += 1.0;
}
}
float _l1l11 = line(_l00I1 * c, 0.35) * step(0.5, _lll11);
float via = _lll11 == 1.0 || _lll11 >= 3.0 ? line(abs(length(f) * c - 1.1), 0.3) + line(length(f) * c, 0.45) : 0.0;
float _lil11 = step(0.72, fract(r / 11.0 - s * 5.0));
float _lOl11 = (_l1l11 * (0.6 + 1.4 * _lil11) + via) * smoothstep(R * 0.2, R * 0.28, r);
float a = atan(q.y, q.x);
float rings = 0.0;
float _l0l11 = 0.0;
for (int i = 1; i <= 4; i++) {
float rr = float(i) * (R - 5.0) * 0.25;
float _liOII = step(0.3, fract(a / TAU * (48.0 + float(i) * 24.0) + s * (float(i) - 2.5) * 0.05));
rings += line(abs(r - rr), 0.45) * (i == 4 ? 1.0 : _liOII);
rings += line(abs(r - rr - 2.2), 0.18) * step(0.8, fract(a / TAU * 360.0));
for (int _liOil = 0; _liOil < 4; _liOil++) {
float _l10ll = float(_liOil) * PI * 0.5 + PI * 0.25;
vec2 _llI11 = vec2(cos(_l10ll), sin(_l10ll));
vec2 _llll1 = vec2(-_llI11.y, _llI11.x);
vec2 uv = vec2(dot(q, _llll1), dot(q, _llI11));
_l0l11 += _l1OI1(uv, vec2(-10.0, rr + 6.0), 8.0, rr, 3, _lI0I1 / 4.0);
}
}
float _lII11 = min(abs(q.x), abs(q.y));
float along = max(abs(q.x), abs(q.y));
float _l1I11 = R + 7.0;
float cross = line(_lII11, 0.4) * step(R * 0.11, along) * step(along, _l1I11);
float _liI11 = step(_lII11, 3.0) * step(0.9, fract(along / 10.0)) * step(R * 0.11, along) * step(along, _l1I11);
vec2 _lOI11 = abs(q);
float _l1lOI = (line(abs(_lOI11.x - _l1I11), 0.7) * step(_l1I11 - R * 0.18, _lOI11.y) * step(_lOI11.y, _l1I11)
+ line(abs(_lOI11.y - _l1I11), 0.7) * step(_l1I11 - R * 0.18, _lOI11.x) * step(_lOI11.x, _l1I11));
float lines = saturate(_li0I1 + _lO0I1 + _lOl11 + rings + _l0l11 * 1.4 + cross + _liI11 + _l1lOI);
float _l0I11 = _l10I1;
float d = max(r, _ll10l * 0.97);
float drawn = smoothstep(_l0I11 + 2.0, _l0I11 - 3.0, d);
float _lIl1I = exp(-max(_l0I11 - d, 0.0) / 24.0);
float _ll111 = exp(-s / 12.0);
vec3 col = mix(vec3(0.55, 0.06, 0.02), mix(_l0l1I, _llI1I, _lIl1I), _ll111) * (1.0 + 5.0 * _lIl1I * exp(-s * 0.5));
return col * lines * drawn * (0.35 + 1.8 * _ll111) * P5.x;
}
vec3 _lI111(vec3 rd, float sceneT, float s) {
vec3 col = vec3(0.0);
if (abs(rd.y) < 1e-4 || P5.y < 0.001) return col;
for (int i = 0; i < 7; i++) {
float _l1Iil = float(i);
bool _l1111 = i == 6;
float k = _l1111 ? s : s - _l1Iil * 0.045;
if (k <= 0.0) continue;
float y = _l1111 ? P2.z + 380.0 * (1.0 - exp(-s * 1.4)) : P2.z + 18.0 + _l1Iil * 50.0 + k * 34.0;
float tp = y / rd.y;
if (tp <= 0.0 || tp > sceneT) continue;
vec2 q = rd.xz * tp - Target.xz;
float r = length(q);
float rr = _l1111 ? P4.z + 12.0 : P4.z + 5.0 + _l1Iil * 6.0 + P1.z * 0.75 * (1.0 - exp(-k * (1.9 - _l1Iil * 0.2)));
float _li111 = max(gPix * tp / max(abs(rd.y), 0.05), 0.05);
float fade = _l1111 ? exp(-s * 0.6) : exp(-k * (0.9 + _l1Iil * 0.2));
float a = atan(q.y, q.x) / TAU;
float spin = k * (_l1Iil - 2.5) * 0.12;
float _l0O1I = floor((a + spin) * 72.0);
float _lO111 = step(0.35, hash11(_l0O1I * 1.7 + _l1Iil * 13.0)) * step(0.12, fract((a + spin) * 72.0));
float band = exp(-sqr((r - rr) / max(0.9, _li111))) * _lO111;
float inner = exp(-sqr((r - rr * 0.95) / max(0.35, _li111)));
float _l0111 = step(0.75, fract(a * 180.0)) * step(rr * 1.015, r) * step(r, rr * 1.04);
float _lli11 = abs(fract(a * 4.0 + 0.125 - spin * 2.0) - 0.5);
float _lIi11 = exp(-sqr((r - rr * 1.08) / max(0.6, _li111))) * step(_lli11, 0.07);
col += mix(_llI1I, _lOl1I, saturate(k * 1.1)) * (band * 2.6 + inner * 1.2 + _l0111 * 1.0 + _lIi11 * 2.4) * fade;
}
return col * P5.y;
}
vec3 _l1i11(vec3 rd, float sceneT, float s) {
if (P5.z < 0.001) return vec3(0.0);
vec2 _lii11 = -Target.xz;
float _ll0ll = length(_lii11);
if (_ll0ll < 1.0) return vec3(0.0);
vec3 n = vec3(_lii11.x / _ll0ll, 0.0, _lii11.y / _ll0ll);
float tp = rayPlane(vec3(0.0), rd, Target, n);
if (tp <= 0.0 || tp > sceneT) return vec3(0.0);
vec3 h = rd * tp - Target;
float _lOi11 = clamp(P1.z / 250.0, 0.3, 1.6);
float u = dot(h, vec3(-n.z, 0.0, n.x)) / _lOi11;
float v = h.y / _lOi11;
float _l1lll = max(gPix * tp / _lOi11, 0.2);
gAA = _l1lll;
float _l0i11 = 70.0;
float _llO11 = 640.0;
if (v < _l0i11 - 40.0 || v > _llO11 + 40.0 || abs(u) > 170.0) return vec3(0.0);
vec2 _lIO11 = vec2(abs(u), v);
float grid = (line(abs(fract(u / 20.0 + 0.5) - 0.5) * 20.0, 0.12) + line(abs(fract(v / 20.0 + 0.5) - 0.5) * 20.0, 0.12))
* step(abs(u), 150.0) * step(_l0i11 - 20.0, v) * step(v, _llO11 + 20.0) * 0.22;
float _l1O11 = (line(abs(_lIO11.x - 150.0), 0.8) * (step(_llO11 - 20.0, v) + step(v, _l0i11 + 20.0)) * step(_l0i11 - 20.0, v) * step(v, _llO11 + 20.0)
+ line(abs(v - _llO11 - 20.0), 0.8) * step(130.0, _lIO11.x) * step(_lIO11.x, 150.0)
+ line(abs(v - _l0i11 + 20.0), 0.8) * step(130.0, _lIO11.x) * step(_lIO11.x, 150.0));
float _liO11 = saturate((v - _l0i11) / (_llO11 - _l0i11));
float _lOO11 = 26.0 * min(_liO11 / 0.42, 1.0) * mix(1.0, 0.8, smoothstep(0.93, 1.0, _liO11));
float inside = step(_l0i11, v) * step(v, _llO11);
float _l0O11 = line(abs(abs(u) - _lOO11), 0.9) * inside;
float _ll011 = (line(abs(u), 0.5) + line(abs(abs(u) - _lOO11 * 0.5), 0.4)) * step(_l0i11 + 10.0, v) * step(v, _llO11);
float _lI011 = line(abs(fract((v - _l0i11) / 57.0 + 0.5) - 0.5) * 57.0, 0.5) * step(abs(u), _lOO11) * inside;
float _lOi1I = saturate((v - (_llO11 - 90.0)) / 90.0);
float _l1011 = mix(_lOO11, 66.0, _lOi1I);
float _li011 = line(abs(abs(u) - _l1011), 0.8) * step(_llO11 - 90.0, v) * step(v, _llO11) * step(_lOO11, abs(u) + 1.0)
+ line(abs(v - _llO11), 0.8) * step(abs(u), 66.0);
float _lO011 = 104.0;
float dim = line(abs(u - _lO011), 0.5) * step(_l0i11, v) * step(v, _llO11)
+ line(abs(v - _l0i11), 0.5) * step(abs(u - _lO011), 10.0) + line(abs(v - _llO11), 0.5) * step(abs(u - _lO011), 10.0)
+ line(abs(abs(u - _lO011) - (v - _l0i11) * 0.35), 0.5) * step(v, _l0i11 + 14.0) * step(_l0i11, v)
+ line(abs(abs(u - _lO011) - (_llO11 - v) * 0.35), 0.5) * step(_llO11 - 14.0, v) * step(v, _llO11);
float _l0011 = _l1OI1(vec2(u, v), vec2(_lO011 + 8.0, (_l0i11 + _llO11) * 0.5 - 12.0), 24.0, 1020.0, 4, _l1lll / 12.0);
float _llli1 = line(sdSegment2(vec2(u, v), vec2(0.0, _l0i11), vec2(-60.0, _l0i11 + 50.0)), 0.5)
+ line(sdSegment2(vec2(u, v), vec2(-60.0, _l0i11 + 50.0), vec2(-140.0, _l0i11 + 50.0)), 0.5);
float speed = _l1OI1(vec2(u, v), vec2(-138.0, _l0i11 + 56.0), 18.0, 9987.0, 4, _l1lll / 9.0);
float _lIli1 = _llO11 + 40.0 - (_llO11 - _l0i11 + 80.0) * saturate(s / 0.9);
float drawn = step(_lIli1, v);
float _l1li1 = exp(-abs(v - _lIli1) / max(1.5, _l1lll)) * step(abs(u), 150.0) * step(s, 0.95);
float lines = saturate(grid + _l1O11 + (_l0O11 + _ll011 * 0.6 + _lI011 * 0.5 + _li011 + dim + _l0011 * 1.3 + _llli1 + speed * 1.3) * drawn);
return (_llI1I * 2.2 + _lOl1I * 1.4) * lines * P5.z + _llI1I * _l1li1 * 3.0 * P5.z;
}
void main() {
initPixel(texCoord);
_l100l = P0.x;
_li00l = P0.y;
_l1iI1 = P5.w > 0.001 ? P5.w : 1.0;
vec3 rd = viewDir(texCoord);
vec3 _l1O0I = scenePosAt(texCoord);
bool sky = skyAt(texCoord);
float sceneT = sky ? FAR : length(_l1O0I);
float _lIllI = P1.x;
float _l0I1l = P1.y;
float _lili1 = P1.z;
vec2 axis = Target.xz;
float _l0iI1 = length(_l1O0I.xz - axis);
vec2 uv = texCoord;
if (_lIllI >= 0.0 && _lIllI < 3.5 && !sky) {
float band = (_l0iI1 - _l0I1l) / (6.0 + _lIllI * 5.0);
float _l0i1l = band * exp(-band * band) * exp(-_lIllI * 0.9) * P4.w;
vec3 tp = project(Target);
vec2 away = tp.z > 0.0 ? normalize(texCoord - tp.xy + 1e-5) : vec2(0.0, 1.0);
uv += away * _l0i1l * 0.012;
}
if (P3.w > 0.001) {
float _lOli1;
float _l0li1 = raySegmentDist(vec3(0.0), rd, Target + vec3(0.0, P4.y - Target.y, 0.0), vec3(Target.x, P4.x, Target.z), _lOli1);
float near = exp(-max(_l0li1 - P4.z, 0.0) / 5.0) * step(_lOli1, sceneT + 4.0);
float _llIi1 = sky ? 0.0 : exp(-_l0iI1 / (P1.z * 0.15)) * step(_l1O0I.y, Target.y + 30.0);
float shimmer = (near + _llIi1) * P3.w;
if (shimmer > 0.001) {
vec2 _llIlI = vec2(vnoise2(texCoord * 90.0 + vec2(0.0, _l100l * 3.0)), vnoise2(texCoord * 90.0 + vec2(7.3, _l100l * 2.6))) - 0.5;
uv += _llIlI * 0.004 * shimmer;
}
}
vec3 base = sampleScene(uv);
vec3 glow = vec3(0.0);
if (P0.z > 0.001) {
if (!sky && abs(_l1O0I.y - Target.y) < 40.0 + _l0iI1 * 0.4) {
float w = max(0.12, sceneT * gPix * 1.2);
vec2 q = _l1O0I.xz - axis;
float _l10ll = atan(q.y, q.x);
if (P2.x > 0.001 && _l0iI1 < 16.0) {
float spin = _l100l * 0.6;
float _lIIi1 = mix(14.0, 6.0, P2.x);
vec2 _l1Ii1 = rot(spin) * q;
float _l10II = saturate(1.0 - _liiI1(_l1Ii1, _lIIi1) / w) * step(0.35, abs(fract(atan(_l1Ii1.y, _l1Ii1.x) / TAU * 6.0) - 0.5) * 2.0);
float _liIi1 = saturate(1.0 - _liiI1(rot(-spin * 1.7) * q, _lIIi1 * 0.45) / w);
float ring = saturate(1.0 - abs(_l0iI1 - 2.2) / w) * step(0.5, fract(_l10ll / TAU * 18.0 - _l100l * 1.5));
float cross = (saturate(1.0 - abs(q.x) / w) + saturate(1.0 - abs(q.y) / w)) * step(3.0, _l0iI1) * step(_l0iI1, 5.0);
float _lOIi1 = exp(-sqr(_l0iI1 / 0.6));
glow += _lOl1I * (_l10II * 2.6 + _liIi1 * 1.4 + ring * 1.6 + cross * 1.4) * P2.x + _l0l1I * _lOIi1 * 3.0 * P0.z;
}
float edge = saturate(1.1 - abs(_l0iI1 - _lili1) / w);
float _l0OII = fract(_l10ll / TAU + _l100l * 0.3);
float _llI0I = exp(-_l0OII * 12.0) * step(_l0iI1, _lili1) * smoothstep(0.0, _lili1 * 0.5, _l0iI1);
float _l0111 = step(0.8, fract(_l10ll / TAU * 60.0)) * step(abs(_l0iI1 - _lili1 + 3.0), 2.0);
float _lil11 = fract(P2.y);
float _l0Ii1 = saturate(1.0 - abs(_l0iI1 - _lili1 * (1.0 - _lil11)) / (w * 2.0 + 1.0)) * (1.0 - _lil11);
glow += _lOl1I * (edge * 2.2 + _l0111 * 1.1 + _llI0I * 0.4 + _l0Ii1 * 1.5) * P0.z;
base = mix(base, base * vec3(1.15, 0.8, 0.7), _llI0I * 0.25 * P0.z);
}
float tRay;
float d = raySegmentDist(vec3(0.0), rd, Target, Target + vec3(0.0, 5000.0, 0.0), tRay);
if (tRay < sceneT) {
vec3 at = rd * tRay;
float _ll1i1 = max(0.06, tRay * gPix * 0.8);
float _liOII = step(0.45, fract((at.y - Target.y) / 14.0 + _l100l * 1.2));
float core = saturate(1.2 - d / _ll1i1) * _liOII;
float _l10lI = exp(-d / (_ll1i1 * 6.0 + 0.3)) * 0.2;
glow += _lOl1I * (core * 2.5 + _l10lI) * P0.z * (1.0 - P0.w);
}
}
float k = P0.w;
if (k > 0.001) {
float h = 20.0 + 9000.0 * pow(max(1.0 - k, 0.0), 0.75);
vec3 _li0OI = Target + vec3(0.0, h, 0.0);
float tRay;
float d = raySegmentDist(vec3(0.0), rd, _li0OI, _li0OI + vec3(0.0, min(h * 1.5, 5000.0), 0.0), tRay);
if (tRay < sceneT) {
vec3 at = rd * tRay;
float up = (at.y - _li0OI.y) / max(h * 1.5, 1.0);
float w = max(0.4 + h * 0.002, tRay * gPix * 0.8);
float core = exp(-d / w) * exp(-up * 3.0);
float _lO0l1 = exp(-d / (w * 8.0 + 3.0)) * exp(-up * 2.0) * 0.35;
glow += (mix(_llI1I, vec3(1.0, 0.45, 0.5), saturate(up * 2.0)) * core * 2.4 + vec3(1.0, 0.4, 0.3) * _lO0l1) * k;
}
for (int i = 0; i < 4; i++) {
float _l1Iil = float(i);
float _lI1i1 = h * (0.015 + _l1Iil * 0.03) + _l1Iil * 3.0;
float _l11i1 = _li0OI.y + _lI1i1;
if (abs(rd.y) < 1e-4) continue;
float tp = _l11i1 / rd.y;
if (tp <= 0.0 || tp > sceneT) continue;
vec3 q = rd * tp;
float rr = length(q.xz - axis);
float rc = _lI1i1 * 0.3;
float _lIOil = max(0.3 + _lI1i1 * 0.02, tp * gPix);
glow += vec3(0.95, 0.97, 1.0) * exp(-sqr((rr - rc) / _lIOil)) * (0.9 - _l1Iil * 0.18) * smoothstep(0.2, 0.7, k);
}
vec3 _l01Il = project(_li0OI);
if (_l01Il.z > 0.0 && length(_li0OI) < sceneT + 5.0) {
vec2 dd = (texCoord - _l01Il.xy) * vec2(OutSize.x / OutSize.y, 1.0);
float _l1lll = 1.0 / OutSize.y;
float g = smoothstep(0.1, 1.0, k);
float _li1i1 = 0.75 + 0.25 * sin(_l100l * 61.0) * sin(_l100l * 37.0 + 2.0);
float _lll0I = (0.03 + 0.34 * g * g) * _li1i1;
float core = exp(-dot(dd, dd) / sqr(_l1lll * (1.5 + 4.0 * g)));
float cross = exp(-abs(dd.y) / (_l1lll * 0.8)) * exp(-abs(dd.x) / _lll0I)
+ exp(-abs(dd.x) / (_l1lll * 0.8)) * exp(-abs(dd.y) / _lll0I);
vec2 _lO1i1 = mat2(0.7071, 0.7071, -0.7071, 0.7071) * dd;
float _l01i1 = exp(-abs(_lO1i1.y) / (_l1lll * 0.6)) * exp(-abs(_lO1i1.x) / (_lll0I * 0.3))
+ exp(-abs(_lO1i1.x) / (_l1lll * 0.6)) * exp(-abs(_lO1i1.y) / (_lll0I * 0.3));
float halo = exp(-length(dd) / (_l1lll * (8.0 + 60.0 * g)));
glow += (_llI1I * core * 6.0 + mix(_llI1I, _l0l1I, 0.4) * (cross * 2.2 + _l01i1 * 1.0) + _l0l1I * halo * 0.8) * (0.3 + 1.4 * g);
}
if (sky) {
float _llii1 = smoothstep(0.2, 0.9, rd.y);
float _lIii1 = sqr(smoothstep(0.0, 0.6, k)) * _llii1 * 0.92;
base = mix(base, base * 0.08 + vec3(0.02, 0.018, 0.03), _lIii1);
}
if (!sky) {
float light = k * k * k * 2.0 * 260.0 * 260.0 / (_l0iI1 * _l0iI1 + h * h * 0.25 + 260.0 * 260.0);
base += base * vec3(1.0, 0.9, 0.8) * light;
} else {
float _l1ii1 = length(rd - normalize(_li0OI));
base += vec3(1.0, 0.8, 0.7) * exp(-_l1ii1 / 0.25) * k * k * 0.5;
}
}
if (_lIllI >= 0.0) {
float _li0l1;
float _lOil1 = rayPointDist(vec3(0.0), rd, Target + vec3(0.0, 4.0, 0.0), _li0l1);
float dome = exp(-_lOil1 / (6.0 + _lIllI * 60.0)) * exp(-_lIllI * 9.0) * step(_li0l1, sceneT + 30.0);
glow += _llI1I * dome * 8.0;
if (!sky && _lIllI < 4.0) {
float _liii1 = 2.5 + _lIllI * 4.0;
float band = exp(-sqr((_l0iI1 - _l0I1l) / _liii1)) * step(P3.z - 4.0, _l1O0I.y) * step(_l1O0I.y, P2.z + 30.0 + _lIllI * 20.0);
glow += mix(_llI1I, _lOl1I, saturate(_lIllI * 0.9)) * band * 3.0 * exp(-_lIllI * 0.8) * P4.w;
float _lOii1 = smoothstep(_l0I1l + 2.0, _l0I1l - 10.0, _l0iI1) * step(_l0iI1, _lili1 + 8.0);
base = mix(base, base * vec3(0.55, 0.42, 0.38), _lOii1 * 0.5 * exp(-_lIllI * 0.15));
}
if (!sky && P2.w > 0.001 && _l0iI1 < P1.z * 0.3 && _l1O0I.y < P2.z + 3.0) {
float _l0ii1 = fbm2(_l1O0I.xz * 0.25 + _li00l);
float _ll111 = exp(-_l0iI1 / (P1.z * 0.11));
float t = P2.w * _ll111 * (0.4 + 0.8 * smoothstep(0.45, 0.7, _l0ii1));
glow += _l0IOI(0.25 + 0.6 * t) * t * 3.0;
}
if (!sky && P2.w > 0.001 && _l0iI1 < 120.0 * _l1iI1 && _l1O0I.y < P3.z) {
float _llOi1 = saturate((P3.z - _l1O0I.y) / max(P3.z - P4.y, 1.0));
_llOi1 = _llOi1 * _llOi1 * (3.0 - 2.0 * _llOi1);
float n = fbm2(vec2(atan(_l1O0I.z - Target.z, _l1O0I.x - Target.x) * 6.0, _l1O0I.y * 0.08) + _li00l);
float t = P2.w * _llOi1 * (0.55 + 0.6 * n);
glow += _l0IOI(0.3 + 0.65 * t) * t * 4.0;
}
if (!sky) {
float _lIOi1 = gPix * sceneT / max(abs(rd.y), 0.08);
glow += _ll0I1(_l1O0I, _lIllI, _lIOi1);
if (_lIllI < 3.5 && _l0I1l > 6.0) {
vec2 q = _l1O0I.xz - axis;
float behind = _l0I1l - _l0iI1;
float _l10ll = atan(q.y, q.x) * _l0I1l;
float _l1Oi1 = max(_l1iI1, 0.4);
float _liOi1 = abs(fract(_l10ll / (7.0 * _l1Oi1) + _lIllI * 2.0) - 0.5) * 7.0 * _l1Oi1;
float _lOOi1 = exp(-sqr((behind - 5.0 * _l1Oi1 - _liOi1 * 0.9) / max(0.35, _lIOi1)))
* step(0.0, behind) * step(behind, 12.0 * _l1Oi1) * step(0.25, fract(_l10ll / (42.0 * _l1Oi1)));
glow += mix(_llI1I, _lOl1I, saturate(_lIllI * 0.8)) * _lOOi1 * 3.0 * exp(-_lIllI * 0.6)
* step(P3.z - 4.0, _l1O0I.y) * step(_l1O0I.y, P2.z + 30.0) * P4.w;
}
}
glow += _lI111(rd, sceneT, _lIllI) + _l1i11(rd, sceneT, _lIllI);
if (P1.w > 0.001) {
float _l0Oi1 = min(P2.z, P3.z) - 2.0;
float _ll0i1 = max(P2.z, P3.z) + (60.0 + _lIllI * 15.0) * max(_l1iI1, 0.35);
float t0 = 0.0;
float t1 = min(sceneT, 900.0);
if (abs(rd.y) > 1e-4) {
float _lI0i1 = _l0Oi1 / rd.y;
float _l1l0I = _ll0i1 / rd.y;
t0 = max(t0, min(_lI0i1, _l1l0I));
t1 = min(t1, max(_lI0i1, _l1l0I));
} else if (_l0Oi1 > 0.0 || _ll0i1 < 0.0) {
t1 = -1.0;
}
if (t1 > t0) {
const int _lOI0I = 14;
float _l0I0I = (t1 - t0) / float(_lOI0I);
float _lI1ll = hash12(gl_FragCoord.xy + fract(_l100l) * 13.0);
float _l10i1 = 1.0;
vec3 _li0i1 = vec3(0.0);
for (int i = 0; i < _lOI0I; i++) {
vec3 p = rd * (t0 + _l0I0I * (float(i) + _lI1ll));
float _lO0i1 = _lOiI1(p, _l0I1l, _lIllI) * P1.w;
if (_lO0i1 < 0.002) continue;
float _l00i1 = length(p.xz - axis);
vec3 _lllO1 = vec3(0.5, 0.47, 0.45) + _l0IOI(0.5) * 1.6 * exp(-_l00i1 / (60.0 * _l1iI1)) * exp(-_lIllI * 0.4)
+ _lOl1I * 0.35 * exp(-abs(_l00i1 - _l0I1l) / (12.0 * max(_l1iI1, 0.35))) * exp(-_lIllI * 0.6);
float a = 1.0 - exp(-_lO0i1 * _l0I0I * 0.08);
_li0i1 += _l10i1 * a * vec3(0.4, 0.36, 0.32) * _lllO1;
_l10i1 *= 1.0 - a;
if (_l10i1 < 0.03) break;
}
base = base * _l10i1 + _li0i1;
glow *= mix(1.0, _l10i1, 0.7);
}
}
}
if (P3.x > 0.001) {
float _lOli1;
vec3 _lIlO1 = vec3(Target.x, P4.y, Target.z);
vec3 _l1lO1 = vec3(Target.x, P4.x, Target.z);
float d = raySegmentDist(vec3(0.0), rd, _lIlO1, _l1lO1, _lOli1);
bool _lilO1 = !sky && length(_l1O0I.xz - axis) < P4.z + 1.5 && _l1O0I.y > P4.y - 2.0;
if (_lOli1 < sceneT + 8.0 && !_lilO1) {
vec3 at = rd * _lOli1;
float off = max(d - P4.z - 0.5, 0.0);
float _lOlO1 = 0.7 + 0.3 * sin(_l100l * 2.2 - (at.y - Target.y) * 0.02);
float _l0lO1 = exp(-off / 3.0) * 0.18 + exp(-off / 16.0) * 0.05;
glow += _lOl1I * _l0lO1 * _lOlO1 * P3.x;
}
}
if (P3.y > 0.001) {
float tRay;
vec3 a = vec3(Target.x, P4.x, Target.z);
vec3 b = a + vec3(0.0, 4200.0, 0.0);
float d = raySegmentDist(vec3(0.0), rd, a, b, tRay);
if (tRay < sceneT) {
vec3 at = rd * tRay;
float up = at.y - a.y;
float _llIO1 = (vnoise2(vec2(up * 0.004, _l100l * 0.05 + 3.0)) - 0.5) * (20.0 + up * 0.03) * (1.0 - P3.y);
float dd = max(d - abs(_llIO1) * 0.5, 0.0);
float w = max(1.2 + (1.0 - P3.y) * 8.0 + up * 0.002, tRay * gPix * 0.8);
float core = exp(-dd / w);
float halo = exp(-dd / (w * 6.0)) * 0.3;
vec3 c = mix(vec3(1.0, 0.55, 0.6), vec3(0.6, 0.35, 0.9), saturate(1.0 - P3.y + up / 6000.0));
glow += c * (core * 0.7 + halo * 0.5) * P3.y * P3.y * 0.6;
}
}
fragColor = vec4(tonemap(base + glow), 1.0);
}