#version 430
#extension GL_ARB_bindless_texture : require

in flat uvec2 fragHandle;
in vec2 fragUV;

out vec4 finalColor;

void main()
{
    sampler2D tex = sampler2D(fragHandle);
    finalColor = texture(tex, fragUV);
}
