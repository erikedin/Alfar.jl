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

using Test
using Alfar.WIP.Math

# Define two coordinate systems for the test cases.
struct TestCoordinateSystem end
struct OtherTestCoordinateSystem end
# Rename is S because it's too tedious to have `TestCoordinateSystem` everywhere.
const S = TestCoordinateSystem
# Rename the other one R for the same reason.
const R = OtherTestCoordinateSystem

@testset "Alfar.WIP.Math  " begin

@testset "Vector +" begin

@testset "add (1,2,3) and (2,3,4); result is (3,5,7)" begin
    # Act
    result = Vector3{Float32, S}(1f0, 2f0, 3f0) + Vector3{Float32, S}(2f0, 3f0, 4f0)

    # Assert
    @test result ≈ Vector3{Float32, S}(3f0, 5f0, 7f0)
end

# You should not be able to add two vectors with different value types, like one
# with Float32 and one with Float64.
@testset "add two vectors with different value types; MethodError" begin
    # Arrange
    a = Vector3{Float32, S}(1f0, 2f0, 3f0)
    b = Vector3{Float64, S}(2.0, 3.0, 4.0)

    # Act
    @test_throws MethodError a + b
end

# Addition of two vectors is only defined if they are in the same coordinate system.
@testset "add two vectors with different coordinate systems; MethodError" begin
    # Arrange
    a = Vector3{Float32, S}(1f0, 2f0, 3f0)
    b = Vector3{Float32, R}(2f0, 3f0, 4f0)

    # Act
    @test_throws MethodError a + b
end

# Comparison of two vectors is only defined if they have the same value type and the same coordinate system.
@testset "compare two vectors with different value types; MethodError" begin
    # Arrange
    a = Vector3{Float32, S}(1f0, 2f0, 3f0)
    b = Vector3{Float64, S}(2.0, 3.0, 4.0)

    # Act
    @test_throws MethodError a ≈ b
end

@testset "compare two vectors with different coordinate systems; MethodError" begin
    # Arrange
    a = Vector3{Float32, S}(1f0, 2f0, 3f0)
    b = Vector3{Float32, R}(2f0, 3f0, 4f0)

    # Act
    @test_throws MethodError a ≈ b
end

end

end