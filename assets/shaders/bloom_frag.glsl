#version 430

// https://github.com/raysan5/raylib/blob/master/examples/shaders/resources/shaders/glsl100/bloom.frag

// Input vertex attributes (from vertex shader)
in vec2 fragTexCoord;
in vec4 fragColor;

// Input uniform values
uniform sampler2D texture0;
uniform vec4 colDiffuse;

const vec2 size = vec2(1920, 1080); // Framebuffer size
const float samples = 4.0; // Pixels per axis; higher = bigger glow, worse performance
const float quality = 6.0; // Defines size factor: Lower = smaller glow, better quality
const float intensity = 0.15;

out vec4 finalColor;

void main() {
    vec4 sum = vec4(0);
    vec2 sizeFactor = vec2(1) / size * quality;

    // Texel color fetching from texture sampler
    vec4 source = texture(texture0, fragTexCoord);

    const int range = 2; // should be = (samples - 1)/2;

    for (int x = -range; x <= range; x++)
    {
        for (int y = -range; y <= range; y++)
        {
            sum += texture2D(texture0, fragTexCoord + vec2(x, y) * sizeFactor);
        }
    }

    // Calculate final fragment color
    vec4 blur = sum / (samples * samples);
    finalColor = ((blur * intensity) + source) * colDiffuse;
}
