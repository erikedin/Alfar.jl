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

using Test
using Alfar.Math
using Alfar.Format.STL
using Alfar.Format.STL: Triangle, STLBinary

@testset "STL binary write" begin

@testset "Write 2 triangles; Read STL back; 2 triangles found" begin
    # Arrange
    io = IOBuffer()
    triangle1 = Triangle(
        (0f0, 0f0, 1f0),
        (0f0, 0f0, 0f0),
        (0f0, 0f0, 0f0),
        (1f0, 0f0, 0f0),
        UInt16(0)
    )
    triangle2 = Triangle(
        (0f0, 1f0, 0f0),
        (0f0, 0f0, 0f0),
        (0f0, 0f0, 1f0),
        (1f0, 0f0, 0f0),
        UInt16(0)
    )
    header = zeros(UInt8, 80)
    stlwrite = STLBinary(header, UInt32(2), Triangle[triangle1, triangle2])

    # Act
    write(io, stlwrite)
    seekstart(io)

    # Assert
    stl = STL.readbinary!(io)
    @test stl.ntriangles == 2
end

@testset "Triangle 1, vertex 1 (17, 42, 0); Read STL back; Triangle 1, Vertex 1 (17, 42, 0)" begin
    # Arrange
    io = IOBuffer()
    triangle1 = Triangle(
        (0f0, 0f0, 1f0),
        (17f0, 42f0, 0f0),
        (0f0, 0f0, 0f0),
        (1f0, 0f0, 0f0),
        UInt16(0)
    )
    triangle2 = Triangle(
        (0f0, 1f0, 0f0),
        (0f0, 0f0, 0f0),
        (0f0, 0f0, 1f0),
        (1f0, 0f0, 0f0),
        UInt16(0)
    )
    header = zeros(UInt8, 80)
    stlwrite = STLBinary(header, UInt32(2), Triangle[triangle1, triangle2])

    # Act
    write(io, stlwrite)
    seekstart(io)

    # Assert
    stl = STL.readbinary!(io)
    @test stl.triangles[1].v1 == (17f0, 42f0, 0f0)
end

end
