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

layout (location = 0) in int vertexIndex;

uniform mat4 projection;
uniform mat4 view;
uniform mat4 model;

out vec2 TextureCoordinate;

void main()
{
    const vec4[4] vertices = vec4[4](
        vec4( 0.5,  0.5, 0.0, 1.0), // 0: Right, Top, Front
        vec4( 0.5, -0.5, 0.0, 1.0), // 1: Right, Bottom, Front
        vec4(-0.5,  0.5, 0.0, 1.0), // 2: Left, Top, Front
        vec4(-0.5, -0.5, 0.0, 1.0)  // 3: Left, Bottom, Front
    );

    const vec2[4] textureCoordinates = vec2[4](
        vec2(1.0, 1.0), // 0: Right, Top
        vec2(1.0, 0.0), // 1: Right, Bottom
        vec2(0.0, 1.0), // 2: Left, Top
        vec2(0.0, 0.0)  // 3: Left, Bottom
    );

    vec4 p = vertices[vertexIndex];
    gl_Position = projection * view * model * p;
    TextureCoordinate = textureCoordinates[vertexIndex];
}