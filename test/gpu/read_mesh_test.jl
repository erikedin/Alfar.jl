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

using Alfar.Meshs
using Alfar.Format.STL
using Alfar.Math

@testset "GPU" begin

@testset "Mesh" begin

function readnumberofvertices_gpu!(mesh::Mesh, nout)
    if threadIdx.x() == 1
        nout[1] = numberofvertices(mesh)
    end
end

@testset "Read cube from STL; Mesh on GPU has 8 vertices" begin
    # Arrange
    # TODO Create cube
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
    triangles = Vector{STL.Triangle}()
    for face in faces
        v1 = vertices[face[1]]
        v2 = vertices[face[2]]
        v3 = vertices[face[3]]
        normal = cross(v2 - v1, v3 - v1)

        triangle = STL.Triangle(normal, v1, v2, v3, UInt16(0))
        push!(triangles, triangle)
    end
    stl = STL.STLBinary(triangles)

    io = IOBuffer()
    write(io, stl)
    seekstart(io)

    # Act
    mesh = STL.read(io, Mesh)

    # Assert
    nout = CuArray{Int}(undef, 1)
    @CUDA.sync @cuda threads=1 readnumberofvertices_gpu!(mesh, nout)
    verticesongpu = nout[1]

    @test verticesongpu == 8
end

end # testset "Mesh"

end # testset "GPU"