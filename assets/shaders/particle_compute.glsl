// We require version 430 since it supports compute shaders.
#version 430

// This is the workgroup size. The largest size that is guaranteed by OpenGL
// to available is 1024, beyond this is uncertain.
// Might influence performance but only in advanced cases.
layout(local_size_x = 1024, local_size_y = 1, local_size_z = 1) in;

layout(std430, binding = 0) buffer ssboPositions {
    vec4 positions[];
};
layout(std430, binding = 1) buffer ssboVelocities {
    vec4 velocities[];
};

// Uniform values are the way in which we can modify the shader efficiently.
// These can be updated every frame efficiently.
// We use layout(location=...) but you can also leave it and query the location in Raylib.
layout(location = 0) uniform float deltaTime;
layout(location = 1) uniform float speed;

void main()
{
    uint index = gl_GlobalInvocationID.x;

    // Test upward movement
    positions[index].x += speed * deltaTime;

    // Test clamp
    if (positions[index].x > 1.0) positions[index].x = -1.0;
    if (positions[index].x < -1.0) positions[index].x = 1.0;

    // velocities[index].xy = vec2(0.0, 0.0);
}
