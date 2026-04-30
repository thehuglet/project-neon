#version 430
#extension GL_ARB_bindless_texture : require

uniform int renderPass;

in flat uvec2 fragHandle;
in vec2 cleanUV;
in vec2 blurUV;
in vec4 vColor;
in float vLifetimeT;
in float vHueShiftOverT;
in float vAlphaOverT;
in float vCleanColorizeFactor;

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

    float alphaOverTFactor = vLifetimeT;

    float hueShiftOverTFactor = vHueShiftOverT * (1.0 - vLifetimeT);
    vec3 shifted = fastShiftHue(vColor.rgb, hueShiftOverTFactor);

    vec4 tintColor = vec4(shifted, vColor.a * alphaOverTFactor);

    if (renderPass == 0) {
        col *= tintColor;
    } else {
        vec4 tint = mix(vec4(1.0), tintColor, vCleanColorizeFactor);
        col *= tint;
    }

    finalColor = col;
}
