vec3 _liiIlI(vec3 c) {
c = max(c, vec3(0.0));
return c / (vec3(1.0) + c);
}
vec3 _l0IIlI(vec3 e) {
e = clamp(e, vec3(0.0), vec3(0.996));
return e / (vec3(1.0) - e);
}
vec3 _lOiIlI(vec3 e, vec2 _l0iIlI) {
return e + (hash12(_l0iIlI + vec2(17.31, 5.17)) - 0.5) / 255.0;
}
float _lIiIlI(float x) {
return clamp(x, 0.0, 1.0);
}
float _llOIlI(float x, float w) {
float k = x / max(w, 1e-5);
return exp(-k * k);
}