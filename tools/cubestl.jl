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

using Alfar.Format.STL
using Alfar.Format.STL: Triangle, STLBinary

function writecube(io::IO)
    vertices = Float32[
        # Position              # Normals
        # Back side
         0.5f0, -0.5f0, -0.5f0,  0f0,  0f0, -1f0, # Right bottom back
        -0.5f0,  0.5f0, -0.5f0,  0f0,  0f0, -1f0, # Left top    back
         0.5f0,  0.5f0, -0.5f0,  0f0,  0f0, -1f0, # Right top    back
         0.5f0, -0.5f0, -0.5f0,  0f0,  0f0, -1f0, # Right bottom back
        -0.5f0, -0.5f0, -0.5f0,  0f0,  0f0, -1f0, # Left bottom back
        -0.5f0,  0.5f0, -0.5f0,  0f0,  0f0, -1f0, # Left top    back

        # Front side
         0.5f0, -0.5f0,  0.5f0,  0f0,  0f0,  1f0, # Right bottom front
         0.5f0,  0.5f0,  0.5f0,  0f0,  0f0,  1f0, # Right top    front
        -0.5f0,  0.5f0,  0.5f0,  0f0,  0f0,  1f0, # Left top     front
         0.5f0, -0.5f0,  0.5f0,  0f0,  0f0,  1f0, # Right bottom front
        -0.5f0,  0.5f0,  0.5f0,  0f0,  0f0,  1f0, # Left top     front
        -0.5f0, -0.5f0,  0.5f0,  0f0,  0f0,  1f0, # Left bottom  front

        # Left side
        -0.5f0,  0.5f0, -0.5f0, -1f0,  0f0,  0f0, # Left top    back
        -0.5f0, -0.5f0, -0.5f0, -1f0,  0f0,  0f0, # Left bottom back
        -0.5f0, -0.5f0,  0.5f0, -1f0,  0f0,  0f0, # Left bottom front
        -0.5f0,  0.5f0, -0.5f0, -1f0,  0f0,  0f0, # Left top    back
        -0.5f0, -0.5f0,  0.5f0, -1f0,  0f0,  0f0, # Left bottom front
        -0.5f0,  0.5f0,  0.5f0, -1f0,  0f0,  0f0, # Left top    front

        # Right side
         0.5f0, -0.5f0, -0.5f0,  1f0,  0f0,  0f0, # Right bottom back
         0.5f0,  0.5f0, -0.5f0,  1f0,  0f0,  0f0, # Right top    back
         0.5f0, -0.5f0,  0.5f0,  1f0,  0f0,  0f0, # Right bottom front
         0.5f0, -0.5f0,  0.5f0,  1f0,  0f0,  0f0, # Right bottom front
         0.5f0,  0.5f0, -0.5f0,  1f0,  0f0,  0f0, # Right top    back
         0.5f0,  0.5f0,  0.5f0,  1f0,  0f0,  0f0, # Right top    front

        # Bottom side
        -0.5f0, -0.5f0, -0.5f0,  0f0, -1f0,  0f0, # Left bottom back
         0.5f0, -0.5f0, -0.5f0,  0f0, -1f0,  0f0, # Right bottom back
         0.5f0, -0.5f0,  0.5f0,  0f0, -1f0,  0f0, # Right bottom front
        -0.5f0, -0.5f0,  0.5f0,  0f0, -1f0,  0f0, # Left bottom front
        -0.5f0, -0.5f0, -0.5f0,  0f0, -1f0,  0f0, # Left bottom back
         0.5f0, -0.5f0,  0.5f0,  0f0, -1f0,  0f0, # Right bottom front

        # Top side
        -0.5f0,  0.5f0, -0.5f0,  0f0,  1f0,  0f0, # Left  top back
         0.5f0,  0.5f0,  0.5f0,  0f0,  1f0,  0f0, # Right top front
         0.5f0,  0.5f0, -0.5f0,  0f0,  1f0,  0f0, # Right top back
         0.5f0,  0.5f0,  0.5f0,  0f0,  1f0,  0f0, # Right top front
        -0.5f0,  0.5f0, -0.5f0,  0f0,  1f0,  0f0, # Left  top back
        -0.5f0,  0.5f0,  0.5f0,  0f0,  1f0,  0f0, # Left  top front
    ]

    triangles = Triangle[]

    for i = 1:18:length(vertices)-6
        normal = STL.V3([vertices[i+3], vertices[i+4], vertices[i+5]])
        v1 = STL.V3([vertices[i+ 0], vertices[i+ 1], vertices[i+ 2]])
        v2 = STL.V3([vertices[i+ 6], vertices[i+ 7], vertices[i+ 8]])
        v3 = STL.V3([vertices[i+12], vertices[i+13], vertices[i+14]])
        attribute = UInt16(0)

        push!(triangles, Triangle(normal, v1, v2, v3, attribute))
    end

    header = zeros(UInt8, 80)

    stl = STLBinary(header, UInt32(length(triangles)), triangles)
    write(io, stl)
end

function writecube(filename::String)
    open(filename, "w") do io
        writecube(io)
    end
end

writecube("mycube.stl")