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
layout (location = 1) in vec4 aColor;

uniform mat4 projection;
uniform mat4 view;
uniform mat4 model;
uniform int frontVertexIndex;

out vec4 Color;

void main()
{
    // These are the 8 vertices of a box of length 1.
    // The order of the vertices is from the book
    // TODO: Name of volume rendering book.
    const vec4[8] vertices = vec4[8](
        vec4( 0.5,  0.5,  0.5, 1.0),
        vec4( 0.5,  0.5, -0.5, 1.0),
        vec4( 0.5, -0.5,  0.5, 1.0),
        vec4(-0.5,  0.5,  0.5, 1.0),
        vec4(-0.5,  0.5, -0.5, 1.0),
        vec4( 0.5, -0.5, -0.5, 1.0),
        vec4(-0.5, -0.5,  0.5, 1.0),
        vec4(-0.5, -0.5, -0.5, 1.0)
    );

    // The point of the box is that it shows three paths from
    // the front-most vertex to the back-most vertex. They are
    // colored red, green, and blue.
    // Therefore, how lines are colored depends on which vertex is
    // the closest to the camera.
    // Instead of defining all paths depending on which the front
    // vertex is, we define the paths for the case when the front vertex
    // is vertex 0, and if the front vertex is another vertex, we simply
    // rename the vertices. That is, if we're coloring edge 0->1, but
    // the front vertex is vertex 7, then we translate those vertex
    // indexes to 7->5, based on the table below.
    const int[64] vertexIndexBasedOnFront = int[64](
        0, 1, 2, 3, 4, 5, 6, 7,
        1, 4, 5, 0, 3, 7, 2, 6,
        2, 6, 0, 5, 7, 3, 1, 4,
        3, 0, 6, 4, 1, 2, 7, 5,
        4, 3, 7, 1, 0, 6, 5, 2,
        5, 2, 1, 7, 6, 0, 4, 3,
        6, 7, 3, 2, 5, 4, 0, 1,
        7, 5, 4, 6, 2, 1, 3, 0
    );

    int translatedVertexIndex = vertexIndexBasedOnFront[frontVertexIndex * 8 + vertexIndex];
    vec4 p = vertices[translatedVertexIndex];

    gl_Position = projection * view * model * p;
    Color = aColor;
}