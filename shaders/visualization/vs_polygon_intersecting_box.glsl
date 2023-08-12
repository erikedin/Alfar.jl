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

layout (location = 0) in int intersectionIndex;

uniform mat4 projection;
uniform mat4 view;
uniform mat4 model;

uniform float distance;
uniform vec3 normal;
uniform int frontVertexIndex;

bool intersection(in vec3 vi, in vec3 vj, out vec4 p)
{
    vec3 eij = vj - vi;
    float ndotvi = dot(normal, vi);
    float ndoteij = dot(normal, eij);

    if (abs(ndoteij) < 0.01) {
        return false;
    }

    float lambda = (distance - ndotvi) / ndoteij;
    vec3 p3 = vi + lambda * eij;
    p = vec4(p3, 1.0);
    return lambda >= 0.0 && lambda <= 1.0;
}

void main()
{
    // These vertices define the object-coordinates of the
    // box.
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

    // This is the intersection table. The question this table answers is,
    // "Given which intersection we're search for, what edges should be searched
    //  for an intersection?".
    // The table has 4 rows for each of the 6 possible intersections. So, the first of the
    // 4 edges to search has index
    // frontVertexIndex * 4
    // the the front vertexes start at 0.
    const ivec2[24] intersectionEdges = ivec2[24](
        ivec2(0, 1),  // p0, index 0
        ivec2(1, 4),  // p0, index 1
        ivec2(4, 7),  // p0, index 2
        ivec2(0, 1),  // p0, index 3
        ivec2(1, 5),  // p1, index 4
        ivec2(0, 1),  // p1, index 5
        ivec2(1, 4),  // p1, index 6
        ivec2(4, 7),  // p1, index 7
        ivec2(0, 2),  // p2, index 8
        ivec2(2, 5),  // p2, index 9
        ivec2(5, 7),  // p2, index 10
        ivec2(0, 2),  // p2, index 11
        ivec2(2, 6),  // p3, index 12
        ivec2(0, 2),  // p3, index 13
        ivec2(2, 5),  // p3, index 14
        ivec2(5, 7),  // p3, index 15
        ivec2(0, 3),  // p4, index 16
        ivec2(3, 6),  // p4, index 17
        ivec2(6, 7),  // p4, index 18
        ivec2(0, 3),  // p4, index 19
        ivec2(3, 4),  // p5, index 20
        ivec2(0, 3),  // p5, index 21
        ivec2(3, 6),  // p5, index 22
        ivec2(6, 7)   // p5, index 23
    );


    // The edges are specified as vertex indexes assuming that vertex 0 is the front-most
    // vertex. If another vertex is the front-most, we need to translate the vertex index
    // to that scenario.

    // TODO This is just for dev purposes. The actual position
    // will be calculated later.
    vec4 p = vertices[intersectionIndex];

    // The input intersectionIndex specifies which of the 6 possible
    // intersections this vertex is for. It will need to search 4 possibilities.

    gl_Position = projection * view * model * p;
}