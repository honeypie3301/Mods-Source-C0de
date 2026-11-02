uniform vec4 TitleSeg[72];
uniform vec4 TitleL[48];
uniform vec4 TitleA;
uniform vec4 TitleB;
int _lil0l() {
return int(TitleA.x + 0.5) + int(TitleA.w);
}
vec4 _llIIlI(int i) {
vec4 s = TitleSeg[i];
float _l0Oi1 = floor(s.x / 8.0 + 0.01);
float _ll0i1 = floor(s.y / 8.0 + 0.01);
return vec4(s.x - 8.0 * _l0Oi1, _l0Oi1, s.y - 8.0 * _ll0i1, _ll0i1);
}
float _lO10l(int _lIIIlI, vec2 p, out float along, out float _l110l, out vec2 away, out vec2 tangent) {
float _l1IIlI = TitleL[_lIIIlI * 4 + 1].w;
int count = int(floor(_l1IIlI / 128.0 + 0.01));
int first = int(_l1IIlI - float(count) * 128.0 + 0.5);
float best = 1e9;
along = 0.0;
_l110l = 1e9;
away = vec2(0.0, 1.0);
tangent = vec2(1.0, 0.0);
for (int i = first; i < first + count; i++) {
vec4 s = _llIIlI(i);
vec2 ba = s.zw - s.xy;
vec2 pa = p - s.xy;
float _liIIlI = dot(ba, ba);
float h = _liIIlI > 1e-6 ? clamp(dot(pa, ba) / _liIIlI, 0.0, 1.0) : 0.0;
vec2 off = pa - ba * h;
float d = length(off);
if (d < best) {
best = d;
float _lll0I = sqrt(_liIIlI);
along = TitleSeg[i].z + h * _lll0I;
_l110l = min(along, TitleSeg[i].w - along);
tangent = _lll0I > 1e-3 ? ba / _lll0I : vec2(1.0, 0.0);
away = d > 1e-4 ? off / d : vec2(-tangent.y, tangent.x);
}
}
return best;
}
float _l0I0l(int _lIIIlI, vec3 ro, vec3 rd, out vec3 lo, out vec3 _lOI0l) {
vec4 c = TitleL[_lIIIlI * 4];
vec3 x = TitleL[_lIIIlI * 4 + 1].xyz;
vec3 y = TitleL[_lIIIlI * 4 + 2].xyz;
vec3 z = cross(x, y);
vec3 o = ro - c.xyz;
lo = vec3(dot(o, x), dot(o, y), dot(o, z)) / c.w + vec3(2.0, 3.0, 0.0);
_lOI0l = vec3(dot(rd, x), dot(rd, y), dot(rd, z));
return c.w;
}
vec3 _l1i0l(int _lIIIlI, vec3 v) {
vec3 x = TitleL[_lIIIlI * 4 + 1].xyz;
vec3 y = TitleL[_lIIIlI * 4 + 2].xyz;
return x * v.x + y * v.y + cross(x, y) * v.z;
}
vec2 _lI10l(vec3 ro, vec3 rd, vec3 lo, vec3 hi) {
vec3 inv = 1.0 / mix(rd, vec3(1e-6), lessThan(abs(rd), vec3(1e-6)));
vec3 t0 = (lo - ro) * inv;
vec3 t1 = (hi - ro) * inv;
vec3 a = min(t0, t1);
vec3 b = max(t0, t1);
return vec2(max(max(a.x, a.y), a.z), min(min(b.x, b.y), b.z));
}
vec3 _lli0l(vec2 p, vec2 b) {
vec2 s = vec2(p.x < 0.0 ? -1.0 : 1.0, p.y < 0.0 ? -1.0 : 1.0);
vec2 q = abs(p) - b;
if (q.x > 0.0 || q.y > 0.0) {
vec2 _l00II = max(q, 0.0);
float _ll0ll = length(_l00II);
return vec3(_ll0ll, s * _l00II / max(_ll0ll, 1e-6));
}
return q.x > q.y ? vec3(q.x, s.x, 0.0) : vec3(q.y, 0.0, s.y);
}