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

using Alfar.WIP.Math

@testset "Alfar.Math.Matrix" begin

struct TestSystem1 end
struct TestSystem2 end

S1 = TestSystem1
S2 = TestSystem2

@testset "Multiply a vector by the identity; the result is the vector unchanged" begin
    # Arrange
    A = one(Matrix4{Float32, S1, S2})
    v = Vector4{Float32, S2}(1f0, 2f0, 3f0, 4f0)

    # Act
    result = A*v

    # Assert
    @test result ≈ Vector4{Float32, S1}(1f0, 2f0, 3f0, 4f0)
end

@testset "Multiply a vector by two across the diagonal; the result is the vector doubled" begin
    # Arrange
    A = Matrix4{Float32, S1, S2}(
        2f0, 0f0, 0f0, 0f0,
        0f0, 2f0, 0f0, 0f0,
        0f0, 0f0, 2f0, 0f0,
        0f0, 0f0, 0f0, 2f0,
    )
    v = Vector4{Float32, S2}(1f0, 2f0, 3f0, 4f0)

    # Act
    result = A*v

    # Assert
    @test result ≈ Vector4{Float32, S1}(2f0, 4f0, 6f0, 8f0)
end

@testset "Multiply a (1,2,3,4) by a matrix that permutates all elements one the right; result is (4,1,2,3)" begin
    # Arrange
    A = Matrix4{Float32, S1, S2}(
        0f0, 0f0, 0f0, 1f0,
        1f0, 0f0, 0f0, 0f0,
        0f0, 1f0, 0f0, 0f0,
        0f0, 0f0, 1f0, 0f0,
    )
    v = Vector4{Float32, S2}(1f0, 2f0, 3f0, 4f0)

    # Act
    result = A*v

    # Assert
    @test result ≈ Vector4{Float32, S1}(4f0, 1f0, 2f0, 3f0)
end

@testset "The Matrix4 FromSystem type and the Vector4 System type do not match during multiplication; MethodError" begin
    # Arrange
    A = Matrix4{Float32, S1, S2}(
        0f0, 0f0, 0f0, 1f0,
        1f0, 0f0, 0f0, 0f0,
        0f0, 1f0, 0f0, 0f0,
        0f0, 0f0, 1f0, 0f0,
    )
    v = Vector4{Float32, S1}(1f0, 2f0, 3f0, 4f0)

    # Act and assert
    @test_throws MethodError A*v
end

@testset "The Matrix4 value type and the Vector4 value type do not match during multiplication; MethodError" begin
    # Arrange
    A = Matrix4{Float32, S1, S2}(
        0f0, 0f0, 0f0, 1f0,
        1f0, 0f0, 0f0, 0f0,
        0f0, 1f0, 0f0, 0f0,
        0f0, 0f0, 1f0, 0f0,
    )
    v = Vector4{Float64, S2}(1.0, 2.0, 3.0, 4.0)

    # Act and assert
    @test_throws MethodError A*v
end
end