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
using Alfar.Format.STL

@testset "STL binary" begin

@testset "Parse STL; Header is all zeroes; Parsed header is all zeros" begin
    # Arrange
    header = zeros(UInt8, 80)
    ntriangles = UInt32(1)
    data = [
        header, ntriangles,

        # Triangle 1
        Float32(0), Float32(0), Float32(1),
        Float32(1), Float32(0), Float32(0),
        Float32(0), Float32(1), Float32(0),
        Float32(0), Float32(0), Float32(0),
        UInt16(0),
    ]
    io = IOBuffer()
    for d in data
        write(io, d)
    end
    seekstart(io)

    # Act
    stl = STL.readbinary!(io)

    # Assert
    @test stl.header == header
end

@testset "Parse STL; Header contains all ones; Parsed header has all ones" begin
    # Arrange
    header = ones(UInt8, 80)
    ntriangles = UInt32(1)
    data = [
        header, ntriangles,

        # Triangle 1
        Float32(0), Float32(0), Float32(1),
        Float32(1), Float32(0), Float32(0),
        Float32(0), Float32(1), Float32(0),
        Float32(0), Float32(0), Float32(0),
        UInt16(0),
    ]
    io = IOBuffer()
    for d in data
        write(io, d)
    end
    seekstart(io)

    # Act
    stl = STL.readbinary!(io)

    # Assert
    @test stl.header == header
end

@testset "Parse STL; Header is too short, only 79 bytes; Parse fails" begin
    # Arrange
    header = ones(UInt8, 79)
    data = [
        header
    ]
    io = IOBuffer()
    for d in data
        write(io, d)
    end
    seekstart(io)

    # Act and Assert
    @test_throws STL.ParserError STL.readbinary!(io)
end

@testset "Parse STL; Header says 1 triangle; Parsed result says 1 triangle" begin
    # Arrange
    header = ones(UInt8, 80)
    ntriangles = UInt32(1)
    data = [
        header, ntriangles,

        # Triangle 1
        Float32(0), Float32(0), Float32(1),
        Float32(1), Float32(0), Float32(0),
        Float32(0), Float32(1), Float32(0),
        Float32(0), Float32(0), Float32(0),
        UInt16(0),
    ]
    io = IOBuffer()
    for d in data
        write(io, d)
    end
    seekstart(io)

    # Act
    stl = STL.readbinary!(io)

    # Assert
    @test stl.ntriangles == 1
end

@testset "Parse STL; Header says 2 triangles; Parsed result says 2 triangles" begin
    # Arrange
    header = ones(UInt8, 80)
    ntriangles = UInt32(2)
    data = [
        header, ntriangles,

        # Triangle 1
        Float32(0), Float32(0), Float32(1),
        Float32(1), Float32(0), Float32(0),
        Float32(0), Float32(1), Float32(0),
        Float32(0), Float32(0), Float32(0),
        UInt16(0),

        # Triangle 2
        Float32(0), Float32(0), Float32(1),
        Float32(1), Float32(0), Float32(0),
        Float32(0), Float32(1), Float32(0),
        Float32(0), Float32(0), Float32(0),
        UInt16(0),
    ]
    io = IOBuffer()
    for d in data
        write(io, d)
    end
    seekstart(io)

    # Act
    stl = STL.readbinary!(io)

    # Assert
    @test stl.ntriangles == 2
end

@testset "Parse STL; Normal is the Z-axis; First normal is the Z-axis" begin
    # Arrange
    header = zeros(UInt8, 80)
    ntriangles = UInt32(1)
    data = [
        header, ntriangles,

        # Triangle 1
        Float32(0), Float32(0), Float32(1),
        Float32(1), Float32(0), Float32(0),
        Float32(0), Float32(1), Float32(0),
        Float32(0), Float32(0), Float32(0),
        UInt16(0),
    ]
    io = IOBuffer()
    for d in data
        write(io, d)
    end
    seekstart(io)

    # Act
    stl = STL.readbinary!(io)

    # Assert
    @test stl.triangles[1].normal == NTuple{3, Float32}([0f0, 0f0, 1f0])
end

@testset "Parse STL; Normal is the Y-axis; First normal is the Y-axis" begin
    # Arrange
    header = zeros(UInt8, 80)
    ntriangles = UInt32(1)
    data = [
        header, ntriangles,

        # Triangle 1
        Float32(0), Float32(1), Float32(0),
        Float32(1), Float32(0), Float32(0),
        Float32(0), Float32(1), Float32(0),
        Float32(0), Float32(0), Float32(0),
        UInt16(0),
    ]
    io = IOBuffer()
    for d in data
        write(io, d)
    end
    seekstart(io)

    # Act
    stl = STL.readbinary!(io)

    # Assert
    @test stl.triangles[1].normal == NTuple{3, Float32}([0f0, 1f0, 0f0])
end

end