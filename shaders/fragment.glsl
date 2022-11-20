// Copyright 2022 Erik Edin
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

#version 330 core

in vec3 ourColor;
in vec3 Normal;
in vec3 FragPos;

out vec4 FragColor;

uniform float alpha;
uniform float ambientStrength;
uniform vec3 lightColor;
uniform vec3 lightPosition;

void main()
{
    // Ambient color
    vec3 ambient = ambientStrength * lightColor;

    // Diffuse color
    vec3 normal = normalize(Normal);
    vec3 lightDirection = normalize(lightPosition - FragPos);
    float diffuseFactor = max(dot(normal, lightDirection), 0.0);
    vec3 diffuse = diffuseFactor * lightColor;

    vec3 color = (ambient + diffuse) * ourColor;
    FragColor = vec4(color, alpha);
}