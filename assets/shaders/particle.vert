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

layout(location = 0) in vec2 quadLocalPos;

// layout(location = 0) uniform float particleScale;
layout(location = 1) uniform mat4 projection;
// layout(location = 2) uniform int cellWidthPx;
// layout(location = 3) uniform int cellHeightPx;
// layout(location = 4) uniform int atlasTexWidth;
// layout(location = 5) uniform int atlasTexHeight;
// layout(location = 6) uniform vec2 viewportSize; // px
layout(location = 8) uniform vec2 atlasCellSizeUV;

layout(std430, binding = 4) buffer CurrentParticleState { ParticleState currentState[]; };

out flat uvec2 fragHandle;
out vec2 fragUV;
out float fragCellV;
out vec4 tintColor;

void main() {
    int index = gl_InstanceID;
    ParticleState p = currentState[index];

    tintColor = p.color;
    fragHandle = p.atlasHandle;
    // float cellU = float(cellWidthPx) / float(atlasTexWidth);
    // float cellV = float(cellHeightPx) / float(atlasTexHeight);
    fragCellV = atlasCellSizeUV.y;

    uint col = p.atlasCellIndex % p.atlasCols;
    uint row = p.atlasCellIndex / p.atlasCols;
    vec2 cellOffset = vec2(float(col) * atlasCellSizeUV.x, float(row) * cellV);
    vec2 baseUV = quadLocalPos + vec2(0.5);
    fragUV = cellOffset + baseUV * vec2(atlasCellSizeUV.x, atlasCellSizeUV.y);

    float angleSin = sin(p.rotation);
    float angleCos = cos(p.rotation);
    mat2 rotationMatrix = mat2(
        angleCos, -angleSin,
        angleSin,  angleCos
    );
    float finalScale = p.scale * 0.2;

    vec2 vertex = rotationMatrix * quadLocalPos * finalScale;
    vec2 worldPos = p.position + vertex;
    gl_Position = projection * vec4(worldPos, 0.0, 1.0);
}
