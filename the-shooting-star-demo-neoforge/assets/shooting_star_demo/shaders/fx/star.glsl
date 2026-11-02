const vec3 _lIi01 = vec3(1.0, 0.045, 0.07);
const vec3 _l1i01 = vec3(1.0, 0.55, 0.6);
const vec3 _lii01 = vec3(0.3, 0.85, 1.0);
#ifndef LOOP_ZERO
#define LOOP_ZERO 0
#endif
float _l100l = 0.0;
float _li00l = 0.0;
vec3 _l10Ol(vec3 c) { return pow(max(c, 0.0), vec3(2.2)); }
vec2 _li0Ol(vec3 n) {
return vec2(0.5 + atan(n.x, n.z) / TAU, 0.5 - asin(clamp(n.y, -1.0, 1.0)) / PI);
}
float _lO0Ol(float _l0l1l, float width) {
return log2(max(_l0l1l * width / TAU, 1e-3));
}
vec3 _l0IOI(float x) {
vec3 c = mix(vec3(0.3, 0.01, 0.0), vec3(1.0, 0.25, 0.02), smoothstep(0.0, 0.45, x));
c = mix(c, vec3(1.0, 0.68, 0.22), smoothstep(0.4, 0.85, x));
return mix(c, vec3(1.0, 0.95, 0.85), smoothstep(0.85, 1.25, x));
}
float _liO0I(float d, float _lOi01, float size) {
float x = d / (_lOi01 * size);
return exp(-x * x) + 0.06 / (1.0 + x * x * 0.4);
}
void facing(vec3 n, out vec3 ax, out vec3 ay) {
ax = normalize(cross(n, abs(n.y) < 0.9 ? vec3(0.0, 1.0, 0.0) : vec3(1.0, 0.0, 0.0)));
ay = cross(ax, n);
}
vec3 _l00Ol(vec3 rd, float _lOi01, float _l0i01) {
vec3 col = vec3(0.0);
for (int _llO01 = 0; _llO01 < 3 + LOOP_ZERO; _llO01++) {
float _lO0Il = float(_llO01);
float _lOi11 = _llO01 == 0 ? 110.0 : _llO01 == 1 ? 260.0 : 520.0;
vec3 id = floor(rd * _lOi11);
float h = hash13(id + _lO0Il * 17.0 + _li00l);
if (h > (_llO01 == 0 ? 0.05 : 0.03)) continue;
vec3 _lO1il = normalize(id + 0.2 + 0.6 * vec3(hash13(id + 3.1), hash13(id + 7.7), hash13(id + 11.3)));
float a = length(rd - _lO1il);
float size = _llO01 == 0 ? 1.1 : 0.8;
float _lIO01 = sqr(sqr(hash13(id + 5.9))) * hash13(id + 5.9) * (_llO01 == 0 ? 9.0 : 2.5) + (_llO01 == 2 ? 0.12 : 0.2);
float _li1i1 = 0.78 + 0.22 * sin(_l100l * (2.0 + h * 40.0) + h * 97.0);
vec3 tint = mix(vec3(0.62, 0.76, 1.0), vec3(1.0, 0.84, 0.64), hash13(id + 2.3));
col += tint * _lIO01 * _li1i1 * exp(-sqr(a / (_lOi01 * size))) * 0.35;
}
return col * _l0i01;
}
vec3 _l1O01(vec3 rd, float _lOi01) {
vec3 col = vec3(0.0);
for (int _llO01 = 0; _llO01 < 3 + LOOP_ZERO; _llO01++) {
float _lO0Il = float(_llO01);
float _lOi11 = _llO01 == 0 ? 34.0 : _llO01 == 1 ? 75.0 : 160.0;
vec3 cell = floor(rd * _lOi11);
float h = hash13(cell + _li00l + _lO0Il * 31.0);
if (h > (_llO01 == 0 ? 0.05 : _llO01 == 1 ? 0.06 : 0.08)) continue;
vec3 c = normalize(cell + 0.3 + 0.4 * vec3(hash13(cell + 1.3), hash13(cell + 2.9), hash13(cell + 5.1)));
vec3 ax, ay;
facing(c, ax, ay);
vec3 d = rd - c;
vec2 q = vec2(dot(d, ax), dot(d, ay)) / _lOi01;
q = rot(hash13(cell + 7.7) * TAU) * q;
float size = (_llO01 == 0 ? 3.4 : _llO01 == 1 ? 2.0 : 1.3) * (0.5 + hash13(cell + 11.0));
q.y /= mix(0.22, 1.0, hash13(cell + 9.1));
float r = length(q) / size;
if (r > 4.0) continue;
float _liO01 = step(0.45, hash13(cell + 13.0));
float _lOO01 = _liO01 * (0.55 + 0.45 * sin(2.0 * atan(q.y, q.x + 1e-6) - 4.0 * log(r + 0.15)));
float _lI1lI = exp(-r * r * 1.4) * mix(1.0, _lOO01, 0.6 * _liO01) + exp(-r * r * 14.0) * 0.9;
vec3 tint = mix(vec3(1.0, 0.78, 0.5), vec3(0.62, 0.74, 1.0), hash13(cell + 17.0));
col += tint * _lI1lI * (_llO01 == 0 ? 0.24 : _llO01 == 1 ? 0.14 : 0.09);
}
return col;
}
vec3 _lIII1(vec3 rd, vec3 _l0O01, float _ll001, float _l0lII, float _lOi01, vec3 _lI001, vec3 _l1001) {
float c = dot(rd, _l0O01);
if (c <= 0.02) return vec3(0.0);
vec3 _ll0II, _lOOO1;
facing(_l0O01, _ll0II, _lOOO1);
vec2 p = vec2(dot(rd, _ll0II), dot(rd, _lOOO1)) / c;
float r = max(length(p), 1e-5);
float _li001 = atan(p.y, p.x + 1e-7);
float u = log(r);
float _l1lll = _lOi01 * (1.0 + r * r);
vec3 col = vec3(0.0);
for (int _llO01 = 0; _llO01 < 3 + LOOP_ZERO; _llO01++) {
float _lO0Il = float(_llO01);
float _l1OO1 = 0.22 + 0.1 * _lO0Il;
float around = 70.0 + 45.0 * _lO0Il;
float _llIO1 = _ll001 * (1.0 + 0.35 * _lO0Il);
vec2 cell = vec2(floor((u - _llIO1) / _l1OO1), floor((_li001 / TAU + 0.5) * around));
float h = hash12(cell + _lO0Il * 17.0 + _li00l);
if (h > 0.14) continue;
float _lO001 = (cell.x + 0.15 + 0.7 * hash12(cell + 3.1)) * _l1OO1 + _llIO1;
float _l0001 = ((cell.y + 0.2 + 0.6 * hash12(cell + 5.3)) / around - 0.5) * TAU;
vec2 o = exp(_lO001) * vec2(cos(_l0001), sin(_l0001));
vec2 _lllli = vec2(cos(_l0001), sin(_l0001));
vec2 _lIlli = p - o;
float along = dot(_lIlli, _lllli);
float across = dot(_lIlli, vec2(-_lllli.y, _lllli.x));
float _lll0I = _l1lll * (1.3 + _l0lII * exp(_lO001) * 90.0);
float _l1lli = _l1lll * (_l0lII > 0.5 ? 0.7 : 1.1 + 0.6 * _lO0Il);
float _li0OI = along < 0.0 ? along / _lll0I : along / (_l1lll * 1.5);
float d = length(vec2(_li0OI, across / _l1lli));
float _liIOl = _l0lII > 0.5 ? mix(0.35, 1.0, saturate(along / _lll0I + 1.0)) : 1.0;
float near = smoothstep(-5.0, -1.5, _lO001);
col += mix(_lI001, _l1001, hash12(cell + 9.0)) * exp(-d * d) * _liIOl * near * (0.6 - 0.15 * _lO0Il) * (_l0lII > 0.5 ? 1.6 : 1.0);
}
return col;
}
vec3 _lilli(vec3 n, vec3 rd, vec3 tint, float seed) {
float _liIl1 = max(dot(n, -rd), 0.0);
float _lO0I1 = fbm3(n * 60.0 + vec3(seed * 3.0, _l100l * 0.05, 0.0));
float _lIOO1 = fbm3(n * 150.0 + vec3(0.0, seed, _l100l * 0.08));
float _lOlli = smoothstep(0.64, 0.72, fbm3(n * 6.0 + seed * 3.1));
vec3 hot = mix(tint * vec3(1.0, 0.72, 0.5), tint, sqrt(_liIl1));
return hot * (0.55 + 0.7 * _lO0I1 + 0.3 * _lIOO1) * (1.0 - 0.7 * _lOlli) * (0.3 + 1.1 * sqrt(_liIl1)) * 60.0;
}
vec3 _l0lli(vec3 rd, vec3 centre, vec3 n, vec3 _l1lIl, float radius, sampler2D _lOilI, float _lOi01, float _l0iOI,
out float _lIO0I, out float _llO0I) {
_lIO0I = 0.0;
_llO0I = -1.0;
float t = rayPlane(vec3(0.0), rd, centre, n);
if (t <= 0.0 || t > _l0iOI) return vec3(0.0);
vec3 q = rd * t - centre;
vec3 _lIlIl = normalize(cross(_l1lIl, n));
vec2 uv = vec2(dot(q, _lIlIl), dot(q, _l1lIl)) / (2.0 * radius) + 0.5;
if (uv.x < 0.0 || uv.y < 0.0 || uv.x > 1.0 || uv.y > 1.0) return vec3(0.0);
float _llIli = abs(dot(rd, n));
float _ll0Ol = log2(max(_lOi01 * t / max(_llIli, 0.04) / (2.0 * radius) * 2048.0, 1e-3));
vec3 c = _l10Ol(textureLod(_lOilI, vec2(uv.x, 1.0 - uv.y), _ll0Ol).rgb);
_llO0I = t;
_lIO0I = saturate(lum(c) * 3.0);
return c * mix(1.0, min(1.0 / max(_llIli, 0.1), 3.0), 0.4);
}