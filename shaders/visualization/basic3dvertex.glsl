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

layout (location = 0) in vec3 aPos;
layout (location = 1) in vec3 aTextureCoordinate;

out vec3 TexCoord;

uniform mat4 model;
uniform mat4 view;
uniform mat4 projection;

void main()
{
    vec4 p = vec4(aPos.x, aPos.y, aPos.z, 1.0);
    gl_Position = projection * view * model * p;
    TexCoord = aTextureCoordinate;
}