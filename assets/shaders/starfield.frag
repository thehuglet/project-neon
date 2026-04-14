#version 330 core

uniform vec2 u_resolution;
uniform float u_time;

out vec4 FragColor;

vec2 hash(in vec2 p) {
    return fract(sin(vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)))) * 43758.5453);
}

vec2 hash22(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * vec3(.1031, .1030, .0973));
    p3 += dot(p3, p3.yzx + 19.19);
    return fract((p3.xx + p3.yz) * p3.zy);
}

float noise(in vec2 p) {
    #ifdef USE_VORONOI
    vec2 n = floor(p);
    vec2 f = fract(p);
    vec2 mg, mr;
    float md = 8.0;
    for (int j = -1; j <= 1; ++j) {
        for (int i = -1; i <= 1; ++i) {
            vec2 g = vec2(float(i), float(j));
            vec2 o = hash22(n + g);
            vec2 r = g + o - f;
            float d = dot(r, r);
            if (d < md) {
                md = d;
                mr = r;
                mg = g;
            }
        }
    }
    return md;
    #else
    vec2 n = floor(p);
    vec2 f = fract(p);
    float md = 1.0;
    vec2 o = hash22(n) * 0.96 + 0.02;
    vec2 r = o - f;
    float d = dot(r, r);
    md = min(d, md);
    return md;
    #endif
}

vec3 starfield(vec2 samplePosition, float threshold) {
    float starValue = noise(samplePosition);
    float power = max(1.0 - (starValue / threshold), 0.0);
    power = power * power * power;

    vec2 cell = floor(samplePosition);
    vec2 seed = hash22(cell);
    float speed = 1.0 + seed.x * 0.5;
    float phase = seed.y * 6.28318;
    // float twinkle = 0.5 + 0.5 * sin(u_time * speed + phase);
    float twinkle = 0.5 + 0.5 * sin(u_time * 1.3 + cell.x * 12.9898 + cell.y * 78.233);

    twinkle = 0.0 + 1.0 * twinkle;
    power *= twinkle;

    #ifdef SHOW_CELLS
    power += starValue;
    #endif
    return vec3(power);
}

void main() {
    vec2 fragCoord = gl_FragCoord.xy;

    float maxResolution = max(u_resolution.x, u_resolution.y);
    float speed = 0.05;
    vec3 finalColor = vec3(0.0);

    vec2 sCoord = (fragCoord.xy / maxResolution) * 8.0;
    vec2 pos = vec2(u_time * 5.0 * speed, sin(u_time * 5.0 * speed) * 5.0 * speed);

    const int STAR_LAYER_COUNT = 8;
    for (int i = 1; i <= STAR_LAYER_COUNT; i++) {
        float fi = float(i);
        float inv = sqrt(1.0 / fi);
        finalColor += starfield((sCoord + vec2(fi * 100.0, -fi * 50.0)) * (1.0 + fi * 0.2) + pos, 0.0005) * inv;
    }

    finalColor *= 0.5;
    FragColor = vec4(finalColor, 1.0);
}
