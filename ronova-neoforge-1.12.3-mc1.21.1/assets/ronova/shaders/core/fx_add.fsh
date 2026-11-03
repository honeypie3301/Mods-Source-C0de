#version 150
// Ronova (порт 1.21.1): ванильный rendertype_entity_translucent.fsh с порогом альфы AlphaCut (тип рендера задаёт свой —
// у ванили 0.1 резал мягкие градиенты) и без тумана: аддитивные типы (ореол крыльев) — туман подмешивал бы свой цвет и в чёрное, а в GUI гасил свет целиком

#moj_import <fog.glsl>

uniform sampler2D Sampler0;

uniform vec4 ColorModulator;
uniform float FogStart;
uniform float FogEnd;
uniform vec4 FogColor;
uniform float AlphaCut;
uniform float AirFog;

in float vertexDistance;
in vec4 vertexColor;
in vec4 lightMapColor;
in vec4 overlayColor;
in vec2 texCoord0;

out vec4 fragColor;

void main() {
    vec4 color = texture(Sampler0, texCoord0);
    if (color.a < AlphaCut) {
        discard;
    }
    color *= vertexColor * ColorModulator;
    color.rgb = mix(overlayColor.rgb, color.rgb, overlayColor.a);
    color *= lightMapColor;
    fragColor = color;
}
