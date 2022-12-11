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
using CUDA

@testset "GPU             " begin

@testset "Mesh" begin

function readnumberofvertices_gpu!(mesh::Mesh, nout)
    if threadIdx().x == 1
        nout[1] = numberofvertices(mesh)
    end
    return
end

@testset "Read cube from STL; Mesh on GPU has 36 vertices" begin
    # Arrange
    # TODO Create cube
    vertices = [
         0.0f0,  0.0f0,  1.0f0,
        -0.5f0, -0.5f0,  0.5f0,
         0.5f0,  0.5f0,  0.5f0,
        -0.5f0,  0.5f0,  0.5f0,

         0.0f0,  0.0f0,  1.0f0,
        -0.5f0, -0.5f0,  0.5f0,
         0.5f0, -0.5f0,  0.5f0,
         0.5f0,  0.5f0,  0.5f0,

         0.0f0,  0.0f0, -1.0f0,
         0.5f0, -0.5f0, -0.5f0,
        -0.5f0,  0.5f0, -0.5f0,
         0.5f0,  0.5f0, -0.5f0,

         0.0f0,  0.0f0, -1.0f0,
         0.5f0, -0.5f0, -0.5f0,
        -0.5f0, -0.5f0, -0.5f0,
        -0.5f0,  0.5f0, -0.5f0,

         1.0f0, -0.0f0,  0.0f0,
         0.5f0, -0.5f0,  0.5f0,
         0.5f0,  0.5f0, -0.5f0,
         0.5f0,  0.5f0,  0.5f0,

         1.0f0,  0.0f0,  0.0f0,
         0.5f0, -0.5f0,  0.5f0,
         0.5f0, -0.5f0, -0.5f0,
         0.5f0,  0.5f0, -0.5f0,

        -1.0f0,  0.0f0,  0.0f0,
        -0.5f0, -0.5f0, -0.5f0,
        -0.5f0,  0.5f0,  0.5f0,
        -0.5f0,  0.5f0, -0.5f0,

        -1.0f0,  0.0f0,  0.0f0,
        -0.5f0, -0.5f0, -0.5f0,
        -0.5f0, -0.5f0,  0.5f0,
        -0.5f0,  0.5f0,  0.5f0,

        -0.0f0,  1.0f0,  0.0f0,
        -0.5f0,  0.5f0,  0.5f0,
         0.5f0,  0.5f0,  0.5f0,
         0.5f0,  0.5f0, -0.5f0,

         0.0f0,  1.0f0,  0.0f0,
        -0.5f0,  0.5f0,  0.5f0,
         0.5f0,  0.5f0, -0.5f0,
        -0.5f0,  0.5f0, -0.5f0,

         0.0f0, -1.0f0,  0.0f0,
        -0.5f0, -0.5f0, -0.5f0,
         0.5f0, -0.5f0, -0.5f0,
         0.5f0, -0.5f0,  0.5f0,

         0.0f0, -1.0f0,  0.0f0,
        -0.5f0, -0.5f0, -0.5f0,
         0.5f0, -0.5f0,  0.5f0,
        -0.5f0, -0.5f0,  0.5f0,
    ]

    triangles = STL.Triangle[]
    for faceindex = 1:12:length(vertices)
        normal = Vector3(vertices[faceindex:faceindex+2])
        v1     = Vector3(vertices[faceindex+3:faceindex+5])
        v2     = Vector3(vertices[faceindex+6:faceindex+8])
        v3     = Vector3(vertices[faceindex+9:faceindex+11])
        push!(triangles, STL.Triangle(normal, v1, v2, v3, UInt16(0)))
    end
    stl = STL.STLBinary(triangles)

    io = IOBuffer()
    write(io, stl)
    seekstart(io)

    # Act
    readstl = STL.readbinary!(io)
    mesh = STL.makemesh(readstl)
    nout = CuArray{Int}(undef, 1)
    @CUDA.sync @cuda threads=1 readnumberofvertices_gpu!(mesh, nout)

    # Assert
    verticesongpu = CUDA.@allowscalar nout[1]

    @test verticesongpu == 36
end

@testset "Read half a cube from STL; Mesh on GPU has 18 vertices" begin
    # Arrange
    # TODO Create cube
    vertices = [
         0.0f0,  0.0f0,  1.0f0,
        -0.5f0, -0.5f0,  0.5f0,
         0.5f0,  0.5f0,  0.5f0,
        -0.5f0,  0.5f0,  0.5f0,

         0.0f0,  0.0f0,  1.0f0,
        -0.5f0, -0.5f0,  0.5f0,
         0.5f0, -0.5f0,  0.5f0,
         0.5f0,  0.5f0,  0.5f0,

         0.0f0,  0.0f0, -1.0f0,
         0.5f0, -0.5f0, -0.5f0,
        -0.5f0,  0.5f0, -0.5f0,
         0.5f0,  0.5f0, -0.5f0,

         0.0f0,  0.0f0, -1.0f0,
         0.5f0, -0.5f0, -0.5f0,
        -0.5f0, -0.5f0, -0.5f0,
        -0.5f0,  0.5f0, -0.5f0,

         1.0f0, -0.0f0,  0.0f0,
         0.5f0, -0.5f0,  0.5f0,
         0.5f0,  0.5f0, -0.5f0,
         0.5f0,  0.5f0,  0.5f0,

         1.0f0,  0.0f0,  0.0f0,
         0.5f0, -0.5f0,  0.5f0,
         0.5f0, -0.5f0, -0.5f0,
         0.5f0,  0.5f0, -0.5f0,
    ]

    triangles = STL.Triangle[]
    for faceindex = 1:12:length(vertices)
        normal = Vector3(vertices[faceindex:faceindex+2])
        v1     = Vector3(vertices[faceindex+3:faceindex+5])
        v2     = Vector3(vertices[faceindex+6:faceindex+8])
        v3     = Vector3(vertices[faceindex+9:faceindex+11])
        push!(triangles, STL.Triangle(normal, v1, v2, v3, UInt16(0)))
    end
    stl = STL.STLBinary(triangles)

    io = IOBuffer()
    write(io, stl)
    seekstart(io)

    # Act
    readstl = STL.readbinary!(io)
    mesh = STL.makemesh(readstl)
    nout = CuArray{Int}(undef, 1)
    @CUDA.sync @cuda threads=1 readnumberofvertices_gpu!(mesh, nout)

    # Assert
    verticesongpu = CUDA.@allowscalar nout[1]

    @test verticesongpu == 18
end

end # testset "Mesh"

end # testset "GPU"