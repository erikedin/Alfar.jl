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
out vec4 FragColor;

layout (binding = 0) uniform sampler3D mytexture;
layout (binding = 1) uniform sampler1D transfer;

uniform float relativeSamplingRate;

void main()
{
    vec4 intensity = texture(mytexture, TexCoord);
    vec4 color1d = texture(transfer, intensity.r);

    float alpha = 1 - pow(1 - color1d.a, relativeSamplingRate);
    FragColor = vec4(color1d.rgb, alpha);
}