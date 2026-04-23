#version 430
#extension GL_ARB_bindless_texture : require

layout(location = 6) uniform vec2 viewportSize;
layout(location = 7) uniform int renderPass;

// in vec2 fragUV;
// // in float fragCellV;
in flat uvec2 fragHandle;
in vec2 cleanUV;
in vec2 blurUV;
in vec4 tintColor;

out vec4 finalColor;

// vec3 hsv2rgb(vec3 hsv) {
//     vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
//     vec3 p = abs(fract(hsv.xxx + K.xyz) * 6.0 - K.www);
//     return hsv.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), hsv.y);
// }

void main() {
    sampler2D tex = sampler2D(fragHandle);

    vec2 uv = (renderPass == 0) ? blurUV : cleanUV;

    vec4 col = texture(tex, uv);
    col *= tintColor;

    finalColor = col;
}
