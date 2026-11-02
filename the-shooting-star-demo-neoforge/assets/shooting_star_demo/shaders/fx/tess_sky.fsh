#include "star.glsl"
uniform sampler2D MilkyTop;
uniform vec4 S0;
uniform vec4 MouthC;
uniform vec4 EngC;
uniform vec3 EngX;
uniform vec3 EngY;
uniform vec3 EngZ;
uniform vec3 KeyDir;
uniform vec3 KeyCol;
#include "tess_engine.glsl"
const float _llIi0 = 1e30;
vec3 _lIIi0(vec2 q, float R) {
float r = length(q) / R;
float _l10ll = atan(q.y, q.x);
float depth = -log(max(r, 1e-3));
float rings = abs(fract(depth * 2.2 - _l100l * 0.35) - 0.5);
float _l1Ii0 = abs(fract(_l10ll / TAU * 24.0) - 0.5) / max(r, 0.05);
float w = 0.04 + 0.02 * depth;
float grid = exp(-sqr(rings / w)) + exp(-sqr(_l1Ii0 / 0.08)) * 0.7;
vec3 col = vec3(0.01, 0.01, 0.016);
col += vec3(0.9, 0.93, 1.0) * grid * exp(-depth * 0.35) * 0.7;
vec2 cell = vec2(floor(depth * 9.0), floor(_l10ll / TAU * 140.0));
float h = hash12(cell);
if (h < 0.18) {
float a0 = (cell.y + 0.5) / 140.0 * TAU;
float _liIi0 = abs(_l10ll - a0) * 140.0 / TAU;
col += mix(vec3(0.7, 0.8, 1.0), vec3(1.0, 0.85, 0.65), hash12(cell + 3.0)) * exp(-sqr(_liIi0 / 0.12)) * 0.6
* exp(-depth * 0.25);
}
col += vec3(0.85, 0.8, 1.0) * exp(-r / 0.05) * 1.5;
return col;
}
void main() {
initPixel(texCoord);
_l100l = S0.x;
_li00l = 0.37;
vec3 rd = viewDir(texCoord);
vec3 _l1O0I = scenePosAt(texCoord);
bool sky = skyAt(texCoord);
float sceneT = sky ? _llIi0 : length(_l1O0I);
float up = smoothstep(-0.08, 0.35, rd.y);
vec3 base = sampleScene(texCoord);
float R = MouthC.w;
bool through = false;
float _lOIi0 = rd.y > 1e-4 ? MouthC.y / rd.y : -1.0;
vec3 glow = vec3(0.0);
if (R > 1.0 && _lOIi0 > 0.0 && _lOIi0 < sceneT) {
vec3 q = rd * _lOIi0 - MouthC.xyz;
float r = length(q.xz);
float _l10ll = atan(q.z, q.x);
if (r < R) {
through = true;
base = _lIIi0(q.xz, R);
} else if (sky && r < R * 1.8) {
vec3 p = rd * _lOIi0 + vec3(q.x, 0.0, q.z) / max(r, 1.0) * R * 0.22 * sqr(R / r);
vec3 s = project(p);
if (s.z > 0.0) base = sampleScene(s.xy);
}
float x = (r - R * 1.03) / max(R * 0.008, gPix * _lOIi0 * 1.5);
float _l1i0O = (r - R * 1.09) / max(R * 0.006, gPix * _lOIi0 * 1.5);
float _ll1Oi = 0.75 + 0.25 * vnoise2(vec2(_l10ll * 40.0, _l100l * 0.2));
glow += vec3(0.95, 0.97, 1.0) * (exp(-x * x) * 2.0 * _ll1Oi + exp(-_l1i0O * _l1i0O) * 0.4 + exp(-abs(r - R) / (R * 0.1)) * 0.2)
+ vec3(1.0) * S0.w * exp(-abs(r - R) / (R * 0.4)) * 2.0;
}
if (sky && S0.y > 0.001 && !through) {
base = mix(base, base * vec3(0.32, 0.3, 0.48) + vec3(0.003, 0.002, 0.012), S0.y * (0.55 + 0.4 * up));
glow += _l00Ol(rd, gPix, 0.6) * S0.y * up;
}
if (S0.z > 0.5) {
vec3 _l0Ii0 = vec3(dot(-EngC.xyz, EngX), dot(-EngC.xyz, EngY), dot(-EngC.xyz, EngZ)) / EngC.w;
vec3 _ll1i0 = vec3(dot(rd, EngX), dot(rd, EngY), dot(rd, EngZ));
vec2 _lli1i = raySphere(_l0Ii0, _ll1i0, vec3(0.0), 2.1);
if (_lli1i.y > 0.0) {
float _li1iI = min(sceneT / EngC.w, _lli1i.y);
if (R > 1.0 && !through && _lOIi0 > 0.0) _li1iI = min(_li1iI, _lOIi0 / EngC.w);
if (_li1iI > max(_lli1i.x, 0.0)) {
_lOl1O(normalize(vec3(dot(KeyDir, EngX), dot(KeyDir, EngY), dot(KeyDir, EngZ))), KeyCol);
_llI1O(base * 0.9, 0.2);
vec4 far = _lI110(_l0Ii0, _ll1i0, _li1iI, gPix);
float _l10lI = exp(-0.1 / max(rd.y, 0.02)) * (sky ? 1.0 : 0.85);
base = base * (1.0 - far.a * _l10lI * 0.9) + far.rgb * _l10lI;
}
}
}
fragColor = vec4(base + glow, 1.0);
}