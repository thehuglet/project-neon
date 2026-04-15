#version 430

layout(local_size_x = 1024, local_size_y = 1, local_size_z = 1) in;

layout(std430, binding = 0) buffer SSBO_0 {
    vec4 data_0[];
};
layout(std430, binding = 1) buffer SSBO_1 {
    vec4 data_1[];
};

layout(location = 0) uniform float deltaTime;
layout(location = 1) uniform float speed;

#define pos(idx)          (data_0[(idx)].xy)
#define lifetime_sec(idx) (data_0[(idx)].x)

void main() {
    uint idx = gl_GlobalInvocationID.x;

    // Test upward movement
    pos(idx).x += speed * deltaTime;

    // Test clamp
    if (pos(idx).x > 1.0) pos(idx).x = -1.0;
    if (pos(idx).x < -1.0) pos(idx).x = 1.0;

    // velocities[index].xy = vec2(0.0, 0.0);
}
