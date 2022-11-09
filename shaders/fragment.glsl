#version 330 core

in vec3 ourColor;

out vec4 FragColor;

uniform float alpha;

void main()
{
    FragColor = vec4(ourColor.r, ourColor.g, ourColor.b, alpha);
}