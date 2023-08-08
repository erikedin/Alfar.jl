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

layout (location = 0) in vec3 v1;
layout (location = 1) in vec3 v2;

out float alpha;

uniform mat4 model;
uniform mat4 view;
uniform mat4 projection;
uniform float distance;
uniform vec3 normal;

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
    vec4 p = vec4(0.0, 0.0, 0.0, 0.0);
    bool intersects12 = intersection(v1, v2, p);
    alpha = intersects12 ? 1.0 : 0.0;
    gl_Position = projection * view * model * p;
}