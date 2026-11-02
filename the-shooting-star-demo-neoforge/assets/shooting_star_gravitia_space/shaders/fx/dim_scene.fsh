#include "dim_common.glsl"
const vec3 _llI1lI = vec3(1.4, 1.4, 2.4);
const vec3 _lII1lI = vec3(3.6, 3.6, 6.0);
const float _l1I1lI = 11.0;
const float _liI1lI = 240.0;
const float _lIOIlI = 2.42;
vec4 _lOI1lI(vec3 c, out vec3 lo, out vec3 hi) {
lo = vec3(0.0);
hi = vec3(0.0);
vec3 q = c + vec3(P0.w * 17.0, P0.w * 31.0, P0.w * 7.0);
float r = length(c.xy);
if (r < 0.5 || (c.z + 1.0) * _llI1lI.z < P3.w + 0.3) {
return vec4(-1.0);
}
float _liiiO = hash13(q);
float _l0I1lI = r < 3.5 ? 0.2 : 0.08;
if (_liiiO > _l0I1lI) {
return vec4(-1.0);
}
vec3 _ll11lI = vec3(hash13(q + 1.7), hash13(q + 4.1), hash13(q + 9.3));
vec3 _lI11lI = vec3(hash13(q + 13.1), hash13(q + 21.7), hash13(q + 27.3));
float shape = hash13(q + 33.3);
vec3 size = vec3(mix(0.4, 0.85, _ll11lI.x));
size.y *= mix(0.8, 1.2, _ll11lI.y);
size.z = size.x * _llI1lI.x / _llI1lI.z * mix(0.85, 1.3, _ll11lI.z);
vec3 _l111lI = vec3(c.x - 0.5, c.y - 0.5, c.z) * _llI1lI;
lo = _l111lI + (vec3(1.0) - size) * _llI1lI * _lI11lI;
hi = lo + size * _llI1lI;
return vec4(_liiiO / _l0I1lI, shape, hash13(q + 41.9), 1.0);
}
bool _li11lI(vec3 ro, vec3 rd, out float _llO0I, out vec3 _lO11lI, out vec3 _l011lI, out vec3 _lli1lI, out vec4 kind) {
_llO0I = _liI1lI;
_lO11lI = vec3(0.0, 0.0, -1.0);
_l011lI = vec3(0.0);
_lli1lI = vec3(0.0);
kind = vec4(0.0);
vec3 off = vec3(0.5 * _llI1lI.x, 0.5 * _llI1lI.y, 0.0);
vec3 g = (ro + off) / _llI1lI;
vec3 cell = floor(g);
vec3 _lIi1lI = rd / _llI1lI;
_lIi1lI = mix(_lIi1lI, vec3(1.0e-6), vec3(lessThan(abs(_lIi1lI), vec3(1.0e-6))));
vec3 stp = sign(_lIi1lI);
vec3 inv = 1.0 / abs(_lIi1lI);
vec3 _l1i1lI = (stp * (cell - g) + max(stp, vec3(0.0))) * inv;
vec3 _lii1lI = 1.0 / mix(rd, vec3(1.0e-6), vec3(lessThan(abs(rd), vec3(1.0e-6))));
for (int i = 0; i < 120; i++) {
vec3 lo;
vec3 hi;
vec4 k = _lOI1lI(cell, lo, hi);
if (k.w > 0.0) {
vec3 _lI0i1 = (lo - ro) * _lii1lI;
vec3 _l1l0I = (hi - ro) * _lii1lI;
vec3 _lOi1lI = min(_lI0i1, _l1l0I);
vec3 _l0i1lI = max(_lI0i1, _l1l0I);
float tn = max(max(_lOi1lI.x, _lOi1lI.y), _lOi1lI.z);
float tf = min(min(_l0i1lI.x, _l0i1lI.y), _l0i1lI.z);
if (tn < tf && tn > 0.0) {
_llO0I = tn;
if (_lOi1lI.x >= _lOi1lI.y && _lOi1lI.x >= _lOi1lI.z) {
_lO11lI = vec3(-stp.x, 0.0, 0.0);
} else if (_lOi1lI.y >= _lOi1lI.z) {
_lO11lI = vec3(0.0, -stp.y, 0.0);
} else {
_lO11lI = vec3(0.0, 0.0, -stp.z);
}
_l011lI = lo;
_lli1lI = hi;
kind = k;
return true;
}
}
float _l1lOO = min(_l1i1lI.x, min(_l1i1lI.y, _l1i1lI.z));
if (_l1lOO > _liI1lI) {
break;
}
vec3 _l00II = vec3(lessThanEqual(_l1i1lI, vec3(_l1lOO)));
cell += stp * _l00II;
_l1i1lI += inv * _l00II;
}
return false;
}
vec4 _llO1lI(vec3 c, out vec3 lo, out vec3 hi) {
lo = vec3(0.0);
hi = vec3(0.0);
float r = max(abs(c.x), abs(c.y));
if (r < 0.5 || (c.z + 1.0) * _lII1lI.z < P3.w + 0.5) {
return vec4(-1.0);
}
vec3 q = c * 1.7 + vec3(P0.w * 23.0, P0.w * 5.0, 91.0);
float _liiiO = hash13(q);
if (_liiiO > (r < 1.5 ? 0.26 : 0.2)) {
return vec4(-1.0);
}
vec3 _ll11lI = vec3(hash13(q + 3.3), hash13(q + 7.9), hash13(q + 12.1));
vec3 _lI11lI = vec3(hash13(q + 17.7), hash13(q + 19.3), hash13(q + 29.9));
float side = mix(0.4, 0.82, _ll11lI.x);
vec3 size = vec3(side, side * mix(0.75, 1.25, _ll11lI.y), side * _lII1lI.x / _lII1lI.z * mix(0.7, 1.0, _ll11lI.z));
size = min(size, vec3(0.92));
vec3 _l111lI = vec3(c.x - 0.5, c.y - 0.5, c.z) * _lII1lI;
vec3 _lIO1lI = (vec3(1.0) - size) * _lII1lI;
lo = _l111lI + _lIO1lI * _lI11lI;
hi = lo + size * _lII1lI;
vec3 _l1O1lI = _l111lI + _lII1lI;
float keep = hash13(q + 51.3) < 0.18 ? 1.3 : 2.2;
if (abs(c.x) >= abs(c.y)) {
if (c.x > 0.0) {
lo.x = max(lo.x, keep);
hi.x = min(max(hi.x, lo.x + 0.8), _l1O1lI.x);
} else {
hi.x = min(hi.x, -keep);
lo.x = max(min(lo.x, hi.x - 0.8), _l111lI.x);
}
} else {
if (c.y > 0.0) {
lo.y = max(lo.y, keep);
hi.y = min(max(hi.y, lo.y + 0.8), _l1O1lI.y);
} else {
hi.y = min(hi.y, -keep);
lo.y = max(min(lo.y, hi.y - 0.8), _l111lI.y);
}
}
return vec4(0.5 + 0.5 * _liiiO, 0.6, hash13(q + 41.9), 1.0);
}
bool _liO1lI(vec3 ro, vec3 rd, float _li1iI, out float _llO0I, out vec3 _lO11lI, out vec3 _l011lI, out vec3 _lli1lI, out vec4 kind) {
_llO0I = _li1iI;
_lO11lI = vec3(0.0, 0.0, -1.0);
_l011lI = vec3(0.0);
_lli1lI = vec3(0.0);
kind = vec4(0.0);
vec3 off = vec3(0.5 * _lII1lI.x, 0.5 * _lII1lI.y, 0.0);
vec3 g = (ro + off) / _lII1lI;
vec3 cell = floor(g);
vec3 _lIi1lI = rd / _lII1lI;
_lIi1lI = mix(_lIi1lI, vec3(1.0e-6), vec3(lessThan(abs(_lIi1lI), vec3(1.0e-6))));
vec3 stp = sign(_lIi1lI);
vec3 inv = 1.0 / abs(_lIi1lI);
vec3 _l1i1lI = (stp * (cell - g) + max(stp, vec3(0.0))) * inv;
vec3 _lii1lI = 1.0 / mix(rd, vec3(1.0e-6), vec3(lessThan(abs(rd), vec3(1.0e-6))));
float _lOO1lI = 0.0;
for (int i = 0; i < 48; i++) {
if (_lOO1lI > _li1iI) {
break;
}
vec3 lo;
vec3 hi;
vec4 k = _llO1lI(cell, lo, hi);
if (k.w > 0.0) {
vec3 _lI0i1 = (lo - ro) * _lii1lI;
vec3 _l1l0I = (hi - ro) * _lii1lI;
vec3 _lOi1lI = min(_lI0i1, _l1l0I);
vec3 _l0i1lI = max(_lI0i1, _l1l0I);
float tn = max(max(_lOi1lI.x, _lOi1lI.y), _lOi1lI.z);
float tf = min(min(_l0i1lI.x, _l0i1lI.y), _l0i1lI.z);
if (tn < tf && tn > 0.0 && tn < _li1iI) {
_llO0I = tn;
if (_lOi1lI.x >= _lOi1lI.y && _lOi1lI.x >= _lOi1lI.z) {
_lO11lI = vec3(-stp.x, 0.0, 0.0);
} else if (_lOi1lI.y >= _lOi1lI.z) {
_lO11lI = vec3(0.0, -stp.y, 0.0);
} else {
_lO11lI = vec3(0.0, 0.0, -stp.z);
}
_l011lI = lo;
_lli1lI = hi;
kind = k;
return true;
}
}
float _l1lOO = min(_l1i1lI.x, min(_l1i1lI.y, _l1i1lI.z));
_lOO1lI = _l1lOO;
vec3 _l00II = vec3(lessThanEqual(_l1i1lI, vec3(_l1lOO)));
cell += stp * _l00II;
_l1i1lI += inv * _l00II;
}
return false;
}
float _l0O1lI(vec3 rd, float wx, float wy) {
vec2 a = rd.xy / max(rd.z, 1.0e-3);
return exp(-(a.x * a.x) / (wx * wx) - (a.y * a.y) / (wy * wy));
}
vec3 _ll01lI(vec3 rd) {
float _l1iOi = P1.x;
float _l0iIl = P1.y;
float _l00iI = _l0O1lI(rd, 0.14, 0.07);
float core = _l0O1lI(rd, 0.07, 0.045);
vec3 _liOl1 = vec3(0.008, 0.01, 0.045);
vec3 _lI01lI = mix(_liOl1, vec3(0.06, 0.07, 0.3), _l00iI * P3.y) + vec3(0.9, 0.2, 0.32) * core * 0.18 * P3.y;
float _l101lI = smoothstep(0.3, 0.45, P0.x) * (1.0 - smoothstep(0.6, 1.0, P0.x));
_lI01lI += vec3(0.42, 0.36, 0.85) * _l101lI * 0.8;
vec3 _li01lI = mix(vec3(0.03, 0.02, 0.1), vec3(1.0, 0.235, 0.59) * 1.2, _l0O1lI(rd, 0.75, 0.55));
float _lIl1I = smoothstep(0.0, 0.12, P0.x) * (1.0 - smoothstep(0.2, 0.42, P0.x));
_li01lI = mix(_li01lI, vec3(1.0, 0.85, 0.95) * 2.4, _l0O1lI(rd, mix(0.2, 0.42, _lIl1I), mix(0.17, 0.34, _lIl1I)));
vec3 _lO01lI = mix(vec3(0.16, 0.1, 0.06) * 0.35, vec3(0.95, 0.55, 0.24), _l0O1lI(rd, 0.3, 0.12));
_lO01lI = mix(_lO01lI, vec3(1.0, 0.86, 0.62) * 1.8, _l0O1lI(rd, 0.2, 0.08));
vec3 c = mix(_lI01lI, _lO01lI, _l0iIl);
return mix(c, _li01lI, _l1iOi);
}
vec3 _l001lI(vec3 ro, vec3 rd, float t, vec3 n, vec3 lo, vec3 hi, vec4 kind, float _ll0IlI) {
vec3 p = ro + rd * t;
float _li111 = t * _ll0IlI;
vec3 _lllilI = min(p - lo, hi - p);
vec3 an = abs(n);
vec3 dd = _lllilI + an * 1.0e3;
float edge = min(dd.x, min(dd.y, dd.z));
vec3 size = hi - lo;
float _l00iI = p.z - ro.z;
float _lIlilI = P1.z - 7.0 * exp(-abs(p.y) * 0.5);
float _l0iIl = smoothstep(-2.5, 2.5, _l00iI - _lIlilI);
float _l1l1I = exp(-sqr((_l00iI - _lIlilI) / 1.8)) * step(-2.0, P1.z) * step(P1.z, 60.0);
float _l1iOi = P1.x;
float _l1lilI = exp(-length(p.xy) * 0.7);
float _lililI = P3.y * _l1lilI * smoothstep(4.0, 22.0, _l00iI);
float red = max(step(kind.x, 0.05) * smoothstep(3.0, 9.0, _l00iI), smoothstep(0.55, 0.98, _lililI * (0.3 + kind.z)));
red *= (1.0 - _l0iIl) * 0.25;
float _lOlilI = _l1iOi * smoothstep(1.0, 6.0, _l00iI);
vec3 base;
vec3 _lIOII;
float _lilII = 0.012 + _li111 * mix(1.8, 1.1, _l1iOi);
float line = 1.0 - smoothstep(_lilII, _lilII + _li111 * 1.3, edge);
float halo = exp(-edge / (0.03 + _li111 * 2.0));
float _ll1OI = mix(0.8, 1.05, kind.z);
if (an.z > 0.5) {
float _l0lilI = 0.035 * min(size.x, size.y) + _li111 * 2.5;
float frame = 1.0 - smoothstep(_l0lilI * 0.5, _l0lilI + _li111, edge);
vec3 _llIilI = vec3(0.015, 0.018, 0.06);
vec3 _lIIilI = vec3(1.0, 0.14, 0.5) * 1.25;
vec3 _l1IilI = vec3(0.07, 0.035, 0.012);
vec3 _liIilI = vec3(0.55, 0.03, 0.13);
base = mix(mix(_llIilI, _liIilI, red), _l1IilI, _l0iIl);
base = mix(base, _lIIilI, _l1iOi * smoothstep(0.55, 0.8, kind.z) * smoothstep(1.5, 5.0, _l00iI));
vec3 _lOIilI = mix(mix(vec3(0.44, 0.9, 1.0), vec3(0.85, 0.2, 0.36), red), vec3(0.85, 0.62, 0.32), _l0iIl);
_lOIilI = mix(_lOIilI, vec3(1.0, 0.55, 0.9), _lOlilI);
base = mix(base, _lOIilI, frame * 0.8);
_lIOII = mix(mix(vec3(0.55, 0.9, 1.0), vec3(1.0, 0.45, 0.55), red), vec3(1.0, 0.84, 0.52), _l0iIl);
_lIOII = mix(_lIOII, vec3(1.0, 0.82, 1.0), _lOlilI);
} else {
float along = clamp((p.z - lo.z) / max(size.z, 1.0e-3), 0.0, 1.0);
vec3 _l0IilI = an.y > 0.5 ? (n.y < 0.0 ? vec3(0.55, 0.44, 1.0) : vec3(0.22, 0.32, 1.0)) : vec3(0.16, 0.25, 1.0);
_l0IilI *= 1.5;
vec3 _ll1ilI = an.y > 0.5 ? (n.y < 0.0 ? vec3(0.16, 0.07, 0.26) : vec3(0.11, 0.05, 0.2)) : vec3(0.1, 0.05, 0.19);
vec3 _lI1ilI = an.y > 0.5 ? (n.y < 0.0 ? vec3(0.98, 0.9, 0.76) : vec3(0.94, 0.85, 0.66)) : vec3(0.9, 0.8, 0.62);
vec3 _l11ilI = vec3(0.62, 0.12, 0.32);
vec3 _li1ilI = _lI1ilI;
base = mix(mix(_l0IilI, _l11ilI, red * 0.85), _li1ilI, _l0iIl);
base = mix(base, _ll1ilI, _lOlilI);
base *= _ll1OI * mix(1.05, 0.8, along);
float inner = exp(-edge / (0.22 * min(min(size.x, size.y), size.z) + _li111));
base *= mix(mix(0.72, 0.55, _l0iIl), 1.0, inner);
_lIOII = mix(mix(vec3(0.5, 0.85, 1.0), vec3(1.0, 0.5, 0.62), red), vec3(1.0, 0.86, 0.56), _l0iIl);
_lIOII = mix(_lIOII, vec3(1.0, 0.85, 1.0), _lOlilI);
}
vec3 col = base + _lIOII * (line * P2.w + halo * 0.18);
col += vec3(1.0, 0.72, 0.42) * _l1l1I * 1.6;
float _l0iil = P3.x * (1.0 - _l1iOi) * exp(-abs(p.y) / 1.3) * exp(-abs(p.x) / 7.0) * smoothstep(2.0, 8.0, _l00iI) * smoothstep(26.0, 10.0, _l00iI);
col += mix(vec3(1.0, 0.36, 0.38), vec3(1.0, 0.62, 0.3), _l0iIl) * _l0iil * 0.55 * (1.0 - 0.6 * an.z);
return col;
}
vec3 _lO1ilI(vec3 ro, vec3 rd, float hitT, float _ll0IlI) {
vec3 _li1ll = vec3(0.0);
float _llIO0 = P3.z;
float _l01ilI = length(rd.xy);
if (_l01ilI < 1.0e-4 || _llIO0 < 0.001) {
return _li1ll;
}
float _l10ll = atan(rd.y, rd.x);
for (int _ll0ll = 0; _ll0ll < 4; _ll0ll++) {
float _lO0Il = float(_ll0ll);
float _lO0Ii = 0.8 + _lO0Il * 0.75;
float t = _lO0Ii / _l01ilI;
if (t < hitT && t < 70.0) {
float z = ro.z + rd.z * t;
float _lliilI = TAU / floor(8.0 + 12.0 * _lO0Ii);
float _l11lO = floor(_l10ll / _lliilI);
float _lIiilI = 1.1;
float _l1iilI = floor(z / _lIiilI);
float _li111 = t * _ll0IlI;
for (int k = -1; k < 2; k++) {
vec2 c = vec2(_l11lO, _l1iilI + float(k));
float h = hash12(c + vec2(_lO0Il * 37.0, 5.0));
float _liiilI = max(max(exp(-sqr(mod(_l10ll - 1.57 + PI, TAU) - PI) / 0.16), exp(-sqr(mod(_l10ll + 1.57 + PI, TAU) - PI) / 0.16)), max(exp(-sqr(mod(_l10ll - 2.4 + PI, TAU) - PI) / 0.08), exp(-sqr(mod(_l10ll + 0.7 + PI, TAU) - PI) / 0.08)));
float _l0l00 = _llIO0 + Pts[0].x * _liiilI;
if (h < _l0l00 * 0.3) {
vec2 _lI11lI = hash22(c * 1.31 + vec2(_lO0Il, 2.0));
float a0 = (c.x + 0.15 + 0.7 * _lI11lI.x) * _lliilI;
float _lIIOi = (c.y + _lI11lI.y) * _lIiilI;
float _liIi0 = abs(mod(_l10ll - a0 + PI, TAU) - PI) * _lO0Ii;
float _l0OII = P0.z * mix(0.025, 0.07, step(0.875, _lI11lI.y)) * (1.0 - 0.6 * P1.y);
float along = z - _lIIOi;
float on = clamp(along, 0.0, _l0OII);
float dist = length(vec2(_liIi0, (along - on) * _l01ilI));
float w = 0.003 + _li111 * 0.45;
float core = exp(-dist * dist / (w * w));
float _lOiilI = on / max(_l0OII, 1.0e-4);
float _l0iilI = 1.0 - 0.85 * _lOiilI;
float _ll111 = step(0.72, fract(h * 13.0));
vec3 tint = mix(vec3(1.0, 0.42, 0.72), vec3(1.0, 0.68, 0.3), max(smoothstep(1.55, 1.8, P0.x), step(_llIO0 * 0.3, h)));
tint = mix(tint, vec3(1.0, 0.85, 0.96), P1.x);
tint = mix(tint, mix(vec3(0.8, 0.88, 1.0), vec3(0.84, 0.78, 1.0), P1.y), _ll111);
vec3 _llOilI = mix(vec3(1.0), mix(tint, vec3(0.66, 0.77, 1.0), _ll111 + (1.0 - _ll111) * 0.3), smoothstep(0.0, 0.6, _lOiilI));
float _lIOilI = 1.0 - smoothstep(0.06, 0.3, _l01ilI);
float _l1OilI = smoothstep(1.1, 1.6, P0.x) * (1.0 - P1.y);
_llOilI = mix(_llOilI, vec3(1.0, 0.2, 0.25), _lIOilI * _l1OilI);
float bright = (0.4 + 0.6 * _lI11lI.x) * (2.6 + 1.2 * step(0.875, _lI11lI.y));
_li1ll += _llOilI * core * _l0iilI * bright * mix(1.0 - _lIOilI, 1.0, _l1OilI);
}
}
}
}
return _li1ll;
}
float _liOilI(vec3 ro, vec3 rd, vec3 a, vec3 b, out float tRay) {
vec3 ba = b - a;
vec3 _lOOilI = ro - a;
float bb = dot(ba, ba);
float br = dot(ba, rd);
float _lll1lI = dot(rd, _lOOilI);
float _lOOiO = dot(ba, _lOOilI);
float _lIOOO = max(bb - br * br, 1.0e-6);
float sp = clamp((_lOOiO - br * _lll1lI) / _lIOOO, 0.0, 1.0);
tRay = max(br * sp - _lll1lI, 0.0);
return length(_lOOilI + rd * tRay - ba * sp);
}
vec3 _l0OilI(vec3 ro, vec3 rd, float hitT, float _ll0IlI) {
float on = smoothstep(1.35, 1.55, P0.x) * (1.0 - smoothstep(2.4, 2.65, P0.x));
vec3 _li1ll = vec3(0.0);
if (on < 0.001) {
return _li1ll;
}
for (int i = 0; i < 8; i++) {
float _l1Iil = float(i);
vec3 h = vec3(hash11(_l1Iil * 3.1 + 0.7), hash11(_l1Iil * 5.7 + 1.3), hash11(_l1Iil * 7.9 + 2.9));
float _l10ll = _l1Iil * 0.785 + h.x * 0.6;
float _lO0Ii = 0.7 + 1.9 * h.y;
vec3 _lllO0 = vec3(cos(_l10ll) * _lO0Ii, sin(_l10ll) * _lO0Ii, Pts[0].y + h.z * 14.0);
vec3 _ll0ilI = _lllO0 + normalize(vec3(h.y - 0.5, h.z - 0.5, 0.3)) * (0.18 + 0.15 * h.x);
vec3 _lI0ilI = _ll0ilI + normalize(vec3(0.5 - h.z, h.x - 0.2, -0.2)) * (0.14 + 0.15 * h.y);
vec3 p3 = _lI0ilI + normalize(vec3(h.x - 0.6, 0.4 - h.y, 0.25)) * (0.16 + 0.12 * h.z);
float t1;
float _l1i1O;
float _l10ilI;
float _llllO = _liOilI(ro, rd, _lllO0, _ll0ilI, t1);
float _liI0I = _liOilI(ro, rd, _ll0ilI, _lI0ilI, _l1i1O);
float _li0ilI = _liOilI(ro, rd, _lI0ilI, p3, _l10ilI);
float d = _llllO;
float _l1IlI = t1;
if (_liI0I < d) {
d = _liI0I;
_l1IlI = _l1i1O;
}
if (_li0ilI < d) {
d = _li0ilI;
_l1IlI = _l10ilI;
}
if (_l1IlI > 0.2 && _l1IlI < hitT) {
float _lO0ilI = smoothstep(2.5, 6.0, _l1IlI);
float _li111 = _l1IlI * _ll0IlI;
float w = 0.008 + _li111 * 0.7;
float core = exp(-d * d / (w * w));
float glow = exp(-d / (0.03 + _li111 * 2.0)) * 0.25;
_li1ll += (vec3(1.0, 0.76, 0.32) * (core * 3.0 + glow) + vec3(1.0, 0.95, 0.85) * core * 1.5) * _lO0ilI;
}
}
return _li1ll * on;
}
void main() {
float _l11ll = OutSize.x / OutSize.y;
vec2 q = (texCoord - P2.yz) * 2.0;
vec3 rd = normalize(vec3(q.x * _l11ll * P2.x, q.y * P2.x, 1.0));
vec3 ro = vec3(0.0, 0.0, P0.y);
float _ll0IlI = 2.0 * P2.x / OutSize.y;
float t;
vec3 n;
vec3 lo;
vec3 hi;
vec4 kind;
bool _l0i0I = _li11lI(ro, rd, t, n, lo, hi, kind);
float _l1l0I;
vec3 _l0OO1;
vec3 _lI1il;
vec3 _l00ilI;
vec4 _l1l0O;
if (_liO1lI(ro, rd, _l0i0I ? t : _liI1lI, _l1l0I, _l0OO1, _lI1il, _l00ilI, _l1l0O)) {
_l0i0I = true;
t = _l1l0I;
n = _l0OO1;
lo = _lI1il;
hi = _l00ilI;
kind = _l1l0O;
}
vec3 _lO0l1 = _ll01lI(rd);
vec3 col;
float light;
bool _l0IOi = P1.w > 0.05 && length(rd.xy * (P1.w / max(rd.z, 1.0e-3)) - vec2(0.0, 0.255)) > _lIOIlI;
if (_l0IOi) {
col = vec3(0.012, 0.007, 0.03);
light = 0.0;
t = P1.w / max(rd.z, 1.0e-3);
} else if (_l0i0I) {
col = _l001lI(ro, rd, t, n, lo, hi, kind, _ll0IlI);
float _lllOlI = smoothstep(0.3, 0.45, P0.x) * (1.0 - smoothstep(0.6, 1.0, P0.x));
float _ll1II = 1.0 - exp(-t / mix(mix(_l1I1lI, 7.0, _lllOlI), 14.0, P1.x));
col = mix(col, _lO0l1, _ll1II);
light = 0.0;
} else {
col = _lO0l1;
light = 1.0;
}
col += _lO1ilI(ro, rd, _l0i0I || _l0IOi ? t : 1.0e4, _ll0IlI);
col += _l0OilI(ro, rd, _l0i0I || _l0IOi ? t : 1.0e4, _ll0IlI);
float _l0O10;
if (_l0i0I || _l0IOi) {
_l0O10 = 0.5 / (1.0 + t / 3.0);
} else {
_l0O10 = 0.5 + 0.5 * light * _l0O1lI(rd, 0.55, 0.4);
}
fragColor = vec4(_lOiIlI(_liiIlI(col), gl_FragCoord.xy), _l0O10);
}