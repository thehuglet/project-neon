#version 430
#extension GL_ARB_bindless_texture : require

layout(location = 6) uniform vec2 viewportSize;
layout(location = 7) uniform int renderPass;

in flat uvec2 fragHandle;
in vec2 cleanUV;
in vec2 blurUV;
in vec4 vColor;
in float vLifetimeT;
in float vHueShiftOverT;
in float vAlphaOverT;

out vec4 finalColor;

vec3 fastShiftHue(vec3 color, float shift) {
    float c = cos(shift);
    float s = sin(shift);

    mat3 rot = mat3(
            c + (1.0 - c) / 3.0, (1.0 - c) / 3.0 - s / 1.73205, (1.0 - c) / 3.0 + s / 1.73205,
            (1.0 - c) / 3.0 + s / 1.73205, c + (1.0 - c) / 3.0, (1.0 - c) / 3.0 - s / 1.73205,
            (1.0 - c) / 3.0 - s / 1.73205, (1.0 - c) / 3.0 + s / 1.73205, c + (1.0 - c) / 3.0
        );

    return rot * color;
}

void main() {
    sampler2D tex = sampler2D(fragHandle);
    vec2 uv = (renderPass == 0) ? blurUV : cleanUV;
    vec4 col = texture(tex, uv);

    // float alphaOverTFactor = clamp(1.0 + (vAlphaOverT - 1.0) * (1.0 - vLifetimeT), 0.0, 1.0);
    float alphaOverTFactor = vLifetimeT;

    float hueShiftOverTFactor = vHueShiftOverT * (1.0 - vLifetimeT);
    vec3 shifted = fastShiftHue(vColor.rgb, hueShiftOverTFactor);
    vec4 tintColor = vec4(shifted, vColor.a * alphaOverTFactor);

    col *= tintColor;

    finalColor = col;
}
