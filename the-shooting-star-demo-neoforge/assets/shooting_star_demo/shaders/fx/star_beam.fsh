#include "star.glsl"
vec3 _lIIli(float r, float R) {
float k = saturate(r / max(R, 1e-3));
return mix(mix(vec3(1.0, 0.92, 0.94), _l1i01, smoothstep(0.02, 0.18, k)), _lIi01, smoothstep(0.12, 0.6, k));
}
void main() {
initPixel(texCoord);
_l100l = P0.y;
_li00l = P0.z;
float R = P0.x;
float _l1Ili = P2.w;
float _lIllI = P2.x;
vec3 rd = viewDir(texCoord);
vec3 _l1O0I = scenePosAt(texCoord);
bool sky = skyAt(texCoord);
float sceneT = sky ? FAR : length(_l1O0I);
vec3 base = sampleScene(texCoord);
vec3 glow = vec3(0.0);
vec2 axis = Target.xz;
float _l0iI1 = length(_l1O0I.xz - axis);
if (P1.x > 0.001) {
float tRay;
float _lIIiI = 0.07 + 0.9 * P1.z * P1.z;
float d = raySegmentDist(vec3(0.0), rd, Target, Target + vec3(0.0, 6000.0, 0.0), tRay);
if (tRay < sceneT) {
float w = max(_lIIiI, tRay * gPix * 0.7);
float core = saturate(1.2 - d / w) * min(1.0, _lIIiI * 2.5 / w + 0.35);
float _l10lI = exp(-d / (w * 5.0 + 0.4)) * 0.3 + exp(-d / (w * 30.0 + 4.0)) * 0.05 * (1.0 + 6.0 * P1.z);
float _liiOI = 0.85 + 0.15 * sin(_l100l * 43.0) * sin(_l100l * 29.0 + 1.3);
glow += (_lIi01 * (core * 4.0 + _l10lI) + _l1i01 * core * 1.5) * _liiOI * P1.x;
}
if (!sky) {
float _liIli = length(_l1O0I - Target);
float _lOIli = exp(-sqr(_liIli / (0.35 + 1.5 * P1.z)));
float halo = exp(-_liIli / (1.8 + 6.0 * P1.z));
glow += (vec3(1.0, 0.85, 0.85) * _lOIli * 3.0 + _lIi01 * halo * 1.4) * P0.w;
base = mix(base, base * vec3(1.2, 0.3, 0.3), saturate(halo * P0.w));
}
}
if (!sky && abs(_l1O0I.y - Target.y) < 40.0 + _l0iI1 * 0.4) {
float w = max(0.12, sceneT * gPix * 1.2);
float _l10ll = atan(_l1O0I.z - axis.y, _l1O0I.x - axis.x);
if (P3.x > 0.001 && _l0iI1 < 12.0) {
float spin = _l10ll + _l100l * 0.8;
float br = mix(11.0, 4.5, P3.x);
float _l0Ili = saturate(1.0 - abs(_l0iI1 - br) / w) * step(0.72, abs(cos(spin * 2.0)));
float ring = saturate(1.0 - abs(_l0iI1 - 2.6) / w) * step(0.5, fract(_l10ll / TAU * 24.0 + _l100l));
float cross = (saturate(1.0 - abs(_l1O0I.x - axis.x) / w) + saturate(1.0 - abs(_l1O0I.z - axis.y) / w))
* step(1.2, _l0iI1) * step(_l0iI1, 3.8);
glow += _lIi01 * (_l0Ili * 2.5 + ring * 1.5 + cross * 1.2) * P3.x;
}
if (P1.y > 0.001) {
float edge = saturate(1.1 - abs(_l0iI1 - _l1Ili) / w);
float _l0OII = fract((_l10ll / TAU) - _l100l * 0.35);
float _llI0I = exp(-_l0OII * 14.0) * step(_l0iI1, _l1Ili) * smoothstep(0.0, _l1Ili * 0.6, _l0iI1);
float _l0111 = step(0.86, fract(_l10ll / TAU * 72.0)) * step(abs(_l0iI1 - _l1Ili + 3.0), 2.0);
float _lil11 = fract(P3.y);
float _l0Ii1 = saturate(1.0 - abs(_l0iI1 - _l1Ili * (1.0 - _lil11)) / (w * 2.0 + 1.0)) * (1.0 - _lil11);
glow += _lIi01 * (edge * 2.2 + _l0111 * 1.2 + _llI0I * 0.35 + _l0Ii1 * 1.6) * P1.y;
base = mix(base, base * vec3(1.1, 0.75, 0.75), _llI0I * 0.3 * P1.y);
}
}
if (P1.z > 0.001) {
vec3 up = normalize(Target + vec3(0.0, 4000.0, 0.0));
float _ll1li = length(rd - up);
glow += _lIi01 * exp(-_ll1li / 0.35) * P1.z * P1.z * 0.6;
if (sky) {
float _lIii1 = sqr(sqr(P1.z)) * 0.9;
base = mix(base, base * 0.1 + vec3(0.05, 0.0, 0.01), _lIii1);
}
float _lI1li = 20.0 + 8980.0 * pow(max(1.0 - P1.z, 0.0), 1.5);
vec3 _li0OI = Target + vec3(0.0, _lI1li, 0.0);
vec3 _l01Il = project(_li0OI);
if (_l01Il.z > 0.0 && length(_li0OI) < sceneT) {
vec2 dd = (texCoord - _l01Il.xy) * vec2(OutSize.x / OutSize.y, 1.0);
float _l1lll = 1.0 / OutSize.y;
float g = smoothstep(0.2, 1.0, P1.z);
float _li1i1 = 0.7 + 0.3 * sin(_l100l * 53.0) * sin(_l100l * 31.0 + 2.0);
float _lll0I = (0.03 + 0.3 * g * g) * _li1i1;
float core = exp(-dot(dd, dd) / sqr(_l1lll * (1.2 + 3.5 * g)));
float cross = exp(-abs(dd.y) / (_l1lll * 0.8)) * exp(-abs(dd.x) / _lll0I)
+ exp(-abs(dd.x) / (_l1lll * 0.8)) * exp(-abs(dd.y) / _lll0I);
vec2 _lO1i1 = mat2(0.7071, 0.7071, -0.7071, 0.7071) * dd;
float _l01i1 = exp(-abs(_lO1i1.y) / (_l1lll * 0.6)) * exp(-abs(_lO1i1.x) / (_lll0I * 0.35))
+ exp(-abs(_lO1i1.x) / (_l1lll * 0.6)) * exp(-abs(_lO1i1.y) / (_lll0I * 0.35));
float halo = exp(-length(dd) / (_l1lll * (6.0 + 40.0 * g)));
glow += (vec3(1.0, 0.92, 0.92) * core * 5.0 + _lIi01 * (cross * 2.4 + _l01i1 * 1.1 + halo * 0.7)) * g * 1.6
+ _lIi01 * halo * 0.25 * P1.z;
}
}
if (P1.w > 0.001 && R > 0.05) {
float _l11li = saturate(_lIllI / 0.14);
float _lIlO1 = mix(Target.y + 3000.0, P3.z - 64.0, _l11li * _l11li);
vec2 o = -axis;
vec2 _li1li = rd.xz;
float _lO1li = length(_li1li);
float _li0l1 = _lO1li > 1e-5 ? -dot(o, _li1li) / (_lO1li * _lO1li) : 0.0;
float b = length(o + _li1li * _li0l1);
vec2 _l0i0I = rayCylinderY(vec3(0.0), rd, vec3(Target.x, 0.0, Target.z), R);
bool _l1II1 = false;
if (_l0i0I.y > 0.0) {
float t0 = max(_l0i0I.x, 0.0);
float t1 = min(_l0i0I.y, sceneT);
if (rd.y < -1e-4) {
float tf = _lIlO1 / rd.y;
t1 = tf > 0.0 ? min(t1, tf) : -1.0;
} else if (rd.y > 1e-4) {
t0 = max(t0, _lIlO1 / rd.y);
} else if (_lIlO1 > 0.0) {
t1 = -1.0;
}
if (t1 > t0) {
_l1II1 = true;
float x = saturate(b / R);
float _l01li = 0.07;
float _llili = (t0 - _li0l1) * _lO1li / R;
float _lIili = (t1 - _li0l1) * _lO1li / R;
float _lIIlI = smoothstep(-1.4 * _l01li, 1.4 * _l01li, _lIili) - smoothstep(-1.4 * _l01li, 1.4 * _l01li, _llili);
float _l1ili = exp(-sqr(x / _l01li)) * _lIIlI;
vec3 _liili = rd * t0;
float a0 = atan(_liili.z - axis.y, _liili.x - axis.x + 1e-6);
float _lOili = _l100l * 260.0;
float _l0lII = fbm2(vec2(a0 * R * 0.05 + _liili.y * 0.01, (_liili.y + _lOili) * 0.016));
float _l0ili = 0.5 + 0.5 * sin((_liili.y + _lOili * 1.5) * 0.04 + a0 * 3.0);
float energy = 0.7 + 0.45 * _l0lII * (0.6 + 0.4 * _l0ili);
vec3 _llOi1 = vec3(0.62, 0.0, 0.02);
vec3 red = vec3(0.96, 0.02, 0.05);
vec3 hot = vec3(0.98, 0.3, 0.3);
vec3 c = mix(red, _llOi1, smoothstep(0.45, 1.0, x));
c = mix(c, hot, smoothstep(0.3, 0.0, x) * 0.75);
c *= energy;
float _llOli = exp(-(1.0 - x) * R / (R * 0.01 + 0.25));
c = mix(c, vec3(1.0, 0.12, 0.14), _llOli * 0.8);
c = mix(c, vec3(1.0, 0.92, 0.92), saturate(_l1ili * 1.3));
float _lIOli = 0.94 + 0.06 * sin(_l100l * 60.0) * sin(_l100l * 37.0);
base = mix(base, c * _lIOli, P1.w);
glow *= 1.0 - P1.w;
}
}
if (!_l1II1) {
float _ll1OI = P1.w * _l11li * (1.0 - P2.y);
base = mix(base, base * vec3(0.55, 0.12, 0.14), _ll1OI * 0.8);
}
if (!_l1II1 && _li0l1 > 0.0 && _li0l1 < sceneT) {
float _l1Oli = max(b - R, 0.0);
float _lO0l1 = exp(-_l1Oli / (R * 0.16)) * 0.4 + exp(-_l1Oli / (R * 1.2)) * 0.12;
glow += vec3(1.0, 0.02, 0.05) * _lO0l1 * P1.w * _l11li;
}
if (!sky && _l0iI1 > R) {
float wall = _l0iI1 - R;
float _l1iIl = R * 1.6 / (wall + R * 0.25) * exp(-wall / (R * 2.5));
base = mix(base, base * vec3(1.9, 0.35, 0.35), saturate(_l1iIl * 0.5) * P1.w);
glow += vec3(1.0, 0.05, 0.08) * exp(-wall / 6.0) * 1.2 * P1.w * _l11li;
}
if (!sky && _lIllI > 0.0 && _lIllI < 3.0) {
float _l0I1l = R + _lIllI * 160.0;
float ring = exp(-abs(_l0iI1 - _l0I1l) / (4.0 + _lIllI * 5.0)) * (1.0 - _lIllI / 3.0);
glow += mix(_l1i01, _lIi01, _lIllI / 3.0) * ring * 2.5 * step(abs(_l1O0I.y - Target.y), 40.0 + _lIllI * 30.0);
}
}
if (!sky && P2.z > 0.001) {
float _liOli = _l1Ili - _l0iI1;
if (_liOli > -1.5 && _liOli < 6.0 && _l1O0I.y < P3.w + 2.0) {
float _lllOI = P2.z * exp(-max(_liOli, 0.0) / 2.5) * smoothstep(-1.5, 0.3, _liOli);
float _l0ii1 = fbm2(vec2(atan(_l1O0I.z - axis.y, _l1O0I.x - axis.x) * _l1Ili * 0.35, _l1O0I.y * 0.35));
float _lOOli = smoothstep(P3.w + 2.0, P3.w - 120.0, _l1O0I.y) * 0.4 + 0.6;
float t = _lllOI * (0.55 + 0.45 * _l0ii1) * _lOOli;
glow += _l0IOI(0.15 + 0.55 * t) * t * 2.6;
base = mix(base, base * vec3(0.35, 0.2, 0.18), saturate(_lllOI));
}
float _liIlI = exp(-abs(_l0iI1 - _l1Ili) / 0.8) * smoothstep(P3.w - 6.0, P3.w + 1.0, _l1O0I.y);
glow += _l0IOI(0.35 + 0.4 * P2.z) * _liIlI * P2.z * 2.0;
}
fragColor = vec4(tonemap(base + glow), 1.0);
}