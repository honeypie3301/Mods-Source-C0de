#include "dim_star.glsl"
#include "gravitia_space_city.glsl"
uniform vec3 CamBlock;
uniform vec3 CamFrac;
uniform vec4 L0;
uniform vec4 Pick;
vec3 _l1OlII(vec2 uv, vec3 _lIIll) {
vec3 at = project(_lIIll * 4096.0);
if (at.z <= 0.0) {
return vec3(0.0);
}
vec2 _lll1i = at.xy;
float _l11ll = OutSize.x / OutSize.y;
float on = 1.0 - smoothstep(0.6, 1.0, max(abs(_lll1i.x - 0.5), abs(_lll1i.y - 0.5)));
if (on <= 0.0) {
return vec3(0.0);
}
float _l1iIl = 0.0;
float _liOil = hash12(gl_FragCoord.xy + 7.0);
float _lilOl = 1.0;
for (int k = 0; k < 28; k++) {
float _lO11l = (float(k) + _liOil) / 28.0;
vec2 s = uv + (_lll1i - uv) * _lO11l * 0.92;
vec2 _llili = clamp(s, vec2(0.001), vec2(0.999));
float sky = skyAt(_llili) ? 1.0 : 0.0;
vec2 off = (s - _lll1i) * vec2(_l11ll, 1.0);
float near = exp(-abs(off.y) / 0.025) * exp(-abs(off.x) / 0.35);
_l1iIl += sky * near * _lilOl;
_lilOl *= 0.955;
}
_l1iIl /= 14.0;
vec3 _li0IlI = mix(vec3(1.0, 0.18, 0.32), vec3(1.0, 0.7, 0.36), _liIlII);
float _lI1lII = mix(0.2, 1.0, exp(-abs(uv.y - _lll1i.y) / 0.15));
return _li0IlI * _l1iIl * on * _lI1lII * 1.4;
}
void main() {
vec2 uv = texCoord;
vec3 scene = texture(DiffuseSampler, uv).rgb;
ivec2 _liOlII = textureSize(DepthSampler, 0);
ivec2 _lOOlII = min(ivec2(uv * vec2(_liOlII)), _liOlII - 1);
float depth = texelFetch(DepthSampler, _lOOlII, 0).r;
vec3 p = unproject((vec2(_lOOlII) + 0.5) / vec2(_liOlII), depth);
vec3 rd = normalize(p);
float _li1lII = L0.x;
vec3 _lII0I = vec3(0.0);
for (int i = 0; i < 4; i++) {
_lII0I += _l1OlII(uv, _l0IlII(i));
}
if (skyAt(uv)) {
fragColor = vec4(_lIOlII(_lIilII(rd, _li1lII) + _lII0I), 1.0);
return;
}
float t = length(p);
float _li111 = t * 2.0 * InvProj[1][1] / OutSize.y;
vec3 q = CamFrac + p + rd * max(0.01, t * 0.0015);
ivec3 _lli00 = ivec3(CamBlock);
ivec3 _l0OlII = _lli00 + ivec3(floor(q));
ivec3 lo;
ivec3 hi;
int _ll00lI;
vec3 col;
bool _ll10l = _llIlII(_l0OlII, lo, hi, _ll00lI);
if (_ll10l) {
vec3 _lIll1 = vec3(_lli00 - lo) + CamFrac + p;
col = _l1ilII(_lIll1, vec3(hi - lo), _ll00lI, _li111, CamBlock.y + CamFrac.y + p.y);
if (Pick.w > 0.5 && _l0OlII == _lli00 + ivec3(Pick.xyz)) {
vec3 b = CamFrac + p - (vec3(_l0OlII - _lli00));
vec3 e = min(b, vec3(1.0) - b);
vec3 _lllilI = min(_lIll1, vec3(hi - lo) - _lIll1);
int axis = _lllilI.x < _lllilI.y ? (_lllilI.x < _lllilI.z ? 0 : 2) : (_lllilI.y < _lllilI.z ? 1 : 2);
float _ll0lII = axis == 0 ? min(e.y, e.z) : (axis == 1 ? min(e.x, e.z) : min(e.x, e.y));
col = mix(col, vec3(0.0), (1.0 - smoothstep(0.012 + _li111, 0.012 + _li111 * 2.0, _ll0lII)) * 0.7);
}
col = _lIOlII(col + _lII0I);
} else {
col = scene + _lIOlII(_lII0I);
}
float _lO0l1 = max(smoothstep(L0.y * 0.3, L0.y * 0.95, t), (1.0 - exp(-t / 220.0)) * 0.45);
col = mix(col, _lIOlII(_lIilII(rd, _li1lII) + _lII0I), _lO0l1);
fragColor = vec4(col, 1.0);
}