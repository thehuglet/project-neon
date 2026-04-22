#version 430
#extension GL_ARB_bindless_texture : require

layout(location = 6) uniform vec2 viewportSize;
layout(location = 7) uniform int renderPass;

in flat uvec2 fragHandle;
in vec2 fragUV;
in float fragCellV;
in vec4 tintColor;

out vec4 finalColor;

vec3 hsv2rgb(vec3 hsv) {
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(hsv.xxx + K.xyz) * 6.0 - K.www);
    return hsv.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), hsv.y);
}

void main() {
    sampler2D tex = sampler2D(fragHandle);
    vec4 clean = texture(tex, fragCleanUV);
    vec2 blurredUV = fragCleanUV + vec2(0.0, fragCellV);
    vec4 blurred = texture(tex, blurredUV);

    if (renderPass == 0) {
        blurred *= tintColor;
        finalColor = blurred;
    } else {
        clean.rgb = mix(clean.rgb, tintColor.rgb, 0.8);
        finalColor = clean;
    }
}
