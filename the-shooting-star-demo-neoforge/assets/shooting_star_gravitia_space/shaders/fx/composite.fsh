uniform float Bloom;
uniform vec4 Flash;
uniform vec4 Vignette;
uniform vec4 Impact;
uniform sampler2D SceneSampler;
#include "dim_common.glsl"
const vec3 _ll1IlI = vec3(1.0, 1.0, 0.99);
float _lI1IlI(float x) {
float k = 0.72;
return x <= k ? x : k + (1.0 - k) * (1.0 - exp(-(x - k) / (1.0 - k)));
}
void main() {
vec2 uv = texCoord;
vec3 _l1lOO = texture(SceneSampler, uv).rgb;
float _l11IlI = Impact.x;
float _l1i1l = Impact.y;
float _l00il = Impact.z;
float dist = max(Vignette.x, 1.0001);
float _li1IlI = Vignette.y;
float _lO1IlI = Vignette.z;
vec2 sp = (uv - 0.5) * 2.0 * _li1IlI * vec2(OutSize.x / OutSize.y, 1.0);
vec3 rd = normalize(vec3(sp, -1.0));
vec3 centre = vec3(0.0, 0.0, -dist);
float b = dot(rd, centre);
float c = dot(centre, centre) - 1.0;
float _llIOi = b * b - c;
vec3 q;
float _lI1Oi = 0.0;
if (_llIOi >= 0.0) {
q = rd * (b - sqrt(_llIOi)) - centre;
} else {
vec3 near = rd * b - centre;
_lI1Oi = length(near) - 1.0;
q = near / max(length(near), 1.0e-4);
}
vec3 axis = vec3(0.0, cos(_lO1IlI), sin(_lO1IlI));
float h = dot(q, axis);
float around = acos(clamp(dot(normalize(q - axis * h), normalize(vec3(0.0, -sin(_lO1IlI), cos(_lO1IlI)))), -1.0, 1.0));
float _lIIlI = 1.0 - smoothstep(_l00il * 1.75 - 0.06, _l00il * 1.75, around);
float _l01IlI = max(fwidth(h), 1.0e-5);
if (Impact.w > 0.5) {
vec3 col = _l0IIlI(texture(DiffuseSampler, uv).rgb);
col += texture(AuxSampler, uv).rgb * Bloom;
float top = max(col.r, max(col.g, col.b));
vec3 _lO0Il = vec3(_lI1IlI(col.r), _lI1IlI(col.g), _lI1IlI(col.b));
vec3 _lliIlI = mix(vec3(1.0), _ll1IlI, _lIiIlI(Vignette.a));
_lO0Il = mix(_lO0Il, _lliIlI, _lIiIlI((top - 1.15) * 0.28));
float inside = _l11IlI >= 1.0 ? 1.0 : (_llIOi >= 0.0 ? 1.0 - smoothstep(_l11IlI - _l01IlI, _l11IlI + _l01IlI, abs(h)) : 0.0);
_l1lOO = mix(_l1lOO, _lO0Il, inside);
}
if (_l1i1l > 0.001 && _l11IlI < 1.0) {
float d = abs(abs(h) - _l11IlI);
float _l1lll = 1.2 + 0.016 * OutSize.y * _l1i1l * _l1i1l;
_l1lll *= 1.0 - smoothstep(0.0, 0.6, _l11IlI) * 0.6;
float core = 1.0 - smoothstep(_l1lll * _l01IlI, (_l1lll + 1.5) * _l01IlI, d);
float glow = exp(-d / (_l01IlI * (_l1lll * 2.5 + 3.0))) * 0.7 + exp(-d / (_l01IlI * (_l1lll * 9.0 + 12.0))) * 0.3;
float _l1iIlI = _llIOi >= 0.0 ? 1.0 : exp(-_lI1Oi * 18.0);
core *= _llIOi >= 0.0 ? 1.0 : 0.0;
vec3 _lill1 = vec3(0.22, 0.52, 1.0);
vec3 hot = mix(vec3(0.55, 0.8, 1.0), vec3(0.95, 0.98, 1.0), _lIiIlI(_l1i1l * 1.4 - 0.2));
_l1lOO += (_lill1 * glow * 1.1 + hot * core) * _lIIlI * _l1i1l * _l1iIlI;
_l1lOO = mix(_l1lOO, hot, core * _lIIlI * _lIiIlI(_l1i1l * 1.5));
}
_l1lOO = mix(_l1lOO, _ll1IlI, _lIiIlI(Flash.a));
_l1lOO += (hash12(gl_FragCoord.xy + vec2(3.7, 1.3)) - 0.5) / 255.0;
fragColor = vec4(_l1lOO, 1.0);
}