# Copyright 2023 Erik Edin
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

using Alfar.WIP.Transformations

@testset "Alfar.WIP.Transformations" begin

struct TestCoordinateSystem1 end
struct TestCoordinateSystem2 end
# Rename the coordinate systems for convenience
S = TestCoordinateSystem1
R = TestCoordinateSystem2

@testset "A point rotation of 0 radians around the X axis; vector is unchanged and in the same coordinate system" begin
    # Arrange
    v = Vector3{Float32, S}(1.0, 2.0, 3.0)
    rotation = PointRotation{Float32, S}(0f0, Vector3{Float32, S}(1f0, 0f0, 0f0))

    # Act
    result = transform(rotation, v)

    # Assert
    @test result ≈ Vector3{Float32, S}(1.0, 2.0, 3.0)
end

@testset "A point rotation of (0, 1, 0) pi/2 radians around the X axis; vector is (0, 0, 1)" begin
    # Arrange
    v = Vector3{Float32, S}(0f0, 1f0, 0f0)
    rotation = PointRotation{Float32, S}(0.5f0 * pi, Vector3{Float32, S}(1f0, 0f0, 0f0))

    # Act
    result = transform(rotation, v)

    # Assert
    @test result ≈ Vector3{Float32, S}(0f0, 0f0, 1f0)
end

@testset "A point rotation of (0, 1, 0) pi/2 radians around the (17, 0, 0) axis; the vector length is unchanged" begin
    # Arrange
    v = Vector3{Float32, S}(0f0, 1f0, 0f0)
    rotation = PointRotation{Float32, S}(0.5f0 * pi, Vector3{Float32, S}(17f0, 0f0, 0f0))

    # Act
    result = transform(rotation, v)

    # Assert
    @test norm(result) ≈ 1f0
end

#
# Tests to ensure type safety
#

@testset "A point rotation for system S is applied to system R; MethodError" begin
    # Arrange
    v = Vector3{Float32, R}(1.0, 2.0, 3.0)
    rotation = PointRotation{Float32, S}(0f0, Vector3{Float32, S}(1f0, 0f0, 0f0))

    # Act and assert
    @test_throws MethodError transform(rotation, v)
end

@testset "A point rotation with value type Float32 is applied to vector with value type Float64; MethodError" begin
    # Arrange
    v = Vector3{Float64, S}(1.0, 2.0, 3.0)
    rotation = PointRotation{Float32, S}(0f0, Vector3{Float32, S}(1f0, 0f0, 0f0))

    # Act and assert
    @test_throws MethodError transform(rotation, v)
end

#
# Table driven tests for point rotations
#

point_rotation_test_cases = [
    ("Rotate pi/2 X around Z -> Y",                  # Description
     Vector3{Float32, S}(1f0, 0f0, 0f0),             # Vector to rotate
     0.5f0 * pi, Vector3{Float32, S}(0f0, 0f0, 1f0), # Angle and axis around which to rotate
     Vector3{Float32, S}(0f0, 1f0, 0f0)),            # Result vector

    ("Rotate pi/2 Y around X -> Z",
     Vector3{Float32, S}(0f0, 1f0, 0f0),
     0.5f0 * pi, Vector3{Float32, S}(1f0, 0f0, 0f0),
     Vector3{Float32, S}(0f0, 0f0, 1f0)),

    ("Rotate pi/2 Z around Y -> X",
     Vector3{Float32, S}(0f0, 0f0, 1f0),
     0.5f0 * pi, Vector3{Float32, S}(0f0, 1f0, 0f0),
     Vector3{Float32, S}(1f0, 0f0, 0f0)),

    ("Rotate pi/2 Y around Z -> -X",
     Vector3{Float32, S}(0f0, 1f0, 0f0),
     0.5f0 * pi, Vector3{Float32, S}(0f0, 0f0, 1f0),
     Vector3{Float32, S}(-1f0, 0f0, 0f0)),
]

point_rotation_test_cases_64 = [
    ("Rotate pi/2 Y around Z -> -X, type Float64",
     Vector3{Float64, S}(0.0, 1.0, 0.0),
     0.5 * pi, Vector3{Float64, S}(0.0, 0.0, 1.0),
     Vector3{Float64, S}(-1.0, 0.0, 0.0)),
]

for testcase in point_rotation_test_cases
    @testset "$(testcase[1])" begin
        # Arrange
        v = testcase[2]
        angle = testcase[3]
        axis = testcase[4]
        expected = testcase[5]
        rotation = PointRotation{Float32, S}(angle, axis)

        # Act
        result = transform(rotation, v)

        # Assert
        @test result ≈ expected
    end
end

for testcase in point_rotation_test_cases_64
    @testset "$(testcase[1])" begin
        # Arrange
        v = testcase[2]
        angle = testcase[3]
        axis = testcase[4]
        expected = testcase[5]
        rotation = PointRotation{Float64, S}(angle, axis)

        # Act
        result = transform(rotation, v)

        # Assert
        @test result ≈ expected
    end
end

#
# PointRotation comparisons
#

@testset "Comparison; A and B are 90 degrees around X; The same" begin
    # Arrange
    a = PointRotation{Float32, S}(0.5f0 * pi, Vector3{Float32, S}(1f0, 0f0, 0f0))
    b = PointRotation{Float32, S}(0.5f0 * pi, Vector3{Float32, S}(1f0, 0f0, 0f0))

    # Act and Assert
    @test a ≈ b
end

@testset "Comparison; A and B are around X, but 90 and 45 resp; Not the same" begin
    # Arrange
    a = PointRotation{Float32, S}(0.5f0 * pi, Vector3{Float32, S}(1f0, 0f0, 0f0))
    b = PointRotation{Float32, S}(0.25f0 * pi, Vector3{Float32, S}(1f0, 0f0, 0f0))

    # Act and Assert
    @test a ≉ b
end

@testset "Comparison; A and B not the same X component; Not the same" begin
    # Arrange
    a = PointRotation{Float32, S}(0.5f0 * pi, Vector3{Float32, S}( 1f0, 0f0, 0f0))
    b = PointRotation{Float32, S}(0.5f0 * pi, Vector3{Float32, S}(-1f0, 0f0, 0f0))

    # Act and Assert
    @test a ≉ b
end

@testset "Comparison; A and B not the same Y component; Not the same" begin
    # Arrange
    a = PointRotation{Float32, S}(0.5f0 * pi, Vector3{Float32, S}(0f0, -1f0, 0f0))
    b = PointRotation{Float32, S}(0.5f0 * pi, Vector3{Float32, S}(0f0,  1f0, 0f0))

    # Act and Assert
    @test a ≉ b
end

@testset "Comparison; A and B not the same Z component; Not the same" begin
    # Arrange
    a = PointRotation{Float32, S}(0.5f0 * pi, Vector3{Float32, S}(0f0, 0f0,  1f0))
    b = PointRotation{Float32, S}(0.5f0 * pi, Vector3{Float32, S}(0f0, 0f0, -1f0))

    # Act and Assert
    @test a ≉ b
end

@testset "Comparison; A and B don't have the same value type; MethodError" begin
    # Arrange
    a = PointRotation{Float32, S}(0.5f0 * pi, Vector3{Float32, S}(0f0, 0f0, 1f0))
    b = PointRotation{Float64, S}(0.5 * pi, Vector3{Float64, S}(0.0, 0.0, 1.0))

    # Act and Assert
    @test_throws MethodError a ≈ b
end

@testset "Comparison; A and B don't have the same coordinate system; MethodError" begin
    # Arrange
    a = PointRotation{Float32, S}(0.5f0 * pi, Vector3{Float32, S}(0f0, 0f0, 1f0))
    b = PointRotation{Float32, R}(0.5f0 * pi, Vector3{Float32, R}(0f0, 0f0, 1f0))

    # Act and Assert
    @test_throws MethodError a ≈ b
end

# TODO MethodError on different value type
# TODO MethodError on different coordinate system

end