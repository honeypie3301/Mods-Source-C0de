uniform sampler2D MilkyWay;
uniform sampler2D Nebula;
uniform vec3 SkyDir;
uniform vec3 SkyX;
uniform vec3 SkyY;
vec2 _lIiOl(vec3 d) {
return vec2(atan(d.z, d.x) / TAU + 0.5, acos(clamp(d.y, -1.0, 1.0)) / PI);
}
vec3 _l1iOl(vec3 rd) {
vec3 col = textureLod(MilkyWay, _lIiOl(rd), 0.0).rgb * 0.85 + vec3(0.004, 0.006, 0.016);
float facing = dot(rd, SkyDir);
if (facing > 0.08) {
vec2 q = vec2(dot(rd, SkyX), dot(rd, SkyY)) / facing;
vec2 _liiOl = q * 0.3 + 0.5;
float edge = 1.0 - smoothstep(0.3, 0.5, max(abs(_liiOl.x - 0.5), abs(_liiOl.y - 0.5)));
vec3 _lOiOl = textureLod(Nebula, clamp(_liiOl, 0.0, 1.0), 0.0).rgb;
_lOiOl = vec3(_lOiOl.r * 0.45 + _lOiOl.b * 0.1, _lOiOl.g * 0.9 + _lOiOl.r * 0.18, _lOiOl.b + _lOiOl.r * 0.4);
col += _lOiOl * edge * 0.8;
}
return col;
}