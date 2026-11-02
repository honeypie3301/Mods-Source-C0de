uniform vec4 P4;
uniform vec4 P5;
uniform vec4 P6;
uniform vec4 P7;
uniform sampler2D MeshDist;
uniform sampler2D GoldColor;
uniform vec3 CamFwd;
uniform vec3 CamUp;
uniform vec3 CamRight;
uniform vec4 V0;
const float _llOIl = 0.975;
const float _lIOIl = 6.0;
const float _l1OIl = 1080.0;
const vec3 _liOIl = vec3(0.93, 0.88, 1.0);
const vec3 _lOOIl = vec3(0.72, 0.56, 1.0);
vec3 _l0OIl(vec2 p) {
vec2 s = vec2((p.x * 2.0 - 1.0) * OutSize.x / OutSize.y, p.y * 2.0 - 1.0);
return normalize(CamFwd + (CamRight * s.x + CamUp * s.y) * V0.x);
}
float _ll0Il(vec2 p) {
float d = texture(MeshDist, p).r;
return d > 0.0 ? d : FAR;
}
vec3 _lI0Il(vec3 c) {
float z = dot(c, CamFwd);
vec2 s = vec2(dot(c, CamRight), dot(c, CamUp)) / (max(z, 1e-4) * V0.x);
return vec3(s.x * OutSize.y / OutSize.x * 0.5 + 0.5, s.y * 0.5 + 0.5, z);
}
vec3 _l10Il(vec2 p) {
vec4 g = texture(GoldColor, p);
float keep = 1.0 - V0.z;
return g.rgb * keep + texture(DiffuseSampler, p).rgb * (1.0 - g.a * keep);
}
vec3 _li0Il(float d, float _lO0Il, float _l00Il) {
vec3 h = mix(vec3(1.0, 1.0, 0.97), vec3(1.0, 0.94, 0.6), smoothstep(0.06, 0.12, d));
h = mix(h, vec3(1.0, 0.85, 0.29), smoothstep(0.11, 0.2, d));
h = mix(h, vec3(1.0, 0.7, 0.18), smoothstep(0.19, 0.28, d));
h = mix(h, vec3(0.91, 0.56, 0.12), smoothstep(0.27, 0.36, d));
h = mix(h, vec3(0.6, 0.3, 0.07), smoothstep(0.35, 0.45, d));
h = mix(h, vec3(0.25, 0.11, 0.03), smoothstep(0.44, 0.56, d));
h = mix(h, vec3(0.0), smoothstep(0.54, 0.68, d));
vec3 p = mix(vec3(1.0), vec3(1.0, 0.97, 0.75), smoothstep(0.08, 0.14, d));
p = mix(p, vec3(1.0, 0.89, 0.36), smoothstep(0.18, 0.34, d));
p = mix(p, vec3(0.9, 0.65, 0.25), smoothstep(0.3, 0.45, d));
p = mix(p, vec3(0.4, 0.25, 0.08), smoothstep(0.42, 0.6, d));
p = mix(p, vec3(0.0), smoothstep(0.58, 0.78, d));
vec3 s = mix(vec3(1.0), vec3(1.0, 0.95, 0.78), smoothstep(0.06, 0.12, d));
s = mix(s, vec3(0.95, 0.8, 0.5), smoothstep(0.2, 0.4, d));
s = mix(s, vec3(0.5, 0.38, 0.2), smoothstep(0.38, 0.55, d));
s = mix(s, vec3(0.0), smoothstep(0.52, 0.75, d));
return mix(h, mix(p, s, _l00Il), _lO0Il);
}
vec3 _lll1l(vec3 rd, float _lIl1l, vec3 c, vec3 n, float _l1l1l) {
if (_lIl1l < 0.5 || _l1l1l <= 1e-3) {
return vec3(0.0);
}
float _lil1l = dot(rd, n);
if (abs(_lil1l) < 1e-4) {
return vec3(0.0);
}
float t = dot(c, n) / _lil1l;
if (t <= 0.0) {
return vec3(0.0);
}
vec3 p = rd * t - c;
float r = length(p);
float x = (r - P4.w) / max(P5.y, 1e-3);
if (abs(x) >= 1.0) {
return vec3(0.0);
}
vec3 _lOl1l = -c - n * dot(-c, n);
float side = dot(p / max(r, 1e-5), normalize(_lOl1l + vec3(1e-5)));
float _l0l1l = smoothstep(-0.15, 0.45, side);
float _llIIl = 0.375 + 0.375 * x;
vec3 _llI1l = clamp(abs(fract(_llIIl + vec3(0.0, 2.0 / 3.0, 1.0 / 3.0)) * 6.0 - 3.0) - 1.0, 0.0, 1.0);
return mix(_llI1l, vec3(1.0), 0.15) * (1.0 - x * x) * _l0l1l * _l1l1l;
}
vec3 _lII1l(vec2 p, vec2 core, float _l1Ill, float _l1l1l) {
vec3 s;
if (_l1Ill > 1e-5) {
vec2 _l1I1l = p - core;
s = vec3(_l10Il(core + _l1I1l * (1.0 + _l1Ill)).r, _l10Il(p).g, _l10Il(core + _l1I1l * (1.0 - _l1Ill)).b);
} else {
s = _l10Il(p);
}
if (_l1l1l < 1e-3) {
return s;
}
float _lIl1l = step(FAR * 0.5, _ll0Il(p));
vec3 on = _lll1l(_l0OIl(p), _lIl1l, P0.xyz, normalize(P4.xyz), _l1l1l);
return s + on * (vec3(1.0) - clamp(s, 0.0, 1.0));
}
float _liI1l(float a) {
if (a < 1.5) {
return 0.15 * smoothstep(0.4, 1.5, a);
}
if (a < 3.0) {
return mix(0.15, 0.16, (a - 1.5) / 1.5);
}
if (a < 4.5) {
return mix(0.16, 0.1, (a - 3.0) / 1.5);
}
if (a < 6.0) {
return 0.1;
}
if (a < 7.5) {
return mix(0.1, 0.07, (a - 6.0) / 1.5);
}
if (a < 9.0) {
return mix(0.07, 0.065, (a - 7.5) / 1.5);
}
if (a < 10.5) {
return mix(0.065, 0.05, (a - 9.0) / 1.5);
}
if (a < 12.0) {
return mix(0.05, 0.035, (a - 10.5) / 1.5);
}
if (a < 13.5) {
return mix(0.035, 0.03, (a - 12.0) / 1.5);
}
if (a < 15.0) {
return mix(0.03, 0.015, (a - 13.5) / 1.5);
}
if (a < 16.5) {
return mix(0.015, 0.008, (a - 15.0) / 1.5);
}
return mix(0.008, 0.0, clamp((a - 16.5) / 1.5, 0.0, 1.0));
}
float _lOI1l(vec2 p, float _l0I1l) {
return step(_l0I1l, _ll0Il(p));
}
float _ll11l(float _l10ll, float seed, float _lI11l, float _l111l) {
float _li11l = 0.0;
for (int k = 0; k < 7; k++) {
float _lO11l = float(k);
float _l011l = (_lO11l - 3.0) * 0.32;
float at = _lI11l + _l011l + (hash11(seed + _lO11l * 7.13) - 0.5) * 0.25 + 0.006 * _l111l * (hash11(seed + _lO11l * 1.9) - 0.5);
float d = _l10ll - at;
d = d - TAU * floor((d + PI) / TAU);
float w = 0.09 + 0.08 * hash11(seed + _lO11l * 3.71);
float g = 0.5 + 0.5 * hash11(seed + _lO11l * 5.27);
g *= 0.87 + 0.13 * sin(_l111l * 0.45 + _lO11l * 2.1);
_li11l += g * exp(-d * d / (w * w));
}
return 0.06 + min(_li11l, 1.0);
}
vec3 _lli1l(float _ll0ll) {
vec3 c = mix(vec3(0.0), vec3(0.02, 0.04, 0.2), smoothstep(0.0, 0.06, _ll0ll));
c = mix(c, vec3(0.07, 0.28, 0.9), smoothstep(0.06, 0.25, _ll0ll));
c = mix(c, vec3(0.18, 0.55, 1.0), smoothstep(0.25, 0.5, _ll0ll));
c = mix(c, vec3(0.58, 0.9, 1.0), smoothstep(0.5, 0.75, _ll0ll));
c = mix(c, vec3(0.88, 0.96, 1.0), smoothstep(0.75, 1.0, _ll0ll));
return mix(c, vec3(1.0), smoothstep(1.0, 1.3, _ll0ll));
}
void main() {
vec2 uv = texCoord;
vec2 _lIi1l = vec2(OutSize.x / OutSize.y, 1.0);
float _l1i1l = P0.w;
vec3 _lii1l = _lI0Il(P0.xyz);
vec2 core = _lii1l.xy;
float _l111l = P1.w;
vec2 dd = (uv - core) * _lIi1l;
float dist = length(dd);
vec2 _lOi1l = dist > 1e-6 ? dd / dist : vec2(0.0);
float _l10ll = atan(_lOi1l.y, _lOi1l.x);
float _l0i1l = 0.0;
float _llO1l = 0.0;
if (_lii1l.z > 0.0) {
for (int k = 0; k < 3; k++) {
float _lIO1l = k == 0 ? P6.x : (k == 1 ? P6.y : P6.z);
float _l1O1l = k == 0 ? P7.x : (k == 1 ? P7.y : P7.z);
if (_l1O1l <= 1e-3 || _lIO1l <= 0.0) {
continue;
}
float _lO11l = float(k);
float _liO1l = _lIO1l / (_lii1l.z * V0.x) * 0.5;
float _lOO1l = fbm2(vec2(_l10ll * 3.0 + _lO11l * 5.1, _l111l * 0.12 + _lO11l * 2.0)) - 0.5;
float _l0O1l = (_liO1l * 0.02 + 2.0 / OutSize.y) * (0.6 + 1.1 * fbm2(vec2(_l10ll * 2.5 + _lO11l * 3.7, _lO11l)));
float g = exp(-sqr((dist - _liO1l * (1.0 + _lOO1l * 0.05)) / _l0O1l)) * _l1O1l;
_l0i1l += g * 0.012 * (0.5 + _lOO1l);
_llO1l += g * smoothstep(0.3, 0.62, fbm2(vec2(_l10ll * 5.0 + _lO11l * 7.3, _l111l * 0.08 + _lO11l)));
}
}
vec2 _llill = core + (uv - core) * (1.0 + _l0i1l);
vec3 col;
if (_l1i1l <= 0.001 || _lii1l.z <= 0.0 || P1.y <= 0.0) {
col = _l10Il(_llill);
} else {
vec2 _ll01l = _lI0Il(P0.xyz + CamRight * P1.x).xy;
vec2 _lI01l = _lI0Il(P0.xyz + CamRight * P1.y).xy;
float _l101l = max(length((_ll01l - core) * _lIi1l), 1e-4);
float _li01l = max(length((_lI01l - core) * _lIi1l), 1e-4);
float seed = P2.w;
float _lO01l = min(_l1i1l, 1.0);
float _l001l = _li01l / 0.75;
float _lllil = dist / _l001l;
float _lIlil = _l001l * (0.25 + 2.8 * (1.0 - exp(-max(_l111l - 1.2, 0.0) / 3.0)));
float _l1lil = 0.005 * smoothstep(1.8, 3.0, _l111l) * (1.0 - smoothstep(4.5, 6.5, _l111l)) * _lO01l;
float _lilil = _l001l * 0.14;
float _lOlil = (dist - _lIlil) / _lilil;
float ring = exp(-_lOlil * _lOlil);
_llill -= _lOi1l / _lIi1l * _l1lil * _lOlil * ring;
float _l0lil = _liI1l(_l111l) * _lO01l * 0.4;
float _llIil = 1.0 - smoothstep(4.5, 7.5, _l111l);
float _l1Ill = P2.y;
float _l1l1l = P5.x;
vec3 base;
if (_l0lil > 1e-4) {
vec3 _li1ll = vec3(0.0);
vec3 _lIIil = vec3(0.0);
vec2 _l1I1l = _llill - core;
for (int i = 0; i < 4; i++) {
float _l1Iil = float(i);
vec3 _liIil = i == 0 ? vec3(1.0) : (i == 1 ? vec3(1.0, 0.35, 0.35) : (i == 2 ? vec3(0.4, 1.0, 0.45) : vec3(0.45, 0.55, 1.0)));
_liIil = mix(vec3(1.0), _liIil, _llIil * 0.35);
_li1ll += _lII1l(core + _l1I1l * (1.0 - _l0lil * _l1Iil / 3.0), core, _l1Ill, _l1l1l) * _liIil;
_lIIil += _liIil;
}
base = _li1ll / _lIIil;
} else {
base = _lII1l(_llill, core, _l1Ill, _l1l1l);
}
float _l0I1l = length(P0.xyz) - P1.x * 0.6;
float _lOIil = max(_l101l / (_l001l * 0.18), 1.0);
float _l0Iil = 1.0 - 0.15 * smoothstep(13.0, 33.0, _l111l) * P3.y;
float _ll1il = _lllil / (_l0Iil * (1.0 + (_lOIil - 1.0) * (1.0 - smoothstep(0.15, 0.6, _lllil))));
float _lI1il = 0.1 * sin(3.0 * _l10ll + seed + 0.04 * _l111l) + 0.07 * sin(5.0 * _l10ll + seed * 1.7 - 0.03 * _l111l)
+ 0.05 * sin(2.0 * _l10ll + seed * 2.3);
_ll1il *= 1.0 - _lI1il * smoothstep(0.02, 0.12, _lllil) * (1.0 - smoothstep(0.25, 0.5, _lllil));
float _lO0Il = P2.x;
float _l00Il = smoothstep(3.4, 4.2, _l111l) * (1.0 - smoothstep(5.0, 7.0, _l111l));
float _l11il = _lOI1l(uv, _l0I1l);
float _li1il = min(_l1i1l, 1.1);
vec2 _lO1il = vec2(cos(P5.w), sin(P5.w));
float _l01il = dot(dd, _lO1il) / (_l001l * 0.36);
float _lliil = dot(dd, vec2(-_lO1il.y, _lO1il.x)) / (_l001l * (dot(dd, vec2(-_lO1il.y, _lO1il.x)) < 0.0 ? 0.27 : 0.2));
float _lIiil = sqrt(_l01il * _l01il + _lliil * _lliil);
vec3 _l1iil = mix(vec3(0.9, 0.62, 0.28), vec3(0.75, 0.45, 0.18), smoothstep(0.0, 0.5, _lIiil));
_l1iil = mix(_l1iil, vec3(0.5, 0.27, 0.1), smoothstep(0.5, 1.0, _lIiil));
_l1iil = mix(_l1iil, vec3(0.25, 0.12, 0.05), smoothstep(1.0, 1.6, _lIiil));
_l1iil *= (1.0 - smoothstep(1.5, 2.2, _lIiil)) * _lO01l * 0.55 * (1.0 - 0.45 * P2.x);
vec3 _liiil;
if (_l11il < 0.5) {
float _lOiil = 0.0;
float _l0iil = 0.0;
if (_ll1il < 1.6) {
float _llOil = 0.0;
float ts = 0.0;
float _lIOil = 0.0;
vec2 _l1Oil = vec2(0.0);
for (int _liOil = 0; _liOil < 16; _liOil++) {
float _lOOil = float(_liOil);
float rr = sqrt((_lOOil + 0.5) / 16.0);
float _l0Oil = _lOOil * 2.39996323 + seed;
vec2 _ll0il = vec2(cos(_l0Oil), sin(_l0Oil));
float side = max(1.0 + 0.9 * dot(_ll0il, -_lOi1l), 0.0);
float _lI0il = exp(-2.0 * rr * rr) * side;
float _l10il = _lOI1l(uv + _ll0il * rr * 0.004 / _lIi1l, _l0I1l);
_llOil += _l10il * _lI0il;
_l1Oil += _l10il * _ll0il;
_lIOil += _lI0il;
ts += _lOI1l(uv + _ll0il * rr * 0.012 / _lIi1l, _l0I1l) * _lI0il;
}
float fade = 1.0 - smoothstep(0.5, 1.5, _ll1il);
float facing = smoothstep(0.0, 0.4, dot(_l1Oil / max(length(_l1Oil), 1e-4), -_lOi1l));
_lOiil = _llOil / max(_lIOil, 1e-4) * fade * facing;
_l0iil = ts / max(_lIOil, 1e-4) * fade * mix(0.3, 1.0, facing);
}
_liiil = (_li0Il(_ll1il * 0.45, _lO0Il, _l00Il) * _lOiil + _li0Il(_ll1il, _lO0Il, _l00Il) * _l0iil * 0.9) * _li1il + _l1iil * 0.08;
} else if (_ll0Il(uv) >= FAR * 0.5) {
_liiil = max(_li0Il(_ll1il, _lO0Il, _l00Il) * _li1il, _l1iil);
} else {
_liiil = max(_li0Il(_ll1il, _lO0Il, _l00Il) * _li1il * 0.15, _l1iil * 0.12);
}
col = base + _liiil * (vec3(1.0) - clamp(base, 0.0, 1.0));
float _li0il = _l11il;
float _lO0il = 0.0;
float _l00il = max(P1.z, 1.0);
float _lil1l = dist / _li01l;
if (_lil1l < _l00il && dist > 1e-5) {
int _lllOl = int(P3.x);
float _lIlOl = max(float(_lllOl), 1.0);
vec2 _l1lOl = uv * OutSize;
float _lI1ll = fract(52.9829189 * fract(dot(_l1lOl, vec2(0.06711056, 0.00583715)) + _l111l * 0.0173 + fract(seed)));
float _li1ll = 0.0;
float _l01ll = 0.0;
float _lilOl = 1.0;
for (int i = 0; i < 96; i++) {
if (i >= _lllOl) {
break;
}
float t = (float(i) + _lI1ll) / _lIlOl;
float r = dist * (1.0 - t);
vec2 sp = core + _lOi1l * r / _lIi1l;
float _lOlOl = r / _li01l;
float _l0lOl = r / (_l101l * 1.6);
float _llIOl = exp(-_l0lOl * _l0lOl);
float _lIIOl = _lOlOl < 1.0 ? _lOI1l(sp, _l0I1l) : 1.0;
_li1ll += _llIOl * _lIIOl * _lilOl;
_l01ll += _llIOl * _lilOl;
_lilOl *= _llOIl;
}
float _l1IOl = _l01ll > 1e-6 ? _li1ll / _l01ll : 0.0;
float _liIOl = 1.0 - smoothstep(_l00il * 0.5, _l00il, _lil1l);
_lO0il = _lIOIl * _l01ll / _lIlOl * _liIOl * mix(0.05, 1.0, smoothstep(0.2, 0.85, _l1IOl));
_lO0il *= _ll11l(_l10ll, seed, P3.w, _l111l) * P2.z * smoothstep(0.1, 0.22, _lllil) * 3.0;
}
vec3 _lOIOl = mix(vec3(1.0, 0.82, 0.42), vec3(1.0, 0.58, 0.18), smoothstep(0.3, 1.6, _lil1l));
vec3 s = clamp(_lOIOl * (_lO0il * _l1i1l * mix(0.2, 1.0, _l11il)), 0.0, 1.0);
col += s * (vec3(1.0) - clamp(col, 0.0, 1.0));
float _l0IOl = dot(dd, _lO1il) / _l001l;
float _ll1Ol = dot(dd, vec2(-_lO1il.y, _lO1il.x)) * _l1OIl;
float _lI1Ol = exp(-abs(_ll1Ol) / 2.0) * exp(-abs(_l0IOl) / 0.6) * smoothstep(0.05, 0.12, _lllil) * _lO01l * 0.5;
col += vec3(1.0, 0.95, 0.8) * _lI1Ol * (vec3(1.0) - clamp(col, 0.0, 1.0));
if (_lO0Il > 1e-4) {
float bloom = _lO0Il * (0.08 * exp(-dist / (_li01l * 0.35)) + mix(0.03, 0.12, _l00Il) * exp(-sqr(dist / (_li01l * 1.6))));
vec3 _l11Ol = mix(vec3(1.0, 0.94, 0.75), vec3(1.0, 0.82, 0.48), smoothstep(0.0, 1.2, _lil1l));
col += (vec3(1.0) - exp(-_l11Ol * bloom)) * mix(0.2, 1.0, _li0il) * (vec3(1.0) - clamp(col, 0.0, 1.0));
}
if (_l1lil > 1e-4) {
col += vec3(1.0, 0.86, 0.6) * ring * _l1lil * 7.0 * (vec3(1.0) - clamp(col, 0.0, 1.0));
}
float _li1Ol = smoothstep(1.6, 2.9, _l111l) * (_l111l < 3.0 ? 1.0 : exp(-(_l111l - 3.0) / 3.0)) * (1.0 - smoothstep(6.5, 9.0, _l111l)) * _lO01l;
if (_li1Ol > 1e-3) {
vec2 at = core * _lIi1l + (_lO1il * 1.3 + vec2(_lO1il.y, -_lO1il.x) * 1.25) * _l001l;
vec2 _lO1Ol = uv * _lIi1l - at;
float _l01Ol = exp(-dot(_lO1Ol, _lO1Ol) / (2.0 * sqr(_l001l * 0.8)));
col += vec3(1.0, 0.88, 0.6) * _l01Ol * _li1Ol * 0.75 * _l11il * (vec3(1.0) - clamp(col, 0.0, 1.0));
}
float lift = P3.z;
if (lift > 1e-4) {
col += vec3(0.18, 0.125, 0.05) * lift * exp(-dist / (_li01l * 3.0));
}
float _lliOl = exp(-sqr(dist / (_l001l * 1.5)));
col *= vec3(1.0 + 0.12 * _lliOl, 1.0, 1.0 - 0.1 * _lliOl);
}
col += mix(_liOIl, _lOOIl, 0.4) * _llO1l * 0.18 * (vec3(1.0) - clamp(col, 0.0, 1.0));
col = mix(col, _lli1l(lum(col)), V0.y);
col += (hash12(gl_FragCoord.xy) + hash12(gl_FragCoord.yx + 17.0) - 1.0) / 255.0;
fragColor = vec4(col, 1.0);
}