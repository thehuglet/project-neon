#version 430

layout(local_size_x = 1, local_size_y = 1, local_size_z = 1) in;

layout(std430, binding = 4) readonly buffer AliveCount {
    uint aliveCount;
};

layout(std430, binding = 5) buffer DispatchIndirect {
    uint numGroupsX;
    uint numGroupsY;
    uint numGroupsZ;
};

void main() {
    // Compute workgroups needed for next frame's simulation
    // (assuming local_size_x = 1024 in the first shader)
    numGroupsX = (aliveCount + 1023) / 1024;
    numGroupsY = 1;
    numGroupsZ = 1;
}
