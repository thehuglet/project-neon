#version 430

layout(location = 0) in vec2 vertexPosition;

layout(location = 0) uniform float particleScale;
layout(location = 1) uniform mat4 projection;

layout(std430, binding = 0) buffer ParticleState_0 {
    vec4 state_0[];
};
layout(std430, binding = 1) buffer ParticleState_1 {
    vec4 state_1[];
};

out vec4 fragColor;

// Accessors to packed data
#define pos(index)            (state_0[(index)].xy)
#define lifetime_sec(index)   (state_0[(index)].z)

vec3 hsv2rgb(vec3 hsv) {
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(hsv.xxx + K.xyz) * 6.0 - K.www);
    return hsv.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), hsv.y);
}

void main() {
    vec2 position = pos(gl_InstanceID);

    // [-1, 1] to [0, 1]
    float hue = (position.x + 1.0) * 0.5;
    vec3 rgb = hsv2rgb(vec3(hue, 1.0, 1.0));
    fragColor = vec4(rgb, 1.0);

    float scale = 0.001 * particleScale;
    vec2 vertex = vertexPosition * scale;
    vec2 worldPos = position + vertex;
    gl_Position = projection * vec4(worldPos, 0.0, 1.0);
}
