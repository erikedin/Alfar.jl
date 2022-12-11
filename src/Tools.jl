# Copyright 2022 Erik Edin
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

module Tools

using Alfar.Format.STL: Vector3, STLBinary
using Alfar.Math

struct BoundingBox
    min::Vector3
    max::Vector3
end

function minv3(a::Vector3, b::Vector3) :: Vector3
    Vector3([
        min(a[1], b[1]),
        min(a[2], b[2]),
        min(a[3], b[3]),
    ])
end

function maxv3(a::Vector3, b::Vector3) :: Vector3
    Vector3([
        max(a[1], b[1]),
        max(a[2], b[2]),
        max(a[3], b[3]),
    ])
end

function boundingbox(stl::STLBinary) :: BoundingBox

    vmin = Vector3([0f0, 0f0, 0f0])
    vmax = Vector3([0f0, 0f0, 0f0])
    isfirst = true

    for triangle in stl.triangles
        if isfirst
            vmin = triangle.v1
            vmax = triangle.v1
            isfirst = false
        end

        vmin = minv3(vmin, triangle.v1)
        vmax = maxv3(vmax, triangle.v1)

        vmin = minv3(vmin, triangle.v2)
        vmax = maxv3(vmax, triangle.v2)

        vmin = minv3(vmin, triangle.v3)
        vmax = maxv3(vmax, triangle.v3)
    end

    BoundingBox(vmin, vmax)
end

function makecube()
    vertices = [
        # Front
        (-0.5f0, -0.5f0,  0.5f0), # 1 Front lower left
        ( 0.5f0, -0.5f0,  0.5f0), # 2 Front lower right
        ( 0.5f0,  0.5f0,  0.5f0), # 3 Front upper right
        (-0.5f0,  0.5f0,  0.5f0), # 4 Front upper left

        # Back
        ( 0.5f0, -0.5f0, -0.5f0), # 5 Back lower right
        (-0.5f0, -0.5f0, -0.5f0), # 6 Back lower left
        (-0.5f0,  0.5f0, -0.5f0), # 7 Back upper left
        ( 0.5f0,  0.5f0, -0.5f0), # 8 Back upper right
    ]
    faces = [
        (1, 3, 4), # Upper front
        (1, 2, 3), # Lower front
        (5, 7, 8), # Upper back
        (5, 6, 7), # Lower back
        (2, 8, 3), # Upper right
        (2, 5, 8), # Lower right
        (6, 4, 7), # Upper left
        (6, 1, 4), # Lower left
        (4, 3, 8), # Front top
        (4, 8, 7), # Back  top
        (6, 5, 2), # Front bottom
        (6, 2, 1), # Back  bottom
    ]

    for face in faces
        v1 = vertices[face[1]]
        v2 = vertices[face[2]]
        v3 = vertices[face[3]]
        normal = cross(v2 - v1, v3 - v1)

        println(join(map(x -> repr(x), [normal[1], normal[2], normal[3]]), ", "))
        println(join(map(x -> repr(x), [v1[1], v1[2], v1[3]]), ", "))
        println(join(map(x -> repr(x), [v2[1], v2[2], v2[3]]), ", "))
        println(join(map(x -> repr(x), [v3[1], v3[2], v3[3]]), ", "))
        println()
    end
end

end # module Tools