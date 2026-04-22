#version 430

struct ParticleState {
    // --- 16 bytes ---
    vec2 position;          // 8
    vec2 velocity;          // 8

    // --- 16 bytes ---
    vec4 color;             // 16

    // --- 16 bytes ---
    uvec2 atlasHandle;      // 8
    uint  atlasCols;        // 4
    uint  atlasRows;        // 4

    // --- 16 bytes ---
    uint  atlasCellIndex;   // 4
    float lifetimeSec;      // 4
    float rotation;         // 4
    float scale;            // 4
};

layout(location = 0) in vec2 vertexPosition;

// layout(location = 0) uniform float particleScale;
layout(location = 1) uniform mat4 projection;
layout(location = 2) uniform int cellWidthPx;
layout(location = 3) uniform int cellHeightPx;
layout(location = 4) uniform int atlasTexWidth;
layout(location = 5) uniform int atlasTexHeight;
layout(location = 6) uniform vec2 viewportSize; // px

layout(std430, binding = 4) buffer CurrentParticleState { ParticleState currentState[]; };

out flat uvec2 fragHandle;
out vec2 fragCleanUV;
out float fragCellV;
out vec4 tintColor;

float rand(inout uint seed) {
    seed = (seed << 13) ^ seed;
    return float((seed * (seed * seed * 15731u + 789221u) + 1376312589u) & 0x7fffffff) / 2147483648.0;
}

void main() {
    int index = gl_InstanceID;

    // vec2 position = currentState[index].state_0.xy;
    // float angle = currentState[index].state_3.z;
    // uint handleLo = uint(currentState[index].state_2.x);
    // uint handleHi = uint(currentState[index].state_2.y);
    // int atlasCols = int(currentState[index].state_2.z);
    // int atlasRows = int(currentState[index].state_2.w);
    // int cellIdx = int(currentState[index].state_3.x);
    // float scale = currentState[index].state_3.w;

    ParticleState p = currentState[index];

    tintColor = p.color;
    fragHandle = p.atlasHandle;
    // tintColor = currentState[index].state_1;

    float cellU = float(cellWidthPx) / float(atlasTexWidth);
    float cellV = float(cellHeightPx) / float(atlasTexHeight);
    fragCellV = cellV;

    // TODO: Move this UV logic to frag instead
    uint col = p.atlasCellIndex % p.atlasCols;
    uint row = p.atlasCellIndex / p.atlasRows;
    vec2 cellOffset = vec2(float(col) * cellU, float(row) * cellV);
    vec2 baseUV = vertexPosition + vec2(0.5);
    fragCleanUV = cellOffset + baseUV * vec2(cellU, cellV);

    float finalScale = p.scale * 0.2;
    float aspect = viewportSize.x / viewportSize.y;

    float angleSin = sin(p.rotation);
    float angleCos = cos(p.rotation);
    mat2 rotationMatrix = mat2(
        angleCos, -angleSin,
        angleSin,  angleCos
    );

    vec2 vertex = rotationMatrix * vertexPosition * finalScale * vec2(1.0 / aspect, 1.0);
    vec2 worldPos = p.position + vertex;
    gl_Position = projection * vec4(worldPos, 0.0, 1.0);
}
