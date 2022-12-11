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

module STL

using Alfar.Math
using Alfar.Meshs

struct Triangle
    normal::Vector3{Float32}
    v1::Vector3{Float32}
    v2::Vector3{Float32}
    v3::Vector3{Float32}
    attribute::UInt16
end

struct STLBinary
    header::Vector{UInt8}
    ntriangles::UInt32
    triangles::Vector{Triangle}
    STLBinary(header::Vector{UInt8}, ntriangles::UInt32, triangles::Vector{Triangle}) = new(header, ntriangles, triangles)
    STLBinary(triangles::Vector{Triangle}) = new(zeros(UInt8, 80), length(triangles), triangles)
end

function Base.read(io::IO, ::Type{Vector3{Float32}}) :: Vector3{Float32}
    x = read(io, Float32)
    y = read(io, Float32)
    z = read(io, Float32)
    Vector3([x, y, z])
end

function readbinary!(io::IO) :: STLBinary
    header = read(io, 80)
    ntriangles = read(io, UInt32)
    triangles = Vector{Triangle}(undef, ntriangles)

    for i=1:ntriangles
        normal = read(io, Vector3{Float32})
        v1 = read(io, Vector3{Float32})
        v2 = read(io, Vector3{Float32})
        v3 = read(io, Vector3{Float32})
        attribute = read(io, UInt16)

        triangles[i] = Triangle(normal, v1, v2, v3, attribute)
    end

    STLBinary(header, ntriangles, triangles)
end

function Base.write(io::IO, v::Vector3{Float32})
    n = write(io, v[1])
    n += write(io, v[2])
    n += write(io, v[3])
    n
end

function Base.write(io::IO, stl::STLBinary)
    n = 0
    n += write(io, stl.header)
    n += write(io, stl.ntriangles)

    for t in stl.triangles
        n += write(io, t.normal)
        n += write(io, t.v1)
        n += write(io, t.v2)
        n += write(io, t.v3)
        n += write(io, t.attribute)
    end

    n
end

function makerendermesh(stl::STLBinary) :: RenderMesh
    vertices = Float32[]

    for t in stl.triangles
        append!(vertices, t.v1)
        append!(vertices, t.normal)
        append!(vertices, t.v2)
        append!(vertices, t.normal)
        append!(vertices, t.v3)
        append!(vertices, t.normal)
    end

    RenderMesh(vertices)
end

end