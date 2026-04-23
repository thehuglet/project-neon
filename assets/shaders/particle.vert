#version 430

struct GpuTextureAtlas {
    // --- 16 bytes ---
    uvec2 handle;           // 8
    uvec2 grid;             // 8
    // --- 16 bytes ---
    vec2 cellSizeUV;        // 8
    uint _pad0;             // 4
    uint _pad1;             // 4
};

struct ParticleState {
    // --- 16 bytes ---
    vec2 position;          // 8
    vec2 velocity;          // 8
    // --- 16 bytes ---
    vec4 color;             // 16
    // --- 16 bytes ---
    uint atlasId;           // 4
    uint atlasCellIndex;    // 4
    uint _pad0;             // 4
    uint _pad1;             // 4
    // --- 16 bytes ---
    float lifetimeSec;      // 4
    float rotation;         // 4
    float scale;            // 4
    uint _pad2;             // 4
};


layout(location = 0) in vec2 quadLocalPos;

// layout(location = 0) uniform float particleScale;
layout(location = 1) uniform mat4 projection;
// layout(location = 2) uniform int cellWidthPx;
// layout(location = 3) uniform int cellHeightPx;
// layout(location = 4) uniform int atlasTexWidth;
// layout(location = 5) uniform int atlasTexHeight;
// layout(location = 6) uniform vec2 viewportSize; // px
// layout(location = 8) uniform vec2 atlasCellSizeUV;
layout(std430, binding = 4) buffer CurrentParticleState { ParticleState currentState[]; };
layout(std430, binding = 6) buffer AtlasTable { GpuTextureAtlas atlases[]; };

out flat uvec2 fragHandle;
out vec2 cleanUV;
out vec2 blurUV;
// out vec2 fragUV;
// out float fragCellV;
out vec4 tintColor;

void main() {
    int index = gl_InstanceID;
    ParticleState p = currentState[index];
    GpuTextureAtlas atlas = atlases[p.atlasId];

    tintColor = p.color;
    fragHandle = atlas.handle;
    uint col = p.atlasCellIndex % atlas.grid.x;
    uint row = p.atlasCellIndex / atlas.grid.x;
    vec2 cellOffset = vec2(col, row) * atlas.cellSizeUV;
    vec2 baseUV = quadLocalPos + vec2(0.5);

    cleanUV = cellOffset + baseUV * atlas.cellSizeUV;
    blurUV = cleanUV + vec2(0.0, atlas.cellSizeUV.y);

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
