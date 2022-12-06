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

const V3 = NTuple{3, Float32}

struct Triangle
    normal::V3
    v1::V3
    v2::V3
    v3::V3
    attribute::UInt16
end

struct STLBinary
    header::Vector{UInt8}
    ntriangles::UInt32
    triangles::Vector{Triangle}
end

function Base.read(io::IO, ::Type{V3}) :: V3
    x = read(io, Float32)
    y = read(io, Float32)
    z = read(io, Float32)
    V3([x, y, z])
end

function readbinary!(io::IO) :: STLBinary
    header = read(io, 80)
    ntriangles = read(io, UInt32)
    triangles = Vector{Triangle}(undef, ntriangles)

    for i=1:ntriangles
        normal = read(io, V3)
        v1 = read(io, V3)
        v2 = read(io, V3)
        v3 = read(io, V3)
        attribute = read(io, UInt16)

        triangles[i] = Triangle(normal, v1, v2, v3, attribute)
    end

    STLBinary(header, ntriangles, triangles)
end

end