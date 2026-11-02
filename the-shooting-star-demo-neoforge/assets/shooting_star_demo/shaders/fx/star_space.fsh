#include "star.glsl"
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
uniform vec3 SiteRel;
uniform vec3 EarthX;
uniform vec3 EarthY;
uniform vec3 EarthZ;
uniform vec3 SunDir;
uniform vec3 SunRelS;
uniform vec4 Planet[8];
uniform vec3 Ecliptic;
uniform vec3 SaturnPole;
uniform vec3 CentreRel;
uniform vec3 SunRelG;
uniform vec3 GalaxyN;
uniform vec3 ToCentre;
uniform vec3 GunRel;
uniform vec3 ThreadRel;
uniform vec4 S0;
uniform vec4 S1;
uniform vec4 S2;
uniform vec4 S3;
uniform vec4 S4;
uniform vec4 S5;
#include "space.glsl"
vec3 _l1OOl(vec3 n) {
vec3 _l0O0I = vec3(dot(_li1O1, EarthX), dot(_li1O1, EarthY), dot(_li1O1, EarthZ));
float near = length(n - _l0O0I);
return _lIi01 * (exp(-near / 0.0009) * 2.5 + exp(-near / 0.012) * 0.35)
+ mix(_l1i01, vec3(1.0), 0.4) * exp(-near / (0.004 + 0.03 * S3.z)) * S3.z * 6.0;
}
vec3 _liOOl(vec3 p) {
float _l00Oi = 0.0035 + 0.02 * S3.z;
float along = dot(p, _li1O1);
float off = length(p - _li1O1 * along);
float column = step(1.0, along) * exp(-sqr(off / _l00Oi));
return column * (_lIi01 * 40.0 * S3.w + mix(_lIi01, _l1i01, 0.5) * S3.z * 900.0);
}
vec3 _lll0i() {
return S4.w > 1.5 ? SunRelG : ThreadRel / max(length(ThreadRel), 1e-30);
}
float _lIl0i(vec3 rd, vec3 _l0O0I, float from, out float tRay) {
float height = max(dot(-_l0O0I, _li1O1), 1e-6);
vec3 a = _l0O0I + _li1O1 * height * from;
float d = raySegmentDist(vec3(0.0), rd, a, _l0O0I + _li1O1 * min(height * 4000.0, S4.x), tRay);
return tRay > 0.0 ? d / tRay : 10.0;
}
vec3 _l1l0i(vec3 rd) {
vec3 _l0O0I = _lll0i();
float tRay;
float _l10ll = _lIl0i(rd, _l0O0I, 0.0, tRay);
float core = saturate(1.15 - _l10ll / (_lI0Ol * 0.85));
float glow = exp(-_l10ll / (_lI0Ol * 4.0)) * 0.35 + exp(-_l10ll / (_lI0Ol * 18.0)) * 0.06;
float _liiOI = 0.85 + 0.15 * sin(_l100l * 37.0) * sin(_l100l * 23.0 + 1.0);
float _lOIli = length(rd - _l0O0I / length(_l0O0I));
vec3 col = _lIi01 * (core * 3.5 + glow) * _liiOI + _l1i01 * core * 0.6;
col += (_lIi01 * _liO0I(_lOIli, _lI0Ol, 1.6) * 2.4 + vec3(1.0, 0.6, 0.6) * exp(-sqr(_lOIli / (_lI0Ol * 0.7))) * 0.5)
* (0.8 + 0.2 * sin(_l100l * 9.0));
return col * S3.w;
}
vec3 beam(vec3 rd) {
vec3 _l0O0I = _lll0i();
float tRay;
float _l10ll = _lIl0i(rd, _l0O0I, 0.62, tRay);
float core = saturate(1.0 - _l10ll / (_lI0Ol * 1.1));
float _l010I = exp(-_l10ll / (_lI0Ol * 2.2)) * 1.2 + exp(-_l10ll / (_lI0Ol * 16.0)) * 0.12;
float height = max(dot(-_l0O0I, _li1O1), 1e-6);
vec3 _li0OI = normalize(_l0O0I + _li1O1 * height * 0.62);
float _l1ii1 = length(rd - _li0OI);
vec3 col = _lIi01 * (_l010I * 3.0 + core * 3.0) + vec3(1.0, 0.9, 0.9) * core * 4.0;
vec3 _l0iI1 = rd - _li0OI * dot(rd, _li0OI);
float _ll0II = dot(_l0iI1, CamRight);
float _lOOO1 = dot(_l0iI1, CamUp);
float _lI1Ol = exp(-abs(_lOOO1) / (_lI0Ol * 1.1)) * exp(-abs(_ll0II) / 0.35) + exp(-abs(_ll0II) / (_lI0Ol * 1.1)) * exp(-abs(_lOOO1) / 0.12);
col += vec3(1.0, 0.92, 0.92) * _liO0I(_l1ii1, _lI0Ol, 2.4) * 6.0 + _lIi01 * (_liO0I(_l1ii1, _lI0Ol, 9.0) * 1.2 + _lI1Ol * 0.9);
return col;
}
vec3 _lil0i(vec3 rd) {
vec3 g = normalize(GunRel);
if (dot(rd, g) <= 0.0) return vec3(0.0);
float d = length(rd - g);
float _lOl0i = 0.35 + 0.65 * step(0.45, fract(_l100l * 1.2));
vec3 off = rd - g * dot(rd, g);
float _lilll = dot(off, CamRight);
float _l0l0i = dot(off, CamUp);
float _lI1Ol = exp(-abs(_l0l0i) / (_lI0Ol * 1.1)) * exp(-abs(_lilll) / (_lI0Ol * 38.0))
+ exp(-abs(_lilll) / (_lI0Ol * 1.1)) * exp(-abs(_l0l0i) / (_lI0Ol * 22.0));
return (_lIi01 * (_liO0I(d, _lI0Ol, 2.4) * 3.0 + _lI1Ol * 0.7) * _lOl0i + vec3(1.0, 0.85, 0.85) * _liO0I(d, _lI0Ol, 0.9) * 2.4)
* S3.y;
}
const vec3 _llI0i = vec3(1.0, 0.97, 0.975);
const vec3 _lII0i = vec3(0.9, 0.58, 0.63);
const vec3 _lII1I = vec3(0.3, 0.0, 0.035);
const vec3 _l1I0i = vec3(0.07, 0.0, 0.012);
vec3 _liI0i(float v) {
vec3 col = mix(_llI0i, _lII0i, smoothstep(0.24, 0.42, v) * 0.8);
col = mix(col, _lII1I, smoothstep(0.4, 0.58, v));
return mix(col, _l1I0i, smoothstep(0.7, 0.88, v) * 0.85);
}
float _lOI0i(vec2 _l000l, vec2 _lll1i, float t, out float _l0I0i) {
vec2 d = _l000l - _lll1i;
float r = length(d);
float a = atan(d.x, -d.y);
a += 0.03 * sin(r * 2.4 + t * 5.0);
float along = r * 1.7 - t * 9.0;
float across = a * 9.0;
float strokes = fbm2(vec2(across * 3.4, along * 0.3) + _li00l);
float _ll10i = fbm2(vec2(across * 2.6, along * 2.0) + 41.0 + _li00l);
float _lIOO1 = fbm2(vec2(across * 12.0, along * 0.45) + 17.0);
_l0I0i = fbm2(vec2(across * 3.0, along * 0.4) + 5.0);
return strokes + (_ll10i - 0.48) * 0.55 + (_lIOO1 - 0.48) * 0.35;
}
float _lI10i(vec2 q) {
float r2 = dot(q, q);
if (r2 >= 1.0) return 0.0;
vec3 n = CamRight * q.x + CamUp * q.y - CamFwd * sqrt(1.0 - r2);
vec2 uv = _li0Ol(_lO1O1(n));
vec3 _l11OI = textureLod(EarthDay, uv, 3.5).rgb;
float _lOIO1 = textureLod(EarthAux, uv + vec2(_l100l * 0.0012, 0.0), 3.5).g;
float _l11li = 1.0 - smoothstep(0.0, 0.07, _l11OI.b - _l11OI.r);
float _liOl1 = smoothstep(0.12, -0.2, dot(n, SunDir));
return saturate(0.3 + _l11li * 0.5 + _liOl1 * 0.45 - _lOIO1 * 0.6);
}
vec4 _l110i(vec2 p, vec2 c, float R, float t) {
vec2 d = (p - c) / R;
float r = length(d);
if (r > 1.14) return vec4(0.0);
vec2 _lIIll = r > 1e-4 ? d / r : vec2(0.0, 1.0);
float _l0Oll = 0.0;
for (int i = 0; i < 8; i++) {
_l0Oll += _lI10i(d - _lIIll * float(i) * 0.03 * (0.25 + r));
}
_l0Oll /= 8.0;
float a = atan(d.x, -d.y);
float _l0lII = fbm2(vec2(a * 40.0, r * 2.2 - t * 12.0) + _li00l);
float _li10i = fbm2(vec2(a * 18.0, r * 9.0 - t * 20.0) + 13.0);
_l0Oll = saturate(_l0Oll + ((_l0lII - 0.5) * 0.6 + (_li10i - 0.5) * 0.3) * smoothstep(0.05, 0.8, r));
vec3 col = _liI0i(_l0Oll);
float _lIOII = smoothstep(0.035, 0.0, abs(r - 1.0) - 0.012);
col = mix(col, _l1I0i, _lIOII);
float _lI1lI = 1.0 - smoothstep(0.995, 1.005, r);
float _l10lI = smoothstep(1.14, 1.0, r) * (1.0 - _lI1lI);
return vec4(mix(col, _lII0i, _l10lI * (1.0 - _lI1lI) * 0.6), max(_lI1lI, max(_lIOII, _l10lI * 0.6)));
}
vec3 _lO10i(vec3 col, vec2 p, vec2 _l010i, float k) {
vec2 from = vec2(-2.6, -1.6);
vec2 _lIIll = normalize(from - _l010i);
vec2 _li0OI = _l010i + _lIIll * mix(0.42, 0.035, smoothstep(0.0, 1.0, k));
float d = sdSegment2(p, _li0OI, from);
float _l1lll = 2.0 / OutSize.y;
col = mix(col, _l1I0i, 1.0 - smoothstep(_l1lll * 4.0, _l1lll * 5.2, d));
col = mix(col, vec3(1.0, 0.1, 0.14), 1.0 - smoothstep(_l1lll * 2.4, _l1lll * 3.3, d));
col = mix(col, vec3(1.0, 0.96, 0.96), 1.0 - smoothstep(_l1lll * 0.6, _l1lll * 1.3, d));
vec2 g = p - _li0OI;
float _li1i1 = 0.8 + 0.2 * sin(_l100l * 60.0);
float _lll0I = (0.1 + 0.18 * k) * _li1i1;
float star = exp(-abs(g.y) / (_l1lll * 1.2)) * exp(-abs(g.x) / _lll0I) + exp(-abs(g.x) / (_l1lll * 1.2)) * exp(-abs(g.y) / _lll0I);
float core = exp(-dot(g, g) / sqr(_l1lll * 5.0));
col = mix(col, vec3(1.0, 0.1, 0.14), saturate(star * 1.5));
return mix(col, vec3(1.0), saturate(core * 1.6));
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
float _lli0i = S2.y;
float inside = 1.0 - S1.w;
vec3 col = _lOll1(rd) * inside;
col += _l00Ol(rd, _lI0Ol, inside * 0.45 + 0.2 * (1.0 - _lli0i));
col += _l1O01(rd, _lI0Ol) * (1.0 - inside) * (1.0 - 0.6 * _lli0i);
if (S2.x > 0.001) {
vec3 _l0O01 = _lli0i > 0.5 ? -_li1O1 : normalize(GunRel);
float _ll001 = _l100l * (_lli0i > 0.5 ? 11.0 : 2.2);
vec3 _lI001 = _lli0i > 0.5 ? vec3(1.0, 0.16, 0.2) : vec3(0.75, 0.82, 1.0);
vec3 _l1001 = _lli0i > 0.5 ? vec3(1.0, 0.9, 0.88) : vec3(1.0, 0.85, 0.65);
col += _lIII1(rd, _l0O01, _ll001, _lli0i > 0.5 ? 2.6 : 0.05, _lI0Ol, _lI001, _l1001) * S2.x * (_lli0i > 0.5 ? 0.9 : 0.7);
}
float _lIO0I;
float _lIi0i;
vec3 _l001i = _l0lli(rd, CentreRel, GalaxyN, ToCentre, 60.0, MilkyTop, _lI0Ol, _liilI, _lIO0I, _lIi0i);
float _l1i0i = S1.z * S1.w;
float _l1l0I;
float _lil0I = rayPointDist(vec3(0.0), rd, CentreRel, _l1l0I);
float _lllii = _l1l0I > 0.0 ? exp(-sqr(_lil0I / 4.5)) : 0.0;
col = col * (1.0 - _lIO0I * 0.85 * _l1i0i) + (_l001i * 0.62 + vec3(1.0, 0.82, 0.55) * _lllii * 0.22) * _l1i0i;
float _lii0i = length(rd - normalize(SunRelG));
col += vec3(1.0, 0.9, 0.75) * _liO0I(_lii0i, _lI0Ol, 1.3) * 3.0 * S1.z;
col += _lil0i(rd);
float _l1ilI = _liilI;
vec3 _l1II1 = vec3(0.0);
bool _lOi0i = length(SunRelS) < 4000.0;
vec2 hs = _lOi0i && _lOII1(SunRelS, S3.x) ? raySphere(vec3(0.0), rd, SunRelS, S3.x) : vec2(-1.0);
if (hs.x > 0.0) {
_l1ilI = hs.x;
_l1II1 = _l0II1(rd * hs.x, SunRelS, S3.x, rd, hs.x);
}
for (int i = 0; i < 8; i++) {
if (!_lOi0i) break;
if (i == 2) continue;
vec3 c = Planet[i].xyz;
float R = Planet[i].w;
vec2 h = _lOII1(c, R) ? raySphere(vec3(0.0), rd, c, R) : vec2(-1.0);
if (h.x > 0.0 && h.x < _l1ilI) {
_l1ilI = h.x;
_l1II1 = _ll1I1(i, rd * h.x, c, R, rd, h.x);
} else if (h.x <= 0.0) {
float d = length(rd - normalize(c));
float _l1iIl = 0.5 + 0.5 * dot(normalize(c - SunRelS), normalize(-c));
col += vec3(1.0, 0.95, 0.85) * _liO0I(d, _lI0Ol, 1.1) * (0.5 + _l1iIl) * 0.9 * (1.0 - S1.x);
}
}
if (_lOi0i) {
float _l0i0i = length(rd - normalize(Planet[2].xyz));
col += vec3(0.55, 0.75, 1.0) * _liO0I(_l0i0i, _lI0Ol, 1.2) * 1.4 * (1.0 - S1.x);
}
if (_l1ilI < _liilI) {
col = _l1II1;
}
vec4 ring = _lOi0i && _lOII1(Planet[5].xyz, Planet[5].w * 2.3) ? _lI1I1(rd, Planet[5].xyz, Planet[5].w, _l1ilI)
: vec4(0.0);
if (ring.a > 0.0) {
float _l0I1l = rayPlane(vec3(0.0), rd, Planet[5].xyz, SaturnPole);
col = mix(col, ring.rgb, ring.a * (_l0I1l < _l1ilI ? 1.0 : 0.0));
}
if (S1.y > 0.001 && _lOi0i) {
col += _lli01(rd, _l1ilI) * S1.y;
}
if (_lOi0i) {
col += _li1I1(rd, SunRelS, S3.x) * (1.0 - S1.x * 0.9);
}
if (S1.x > 0.001) {
vec3 ro = -EarthRel;
vec2 _lIiil = raySphere(ro, rd, vec3(0.0), 1.0);
vec2 _lO1I1 = raySphere(vec3(0.0), rd, MoonRel, S2.w);
float _ll0lI = _lIiil.x > 0.0 ? _lIiil.x : _liilI;
float _l01I1 = _lO1I1.x > 0.0 ? _lO1I1.x : _liilI;
vec3 near = col;
if (_l01I1 < _ll0lI) {
near = _lIiI1(rd * _l01I1, MoonRel, S2.w, rd, _l01I1);
} else if (_ll0lI < _liilI) {
near = _lI0lI(ro + rd * _ll0lI, rd, _ll0lI);
}
vec3 through;
vec3 _l10lI = _li0lI(ro, rd, min(_ll0lI, _l01I1), through);
near = near * through + _l10lI;
col = mix(col, near, S1.x);
}
col += _lli0i > 0.5 ? beam(rd) : _l1l0i(rd);
if (_lli0i > 0.5) {
float edge = smoothstep(0.9, 1.7, length(_l000l));
col += _lIi01 * edge * 0.4 * S3.z;
}
col = 1.0 - exp(-col * 1.1);
col = pow(col, vec3(1.0 / 2.2));
float _lOIII = S2.z;
float _l0III = S0.w;
float _ll1II = sin(saturate(_lOIII) * PI) * (1.0 - _lli0i);
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
if (S4.z > 0.001) {
float t = floor(_l100l * 12.0) / 12.0;
vec2 _llO0i = (vec2(hash11(t * 7.13), hash11(t * 3.31)) - 0.5) * 0.014;
vec2 p = _l000l + _llO0i;
float dist = max(length(EarthRel), 1.0001);
float R = tan(asin(1.0 / dist)) / _liO0l;
vec4 _lIO0i = _l110i(p, vec2(0.0), R, t);
float _l0I0i;
vec3 _l1O0i = _lIO0i.rgb;
if (_lIO0i.a < 0.999) {
_l1O0i = mix(_liI0i(_lOI0i(p, vec2(0.0), t, _l0I0i)), _lIO0i.rgb, _lIO0i.a);
} else {
vec2 d = p;
_l0I0i = fbm2(vec2(atan(d.x, -d.y) * 27.0, (length(d) * 1.7 - t * 9.0) * 0.4) + 5.0);
}
_l1O0i = _lO10i(_l1O0i, p, vec2(0.0), S5.x);
float _liO0i = smoothstep(_l0I0i - 0.1, _l0I0i + 0.1, S4.z * 1.25 - 0.1);
_lI1II = mix(_lI1II, _l1O0i, _liO0i);
}
fragColor = vec4(_lI1II, 1.0 - _l11II);
}