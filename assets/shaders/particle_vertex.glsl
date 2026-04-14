#version 430

// This is the vertex position of the base particle!
// This is the vertex attribute set in the code, index 0.
layout(location = 0) in vec2 vertexPosition;

// Input uniform values.
layout(location = 0) uniform float particleScale;
layout(location = 1) uniform mat4 projection;

// The two buffers we will be reading from.
// We can write to them here but should not.
layout(std430, binding = 0) buffer ssboPositions {
    vec4 positions[];
};
layout(std430, binding = 1) buffer ssboVelocities {
    vec4 velocities[];
};

// We will only output color.
out vec4 fragColor;

void main() {
    vec2 position = pos[gl_InstanceID].xy;
    vec2 velocity = vel[gl_InstanceID].xy;

    if (length(velocity) > 0.0)
        fragColor = vec4(abs(normalize(velocity)), 1.0);
    else
        fragColor = vec4(0.5, 0.5, 0.5, 1.0);

    float scale = 0.005 * particleScale;
    vec2 vertex = vertexPosition * scale;

    vec2 worldPos = position + vertex;

    gl_Position = projection * vec4(worldPos, 0.0, 1.0);
}
