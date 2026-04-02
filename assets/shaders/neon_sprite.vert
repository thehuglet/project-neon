#version 330

in vec3 vertexPosition;
in vec2 vertexTexCoord;
in vec3 vertexNormal;
in vec4 vertexColor;

uniform mat4 mvp;

out vec2 fragTexCoord;
out vec4 fragColor;
out float hueShift;
out float lightnessShift;
out float alphaScale;

void main() {
    fragTexCoord = vertexTexCoord;
    fragColor = vertexColor;

    // Values passed via normals as
    // they are unused by raylib
    hueShift = vertexNormal.x;
    lightnessShift = vertexNormal.y;
    alphaScale = vertexNormal.z;

    gl_Position = mvp * vec4(vertexPosition, 1.0);
}
