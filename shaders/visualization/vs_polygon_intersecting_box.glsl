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

out vec3 TexCoord;
out vec3 Position;

bool intersection(in vec3 vi, in vec3 vj, out vec4 p, out float lambda)
{
    vec3 eij = vj - vi;
    float ndotvi = dot(normal, vi);
    float ndoteij = dot(normal, eij);

    if (abs(ndoteij) < 0.01) {
        return false;
    }

    lambda = (distance - ndotvi) / ndoteij;
    vec3 p3 = vi + lambda * eij;
    p = vec4(p3, 1.0);
    return lambda >= 0.0 && lambda <= 1.0;
}

void main()
{
    // These vertices define the object-coordinates of the
    // box.
    const vec3 vertices[8] = vec3[8](
        vec3( 0.5,  0.5,   0.5),
        vec3( 0.5,  0.5,  -0.5),
        vec3( 0.5, -0.5,   0.5),
        vec3(-0.5,  0.5,   0.5),
        vec3(-0.5,  0.5,  -0.5),
        vec3( 0.5, -0.5,  -0.5),
        vec3(-0.5, -0.5,   0.5),
        vec3(-0.5, -0.5,  -0.5)
    );

    // These texture coordinates are hard coded for now.
    // These should be in an array uniform.
    const vec3 texturecoordinates[8] = vec3[8](
        vec3(1.0, 1.0, 0.0),
        vec3(1.0, 1.0, 1.0),
        vec3(1.0, 0.0, 0.0),
        vec3(0.0, 1.0, 0.0),
        vec3(0.0, 1.0, 1.0),
        vec3(1.0, 0.0, 1.0),
        vec3(0.0, 0.0, 0.0),
        vec3(0.0, 0.0, 1.0)
    );

    // The edges defined in `intersectionEdges` are only really
    // correct for the case when the front vertex is vertex 0. To
    // get the correct vertices, based on which vertex is the front-most,
    // we need to translate them here.
    // This table is and 8x8 lookup table. If the front vertex index is `m`,
    // then the 8 entries starting at `m*8` list the new vertex indexes.
    // That is, whichever vertex that
    // takes the place of vertex 0 is at `m*8 + 0`,
    // takes the place of vertex 1 is at `m*8 + 1`,
    // takes the place of vertex 2 is at `m*8 + 2`,
    // and so on.
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

    // This is the intersection table. The question this table answers is,
    // "Given which intersection we're search for, what edges should be searched
    //  for an intersection?".
    // The table has 4 rows for each of the 6 possible intersections. So, the first of the
    // 4 edges to search has index
    // intersectionIndex * 4
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

    // The result of this vertex shader will be a position of an intersection,
    // named `p` here.
    vec4 p = vec4(0.0, 0.0, 0.0, 1.0);

    // There are (at most) four possible edges we should search for an intersection,
    // listed in the above table `intersectionEdges`. The input `intersectionIndex` is used to find
    // which section of the table we should start at (e.g. p0, p1, p2...).
    // The loop index `i` is used to loop through the 4 rows for that section.
    for (int i = 0; i < 4; i++) {
        int edgeIndex = intersectionIndex * 4 + i;
        ivec2 edge = intersectionEdges[edgeIndex];

        // Now, edge.x is the start vertex index, and edge.y is the end vertex index.
        // The edges are specified as vertex indexes assuming that vertex 0 is the front-most
        // vertex. If another vertex is the front-most, we need to translate the vertex index
        // to that scenario.
        // The vertexIndexBasedOnFront is a table indexed first by the `frontVertexIndex` uniform.
        // Each row has 8 elements, representing the translated vertex indexes. To find the right row,
        // start at `frontVertexIndex * 8`. Add the vertex index to find the correct element in that row.
        int vertexStartIndex = vertexIndexBasedOnFront[frontVertexIndex * 8 + edge.x];
        int vertexEndIndex = vertexIndexBasedOnFront[frontVertexIndex * 8 + edge.y];

        // Here, `vi` is the final coordinates of the edge start, and `vj` is the coordinates
        // of the edge end.
        vec3 vi = vertices[vertexStartIndex];
        vec3 vj = vertices[vertexEndIndex];

        // Check if there is an intersection between the plane and the edge defined by `vi` and `vj`.
        vec4 pout = vec4(0.0, 0.0, 0.0, 1.0);
        float lambda = 0.0;
        bool hasIntersection = intersection(vi, vj, pout, lambda);

        // We take the first intersection we find. In the cases when we're search for intersections
        // p0, p2, p4, there will only be one possible intersection.
        // For intersections p1, p3, p5, we have one potential intersection, but falls back to a guaranteed
        // intersection (p0, p2, p4, respectively) if not found.
        if (hasIntersection)
        {
            // To find the texture coordinates, interpolate between the texture coordinates
            // for the vertices (after they're translated to the actual vertices),
            // using `lambda` as the interpolation factor.
            // Lambda is already calculated to be where along the vi-vj edge there is an
            // intersection.
            TexCoord = mix(texturecoordinates[vertexStartIndex],
                           texturecoordinates[vertexEndIndex],
                           lambda);

            p = pout;
            break;
        }
    }

    Position = (projection * view * model * p).xyz;
    gl_Position = projection * view * model * p;
}