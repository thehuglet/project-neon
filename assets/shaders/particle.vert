#version 430

layout(location = 0) in vec2 vertexPosition;

layout(location = 0) uniform float particleScale;
layout(location = 1) uniform mat4 projection;
layout(location = 2) uniform int cellWidthPx;   // 96
layout(location = 3) uniform int cellHeightPx;  // 96
layout(location = 4) uniform int atlasTexWidth; // 1024
layout(location = 5) uniform int atlasTexHeight;// 2048
layout(location = 6) uniform vec2 viewportSize;   // (width, height) in pixels

layout(std430, binding = 4) buffer CurrentParticleState_0 { vec4 currentState_0[]; };
layout(std430, binding = 5) buffer CurrentParticleState_1 { vec4 currentState_1[]; };
layout(std430, binding = 6) buffer CurrentParticleState_2 { vec4 currentState_2[]; };
layout(std430, binding = 7) buffer CurrentParticleState_3 { vec4 currentState_3[]; };

out flat uvec2 fragHandle;
out vec2 fragUV;

void main() {
    int id = gl_InstanceID;

    vec2 position = currentState_0[id].xy;
    uint handleLo = uint(currentState_2[id].x);
    uint handleHi = uint(currentState_2[id].y);
    int atlasCols = int(currentState_2[id].z);
    int atlasRows = int(currentState_2[id].w);
    int cellIdx = int(currentState_3[id].x);

    fragHandle = uvec2(handleLo, handleHi);

    // Use exact pixel sizes for UV calculation
    float cellU = float(cellWidthPx) / float(atlasTexWidth);
    float cellV = float(cellHeightPx) / float(atlasTexHeight);

    int col = cellIdx % atlasCols;
    int row = cellIdx / atlasCols;
    vec2 cellOffset = vec2(float(col) * cellU, float(row) * cellV);

    vec2 baseUV = vertexPosition + vec2(0.5);
    fragUV = cellOffset + baseUV * vec2(cellU, cellV);

    float scale = particleScale * 0.01;
    float aspect = viewportSize.x / viewportSize.y;
    vec2 vertex = vertexPosition * scale * vec2(1.0 / aspect, 1.0);
    vec2 worldPos = position + vertex;
    gl_Position = projection * vec4(worldPos, 0.0, 1.0);
}
