#version 430

layout(location = 0) in vec2 vertexPosition;

layout(location = 0) uniform float particleScale;
layout(location = 1) uniform mat4 projection;
layout(location = 2) uniform int cellWidthPx;
layout(location = 3) uniform int cellHeightPx;
layout(location = 4) uniform int atlasTexWidth;
layout(location = 5) uniform int atlasTexHeight;
layout(location = 6) uniform vec2 viewportSize; // px

layout(std430, binding = 10) buffer CurrentParticleState_0 { vec4 currentState_0[]; };
layout(std430, binding = 11) buffer CurrentParticleState_1 { vec4 currentState_1[]; };
layout(std430, binding = 12) buffer CurrentParticleState_2 { vec4 currentState_2[]; };
layout(std430, binding = 13) buffer CurrentParticleState_3 { vec4 currentState_3[]; };

out flat uvec2 fragHandle;
out vec2 fragCleanUV;
out float fragCellV;
out vec4 tintColor;

float rand(inout uint seed) {
    seed = (seed << 13) ^ seed;
    return float((seed * (seed * seed * 15731u + 789221u) + 1376312589u) & 0x7fffffff) / 2147483648.0;
}

void main() {
    int id = gl_InstanceID;

    vec2 position = currentState_0[id].xy;
    float angle = currentState_3[id].z;
    uint handleLo = uint(currentState_2[id].x);
    uint handleHi = uint(currentState_2[id].y);
    int atlasCols = int(currentState_2[id].z);
    int atlasRows = int(currentState_2[id].w);
    int cellIdx = int(currentState_3[id].x);

    tintColor = currentState_1[id];

    float angle_sin = sin(angle);
    float angle_cos = cos(angle);
    mat2 rot = mat2(
        angle_cos, -angle_sin,
        angle_sin,  angle_cos
    );

    fragHandle = uvec2(handleLo, handleHi);

    float cellU = float(cellWidthPx) / float(atlasTexWidth);
    float cellV = float(cellHeightPx) / float(atlasTexHeight);
    fragCellV = cellV;

    int col = cellIdx % atlasCols;
    int row = cellIdx / atlasCols;
    vec2 cellOffset = vec2(float(col) * cellU, float(row) * cellV);
    vec2 baseUV = vertexPosition + vec2(0.5);
    fragCleanUV = cellOffset + baseUV * vec2(cellU, cellV);

    float scale = particleScale * 0.2;
    float aspect = viewportSize.x / viewportSize.y;
    vec2 vertex = rot * vertexPosition * scale * vec2(1.0 / aspect, 1.0);
    vec2 worldPos = position + vertex;
    gl_Position = projection * vec4(worldPos, 0.0, 1.0);
}
