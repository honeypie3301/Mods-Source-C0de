#include "star.glsl"
uniform sampler2D EarthDay;
uniform sampler2D EarthAux;
uniform sampler2D MoonColor;
uniform sampler2D MilkyWay;
uniform sampler2D Planets;
uniform sampler2D Rings;
uniform sampler2D Nebula;
uniform sampler2D MeshColor;
uniform sampler2D MeshDist;
uniform sampler2D GoldColor;
uniform vec3 CamFwd;
uniform vec3 CamUp;
uniform vec3 CamRight;
uniform vec3 EarthRel;
uniform vec3 MoonRel;
uniform vec3 EarthX;
uniform vec3 EarthY;
uniform vec3 EarthZ;
uniform vec3 SunDir;
uniform vec3 SunRelS;
uniform vec4 Planet[8];
uniform vec3 Ecliptic;
uniform vec3 SaturnPole;
uniform vec3 GalaxyN;
uniform vec3 ToCentre;
uniform vec3 MachX;
uniform vec3 MachY;
uniform vec3 MachZ;
uniform vec4 Moons[4];
uniform vec4 V0;
uniform vec4 V1;
uniform vec4 V2;
uniform vec4 V3;
uniform vec4 V4;
#define EARTH_WRONG
#include "space.glsl"
#include "title.glsl"
float _l0iOl() {
return V3.y;
}
vec3 _llOOl() {
return MachZ;
}
const vec3 _liOIl = vec3(0.93, 0.88, 1.0);
const vec3 _lOOIl = vec3(0.72, 0.56, 1.0);
const vec3 _lIOOl = vec3(1.0, 0.72, 0.92);
vec3 _l1OOl(vec3 n) {
return vec3(0.0);
}
vec3 _liOOl(vec3 p) {
return vec3(0.0);
}
float _lOOOl = 0.0;
vec3 _l0OOl(vec3 rd) {
vec3 c = EarthRel - MachZ * 620.0;
float t = rayPlane(vec3(0.0), rd, c, MachZ);
if (t <= 0.0) {
return vec3(0.0);
}
vec3 q = rd * t - c;
vec2 uv = vec2(dot(q, MachX), -dot(q, MachY)) / 1500.0 + vec2(0.39, 0.55);
float edge = smoothstep(0.0, 0.1, uv.x) * smoothstep(1.0, 0.9, uv.x) * smoothstep(0.0, 0.1, uv.y)
* smoothstep(1.0, 0.9, uv.y);
float _ll0Ol = log2(max(_lI0Ol * t / 1500.0 * 2048.0, 1e-3)) - 0.15 + 1.6 * _lOOOl;
vec3 _lOiOl = _l10Ol(textureLod(Nebula, uv, _ll0Ol).rgb);
return _lOiOl * vec3(0.92, 0.9, 1.08) * edge;
}
vec3 skyAt(vec3 rd) {
vec3 _liOll = cross(GalaxyN, ToCentre);
vec3 g = vec3(dot(rd, _liOll), dot(rd, GalaxyN), dot(rd, ToCentre));
vec3 col = _l10Ol(textureLod(MilkyWay, _li0Ol(g), _lO0Ol(_lI0Ol, 4096.0) + 2.0).rgb) * 1.4 * mix(0.3, 0.16, V1.w);
col += _l00Ol(rd, _lI0Ol, 0.55);
col += _l0OOl(rd) * 0.62;
return col;
}
vec4 _lll0l(vec3 rd, vec3 _lIl0l) {
int _l1l0l = _lil0l();
if (_l1l0l <= 0) return vec4(0.0);
float _lOl0l = 1e9;
int _l0l0l = -1;
vec3 _llI0l = vec3(0.0);
float _lII0l = 0.0;
float _l1I0l = 0.0;
for (int _liI0l = 0; _liI0l < _l1l0l; _liI0l++) {
if (TitleL[_liI0l * 4 + 2].w <= 0.0) continue;
float s = TitleL[_liI0l * 4].w;
vec3 lo;
vec3 _lOI0l;
_l0I0l(_liI0l, vec3(0.0), rd, lo, _lOI0l);
vec2 _ll10l = _lI10l(lo, _lOI0l, vec3(-0.6, -0.6, -0.3), vec3(4.6, 6.6, 0.3));
if (_ll10l.y < max(_ll10l.x, 0.0) || _ll10l.x * s > _lOl0l) continue;
float t = max(_ll10l.x, 0.0);
for (int i = 0; i < 40 + int(TitleA.w); i++) {
vec3 p = lo + _lOI0l * t;
float along;
float _l110l;
vec2 away;
vec2 _li10l;
float r = _lO10l(_liI0l, p.xy, along, _l110l, away, _li10l);
vec3 _l010l = _lli0l(vec2(r, p.z), vec2(0.34, 0.18));
float _lIi0l = max(_lI0Ol * t * 0.5, 0.003);
if (_l010l.x < _lIi0l) {
if (t * s < _lOl0l) {
_lOl0l = t * s;
_l0l0l = _liI0l;
_llI0l = _l1i0l(_liI0l, normalize(vec3(away * _l010l.y, _l010l.z)));
_lII0l = along;
_l1I0l = r;
}
break;
}
t += max(_l010l.x * 0.85, _lIi0l * 0.5);
if (t > _ll10l.y) break;
}
}
if (_l0l0l < 0) return vec4(0.0);
vec4 st = TitleL[_l0l0l * 4 + 3];
vec3 n = _llI0l;
vec3 v = -rd;
if (dot(n, v) < 0.0) n = -n;
vec3 h = normalize(SunDir + v);
float _lii0l = max(dot(n, SunDir), 0.0);
float _lOi0l = max(dot(n, h), 0.0);
float _l0i0l = 0.04 + 0.96 * pow(1.0 - max(dot(n, v), 0.0), 5.0);
vec3 col = vec3(0.03, 0.033, 0.04) * (0.25 + _lii0l) + _llO0l * pow(_lOi0l, 90.0) * 0.6 * _l0i0l + _lIl0l * 0.2 * _l0i0l;
float _lIO0l = 0.75 + 0.25 * sin(_lII0l * 2.4 + TitleB.x * 3.0 + st.w);
float core = exp(-_l1I0l / 0.045) * _lIO0l;
col += vec3(0.32, 0.6, 1.0) * core * 2.4;
col += vec3(0.75, 0.82, 1.0) * exp(-max(0.34 - _l1I0l, 0.0) / 0.018) * 0.35;
col += vec3(0.92, 0.9, 1.0) * st.x * 2.2;
return vec4(col, 1.0 - smoothstep(0.55, 1.0, st.y));
}
vec2 _l1O0l(vec3 p, float _liO0l) {
float z = max(dot(p, CamFwd), 1e-4);
return vec2(dot(p, CamRight), dot(p, CamUp)) / (z * _liO0l);
}
vec3 _lOO0l(vec2 s, float _liO0l) {
return normalize(CamFwd + (CamRight * s.x + CamUp * s.y) * _liO0l);
}
vec3 _l0O0l(vec2 s, vec2 e, float _liO1l, float _ll00l, float _liO0l) {
vec2 d = s - e;
float r = length(d);
float _lI00l = r / max(_liO1l, 1e-5);
float from = mix(_lI00l, max(_lI00l - 0.55 / max(_lI00l * _lI00l, 1e-3), 0.0), _ll00l);
vec2 _llIOl = e + (r > 1e-6 ? d / r : vec2(0.0)) * from * _liO1l;
return skyAt(_lOO0l(_llIOl, _liO0l));
}
void main() {
_l100l = V0.y;
_li00l = V0.z;
float _liO0l = V0.x;
_lI0Ol = 2.0 * _liO0l / OutSize.y;
gPix = _lI0Ol;
vec2 _lO00l = texCoord * 2.0 - 1.0;
float _l11ll = OutSize.x / OutSize.y;
vec2 _l000l = vec2(_lO00l.x * _l11ll, _lO00l.y);
float _ll00l = V1.w;
float _llllI = V1.x;
float _lIllI = V1.y;
float _l1llI = V4.x;
float r2 = dot(_l000l, _l000l);
vec2 s = _l000l * (1.0 + 0.04 * _l1llI * r2);
vec3 rd = _lOO0l(s, _liO0l);
_lOOOl = smoothstep(0.9, 1.75, length(_l000l));
float _lillI = max(dot(EarthRel, CamFwd), 1e-3);
vec2 e = _l1O0l(EarthRel, _liO0l);
float _liO1l = _llllI / (_lillI * _liO0l);
vec2 d = s - e;
float r = length(d);
float _lI00l = _llllI > 0.0 ? r / max(_liO1l, 1e-5) : 1e9;
float _l10ll = atan(d.y, d.x);
float _lOllI = 2.0 / OutSize.y / max(_liO1l, 1e-5);
float x = _lI00l - 1.0;
float _l0llI = _llllI > 0.0 ? smoothstep(0.0, 0.012, x) * (1.0 - smoothstep(0.3, 0.33, x)) : 0.0;
float _liOll = clamp(x / 0.32, 0.0, 1.0);
float _llIlI = fbm2(vec2(_l10ll * 6.0 + _li00l, _liOll * 2.5 - _lIllI * 0.35)) - 0.5;
float _l0i1l = -(sin(_liOll * PI) * 0.06 + _llIlI * 0.035) * _l0llI;
float _llO1l = 0.0;
if (_llllI > 0.0 && x > 0.3) {
for (int i = 0; i < 3; i++) {
float _l1Iil = float(i);
float _lIIlI = fract(_lIllI * 0.11 + _l1Iil * 0.37);
float _lOO1l = fbm2(vec2(_l10ll * 3.0 + _l1Iil * 5.1, _lIllI * 0.3 + _l1Iil * 2.0)) - 0.5;
float at = 0.345 + 0.045 * _l1Iil + 0.08 * _lIIlI + _lOO1l * 0.09;
float _l0O1l = (0.003 + _lOllI) * (0.45 + 1.2 * fbm2(vec2(_l10ll * 2.5 + _l1Iil * 3.7, _l1Iil)));
float g = exp(-sqr((x - at) / _l0O1l)) * (1.0 - _lIIlI) * smoothstep(0.0, 0.8, _lIllI);
_l0i1l += g * 0.012 * (0.5 + _lOO1l);
_llO1l += g * smoothstep(0.3, 0.62, fbm2(vec2(_l10ll * 5.0 + _l1Iil * 7.3, _lIllI * 0.2 + _l1Iil)));
}
}
_l0i1l *= _ll00l;
vec3 col;
if (_llllI <= 0.0) {
col = skyAt(rd);
} else if (_lI00l < 1.0) {
float _l1IlI = (1.0 - _lI00l) * 2.6 + _lIllI * 0.25;
vec2 q = vec2(cos(_l10ll + _l1IlI), sin(_l10ll + _l1IlI)) * _lI00l * _liO1l * 0.9;
vec3 _liill = skyAt(_lOO0l(e + q, _liO0l));
float lum = dot(_liill, vec3(0.3, 0.5, 0.2));
col = mix(vec3(lum), _liill, 0.3) * 0.01 * smoothstep(0.35, 0.98, _lI00l);
} else {
float _liIlI = exp(-sqr(x / 0.02)) + exp(-sqr((x - 0.31) / 0.02));
float _l1Ill = (0.012 * _liIlI * _l0llI + 0.004 * _llO1l) * _ll00l;
vec3 _lOIlI;
_lOIlI.r = _l0O0l(e + d * (1.0 + _l0i1l + _l1Ill), e, _liO1l, _ll00l, _liO0l).r;
_lOIlI.g = _l0O0l(e + d * (1.0 + _l0i1l), e, _liO1l, _ll00l, _liO0l).g;
_lOIlI.b = _l0O0l(e + d * (1.0 + _l0i1l - _l1Ill), e, _liO1l, _ll00l, _liO0l).b;
col = mix(_lOIlI, _lOIlI * vec3(0.68, 0.68, 0.86) + vec3(0.002, 0.002, 0.006), _l0llI * _ll00l);
float _l0IlI = fbm2(vec2(_l10ll * 3.0 + 11.0, _liOll * 4.0 + _llIlI * 2.2 - _lIllI * 0.15));
float _ll1lI = 0.25 + 0.75 * smoothstep(-0.2, 0.95, -cos(_l10ll + 0.5));
float _lI1lI = sin(_liOll * PI);
float _l11lI = exp(-sqr((x - 0.035) / 0.03));
col *= 1.0 - 0.5 * _l11lI * _ll00l;
float _li1lI = exp(-sqr((x - 0.078 - _llIlI * 0.012) / (0.0035 + _lOllI)));
col += _liOIl * _li1lI * 0.16 * smoothstep(0.35, 0.75, _l0IlI) * _ll00l;
float _lO1lI = fbm2(vec2(_l10ll * 26.0 + 5.0, _liOll * 30.0 + _l0IlI * 2.0 - _lIllI * 0.4));
float _l01lI = smoothstep(0.73, 0.86, _lO1lI) * _lI1lI;
col += _liOIl * _l01lI * _l0llI * 0.55 * _ll1lI * _ll00l;
float _llilI = exp(-sqr((x - 0.31 - _llIlI * 0.012) / (0.002 + _lOllI * 0.8)));
col += _liOIl * _llilI * 0.4 * (0.2 + 0.8 * smoothstep(0.3, 0.65, _l0IlI)) * _ll00l;
col += mix(_liOIl, _lOOIl, 0.4) * _llO1l * 0.07 * _ll00l;
float _lIilI = exp(-sqr((_lI00l - 1.5) / 0.28));
col *= mix(1.0, mix(0.5, 1.8, _lIilI), _ll00l * (1.0 - _l0llI));
}
col *= 1.0 - 0.55 * smoothstep(0.85, 1.7, r) * _ll00l;
vec4 title = _lll0l(rd, col);
col = mix(col, title.rgb, title.a);
float _l1ilI = _liilI;
for (int i = 0; i < 4; i++) {
vec3 c = Moons[i].xyz;
float R = Moons[i].w;
vec2 h = raySphere(vec3(0.0), rd, c, R);
if (h.x > 0.0 && h.x < _l1ilI) {
_l1ilI = h.x;
vec3 p = rd * h.x;
vec3 n = normalize(p - c);
vec2 uv = _li0Ol(vec3(dot(n, MachX), dot(n, MachY), dot(n, MachZ)));
vec3 _lOilI = i == 1 ? _l10Ol(textureLod(MoonColor, uv, 2.0).rgb)
: _l10Ol(textureLod(Planets, _l0ilI(i == 2 ? 3 : 0, uv), 1.0).rgb);
_lOilI = mix(vec3(dot(_lOilI, vec3(0.3, 0.55, 0.15))), _lOilI, 0.3);
vec3 _llOlI = normalize(EarthRel - c);
float _l00ll = max(dot(n, _llOlI), 0.0);
float _lIOlI = max(dot(n, SunDir), 0.0);
float _l1OlI = pow(1.0 - max(dot(n, -rd), 0.0), 4.0) * smoothstep(-0.2, 0.4, dot(n, _llOlI));
float _liOlI = smoothstep(-0.05, 0.25, dot(n, _llOlI));
col = _lOilI * (_liOIl * _l00ll * _liOlI * 1.4 * _ll00l + _llO0l * _lIOlI * mix(0.6, 0.05, _ll00l))
+ _liOIl * _l1OlI * 0.35 * _ll00l;
}
}
float _lOOlI = V2.z;
float _l0OlI = _lOOlI < 0.0 ? 1.0 : V3.z;
if (_l0OlI > 0.0 && _l0OlI < 1.0 && V3.x > 0.5 && texture(GoldColor, texCoord).a > 0.5) {
_l0OlI = 1.0;
}
vec3 ro = -EarthRel;
if (_l0OlI > 0.0) {
vec2 _lIiil = raySphere(ro, rd, vec3(0.0), 1.0);
float _ll0lI = _lIiil.x > 0.0 ? _lIiil.x : _liilI;
vec3 near = col;
if (_ll0lI < _l1ilI) {
near = _lI0lI(ro + rd * _ll0lI, rd, _ll0lI);
_l1ilI = _ll0lI;
}
vec3 through;
vec3 _l10lI = _li0lI(ro, rd, min(_ll0lI, _liilI), through);
col = mix(col, near * through + _l10lI, _l0OlI);
}
if (V3.x > 0.5) {
vec2 _lO0lI = texCoord;
if (abs(_l0i1l) > 1e-5) {
vec2 off = d * _l0i1l;
_lO0lI += vec2(off.x / _l11ll, off.y) * 0.5;
}
vec4 _l00lI = texture(MeshColor, _lO0lI);
float _lllII = texture(MeshDist, _lO0lI).r;
bool _lIlII = false;
if (_llllI > 0.0 && _lllII > 0.0) {
vec2 hs = raySphere(vec3(0.0), rd, EarthRel, _llllI);
_lIlII = hs.y > 0.0 && _lllII > hs.y;
}
if ((_lllII <= 0.0 || _lllII < _l1ilI) && !_lIlII) {
col = _l00lI.rgb + col * (1.0 - _l00lI.a);
}
}
if (_llllI > 0.0) {
float _l1lII = 0.75 + 0.5 * fbm2(vec2(_l10ll * 4.0 + 1.7, _lIllI * 0.4));
float _lilII = (_lOllI * 0.9 + 0.0005) * _l1lII;
float line = x >= 0.0 ? exp(-sqr(x / (_lilII * 1.3))) : exp(-sqr(x / (_lilII * 0.45)));
float _lOlII = x >= 0.0 ? exp(-x / (0.005 * _l1lII)) : 0.0;
float across = exp(-sqr(d.y / max(_liO1l * 0.33, 1e-4)));
float outward = smoothstep(-0.004, 0.03, x) * exp(-max(x - 0.03, 0.0) / 0.26);
float _l0lII = across * outward * (0.85 + 0.3 * fbm2(vec2(d.y / max(_liO1l, 1e-4) * 6.0, _lIllI * 0.3)));
vec3 glow = _liOIl * (line * 1.5 * _l1lII + _lOlII * 0.18) + mix(_lOOIl, _lIOOl, 0.5) * _l0lII * 1.1;
col += glow * _ll00l;
float _lO0Il = V1.z;
col += _liOIl * _lO0Il * (exp(-r / 0.035) * 2.5 + exp(-r / 0.25) * 0.4);
}
if (_l1llI > 0.001) {
vec2 _llIII = e * 0.6 + vec2(-0.02, 0.0);
float _lIIII = length(_l000l - _llIII);
float _l1III = 1.47;
float fade = smoothstep(_l1III - 0.38, _l1III + 0.08, _lIIII);
col *= mix(1.0, 0.22, fade * _l1llI);
float _liIII = atan(_l000l.y - _llIII.y, _l000l.x - _llIII.x);
float side = pow(max(cos(_liIII - 0.6), 0.0), 40.0) + 0.55 * pow(max(cos(_liIII + 2.45), 0.0), 120.0);
float k = (_lIIII - _l1III) / 0.011;
vec3 _lI1Il = vec3(exp(-sqr(k + 0.9)), exp(-sqr(k)), exp(-sqr(k - 0.9)));
vec3 _l0l1l = mix(vec3(exp(-sqr(k))), _lI1Il, 0.5) * vec3(1.0, 0.9, 0.86) * 0.7
+ vec3(0.9, 0.78, 0.95) * 0.3 * exp(-sqr((_lIIII - _l1III + 0.03) / 0.05));
col += _l0l1l * side * 0.6 * _l1llI;
}
col = 1.0 - exp(-col * 1.1);
col = pow(col, vec3(1.0 / 2.2));
float _lOIII = V2.y;
float _l0III = V0.w;
float _ll1II = sin(saturate(_lOIII) * PI);
vec3 _lI1II = col;
float _l11II = 1.0;
if (_l0III < 0.999 || _ll1II > 0.001) {
vec3 world = texture(DiffuseSampler, texCoord).rgb;
float rr = length(_l000l);
float aa = atan(_l000l.y, _l000l.x);
float _li1II = fbm2(vec2(aa * 2.5, log(rr + 0.03) * 2.2 - _lOIII * 7.0) + _li00l);
_l11II = smoothstep(_li1II - 0.12, _li1II + 0.12, _l0III * 1.35 - 0.2);
_lI1II = mix(world, col, _l11II);
float _lO1II = smoothstep(0.35, 0.8, fbm2(_l000l * 2.2 + vec2(0.0, -_lOIII * 5.0) + _li1II));
_lI1II = mix(_lI1II, vec3(0.92, 0.94, 1.0), _ll1II * (0.35 + 0.65 * _lO1II) * 0.95);
}
_lI1II += (hash12(texCoord * OutSize + fract(_l100l * 7.3) * 113.0) - 0.5) * 0.022 * _l1llI;
_lI1II = mix(_lI1II, vec3(1.0), V2.w);
fragColor = vec4(_lI1II, 1.0 - _l11II);
}