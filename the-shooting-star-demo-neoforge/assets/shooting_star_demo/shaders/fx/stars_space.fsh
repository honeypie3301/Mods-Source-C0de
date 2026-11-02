#include "star.glsl"
#include "title.glsl"
uniform sampler2D EarthDay;
uniform sampler2D EarthAux;
uniform sampler2D MoonColor;
uniform sampler2D MilkyWay;
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
uniform vec4 Stars[7];
uniform vec4 Tints[7];
uniform vec4 Shots[7];
uniform vec3 Heading;
uniform vec4 S0;
uniform vec4 S1;
uniform vec4 S2;
uniform vec4 S3;
#include "space.glsl"
const vec3 _lOO0i = vec3(0.62, 0.48, 1.0);
const vec3 _l0O0i = vec3(0.86, 0.8, 1.0);
const float _ll00i = 7.354e-8;
vec3 _lOO0I(vec3 v) {
return vec3(dot(v, EarthX), dot(v, EarthY), dot(v, EarthZ));
}
vec3 _l1OOl(vec3 n) {
vec3 _l0O0I = _lOO0I(SiteN);
float near = length(n - _l0O0I);
return _lOO0i * (exp(-near / 0.0002) * 3.0 + exp(-near / 0.004) * 0.2) * (1.0 - S1.z * 0.0);
}
vec3 _liOOl(vec3 p) {
return vec3(0.0);
}
vec3 _lI00i(vec3 rd, vec3 c, float radius, float _l10OI, vec3 _l100i, float _l0iOI) {
if (_l10OI < 0.001) return vec3(0.0);
float dist = length(c);
float R = max(max(radius, 2.0 * _ll00i) * 6.0, dist * S3.z);
float t = rayPlane(vec3(0.0), rd, c, _l100i);
vec3 col = vec3(0.0);
vec3 _lIIll = c / dist;
vec3 off = rd - _lIIll * dot(rd, _lIIll);
vec2 sq = vec2(dot(off, CamRight), dot(off, CamUp)) / _lI0Ol;
float rr = length(sq);
float _li00i = 9.0 + 3.0 * (1.0 - _l10OI);
float _l0111 = step(0.55, fract(atan(sq.y, sq.x) / TAU * 16.0 + _l100l * 0.3));
float _lO00i = exp(-sqr((rr - _li00i) / 0.9)) * _l0111 + exp(-sqr((rr - _li00i - 4.0) / 0.7)) * step(0.82, abs(cos(atan(sq.y, sq.x) * 2.0)));
float far = 1.0 - smoothstep(_lI0Ol * 2.0, _lI0Ol * 12.0, R * 6.0 / dist);
col += (_lOO0i * _lO00i * 1.4 + _lOO0i * _liO0I(length(rd - _lIIll), _lI0Ol, 2.2) * 1.5) * _l10OI * far * step(0.0, dot(rd, _lIIll));
if (t <= 0.0 || t > _l0iOI || R / dist < _lI0Ol * 2.0) return col;
vec3 q = rd * t - c;
vec3 ax, ay;
facing(_l100i, ax, ay);
vec2 p = vec2(dot(q, ax), dot(q, ay)) / R;
float r = length(p);
float a = atan(p.y, p.x) / TAU + 0.5;
float _li111 = _lI0Ol * t / (R * max(abs(dot(rd, _l100i)), 0.08));
gAA = _li111;
float _l1iIl = step(a, _l10OI + 0.001);
float lines = 0.0;
for (int i = 0; i < 3; i++) {
float rr = 1.0 + float(i) * 0.28;
float _l0O1I = floor(a * (48.0 + float(i) * 24.0) + _l100l * (float(i) - 1.0) * 0.4);
float bar = step(0.3, hash11(_l0O1I * 1.7 + float(i) * 11.0));
lines += line(abs(r - rr), 0.012 + 0.006 * float(i == 0 ? 1 : 0)) * bar;
lines += line(abs(r - rr - 0.035), 0.004) * 0.6;
}
float _l1iIi = abs(fract(a * 6.0) - 0.5) / 6.0 * TAU * r;
lines += line(_l1iIi, 0.008) * step(0.9, r) * step(r, 1.72);
vec2 _lOIOI = vec2(cos((floor(a * 6.0) + 0.5) / 6.0 * TAU - PI), sin((floor(a * 6.0) + 0.5) / 6.0 * TAU - PI)) * 1.72;
lines += line(abs(length(p - _lOIOI) - 0.05), 0.01);
lines += line(abs(r - 0.34), 0.006) * 0.8;
float _l0OII = exp(-sqr((fract(a - _l100l * 0.35) - 0.5) / 0.02)) * step(0.9, r) * step(r, 1.7) * 0.35;
float _lO0l1 = exp(-abs(r - 1.28) / 0.35) * 0.08;
col += (_lOO0i * lines * 0.9 + _l0O0i * lines * _l10OI * 0.5 + _lOO0i * (_l0OII + _lO0l1)) * _l1iIl * (0.6 + 1.2 * _l10OI);
return col;
}
float _l000i(vec3 p) {
vec3 cell = floor(p);
vec3 f = p - cell;
float _llllO = 9.0;
float _liI0I = 9.0;
for (int z = -1; z <= 1; z++) {
for (int y = -1; y <= 1; y++) {
for (int x = -1; x <= 1; x++) {
vec3 o = vec3(float(x), float(y), float(z));
vec3 c = cell + o;
vec3 h = vec3(hash13(c), hash13(c + 17.1), hash13(c + 31.7));
float d = length(o + h - f);
if (d < _llllO) {
_liI0I = _llllO;
_llllO = d;
} else if (d < _liI0I) {
_liI0I = d;
}
}
}
}
return smoothstep(0.0, 0.55, _liI0I - _llllO);
}
vec4 _lIllO(vec3 rd, out vec3 _ll101) {
_ll101 = vec3(0.0);
int _l1l0l = _lil0l();
if (_l1l0l <= 0) return vec4(0.0);
float _lOl0l = 1e9;
int _l0l0l = -1;
vec3 _llI0l = vec3(0.0);
vec3 _l1lI1 = vec3(0.0);
float _lII0l = 0.0;
for (int _liI0l = 0; _liI0l < _l1l0l; _liI0l++) {
vec4 st = TitleL[_liI0l * 4 + 3];
if (TitleL[_liI0l * 4 + 2].w <= 0.0 || st.x <= 0.0) continue;
float s = TitleL[_liI0l * 4].w;
vec3 lo;
vec3 _lOI0l;
_l0I0l(_liI0l, vec3(0.0), rd, lo, _lOI0l);
vec2 _ll10l = _lI10l(lo, _lOI0l, vec3(-1.4, -1.4, -1.0), vec3(5.4, 7.4, 1.0));
if (_ll10l.y < max(_ll10l.x, 0.0) || _ll10l.x * s > _lOl0l) continue;
float radius = 0.4 * sqrt(max(1.0 - st.y, 0.0));
float t = max(_ll10l.x, 0.0);
float closest = 1e9;
float _l1llO = 0.0;
bool _l0i0I = false;
for (int i = 0; i < 40 + int(TitleA.w); i++) {
vec3 p = lo + _lOI0l * t;
float along;
float _l110l;
vec2 away;
vec2 _li10l;
float r = _lO10l(_liI0l, p.xy, along, _l110l, away, _li10l);
float _lillO = along - st.x;
float d = max(length(vec2(r, p.z)) - radius, _lillO);
if (d < closest) {
closest = d;
_l1llO = along;
}
float _lIi0l = max(_lI0Ol * t * 0.5, 0.003);
if (d < _lIi0l && radius > 0.01) {
if (t * s < _lOl0l) {
_lOl0l = t * s;
_l0l0l = _liI0l;
vec2 _lllli = vec2(r, p.z) / max(length(vec2(r, p.z)), 1e-4);
vec3 _lii0l = _lillO > length(vec2(r, p.z)) - radius ? vec3(_li10l, 0.0)
: vec3(away * _lllli.x, _lllli.y);
_llI0l = _l1i0l(_liI0l, normalize(_lii0l));
_l1lI1 = p;
_lII0l = along;
}
_l0i0I = true;
break;
}
t += max(d * 0.85, _lIi0l * 0.5);
if (t > _ll10l.y) break;
}
float _lIOli = 0.6 + 0.4 * vnoise2(vec2(_l1llO * 2.5 + float(_liI0l) * 3.0, TitleB.x * 7.0));
float _lllOI = (1.0 + st.z * 3.0) * (1.0 + st.y * 2.0) * (1.0 - smoothstep(0.7, 1.0, st.y));
_ll101 += mix(_lOO0i, vec3(1.0, 0.92, 1.0), 0.15) * exp(-max(closest, 0.0) / 0.2) * 0.42 * _lIOli * _lIOli * _lllOI;
}
if (_l0l0l < 0) return vec4(0.0);
vec4 st = TitleL[_l0l0l * 4 + 3];
vec3 n = _llI0l;
vec3 v = -rd;
float _liIl1 = saturate(dot(n, v));
float _lOllO = 0.3 + 0.7 * sqrt(_liIl1);
vec3 q = _l1lI1 * 2.3 + vec3(TitleB.x * 0.25, 0.0, TitleB.x * 0.6);
float _l0llO = _l000i(q) * (0.75 + 0.25 * vnoise3(_l1lI1 * 9.0 + TitleB.x));
vec3 hot = vec3(1.0, 0.96, 1.0);
vec3 tint = mix(_lOO0i, Tints[int(st.w + 0.5)].rgb, 0.2);
float _lI1Ol = smoothstep(0.82, 1.0, sin(_lII0l * 1.7 - TitleB.x * 9.0 + float(_l0l0l) * 2.1) * 0.5 + 0.5);
vec3 col = mix(tint * 0.07, hot * 1.25, _l0llO) * (0.2 + 0.8 * _liIl1 * _liIl1) + hot * _lI1Ol * 0.9 * _liIl1;
col += _lOO0i * 0.35 * pow(1.0 - _liIl1, 3.0);
float _llIlO = exp(-max(st.x - _lII0l, 0.0) / 0.35) * step(_lII0l, st.x + 0.05);
col += hot * _llIlO * 2.0 * (1.0 - smoothstep(0.0, 1.0, st.x - 40.0));
col = col * (1.0 + st.z * 1.5 + st.y * 2.0);
return vec4(col, 1.0);
}
void main() {
_l100l = S0.y;
_li00l = S0.z;
float _liO0l = S0.x;
_lI0Ol = 2.0 * _liO0l / OutSize.y;
gPix = _lI0Ol;
vec2 _lO00l = texCoord * 2.0 - 1.0;
vec2 _l000l = vec2(_lO00l.x * OutSize.x / OutSize.y, _lO00l.y);
vec3 rd = normalize(CamFwd + (CamRight * _l000l.x + CamUp * _l000l.y) * _liO0l);
vec3 col = _lOll1(rd) * 0.8 + _l00Ol(rd, _lI0Ol, 0.5);
if (S1.y > 0.001) {
vec3 _l0iI1 = normalize(Heading);
float _l00iI = smoothstep(0.3, 0.65, dot(rd, _l0iI1));
col += _lIII1(rd, _l0iI1, _l100l * 9.0, 2.6, _lI0Ol, vec3(0.7, 0.66, 1.0), vec3(0.95, 0.9, 1.0)) * S1.y * _l00iI;
}
vec3 _ll101;
vec4 title = _lIllO(rd, _ll101);
col = mix(col, title.rgb, title.a) + _ll101;
float _l1ilI = _liilI;
vec3 _l1II1 = vec3(0.0);
vec2 hs = _lOII1(SunRelS, S2.x) ? raySphere(vec3(0.0), rd, SunRelS, S2.x) : vec2(-1.0);
if (hs.x > 0.0) {
_l1ilI = hs.x;
_l1II1 = _l0II1(rd * hs.x, SunRelS, S2.x, rd, hs.x);
}
for (int i = 0; i < 8; i++) {
if (i == 2) continue;
vec3 c = Planet[i].xyz;
float R = Planet[i].w;
vec2 h = _lOII1(c, R) ? raySphere(vec3(0.0), rd, c, R) : vec2(-1.0);
if (h.x > 0.0 && h.x < _l1ilI) {
_l1ilI = h.x;
_l1II1 = _ll1I1(i, rd * h.x, c, R, rd, h.x);
}
}
if (_l1ilI < _liilI) {
col = _l1II1;
}
if (length(SunRelS) < 200.0) {
col += _li1I1(rd, SunRelS, S2.x);
} else {
col += vec3(1.0, 0.95, 0.85) * _liO0I(length(rd - normalize(SunRelS)), _lI0Ol, 1.4) * 2.0;
}
vec3 _lIIlO = SunRelS * S3.y;
float _l1IlO = _liilI;
for (int i = 0; i < 7; i++) {
vec3 c = Stars[i].xyz;
float R = Stars[i].w;
vec3 tint = Tints[i].rgb;
float dist = length(c);
vec3 _lIIll = c / dist;
vec2 h = _lOII1(c, R) ? raySphere(vec3(0.0), rd, c, R) : vec2(-1.0);
if (h.x > 0.0 && h.x < _l1IlO) {
_l1IlO = h.x;
col = _lilli(normalize(rd * h.x - c), rd, tint, float(i) * 7.0);
} else {
float _l10ll = length(rd - _lIIll);
float ar = max(R / dist, _lI0Ol * 1.2);
float glow = _liO0I(_l10ll, _lI0Ol, 1.3) * 5.0 + ar * ar / (_l10ll * _l10ll + ar * ar) * 3.0;
vec3 off = rd - _lIIll * dot(rd, _lIIll);
vec2 sq = vec2(dot(off, CamRight), dot(off, CamUp)) / _lI0Ol;
float _liIlO = (exp(-abs(sq.y) / 0.8) * exp(-abs(sq.x) / 14.0) + exp(-abs(sq.x) / 0.8) * exp(-abs(sq.y) / 14.0));
col += tint * (glow + _liIlO * 0.8) * step(0.0, dot(rd, _lIIll));
}
vec3 _l100i = normalize(_lIIlO - c);
col += _lI00i(rd, c, R, Tints[i].w, _l100i, _l1IlO);
float f = Shots[i].w;
if (f >= 0.0) {
float _l10ll = length(rd - _lIIll);
vec3 off = rd - _lIIll * dot(rd, _lIIll);
vec2 sq = vec2(dot(off, CamRight), dot(off, CamUp)) / _lI0Ol;
float k = floor(atan(sq.y, sq.x) / TAU * 16.0);
float _llI0I = exp(-sqr((fract(atan(sq.y, sq.x) / TAU * 16.0) - 0.5) / 0.07));
float _lII0I = _llI0I * exp(-length(sq) / (18.0 + 90.0 * hash11(k + float(i) * 7.0))) * step(0.55, hash11(k * 3.1 + float(i)));
float _l1iOi = exp(-f * 6.0);
float _l1liI = f * 900.0;
float _lOIlO = exp(-sqr((length(sq) - _l1liI) / (2.0 + f * 30.0))) * exp(-f * 3.0);
col += (_l0O0i * (_liO0I(_l10ll, _lI0Ol, 5.0) * 16.0 + _lII0I * 2.2) * _l1iOi + _lOO0i * _lOIlO * 0.8)
* step(0.0, dot(rd, _lIIll));
vec3 s = Shots[i].xyz;
float _l0IlO = length(s);
float _ll1lO = length(c - s);
if (_l0IlO > 1e-12 && _ll1lO > 1e-12) {
vec3 _lIl0l = (c - s) / _ll1lO;
float _liOOI = min(_ll1lO, _l0IlO * 0.6);
float tRay;
float d = raySegmentDist(vec3(0.0), rd, s, s + _lIl0l * _liOOI, tRay);
float w = max(tRay * _lI0Ol * 0.8, 1e-12);
col += (_l0O0i * exp(-d / w) * 1.6 + _lOO0i * exp(-d / (w * 6.0)) * 0.3) * step(0.0, tRay);
col += vec3(1.0, 0.97, 1.0) * _liO0I(length(rd - s / _l0IlO), _lI0Ol, 2.4) * 9.0;
}
}
}
float _lI1lO = max(S2.y, S2.z);
if (_lI1lO > 0.001) {
for (int k = 0; k < 7; k++) {
int _l11lO = k == 0 ? 0 : k == 1 ? 1 : k == 2 ? 2 : k == 3 ? 3 : k == 4 ? 3 : k == 5 ? 4 : 5;
int _li1lO = k == 0 ? 1 : k == 1 ? 2 : k == 2 ? 3 : k == 3 ? 0 : k == 4 ? 4 : k == 5 ? 5 : 6;
vec3 a = S2.z > S2.y ? normalize(Shots[_l11lO].xyz) : normalize(Stars[_l11lO].xyz);
vec3 b = S2.z > S2.y ? normalize(Shots[_li1lO].xyz) : normalize(Stars[_li1lO].xyz);
vec3 _lIiIl = normalize(cross(a, b));
float off = abs(dot(rd, _lIiIl));
float along = step(0.0, dot(cross(a, rd), _lIiIl)) * step(0.0, dot(cross(rd, b), _lIiIl));
float _liOII = step(0.35, fract(dot(rd, normalize(a + b)) * 900.0 + _l100l * 2.0));
col += (_lOO0i * exp(-off / (_lI0Ol * 1.2)) * 2.2 + _lOO0i * exp(-off / (_lI0Ol * 6.0)) * 0.25) * along
* (0.5 + 0.5 * _liOII) * _lI1lO;
}
}
if (S1.x > 0.001) {
vec3 ro = -EarthRel;
vec2 _lIiil = _lOII1(EarthRel, 1.0) ? raySphere(ro, rd, vec3(0.0), 1.0) : vec2(-1.0);
vec2 _lO1I1 = _lOII1(MoonRel, S1.w) ? raySphere(vec3(0.0), rd, MoonRel, S1.w) : vec2(-1.0);
float _ll0lI = _lIiil.x > 0.0 ? _lIiil.x : _liilI;
float _l01I1 = _lO1I1.x > 0.0 ? _lO1I1.x : _liilI;
vec3 near = col;
if (_l01I1 < _ll0lI) {
near = _lIiI1(rd * _l01I1, MoonRel, S1.w, rd, _l01I1);
} else if (_lIiil.x > 0.0) {
near = _lI0lI(ro + rd * _ll0lI, rd, _ll0lI);
}
if (_lOII1(EarthRel, 1.0)) {
vec3 through;
vec3 _l10lI = _li0lI(ro, rd, min(_ll0lI, _l01I1), through);
near = near * through + _l10lI;
}
col = mix(col, near, S1.x);
}
col = 1.0 - exp(-col * 1.1);
col = pow(col, vec3(1.0 / 2.2));
float _lOIII = S1.z;
float _l0III = S0.w;
float _ll1II = sin(saturate(_lOIII) * PI) * (1.0 - step(0.999, _lOIII)) * step(S2.w, 0.5);
float _l11II = 1.0;
vec3 _lI1II = col;
if (_l0III < 0.999 || _ll1II > 0.001) {
vec3 world = texture(DiffuseSampler, texCoord).rgb;
float r = length(_l000l);
float _l10ll = atan(_l000l.y, _l000l.x);
float _li1II = fbm2(vec2(_l10ll * 2.5, log(r + 0.03) * 2.2 - _lOIII * 7.0) + _li00l);
_l11II = smoothstep(_li1II - 0.12, _li1II + 0.12, _l0III * 1.35 - 0.2);
_lI1II = mix(world, col, _l11II);
float _lO1II = smoothstep(0.35, 0.8, fbm2(_l000l * 2.2 + vec2(0.0, -_lOIII * 5.0) + _li1II));
_lI1II = mix(_lI1II, vec3(0.92, 0.94, 1.0), _ll1II * (0.35 + 0.65 * _lO1II) * 0.95);
}
fragColor = vec4(_lI1II, 1.0 - _l11II);
}