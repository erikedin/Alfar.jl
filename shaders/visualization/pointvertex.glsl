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

layout (location = 0) in vec3 vi;
layout (location = 1) in vec3 vj;

out float alpha;

uniform mat4 model;
uniform mat4 view;
uniform mat4 projection;
uniform float distance;
uniform vec3 normal;

void main()
{
    vec3 eij = vj - vi;
    float ndotvi = dot(normal, vi);
    float ndoteij = dot(normal, eij);
    if (abs(ndoteij) > 0.01) {
        float lambda = (distance - ndotvi) / ndoteij;
        vec3 p3 = vi + lambda * eij;
        vec4 p = vec4(p3, 1.0);
        gl_Position = projection * view * model * p;
        alpha = 1.0;

        // Hide the point by making it transparent if lambda
        // is outside the valid range [0, 1].
        if (lambda < 0.0 || lambda > 1.0) {
            alpha = 0.0;
        }
    }
    else {
        // Hide the point by making it transparent if the
        // intersection is not valid because it's too close to being
        // parallell to the edge.
        gl_Position = vec4(vi, 1.0);
        alpha = 0.0;
    }
}