// Copyright 2023 Erik Edin
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#version 420 core

in vec3 TexCoord;
in vec3 position;
out vec4 FragColor;

layout (binding = 0) uniform sampler3D mytexture;
layout (binding = 1) uniform sampler1D transfer;

uniform float relativeSamplingRate;

vec4 blinnphong(vec3 normal, vec3 light_direction, vec3 view_direction)
{
    const vec3 ka = vec3(0.1, 0.1, 0.1);
    const vec3 kd = vec3(0.6, 0.6, 0.6);
    const vec3 ks = vec3(0.2, 0.2, 0.2);
    const float shininess = 100.0;

    const vec3 light_color = vec3(1.0, 1.0, 1.0);
    const vec3 ambient_light = vec3(0.3, 0.3, 0.3);

    const vec3 halfway = normalize(light_direction - view_direction);

    vec3 ambient = ka * ambient_light;
    float diffuse_light = max(dot(normal, light_direction), 0.0);
    vec3 diffuse = kd * light_color * diffuse_light;
    vec3 specular = vec3(0.0, 0.0, 0.0);

    vec3 color = ambient + diffuse + specular;
    return vec4(color, 0.0);
}

void main()
{
    vec4 intensity = texture(mytexture, TexCoord);
    vec4 transfercolor = texture(transfer, intensity.r);
    float alpha = 1 - pow(1 - transfercolor.a, relativeSamplingRate);
    transfercolor.a = alpha;

    // Hard code all these values for now
    const float h = 0.01;
    const vec3 px = vec3(h, 0.0, 0.0);
    const vec3 nx = vec3(-h, 0.0, 0.0);
    const vec3 py = vec3(0.0, h, 0.0);
    const vec3 ny = vec3(0.0, -h, 0.0);
    const vec3 pz = vec3(0.0, 0.0, h);
    const vec3 nz = vec3(0.0, 0.0, -h);
    vec3 sample1;
    vec3 sample2;
    sample1.x = texture(mytexture, TexCoord + px).r;
    sample2.x = texture(mytexture, TexCoord + nx).r;
    sample1.y = texture(mytexture, TexCoord + py).r;
    sample2.y = texture(mytexture, TexCoord + ny).r;
    sample1.z = texture(mytexture, TexCoord + pz).r;
    sample2.z = texture(mytexture, TexCoord + nz).r;

    vec3 gradient = normalize(sample2 - sample1);

    vec3 light_position = vec3(0.0, 0.0, 3.0);
    vec3 view_position = vec3(0.0, 0.0, 3.0);
    vec3 position = gl_FragCoord.xyz;
    vec3 light_direction = normalize(light_position - position);
    vec3 view_direction = normalize(view_position - position);

    FragColor = transfercolor + blinnphong(gradient, light_direction, view_direction);
}