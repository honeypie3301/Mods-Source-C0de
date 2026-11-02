uniform float Shake;
uniform float Aberration;
uniform float Desaturate;
uniform float ZoomBlur;
uniform float Bloom;
uniform vec4 Flash;
uniform vec4 Vignette;
uniform vec4 Impact;
uniform sampler2D SceneSampler;
uniform sampler2D SceneLowSampler;
uniform float Upscaled;
uniform sampler2D ExposureSampler;
uniform float AutoExposure;
uniform sampler2D HoldSampler;
uniform vec4 Grade;
float _lllll() {
if (AutoExposure < 0.5) {
return 1.0;
}
float _lIlll = 0.0;
for (int i = 0; i < 16; i++) {
vec2 p = (vec2(float(i - (i / 4) * 4), float(i / 4)) + 0.5) / 4.0;
_lIlll += lum(texture(ExposureSampler, p).rgb);
}
_lIlll /= 16.0;
return 1.0 / (1.0 + max(_lIlll - 0.05, 0.0) * 3.0);
}
vec3 _l1lll(vec2 uv) {
uv = clamp(uv, 0.001, 0.999);
vec3 _lilll = texture(DiffuseSampler, uv).rgb;
if (Upscaled > 0.001) {
vec3 _lOlll = texture(SceneSampler, uv).rgb;
vec3 _l0lll = texture(SceneLowSampler, uv).rgb;
_lilll *= mix(vec3(1.0), clamp((_lOlll + 0.03) / (_l0lll + 0.03), 0.5, 2.0), Upscaled);
}
return _lilll;
}
vec3 _llIll(vec2 uv, vec2 _lIIll, float _l1Ill) {
if (_l1Ill < 1e-5) {
return _l1lll(uv);
}
return vec3(_l1lll(uv + _lIIll * _l1Ill).r, _l1lll(uv).g, _l1lll(uv - _lIIll * _l1Ill).b);
}
vec3 _liIll(vec2 uv) {
return texture(AuxSampler, clamp(uv, 0.001, 0.999)).rgb;
}
const vec3 _lOIll = vec3(0.18, 0.55, 1.0);
vec3 _l0Ill(int i) {
return i == 0 ? vec3(0.02, 0.04, 0.2) : i == 1 ? vec3(0.04, 0.12, 0.5) : i == 2 ? vec3(0.07, 0.28, 0.9)
: i == 3 ? vec3(0.16, 0.5, 1.0) : i == 4 ? vec3(0.3, 0.74, 1.0) : i == 5 ? vec3(0.58, 0.9, 1.0)
: vec3(0.88, 0.96, 1.0);
}
vec3 _ll1ll(float h) {
float x = fract(h) * 7.0;
int i = int(floor(x));
float f = x - float(i);
f = f * f * (3.0 - 2.0 * f);
return mix(_l0Ill(i), _l0Ill(i == 6 ? 0 : i + 1), f);
}
void main() {
vec2 uv = texCoord;
float t = GTime;
vec2 _lI1ll = vec2(vnoise2(vec2(t * 31.0, 1.7)), vnoise2(vec2(5.3, t * 29.0))) - 0.5;
uv += _lI1ll * Shake * 0.03;
vec2 c = uv - 0.5;
float _l11ll = OutSize.x / OutSize.y;
float _l1Ill = Aberration * 0.018 * dot(c * vec2(_l11ll, 1.0), c * vec2(_l11ll, 1.0)) * 2.0;
vec3 col = _llIll(uv, c, _l1Ill);
vec3 bloom = _liIll(uv);
if (ZoomBlur > 0.001) {
vec3 _li1ll = col;
vec3 _lO1ll = bloom;
float _l01ll = 1.0;
for (int i = 1; i < 10; i++) {
float k = float(i) / 10.0;
vec2 _llill = 0.5 + c * (1.0 - ZoomBlur * 0.12 * k);
float w = 1.0 - k * 0.6;
_li1ll += _llIll(_llill, c, _l1Ill) * w;
_lO1ll += _liIll(_llill) * w;
_l01ll += w;
}
col = _li1ll / _l01ll;
bloom = _lO1ll / _l01ll;
}
float _lIill = _lllll();
col *= _lIill;
bloom *= _lIill;
vec3 b = bloom * Bloom;
col = col + b - col * b * 0.35;
float grey = lum(col);
vec3 _l1ill = col;
col = mix(col, vec3(grey) * vec3(0.92, 1.0, 0.97), saturate(Desaturate));
col = mix(col, _l1ill * 1.15, Grade.w * smoothstep(0.62, 0.95, grey));
if (Grade.x > 0.001) {
col = clamp((col - 0.42) * (1.0 + Grade.x) + 0.42, 0.0, 1.6);
}
float edge = smoothstep(0.25, 0.95, length(c * vec2(_l11ll * 0.8, 1.0)) * 1.3);
col = mix(col, Vignette.rgb * (0.35 + 0.65 * grey), saturate(Vignette.a * edge));
if (Grade.z > 0.001) {
vec3 held = vec3(0.0);
for (int i = 0; i < 5; i++) {
vec2 o = i == 0 ? vec2(0.0) : vec2(cos(float(i) * 1.571), sin(float(i) * 1.571)) * 0.006;
held += texture(HoldSampler, clamp(texCoord + o, 0.001, 0.999)).rgb;
}
float _liill = smoothstep(0.08, 0.9, lum(held / 5.0)) * saturate(Grade.z);
col = 1.0 - (1.0 - col) * (1.0 - _liill * vec3(1.0, 0.96, 0.88));
}
col += Flash.rgb * Flash.a;
col = mix(col, vec3(1.0), saturate(Flash.a - 1.0));
if (Grade.y > 0.001) {
col += (hash12(texCoord * OutSize + fract(t * 7.3) * 431.0) - 0.5) * Grade.y * 0.2;
}
if (Impact.x > 0.001) {
float _lOill = Impact.y;
vec3 _l0ill = vec3(1.0, 0.33, 0.06);
bool _llOll = false;
bool _lIOll = false;
if (_lOill > 41.5 && _lOill < 44.5) {
_lOill -= 9.0;
_lIOll = true;
} else if (_lOill > 35.5 && _lOill < 41.5) {
_lOill -= 21.0;
_l0ill = _lOIll;
_lIOll = true;
} else if (_lOill > 26.5 && _lOill < 32.5) {
_lOill -= 12.0;
_llOll = true;
} else if (_lOill > 20.5 && _lOill < 26.5) {
_lOill -= 6.0;
_l0ill = vec3(0.64, 0.46, 1.0);
}
vec2 _l1Oll = 1.5 / OutSize;
float _liOll = lum(texture(DiffuseSampler, uv + vec2(_l1Oll.x, 0.0)).rgb) - lum(texture(DiffuseSampler, uv - vec2(_l1Oll.x, 0.0)).rgb);
float _lOOll = lum(texture(DiffuseSampler, uv + vec2(0.0, _l1Oll.y)).rgb) - lum(texture(DiffuseSampler, uv - vec2(0.0, _l1Oll.y)).rgb);
float _l0Oll = smoothstep(0.06, 0.18, length(vec2(_liOll, _lOOll)));
float _ll0ll = lum(_l1lll(uv));
float _lI0ll = 0.0;
for (int i = 0; i < 8; i++) {
float a = float(i) * 0.785398;
_lI0ll += lum(_l1lll(uv + vec2(cos(a) / _l11ll, sin(a)) * 0.045));
}
_lI0ll /= 8.0;
float two = step(_lI0ll + 0.004, _ll0ll);
vec2 d = (texCoord - Impact.zw) * vec2(_l11ll, 1.0);
float _l10ll = atan(d.y, d.x);
if (_llOll) {
_l0ill = prism7(_l10ll / TAU + length(d) * 0.9 - t * 0.7);
}
vec3 frame;
vec2 tp = mat2(0.7071, -0.7071, 0.7071, 0.7071) * (texCoord * OutSize) / 5.0;
float _li0ll = saturate((_ll0ll - _lI0ll) * 5.0 + 0.5);
float _lO0ll = step(length(fract(tp) - 0.5), sqrt(saturate(1.0 - _li0ll)) * 0.62);
float _l00ll = smoothstep(0.15, 0.35, _li0ll) * (1.0 - smoothstep(0.65, 0.85, _li0ll));
float core = step(_lI0ll + 0.18, _ll0ll);
if (_lOill > 32.5) {
vec3 black = vec3(0.01, 0.008, 0.02);
if (_lOill < 33.5) {
vec2 _lllIl = normalize(d + 1e-5) / vec2(_l11ll, 1.0);
vec3 _li1ll = vec3(0.0);
for (int k = 0; k < 7; k++) {
vec2 o = uv + _lllIl * float(k - 3) * (0.0035 + 0.004 * length(d));
float _lIlIl = lum(texture(DiffuseSampler, o + vec2(_l1Oll.x, 0.0)).rgb) - lum(texture(DiffuseSampler, o - vec2(_l1Oll.x, 0.0)).rgb);
float _l1lIl = lum(texture(DiffuseSampler, o + vec2(0.0, _l1Oll.y)).rgb) - lum(texture(DiffuseSampler, o - vec2(0.0, _l1Oll.y)).rgb);
_li1ll += (_lIOll ? _ll1ll(float(k) / 7.0) : prism7(float(k) / 7.0)) * smoothstep(0.05, 0.16, length(vec2(_lIlIl, _l1lIl)));
}
frame = black + _li1ll * 0.75;
frame = mix(frame, vec3(1.0), core * 0.9);
} else if (_lOill < 34.5) {
float band = floor(saturate((_ll0ll - _lI0ll) * 2.4 + 0.5) * 6.999);
int ring = int(floor(length(d) * 9.0 - t * 6.0));
int _lilIl = int(mod(float(6 - int(band) + ring), 7.0));
frame = _lIOll ? _l0Ill(_lilIl) : prismStop(_lilIl);
frame = mix(frame, vec3(1.0), core);
frame = mix(frame, black, _l0Oll * 0.9);
} else {
vec2 sp = texCoord * OutSize / 46.0;
float _lOlIl = 1.0;
_lOlIl = min(_lOlIl, abs(fract(dot(sp, vec2(-0.5, 0.866))) - 0.5));
_lOlIl = min(_lOlIl, abs(fract(dot(sp, vec2(0.5, 0.866))) - 0.5));
_lOlIl = min(_lOlIl, abs(fract(sp.x * 1.1547) - 0.5));
float _l0lIl = smoothstep(0.035, 0.0, _lOlIl);
vec3 _llIIl = _lIOll ? _ll1ll(dot(texCoord, vec2(0.6, 0.4)) + t * 0.5) : prism7(dot(texCoord, vec2(0.6, 0.4)) + t * 0.5);
frame = black + _llIIl * _l0lIl * 0.28;
frame = mix(frame, _llIIl * 1.1, _l0Oll);
frame = mix(frame, vec3(1.0), core * 0.85);
}
} else if (_lOill < 0.5) {
frame = vec3(1.0 - two) * (1.0 - _l0Oll);
frame = mix(frame, vec3(1.0 - _lO0ll), _l00ll * 0.8);
} else if (_lOill < 1.5) {
frame = vec3(two) * (1.0 - _l0Oll);
frame = mix(frame, vec3(_lO0ll), _l00ll * 0.8);
} else if (_lOill < 2.5) {
frame = mix(vec3(0.05, 0.0, 0.0), vec3(1.0, 0.1, 0.12), two) * (1.0 - _l0Oll);
frame = mix(frame, vec3(1.0, 0.1, 0.12) * _lO0ll, _l00ll * 0.7);
} else if (_lOill < 5.5) {
vec3 _l0ill = _lOill < 3.5 ? vec3(0.35, 0.9, 1.0) : _lOill < 4.5 ? vec3(0.22, 0.42, 1.0)
: vec3(1.0, 0.22, 0.9);
frame = mix(vec3(0.0), _l0ill, two);
frame = mix(frame, vec3(1.0), core);
frame = mix(frame, _l0ill * _lO0ll, _l00ll * 0.75);
frame *= 1.0 - _l0Oll;
} else if (_lOill < 6.5) {
vec3 _lIIIl = 1.0 - _l1lll(uv);
float g = lum(_lIIIl);
frame = clamp((mix(vec3(g), _lIIIl, 1.8) - 0.5) * 1.6 + 0.5, 0.0, 1.0) * (1.0 - _l0Oll * 0.7);
} else if (_lOill > 16.5) {
vec3 black = vec3(0.012, 0.006, 0.006);
vec3 _l1IIl = _l0ill;
vec3 white = _llOll ? vec3(1.0) : _l0ill.b > 0.5 ? vec3(0.95, 0.94, 1.0) : vec3(1.0, 0.93, 0.82);
if (_lOill > 19.5) {
float _liIIl = floor(t * 20.0);
float band = floor(texCoord.y * OutSize.y / 18.0);
float _lOIIl = (hash11(band * 13.1 + _liIIl) - 0.5) * 0.16 * step(0.5, hash11(band * 7.7 + _liIIl * 3.0));
vec2 _l0IIl = floor(texCoord * OutSize / vec2(64.0, 36.0));
vec2 _ll1Il = (vec2(hash12(_l0IIl + _liIIl), hash12(_l0IIl * 1.7 + _liIIl)) - 0.5) * 0.08 * step(0.86, hash12(_l0IIl * 3.1 + _liIIl));
vec2 g = texCoord + vec2(_lOIIl, 0.0) + _ll1Il;
float _lI1Il = 0.006 + 0.01 * hash11(_liIIl);
vec3 _l11Il = vec3(_l1lll(g + vec2(_lI1Il, 0.0)).r, _l1lll(g).g, _l1lll(g - vec2(_lI1Il, 0.0)).b);
float _li1Il = lum(_l11Il);
frame = _li1Il < 0.25 ? black : _li1Il < 0.6 ? _l1IIl : white;
frame.r += max(_l11Il.r - _li1Il, 0.0) * 1.2;
frame.gb += max(_l11Il.b - _li1Il, 0.0) * vec2(0.9, 1.4);
frame *= 0.72 + 0.28 * step(0.5, fract(texCoord.y * OutSize.y / 3.0));
float _lO1Il = step(0.975, hash12(floor(texCoord * OutSize / vec2(24.0, 8.0)) + _liIIl * 7.0));
frame = mix(frame, hash11(_liIIl + _l0IIl.x) > 0.5 ? white : vec3(0.3, 0.9, 1.0), _lO1Il * 0.85);
} else if (_lOill > 18.5) {
vec2 _l01Il = mat2(0.866, -0.5, 0.5, 0.866) * (texCoord * OutSize) / 12.0;
float _lliIl = step(length(fract(_l01Il) - 0.5), sqrt(saturate((_ll0ll - _lI0ll) * 3.0 + 0.5)) * 0.64);
frame = mix(black, _l1IIl, _lliIl);
frame = mix(frame, white, core);
frame = mix(frame, black, _l0Oll * 0.85);
} else if (_lOill > 17.5) {
float _l10ll = hash11(floor(t * 20.0) + 3.0) * PI;
vec2 _lIiIl = vec2(cos(_l10ll), sin(_l10ll));
float along = dot(d, vec2(-_lIiIl.y, _lIiIl.x));
float side = dot(d, _lIiIl) + (vnoise2(vec2(along * 38.0, floor(t * 20.0))) - 0.5) * 0.02;
float a = step(0.0, side);
float _l1iIl = mix(two, 1.0 - two, a);
frame = mix(black, _l1IIl, _l1iIl);
frame = mix(frame, a > 0.5 ? black : _l1IIl, _l0Oll * _l1iIl);
frame = mix(frame, white, saturate(exp(-abs(side) / 0.0035) * 1.6));
} else {
frame = mix(black, _l1IIl, _l0Oll);
frame = mix(frame, white, core);
}
} else if (_lOill > 14.5) {
vec3 black = vec3(0.012, 0.006, 0.006);
vec3 _l1IIl = _l0ill;
float _l1iIl = _lOill < 15.5 ? two : 1.0 - two;
frame = mix(black, _l1IIl, _l1iIl);
frame = mix(frame, _lIOll ? vec3(0.92, 0.97, 1.0) : vec3(1.0, 0.93, 0.82), core * (_lOill < 15.5 ? 1.0 : 0.0));
frame = mix(frame, mix(black, _l1IIl, _lO0ll), _l00ll * 0.7);
frame = mix(frame, black, _l0Oll * _l1iIl);
} else if (_lOill > 12.5) {
vec3 _liiIl = vec3(0.035, 0.045, 0.16);
vec3 _lOiIl = vec3(1.0, 0.8, 0.12);
float _l1iIl = _lOill < 13.5 ? two : 1.0 - two;
frame = mix(_liiIl, _lOiIl, _l1iIl);
frame = mix(frame, vec3(1.0, 0.98, 0.9), core * (_lOill < 13.5 ? 1.0 : 0.0));
frame = mix(frame, mix(_liiIl, _lOiIl, _lO0ll), _l00ll * 0.7);
frame = mix(frame, _liiIl * 0.5, _l0Oll * _l1iIl);
} else if (_lOill > 10.5) {
vec3 _lOiIl = vec3(1.0, 0.84, 0.1);
vec3 white = vec3(1.0, 0.99, 0.95);
float _l1iIl = _lOill < 11.5 ? two : 1.0 - two;
frame = mix(_lOiIl, white, _l1iIl);
frame = mix(frame, mix(white, _lOiIl, _lO0ll), _l00ll * 0.7);
frame = mix(frame, vec3(0.62, 0.26, 0.0), _l0Oll * _l1iIl);
} else if (_lOill > 8.5) {
vec3 _l0iIl = vec3(0.98, 0.58, 0.08);
vec3 white = vec3(1.0, 0.98, 0.94);
float _l1iIl = _lOill < 9.5 ? two : 1.0 - two;
frame = mix(_l0iIl, white, _l1iIl);
frame = mix(frame, mix(white, _l0iIl, _lO0ll), _l00ll * 0.7);
frame = mix(frame, vec3(0.35, 0.12, 0.0), _l0Oll * _l1iIl);
} else {
vec3 red = vec3(0.93, 0.03, 0.07);
vec3 white = vec3(1.0, 0.97, 0.97);
float _l1iIl = _lOill < 7.5 ? two : 1.0 - two;
frame = mix(red, white, _l1iIl);
frame = mix(frame, mix(white, red, _lO0ll), _l00ll * 0.7);
frame = mix(frame, red, _l0Oll * _l1iIl);
}
col = mix(col, frame, saturate(Impact.x));
}
fragColor = vec4(col, 1.0);
}