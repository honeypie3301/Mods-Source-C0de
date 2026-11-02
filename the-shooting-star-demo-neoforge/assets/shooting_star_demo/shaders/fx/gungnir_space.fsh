#include "star.glsl"
#include "title.glsl"
uniform sampler2D EarthDay;
uniform sampler2D EarthAux;
uniform sampler2D MoonColor;
uniform sampler2D MilkyWay;
uniform sampler2D Planets;
uniform sampler2D Rings;
uniform sampler2D Jupiter;
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
uniform vec3 JupRel;
uniform vec3 JupPole;
uniform vec3 JupX;
uniform vec3 JupZ;
uniform vec3 SunJ;
uniform vec3 NeedleJ;
uniform vec3 BreechJ;
uniform vec3 Heading;
uniform vec4 G0;
uniform vec4 G1;
uniform vec4 G2;
uniform vec4 G3;
uniform vec4 G4;
uniform vec4 G5;
#define CLOUD_CUT
#include "space.glsl"
const vec3 _lOl1I = vec3(1.0, 0.3, 0.06);
const vec3 _l0l1I = vec3(1.0, 0.62, 0.3);
vec3 _lOO0I(vec3 v) {
return vec3(dot(v, EarthX), dot(v, EarthY), dot(v, EarthZ));
}
vec3 _l1OOl(vec3 n) {
vec3 _l0O0I = _lOO0I(SiteN);
float near = length(n - _l0O0I);
vec3 col = vec3(0.0);
float _ll00I = max(G5.x, G5.z);
if (_ll00I > 0.001) {
float ring = exp(-sqr((near - 0.000031) / 0.000006));
col += _lOl1I * (exp(-near / 0.00012) * 5.0 + exp(-near / 0.004) * 0.3 + ring * 2.0) * _ll00I;
}
if (G5.w > 0.0 && G4.y > 0.001) {
float h = max(G5.w, 0.0004);
col += vec3(1.0, 0.62, 0.42) * G4.y * exp(-near / (h * 0.5)) * 0.8 * smoothstep(0.02, 0.006, h);
}
return col;
}
float _lI00I(vec3 n) {
if (G4.y < 0.001) return 1.0;
vec3 _l0O0I = _lOO0I(SiteN);
float d = length(n - _l0O0I);
float r = mix(0.001, 0.02, G4.y);
float _l100I = smoothstep(r * 0.7, r, d);
float _lIOII = exp(-sqr((d - r * 1.08) / (r * 0.12)));
return _l100I + _lIOII * 0.9;
}
vec3 _liOOl(vec3 p) {
return vec3(0.0);
}
vec3 _li00I(vec3 rd, vec3 h, float _lO00I, out float _l000I) {
float c = dot(rd, h);
float _ll01I = (c - _lO00I) / (1.0 - _lO00I * c);
vec3 _llll1 = rd - h * c;
float _lIll1 = length(_llll1);
_l000I = sqrt(max(1.0 - _lO00I * _lO00I, 1e-4)) / max(1.0 - _lO00I * c, 1e-3);
if (_lIll1 < 1e-5) return rd;
return h * _ll01I + _llll1 / _lIll1 * sqrt(max(1.0 - _ll01I * _ll01I, 0.0));
}
vec3 _l1ll1(vec3 col, float d) {
float _ll0ll = lum(col);
float s = log2(max(d, 1e-3));
vec3 _lill1 = _ll0ll * vec3(0.5, 0.72, 1.35);
vec3 red = _ll0ll * vec3(1.45, 0.5, 0.28);
col = mix(col, _lill1, saturate(s * 0.55));
col = mix(col, red, saturate(-s * 0.55));
return col * clamp(d * d * d, 0.03, 9.0);
}
vec3 sky(vec3 rd) {
float _lO00I = G2.w;
if (_lO00I < 0.001) {
return _lOll1(rd) + _l00Ol(rd, _lI0Ol, 0.5);
}
float d;
vec3 _llIOl = _li00I(rd, normalize(Heading), _lO00I, d);
vec3 col = _lOll1(_llIOl) * 0.9 + _l00Ol(_llIOl, _lI0Ol * mix(1.0, 0.6, _lO00I), 0.55);
return _l1ll1(col, d);
}
vec3 _l0ll1(vec3 v) {
return vec3(dot(v, JupX), dot(v, JupPole), dot(v, JupZ));
}
float _llIl1(vec3 p) {
float y = dot(p, JupPole);
float r = length(p - JupPole * y);
return length(vec2(r - G4.z, y));
}
vec3 _lIIl1(vec3 n, vec3 rd, float t) {
vec3 _l1Il1 = _l0ll1(n);
vec2 uv = _li0Ol(_l1Il1);
float _liIl1 = max(dot(n, -rd), 0.0);
float _l0l1l = _lI0Ol * t / max(_liIl1, 0.1);
float _ll0Ol = _lO0Ol(_l0l1l, 2048.0);
float _lOIl1 = G3.y;
vec3 _lOilI = vec3(0.0);
const int _l0Il1 = 9;
if (_lOIl1 > 0.002) {
for (int i = 0; i < _l0Il1; i++) {
float o = (float(i) / float(_l0Il1 - 1) - 0.5) * _lOIl1 / TAU;
_lOilI += _l10Ol(textureLod(Jupiter, uv + vec2(o, 0.0), _ll0Ol + 1.0).rgb);
}
_lOilI /= float(_l0Il1);
} else {
_lOilI = _l10Ol(textureLod(Jupiter, uv, _ll0Ol).rgb);
}
float detail = saturate(-_ll0Ol * 0.4 + 0.25);
float _ll1l1 = 0.0;
vec3 _lI1l1 = normalize(cross(JupPole, n) + vec3(1e-6));
vec3 _l11l1 = cross(n, _lI1l1);
if (detail > 0.0) {
float _li1l1 = asin(clamp(_l1Il1.y, -1.0, 1.0));
float _lO1l1 = atan(_l1Il1.z, _l1Il1.x);
vec2 q = vec2(_lO1l1 * cos(_li1l1), _li1l1) * 46.0 + vec2(_l100l * 0.02, 0.0);
vec2 w = vec2(fbm2(q * 1.2 + _li00l * 3.0), fbm2(q * 1.2 + vec2(5.2, 1.3)));
float _l01l1 = sin(q.y * 1.6 + w.y * 2.0) * 3.5;
vec2 r = q * vec2(0.55, 2.4) + vec2(_l01l1, 0.0) + (w - 0.5) * 3.2;
float c1 = fbm2(r);
float _llil1 = fbm2(r * 3.1 + w * 2.0 + 7.7);
float _lO1II = c1 * 0.62 + _llil1 * 0.38;
float _ll0ll = lum(_lOilI);
vec3 _lIil1 = _lOilI * 1.12 + vec3(0.03, 0.025, 0.015);
vec3 _l1il1 = _ll0ll * vec3(0.95, 0.66, 0.42);
vec3 _liil1 = _ll0ll * vec3(0.3, 0.33, 0.42);
vec3 _lOil1 = mix(_liil1, _l1il1, smoothstep(0.28, 0.46, _lO1II));
_lOil1 = mix(_lOil1, _lIil1, smoothstep(0.5, 0.7, _lO1II));
_lOilI = mix(_lOilI, _lOil1, detail * 0.85);
float e = 0.06;
vec2 _l0il1 = vec2(fbm2(r + vec2(e, 0.0)) - c1, fbm2(r + vec2(0.0, e)) - c1) / e;
vec2 _llOl1 = vec2(dot(SunJ, _lI1l1), dot(SunJ, _l11l1));
_ll1l1 = dot(_l0il1 * vec2(0.55, 2.4), _llOl1) * detail;
}
float _lIOl1 = dot(n, SunJ);
float day = max(_lIOl1, 0.0);
_lOilI = pow(_lOilI, vec3(1.18)) * vec3(1.02, 0.97, 0.9);
float _l0lll = 1.0 - smoothstep(0.1, 0.7, day);
float _l1Ol1 = max(day + _ll1l1 * (0.08 + 0.3 * _l0lll), 0.0);
vec3 col = _lOilI * _llO0l * 0.7 * smoothstep(-0.06, 0.25, _lIOl1) * (0.2 + 0.8 * _l1Ol1) * (0.45 + 0.55 * sqrt(_liIl1));
float up = dot(SunJ, JupPole);
if (abs(up) > 1e-3 && _lIOl1 > 0.0) {
float tt = -dot(n, JupPole) / up;
if (tt > 0.0) {
vec3 q = n + SunJ * tt;
float r = length(q);
float shadow = exp(-sqr((r - G4.z) / (G5.y * 1.6 + _lI0Ol * t * 0.8)));
col *= 1.0 - 0.85 * shadow;
}
}
if (G4.x > 0.001) {
float d = _llIl1(n);
float glow = 0.05 / (d * d + 0.004);
col += _l0IOI(0.35 + 0.7 * G4.x) * glow * G4.x * G4.x * 0.25 * (0.5 + 0.5 * _lOilI / max(lum(_lOilI), 1e-3));
}
float _liOl1 = 1.0 - smoothstep(-0.12, 0.05, _lIOl1);
if (G3.z > 0.001 && _liOl1 > 0.01) {
vec2 cell = floor(vec2(uv.x * 180.0, uv.y * 90.0));
float _lOOl1 = step(0.86, hash12(cell + _li00l * 17.0));
float _liIIl = floor(_l100l * 9.0 + hash12(cell) * 40.0);
float _lIl1I = step(0.9, hash12(cell + _liIIl * 3.7)) * _lOOl1;
vec2 f = fract(vec2(uv.x * 180.0, uv.y * 90.0)) - 0.5;
float _l0Ol1 = exp(-dot(f, f) * 9.0);
float _ll0l1 = exp(-sqr(_l1Il1.y / 0.28));
col += vec3(0.75, 0.85, 1.0) * _lIl1I * _l0Ol1 * _liOl1 * G3.z * (0.4 + 2.6 * _ll0l1) * 3.0;
col += vec3(0.35, 0.42, 0.7) * _liOl1 * G3.z * _ll0l1 * 0.02 * (0.5 + 0.5 * sin(_l100l * 23.0 + uv.x * 300.0));
}
if (G3.x >= 0.0) {
float a = acos(clamp(dot(n, BreechJ), -1.0, 1.0));
float s = G3.x;
float _l0I1l = s * 1.4;
float ring = exp(-sqr((a - _l0I1l) / (0.02 + 0.05 * s))) * exp(-s * 0.7);
float _lI0l1 = exp(-sqr((a - _l0I1l * 0.6) / (0.015 + 0.03 * s))) * exp(-s * 1.1) * 0.6;
col *= 1.0 + (ring + _lI0l1) * 2.2;
col += _l0l1I * exp(-a / 0.03) * exp(-s * 7.0) * 4.0 + vec3(1.0, 0.9, 0.8) * (ring + _lI0l1) * 0.2;
}
return col;
}
vec3 _l10l1(vec3 rd, vec3 c, float _l1ilI) {
float _li0l1 = dot(c, rd);
if (_li0l1 <= 0.0) return vec3(0.0);
vec3 closest = rd * _li0l1 - c;
float b = length(closest);
if (b < 1.0 || b > 1.08) return vec3(0.0);
vec3 n = closest / b;
float _l1iIl = smoothstep(-0.25, 0.3, dot(n, SunJ));
float _lO0l1 = exp(-(b - 1.0) / 0.006);
vec3 col = vec3(0.95, 0.78, 0.58) * _lO0l1 * _l1iIl * 0.9;
col += vec3(1.0, 0.7, 0.45) * _lO0l1 * sqr(sqr(max(dot(rd, SunJ), 0.0))) * 3.0;
return col;
}
vec3 _l00l1(float r, float z, float _l110l) {
float _lllI1 = sqrt(saturate(_l110l / 1.1));
float w = mix(0.07, 0.46, _lllI1);
float h = w * 0.62;
vec2 q = vec2(r, abs(z));
vec2 _lIiIl = normalize(vec2(h, w));
float d = dot(q - vec2(w, 0.0), _lIiIl);
return vec3(d, _lIiIl.x, _lIiIl.y * (z < 0.0 ? -1.0 : 1.0));
}
vec4 _lIlI1(vec3 rd, vec3 _lIl0l) {
int _l1l0l = _lil0l();
if (_l1l0l <= 0) return vec4(0.0);
float _lOl0l = 1e9;
int _l0l0l = -1;
vec3 _llI0l = vec3(0.0);
vec3 _l1lI1 = vec3(0.0);
float _lII0l = 0.0;
float _l1I0l = 0.0;
float _lilI1 = 0.0;
for (int _liI0l = 0; _liI0l < _l1l0l; _liI0l++) {
if (TitleL[_liI0l * 4 + 2].w <= 0.0) continue;
float s = TitleL[_liI0l * 4].w;
vec3 lo;
vec3 _lOI0l;
_l0I0l(_liI0l, vec3(0.0), rd, lo, _lOI0l);
vec2 _ll10l = _lI10l(lo, _lOI0l, vec3(-0.6, -0.6, -0.35), vec3(4.6, 6.6, 0.35));
if (_ll10l.y < max(_ll10l.x, 0.0) || _ll10l.x * s > _lOl0l) continue;
float t = max(_ll10l.x, 0.0);
for (int i = 0; i < 40 + int(TitleA.w); i++) {
vec3 p = lo + _lOI0l * t;
float along;
float _l110l;
vec2 away;
vec2 _li10l;
float r = _lO10l(_liI0l, p.xy, along, _l110l, away, _li10l);
vec3 _l010l = _l00l1(r, p.z, _l110l);
float _lIi0l = max(_lI0Ol * t * 0.5, 0.003);
if (_l010l.x < _lIi0l) {
if (t * s < _lOl0l) {
_lOl0l = t * s;
_l0l0l = _liI0l;
_llI0l = _l1i0l(_liI0l, normalize(vec3(away * _l010l.y, _l010l.z)));
_l1lI1 = p;
_lII0l = along;
_l1I0l = r;
_lilI1 = _l110l;
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
vec3 at = rd * _lOl0l;
vec3 _lIOlI = normalize(SunJ);
vec2 _ll1OI = raySphere(at, _lIOlI, JupRel, 1.0);
float _l1iIl = _ll1OI.y > 0.0 ? 0.0 : 1.0;
vec3 h = normalize(_lIOlI + v);
float _lii0l = max(dot(n, _lIOlI), 0.0);
float _lOi0l = max(dot(n, h), 0.0);
float _l0i0l = 0.04 + 0.96 * pow(1.0 - max(dot(n, v), 0.0), 5.0);
vec3 col = vec3(0.004, 0.0035, 0.0035) * _lii0l * _l1iIl;
col += vec3(1.0, 0.86, 0.7) * pow(_lOi0l, 220.0) * 40.0 * _l1iIl * _l0i0l;
vec3 _lOlI1 = normalize(JupRel - at);
col += vec3(0.9, 0.62, 0.38) * 0.006 * max(dot(n, _lOlI1), 0.0);
col += _lIl0l * 0.35 * _l0i0l;
float w = mix(0.07, 0.46, sqrt(saturate(_lilI1 / 1.1)));
float _liiOI = 0.55 + 0.45 * vnoise2(vec2(_lII0l * 3.0 + st.w, TitleB.x * 6.0));
float _l0lI1 = exp(-_l1I0l / 0.03) * _liiOI;
vec3 _l1IIl = vec3(1.0, 0.3, 0.05);
col += _l1IIl * _l0lI1 * (2.2 + TitleB.y * 3.0 + st.x * 4.0);
float edge = exp(-max(w - _l1I0l, 0.0) / 0.025);
col += _l1IIl * edge * (0.7 + TitleB.y * 1.2) * _liiOI;
float _lllOI = st.x * exp(-_l1I0l / 0.25);
col += mix(_l1IIl, vec3(1.0, 0.75, 0.4), _lllOI) * _lllOI * 3.0;
float _llII1 = vnoise2(_l1lI1.xy * 3.1 + float(_l0l0l) * 7.0) * 0.7 + vnoise2(_l1lI1.xy * 9.0) * 0.3;
float keep = 1.0 - smoothstep(_llII1 - 0.08, _llII1 + 0.02, st.y * 1.15);
col += _l1IIl * 4.0 * saturate(1.0 - abs(st.y * 1.15 - _llII1) / 0.08) * step(0.001, st.y);
return vec4(col, keep);
}
void main() {
_l100l = G0.y;
_li00l = G0.z;
float _liO0l = G0.x;
_lI0Ol = 2.0 * _liO0l / OutSize.y;
gPix = _lI0Ol;
vec2 _lO00l = texCoord * 2.0 - 1.0;
vec2 _l000l = vec2(_lO00l.x * OutSize.x / OutSize.y, _lO00l.y);
vec3 rd = normalize(CamFwd + (CamRight * _l000l.x + CamUp * _l000l.y) * _liO0l);
vec3 col = sky(rd);
if (G2.z > 0.001) {
float _l00iI = smoothstep(0.3, 0.65, dot(rd, normalize(Heading)));
col += _lIII1(rd, normalize(Heading), _l100l * mix(5.0, 12.0, G2.w), mix(1.6, 3.0, G2.w), _lI0Ol,
vec3(0.62, 0.78, 1.0), vec3(1.0, 0.8, 0.6)) * G2.z * _l00iI;
}
vec4 title = _lIlI1(rd, col);
col = mix(col, title.rgb, title.a);
float _l1ilI = _liilI;
vec3 _l1II1 = vec3(0.0);
bool _liII1 = G1.z > 0.5;
vec2 hs = _lOII1(SunRelS, G2.y) ? raySphere(vec3(0.0), rd, SunRelS, G2.y) : vec2(-1.0);
if (hs.x > 0.0) {
_l1ilI = hs.x;
_l1II1 = _l0II1(rd * hs.x, SunRelS, G2.y, rd, hs.x);
}
for (int i = 0; i < 8; i++) {
if (i == 2) continue;
if (i == 4 && _liII1) continue;
vec3 c = Planet[i].xyz;
float R = Planet[i].w;
vec2 h = _lOII1(c, R) ? raySphere(vec3(0.0), rd, c, R) : vec2(-1.0);
if (h.x > 0.0 && h.x < _l1ilI) {
_l1ilI = h.x;
_l1II1 = _ll1I1(i, rd * h.x, c, R, rd, h.x);
} else if (h.x <= 0.0) {
float d = length(rd - normalize(c));
float _l1iIl = 0.5 + 0.5 * dot(normalize(c - SunRelS), normalize(-c));
col += vec3(1.0, 0.95, 0.85) * _liO0I(d, _lI0Ol, 1.1) * (0.5 + _l1iIl) * 0.9;
}
}
if (_l1ilI < _liilI) {
col = mix(_l1II1, col, title.a);
}
vec4 ring = _lOII1(Planet[5].xyz, Planet[5].w * 2.3) ? _lI1I1(rd, Planet[5].xyz, Planet[5].w, _l1ilI) : vec4(0.0);
if (ring.a > 0.0) {
float _l0I1l = rayPlane(vec3(0.0), rd, Planet[5].xyz, SaturnPole);
col = mix(col, ring.rgb, ring.a * (_l0I1l < _l1ilI ? 1.0 : 0.0));
}
float _l11I1 = 1.0;
if (_liII1) {
vec3 _lO1il = normalize(SunRelS);
vec2 _lOi0I = raySphere(vec3(0.0), _lO1il, JupRel, 1.0);
if (_lOi0I.y > 0.0) {
float _li0l1 = dot(JupRel, _lO1il);
float b = length(_lO1il * _li0l1 - JupRel);
_l11I1 = smoothstep(0.985, 1.02, b);
}
}
col += _li1I1(rd, SunRelS, G2.y) * _l11I1 * (1.0 - title.a);
if (_liII1) {
vec2 _lOi0I = raySphere(vec3(0.0), rd, JupRel, 1.0);
float _lIOOI = _lOi0I.x > 0.0 ? _lOi0I.x : _liilI;
if (_lOi0I.x > 0.0) {
vec3 n = normalize(rd * _lOi0I.x - JupRel);
col = _lIIl1(n, rd, _lOi0I.x);
} else if (!_lOII1(JupRel, 1.0)) {
float d = length(rd - normalize(JupRel));
col += vec3(1.0, 0.9, 0.75) * _liO0I(d, _lI0Ol, 1.3) * 1.4;
}
col += _l10l1(rd, JupRel, _lIOOI);
}
if (G1.x > 0.001) {
vec3 ro = -EarthRel;
vec2 _lIiil = raySphere(ro, rd, vec3(0.0), 1.0);
vec2 _lO1I1 = _lOII1(MoonRel, G2.x) ? raySphere(vec3(0.0), rd, MoonRel, G2.x) : vec2(-1.0);
float _ll0lI = _lIiil.x > 0.0 ? _lIiil.x : _liilI;
float _l01I1 = _lO1I1.x > 0.0 ? _lO1I1.x : _liilI;
bool _lliI1 = _lOII1(EarthRel, 1.0);
vec3 near = col;
if (_l01I1 < _ll0lI) {
near = _lIiI1(rd * _l01I1, MoonRel, G2.x, rd, _l01I1);
} else if (_lIiil.x > 0.0 && _lliI1) {
near = _lI0lI(ro + rd * _ll0lI, rd, _ll0lI);
}
if (_lliI1) {
vec3 through;
vec3 _l10lI = _li0lI(ro, rd, min(_ll0lI, _l01I1), through);
float inside = 1.0 - smoothstep(0.004, 0.035, length(ro) - 1.0);
_l10lI *= 1.0 - 0.7 * inside;
through = mix(through, vec3(1.0), 0.6 * inside);
near = near * through + _l10lI;
} else {
float d = length(rd - normalize(EarthRel));
near += vec3(0.55, 0.75, 1.0) * _liO0I(d, _lI0Ol, 1.2) * 1.6;
}
col = mix(col, near, G1.x);
}
col = 1.0 - exp(-col * 1.1);
col = pow(col, vec3(1.0 / 2.2));
float _lOIII = G1.w;
float _l0III = G0.w;
float _ll1II = sin(saturate(_lOIII) * PI) * (1.0 - step(0.999, _lOIII)) * step(G4.w, 0.5);
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