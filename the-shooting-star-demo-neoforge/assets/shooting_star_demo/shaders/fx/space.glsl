vec3 _l1OOl(vec3 n);
vec3 _liOOl(vec3 p);
#ifdef CLOUD_CUT
float _lI00I(vec3 n);
#endif
#ifdef GROUND_TINT
vec2 _lIIO1(vec3 n, vec2 uv);
vec3 _l1IO1(vec3 n, vec3 _l11OI, inout float _liIO1, inout float _lOIO1);
float _l0IO1();
#endif
#ifdef EARTH_SMEAR
float _ll1O1();
#endif
#ifdef EARTH_WRONG
float _l0iOl();
vec3 _llOOl();
#endif
#ifndef SUN_REL
#define SUN_REL SunRelS
#endif
const float _lI1O1 = 1.045;
const float _l11O1 = 0.014;
const vec3 _llO0l = vec3(1.0, 0.96, 0.9) * 1.7;
const vec3 _li1O1 = vec3(0.0, 1.0, 0.0);
const float _liilI = 1e30;
float _lI0Ol = 0.0;
bool _lOII1(vec3 c, float R) {
return R > length(c) * _lI0Ol * 0.02;
}
vec3 _lO1O1(vec3 v) {
return vec3(dot(v, EarthX), dot(v, EarthY), dot(v, EarthZ));
}
void _l01O1(vec3 n, out vec3 _lI1l1, out vec3 _l11l1) {
_lI1l1 = vec3(n.z, 0.0, -n.x);
float _ll0ll = length(_lI1l1);
_lI1l1 = _ll0ll > 1e-4 ? _lI1l1 / _ll0ll : vec3(1.0, 0.0, 0.0);
_l11l1 = cross(n, _lI1l1);
}
vec3 _lI0lI(vec3 p, vec3 rd, float t) {
vec3 n = _lO1O1(normalize(p));
vec3 _lIOlI = _lO1O1(SunDir);
vec3 _lliO1 = _lO1O1(rd);
vec2 uv = _li0Ol(n);
#ifdef GROUND_TINT
uv = _lIIO1(n, uv);
#endif
#ifdef EARTH_WRONG
float _lIiO1 = _l0iOl();
if (_lIiO1 > 0.5) {
vec3 c = normalize(_lO1O1(_llOOl()));
vec3 _l11l1 = _li1O1 - c * c.y;
_l11l1 = dot(_l11l1, _l11l1) > 1e-6 ? normalize(_l11l1) : vec3(1.0, 0.0, 0.0);
uv = _li0Ol(n - 2.0 * dot(n, _l11l1) * _l11l1);
}
#endif
float _l0l1l = _lI0Ol * t / max(dot(-_lliO1, n), 0.1);
float _l1iO1 = _lO0Ol(_l0l1l, 4096.0);
float _liiO1 = _lO0Ol(_l0l1l, 2048.0);
vec3 _l11OI = _l10Ol(textureLod(EarthDay, uv, _l1iO1).rgb);
vec4 _lOiO1 = textureLod(EarthAux, uv, _liiO1);
float _llIO1 = _l100l * 0.0012;
#ifdef EARTH_WRONG
_llIO1 = _lIiO1 > 0.5 ? -_llIO1 : _llIO1;
#endif
float _lOIO1 = textureLod(EarthAux, uv + vec2(_llIO1, 0.0), _liiO1).g;
#ifdef EARTH_SMEAR
float _lOIl1 = _ll1O1();
if (_lOIl1 > 0.0005) {
vec3 _l0iO1 = _l11OI;
float _llOO1 = _lOIO1;
for (int i = 1; i < 6; i++) {
float o = _lOIl1 * (float(i) / 5.0 - 0.5) * 2.0;
_l0iO1 += _l10Ol(textureLod(EarthDay, uv + vec2(o, 0.0), _l1iO1 + 1.0).rgb);
_llOO1 += textureLod(EarthAux, uv + vec2(o * 1.3 + _llIO1, 0.0), _liiO1 + 1.0).g;
}
_l11OI = _l0iO1 / 6.0;
_lOIO1 = mix(_llOO1 / 6.0, sqr(_llOO1 / 6.0), saturate(_lOIl1 * 6.0));
}
#endif
float detail = saturate(-_liiO1 * 0.5);
if (detail > 0.0) {
vec2 _lIOO1 = uv * vec2(9000.0, 4500.0);
_l11OI *= mix(1.0, 0.75 + 0.5 * fbm2(_lIOO1 * 0.5), detail * 0.7);
_lOIO1 = saturate(_lOIO1 + (fbm2(_lIOO1 * 0.35 + _llIO1 * 900.0) - 0.5) * 0.7 * detail);
_lOiO1.r *= mix(1.0, sqr(vnoise2(_lIOO1 * 1.6)) * 2.2, detail);
}
#ifdef CLOUD_CUT
_lOIO1 *= _lI00I(n);
#endif
vec3 _lI1l1, _l11l1;
_l01O1(n, _lI1l1, _l11l1);
float _l1OO1 = max(exp2(_liiO1), 1.0) / 2048.0;
float _liOO1 = max(sqrt(1.0 - n.y * n.y), 0.05);
float _ll0II = textureLod(EarthAux, uv + vec2(_l1OO1, 0.0), _liiO1).b - textureLod(EarthAux, uv - vec2(_l1OO1, 0.0), _liiO1).b;
float _lOOO1 = textureLod(EarthAux, uv - vec2(0.0, _l1OO1 * 0.5), _liiO1).b - textureLod(EarthAux, uv + vec2(0.0, _l1OO1 * 0.5), _liiO1).b;
vec3 _l0OO1 = normalize(n - (_lI1l1 * _ll0II / _liOO1 + _l11l1 * _lOOO1 * 2.0) * (0.03 / (TAU * _l1OO1)));
float _ll0O1 = dot(n, _lIOlI);
float _l1iIl = smoothstep(-0.08, 0.25, _ll0O1);
float _lI0O1 = max(dot(_l0OO1, _lIOlI), 0.0) * smoothstep(-0.08, 0.1, _ll0O1);
float _l10O1 = exp(-_ll0O1 * _ll0O1 / 0.012);
vec3 _li0O1 = _llO0l * mix(vec3(1.0), vec3(1.0, 0.5, 0.25), _l10O1 * 0.8);
float _liIO1 = (1.0 - smoothstep(0.0, 0.03, _lOiO1.b)) * smoothstep(0.0, 0.04, _l11OI.b - _l11OI.r);
#ifdef GROUND_TINT
_l11OI = _l1IO1(n, _l11OI, _liIO1, _lOIO1);
#endif
vec3 h = normalize(_lIOlI - _lliO1);
float _lOi0l = max(dot(n, h), 0.0);
float _lO0O1 = pow(_lOi0l, 400.0) * 0.9 + pow(_lOi0l, 30.0) * 0.04;
float _l00O1 = pow(1.0 - max(dot(n, -_lliO1), 0.0), 5.0);
vec3 col = _l11OI * _lI0O1 * _li0O1 + _liIO1 * (_lO0O1 + _l00O1 * 0.2) * _li0O1 * _l1iIl;
float shadow = textureLod(EarthAux, uv + vec2(_llIO1, 0.0) - vec2(dot(_lIOlI, _lI1l1), -dot(_lIOlI, _l11l1)) * 0.004, _liiO1).g;
col *= 1.0 - shadow * 0.45 * _l1iIl;
col = mix(col, _li0O1 * (max(dot(n, _lIOlI), 0.0) * 0.9 + 0.015), _lOIO1 * 0.92);
float _liOl1 = 1.0 - smoothstep(-0.2, 0.04, _ll0O1);
#ifdef EARTH_WRONG
_liOl1 = mix(_liOl1, smoothstep(-0.04, 0.2, _ll0O1) * 3.0, saturate(_lIiO1));
#endif
#ifdef GROUND_TINT
_lOiO1.r *= _l0IO1();
#endif
col += vec3(1.0, 0.68, 0.3) * _lOiO1.r * _lOiO1.r * 3.2 * _liOl1 * (1.0 - _lOIO1 * 0.75);
col += (_l11OI + _lOIO1 * 0.3) * vec3(0.3, 0.42, 0.75) * 0.08 * _liOl1;
return col + _l1OOl(n);
}
vec3 _li0lI(vec3 ro, vec3 rd, float _lll01, out vec3 through) {
through = vec3(1.0);
vec2 _lIl01 = raySphere(ro, rd, vec3(0.0), _lI1O1);
if (_lIl01.y <= 0.0) return vec3(0.0);
float t0 = max(_lIl01.x, 0.0);
float t1 = min(_lIl01.y, _lll01);
if (t1 <= t0) return vec3(0.0);
const int _lOI0I = 12;
int _lllOl = _lOI0I + LOOP_ZERO;
float _l0I0I = (t1 - t0) / float(_lllOl);
vec3 _l1l01 = vec3(0.12, 0.32, 1.0) * 30.0;
float _lil01 = 6.0;
float _liIl1 = dot(rd, SunDir);
float _lOl01 = 0.75 * (1.0 + _liIl1 * _liIl1);
float g = 0.8;
float _l0l01 = (1.0 - g * g) / pow(1.0 + g * g - 2.0 * g * _liIl1, 1.5) * 0.08;
vec3 _li11l = vec3(0.0);
vec3 depth = vec3(0.0);
for (int i = 0; i < _lllOl; i++) {
vec3 p = ro + rd * (t0 + _l0I0I * (float(i) + 0.5));
float r = length(p);
float _lO0i1 = exp(-(r - 1.0) / _l11O1);
depth += (_l1l01 + _lil01) * _lO0i1 * _l0I0I;
float _ll0O1 = dot(p / r, SunDir);
vec3 _llI01 = exp(-(_l1l01 + _lil01) * _l11O1 * 0.9 / max(_ll0O1 + 0.18, 0.03) * _lO0i1 * 0.35);
float _ll1OI = smoothstep(-0.16, 0.02, _ll0O1);
_li11l += _lO0i1 * _l0I0I * exp(-depth) * _llI01 * _ll1OI * (_l1l01 * _lOl01 + _lil01 * _l0l01) * _llO0l * 0.6;
_li11l += _lO0i1 * _l0I0I * exp(-depth) * _liOOl(p);
}
through = exp(-depth * 0.7);
return _li11l;
}
vec3 _lIiI1(vec3 p, vec3 c, float R, vec3 rd, float t) {
vec3 n = normalize(p - c);
vec3 _lII01 = normalize(EarthRel - c);
vec3 _l1I01 = normalize(cross(abs(_lII01.y) < 0.95 ? _li1O1 : vec3(1.0, 0.0, 0.0), _lII01));
vec3 _liI01 = cross(_lII01, _l1I01);
vec2 uv = _li0Ol(vec3(dot(n, _l1I01), dot(n, _liI01), dot(n, _lII01)));
float _l0l1l = _lI0Ol * t / (R * max(dot(-rd, n), 0.1));
vec3 _l11OI = _l10Ol(textureLod(MoonColor, uv, _lO0Ol(_l0l1l, 4096.0)).rgb);
float _lIOl1 = max(dot(n, SunDir), 0.0);
float _lOI01 = max(dot(n, -rd), 0.05);
return _l11OI * _llO0l * 0.62 * mix(_lIOl1, _lIOl1 / (_lIOl1 + _lOI01) * 2.0, 0.4);
}
vec2 _l0ilI(int i, vec2 uv) {
float col = float(i - (i / 2) * 2);
float row = float(i / 2);
return vec2((col + clamp(uv.x, 0.001, 0.999)) * 0.5, (row + clamp(uv.y, 0.002, 0.998)) * 0.25);
}
vec3 _l0II1(vec3 p, vec3 c, float R, vec3 rd, float t) {
vec3 n = normalize(p - c);
vec3 ax, ay;
facing(Ecliptic, ax, ay);
vec2 uv = _li0Ol(vec3(dot(n, ax), dot(n, Ecliptic), dot(n, ay))) + vec2(_l100l * 0.004, 0.0);
float _ll0Ol = _lO0Ol(_lI0Ol * t / (R * max(dot(-rd, n), 0.1)), 1024.0);
vec3 _lOilI = _l10Ol(textureLod(Planets, _l0ilI(2, uv), _ll0Ol).rgb);
float _liIl1 = max(dot(n, -rd), 0.0);
return (_lOilI * 1.6 + vec3(0.3, 0.16, 0.05)) * (0.3 + 0.7 * sqrt(_liIl1)) * 70.0;
}
vec3 _li1I1(vec3 rd, vec3 c, float R) {
float dist = length(c);
vec3 _lIIll = c / dist;
float _l0I01 = dot(rd, _lIIll);
if (_l0I01 <= 0.0) return vec3(0.0);
float _l10ll = sqrt(max(2.0 - 2.0 * _l0I01, 0.0));
float ar = max(R / dist, _lI0Ol * 1.5);
float _ll101 = exp(-(_l10ll - ar) / (ar * 1.2)) * step(ar, _l10ll);
float bloom = ar * ar / (_l10ll * _l10ll + ar * ar) * 0.9;
float _l0lII = 0.0;
float _lI101 = dot(_lIIll, CamFwd);
float _l1101 = dot(rd, CamFwd);
if (_lI101 > 0.05 && _l1101 > 0.05) {
vec2 off = vec2(dot(rd, CamRight), dot(rd, CamUp)) / _l1101 - vec2(dot(_lIIll, CamRight), dot(_lIIll, CamUp)) / _lI101;
_l0lII = exp(-abs(off.y) / (_lI0Ol * 1.6)) * exp(-abs(off.x) / 0.35) * min(ar / _lI0Ol, 30.0) * 0.02
* smoothstep(0.05, 0.5, _lI101);
}
return vec3(1.0, 0.86, 0.66) * (_ll101 * 3.0 + bloom * 4.0) + vec3(1.0, 0.6, 0.45) * _l0lII;
}
vec3 _ll1I1(int i, vec3 p, vec3 c, float R, vec3 rd, float t) {
vec3 n = normalize(p - c);
vec3 _li101 = i == 5 ? SaturnPole : Ecliptic;
vec3 ax, ay;
facing(_li101, ax, ay);
vec2 uv = _li0Ol(vec3(dot(n, ax), dot(n, _li101), dot(n, ay))) + vec2(_l100l * 0.006 * float(i + 1), 0.0);
float _ll0Ol = _lO0Ol(_lI0Ol * t / (R * max(dot(-rd, n), 0.1)), 1024.0);
vec3 _lOilI = _l10Ol(textureLod(Planets, _l0ilI(i, uv), _ll0Ol).rgb);
vec3 _llI01 = normalize(SUN_REL - c);
float _lIOl1 = dot(n, _llI01);
vec3 col = _lOilI * _llO0l * max(_lIOl1, 0.0) * 1.1 + _lOilI * 0.003;
float edge = 1.0 - max(dot(n, -rd), 0.0);
float _lIOII = edge * edge * edge * smoothstep(-0.1, 0.4, _lIOl1);
float _lO101 = sqr(sqr(max(dot(rd, _llI01), 0.0)));
float _lIii1 = sqr(sqr(edge)) * (0.25 + _lO101 * 8.0) * smoothstep(-0.6, 0.1, _lIOl1);
return col + _lOilI * _lIOII * 0.4 + (_lOilI * 0.6 + vec3(0.9, 0.7, 0.45)) * _lIii1;
}
vec4 _lI1I1(vec3 rd, vec3 c, float R, float _l0iOI) {
float t = rayPlane(vec3(0.0), rd, c, SaturnPole);
if (t <= 0.0 || t > _l0iOI) return vec4(0.0);
vec3 q = rd * t - c;
float r = length(q) / R;
if (r < 1.24 || r > 2.27) return vec4(0.0);
float s = (r - 1.24) / (2.27 - 1.24);
vec3 _lOilI = _l10Ol(textureLod(Rings, vec2(s, 0.5), log2(max(_lI0Ol * t / R * 400.0 / max(abs(dot(rd, SaturnPole)), 0.05), 1e-3))).rgb);
float a = saturate(max(_lOilI.r, max(_lOilI.g, _lOilI.b)) * 2.2);
vec3 _llI01 = normalize(SUN_REL - c);
vec2 _lIIOI = raySphere(q + c, _llI01, c, R);
float _l1iIl = _lIIOI.y > 0.0 ? 0.05 : 1.0;
float _l0101 = sqr(sqr(max(dot(rd, _llI01), 0.0)));
return vec4(_lOilI / max(a, 0.05) * _llO0l * _l1iIl * (1.2 + 7.0 * _l0101), a);
}
vec3 _lli01(vec3 rd, float _l0iOI) {
float t = rayPlane(vec3(0.0), rd, SunRelS, Ecliptic);
if (t <= 0.0 || t > _l0iOI) return vec3(0.0);
float r = length(rd * t - SunRelS);
float w = _lI0Ol * t / max(abs(dot(rd, Ecliptic)), 0.06);
vec3 col = vec3(0.0);
for (int i = 0; i < 8; i++) {
float R = length(Planet[i].xyz - SunRelS);
float d = abs(r - R) / w;
float line = saturate(1.1 - d) + 0.18 * exp(-d / 2.5);
col += vec3(1.0) * (i == 2 ? 0.32 : 0.2) * line;
}
return col;
}
vec3 _lOll1(vec3 rd) {
vec3 _liOll = cross(GalaxyN, ToCentre);
vec3 g = vec3(dot(rd, _liOll), dot(rd, GalaxyN), dot(rd, ToCentre));
return _l10Ol(textureLod(MilkyWay, _li0Ol(g), _lO0Ol(_lI0Ol, 4096.0)).rgb) * 1.4 + vec3(0.003, 0.005, 0.012);
}