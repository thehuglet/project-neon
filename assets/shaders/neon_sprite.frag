#version 330

in vec2 fragTexCoord;
in vec4 fragColor;
in float hueShift;
in float lightnessShift;
in float alphaScale;

uniform sampler2D texture0;
uniform vec4 colDiffuse;

out vec4 finalColor;

vec3 shiftLightness(vec3 color, float shift) {
    return color + (vec3(1.0) - color) * shift;
}

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
    vec4 color = texture(texture0, fragTexCoord);

    // Tint
    color *= fragColor * colDiffuse;

    // Hue shift
    color.rgb = fastShiftHue(color.rgb, hueShift);

    // Lightness shift
    color.rgb = shiftLightness(color.rgb, lightnessShift);

    // Alpha boost
    color.a *= alphaScale;

    finalColor = color;
}
