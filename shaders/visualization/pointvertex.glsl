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

layout (location = 0) in vec3 v;

uniform mat4 model;
uniform mat4 view;
uniform mat4 projection;
uniform float distance;
uniform vec3 normal;

void main()
{
    vec3 v1 = vec3(0.5, 0.5, 0.5);
    vec3 v2 = vec3(0.5, 0.5, -0.5);
    vec3 e12 = v2 - v1;
    float ndotv1 = dot(normal, v1);
    float ndote12 = dot(normal, e12);
    if (abs(ndote12) > 0.01) {
        float lambda = (distance - ndotv1) / ndote12;
        //vec4 p = vec4(v.x, v.y, v.z, 1.0);
        vec3 p3 = v1 + lambda * e12;
        vec4 p = vec4(p3, 1.0);
        gl_Position = projection * view * model * p;
    } else {
        gl_Position = vec4(v1, 0.0);
    }

}