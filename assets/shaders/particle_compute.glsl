#version 430

layout(local_size_x = 1024, local_size_y = 1, local_size_z = 1) in;

layout(std430, binding = 0) readonly buffer CurrentSSBO_0 {
    vec4 currentData_0[];
};
layout(std430, binding = 1) readonly buffer CurrentSSBO_1 {
    vec4 currentData_1[];
};

layout(std430, binding = 2) buffer NextSSBO_0 {
    vec4 nextData_0[];
};
layout(std430, binding = 3) buffer NextSSBO_1 {
    vec4 nextData_1[];
};

layout(std430, binding = 4) buffer AliveCount {
    uint aliveCount;
};

layout(location = 0) uniform float deltaTime;
layout(location = 1) uniform float speed;

// Accessors to packed data
#define pos(idx)          (currentData_0[(idx)].xy)
#define lifetime_sec(idx) (currentData_0[(idx)].z)

void main() {
    uint idx = gl_GlobalInvocationID.x;

    float newLifetimeSec = lifetime_sec(idx) - deltaTime;

    if (lifetime_sec(idx) > 0.0) {
        // Particle is alive in this branch
        uint outIdx = atomicAdd(aliveCount, 1);

        float posX = pos(idx).x;
        float posY = pos(idx).y;
        nextData_0[outIdx] = vec4(posX, posY, newLifetimeSec, 0.0);
        nextData_1[outIdx] = currentData_1[idx];
    }
}
