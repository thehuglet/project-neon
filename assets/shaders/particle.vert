#version 430

struct GpuTextureAtlas {
    // --- 16 ---
    uvec2 handle;
    uvec2 grid;
    // --- 16 ---
    vec2 cellSizeUV;
    uint _pad0;
    uint _pad1;
};

struct ParticleState {
    // --- 16 ---
    vec2 position;
    vec2 velocity;
    // --- 16 ---
    vec4 color;
    // --- 16 ---
    int atlasId;
    int atlasCellIndex;
    float initialLifetimeSec;
    float lifetimeSec;
    // --- 16 ---
    float rotation;
    float spinSpeed;
    float scale;
    float scaleOverT;
    // --- 16 ---
    float alphaOverT;
    float hueShiftOverT;
    uint _pad1;
    uint _pad2;
};

layout(location = 0) in vec2 quadLocalPos;
layout(location = 1) uniform mat4 projection;
layout(location = 2) uniform float viewportHeight;

layout(std430, binding = 4) buffer CurrentParticleState { ParticleState currentState[]; };
layout(std430, binding = 6) buffer AtlasTable { GpuTextureAtlas atlases[]; };

out flat uvec2 fragHandle;
out vec2 cleanUV;
out vec2 blurUV;
out vec4 vColor;
out float vLifetimeT;
out float vHueShiftOverT;
out float vAlphaOverT;

void main() {
    int index = gl_InstanceID;
    ParticleState p = currentState[index];
    GpuTextureAtlas atlas = atlases[p.atlasId];

    float lifetimeT = clamp(p.lifetimeSec / p.initialLifetimeSec, 0.0, 1.0);

    vColor = p.color;
    vLifetimeT = lifetimeT;
    vHueShiftOverT = p.hueShiftOverT;
    vAlphaOverT = p.alphaOverT;

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
    float scaleOverTFactor = 1.0 + (p.scaleOverT - 1.0) * (1.0 - lifetimeT);
    float finalScale = p.scale * scaleOverTFactor;

    vec2 vertex = rotationMatrix * quadLocalPos * finalScale;
    vec2 worldPos = vec2(p.position.x, viewportHeight - p.position.y) + vertex;
    gl_Position = projection * vec4(worldPos, 0.0, 1.0);
}
