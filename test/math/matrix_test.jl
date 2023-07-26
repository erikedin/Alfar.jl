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
struct TestSystem3 end

S1 = TestSystem1
S2 = TestSystem2
S3 = TestSystem3

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

@testset "Matrix4 I*I; Result is I" begin
    # Arrange
    a = one(Matrix4{Float32, S1, S2})
    b = one(Matrix4{Float32, S2, S1})

    # Act
    c = a*b

    # Assert
    @test c ≈ one(Matrix4{Float32, S1, S1})
end

@testset "Matrix4 I*B; Matrix has the same values as B" begin
    # Arrange
    a = one(Matrix4{Float32, S1, S2})
    b = Matrix4{Float32, S2, S1}(
        11f0, 12f0, 13f0, 14f0,
        21f0, 22f0, 23f0, 24f0,
        31f0, 32f0, 33f0, 34f0,
        41f0, 42f0, 43f0, 44f0,
    )
    expected = Matrix4{Float32, S1, S1}(
        11f0, 12f0, 13f0, 14f0,
        21f0, 22f0, 23f0, 24f0,
        31f0, 32f0, 33f0, 34f0,
        41f0, 42f0, 43f0, 44f0,
    )

    # Act
    c = a*b

    # Assert
    @test c ≈ expected
end

@testset "Matrix4 A*B; A and B have convenient values" begin
    # Arrange
    a = Matrix4{Float32, S3, S2}(
        1f0, 10f0, 100f0, 1000f0,
        2f0, 20f0, 200f0, 2000f0,
        3f0, 30f0, 300f0, 3000f0,
        4f0, 40f0, 400f0, 4000f0,
    )
    b = Matrix4{Float32, S2, S1}(
        1f0, 2f0, 3f0, 4f0,
        2f0, 3f0, 4f0, 5f0,
        3f0, 4f0, 5f0, 6f0,
        4f0, 5f0, 6f0, 7f0,
    )
    expected = Matrix4{Float32, S3, S1}(
         4321f0,  5432f0,  6543f0,  7654f0,
         8642f0, 10864f0, 13086f0, 15308f0,
        12963f0, 16296f0, 19629f0, 22962f0,
        17284f0, 21728f0, 26172f0, 30616f0,
    )

    # Act
    c = a*b

    # Assert
    @test c ≈ expected
end

@testset "The Matrix4 value types do not match during multiplication; MethodError" begin
    # Arrange
    a = Matrix4{Float32, S1, S2}(
        0f0, 0f0, 0f0, 1f0,
        1f0, 0f0, 0f0, 0f0,
        0f0, 1f0, 0f0, 0f0,
        0f0, 0f0, 1f0, 0f0,
    )
    b = Matrix4{Float64, S2, S1}(
        0f0, 0f0, 0f0, 1f0,
        1f0, 0f0, 0f0, 0f0,
        0f0, 1f0, 0f0, 0f0,
        0f0, 0f0, 1f0, 0f0,
    )

    # Act and assert
    @test_throws MethodError a*b
end

@testset "The Matrix4 FromSystem and ToSystem systems don't match; MethodError" begin
    # Arrange
    a = Matrix4{Float32, S1, S2}(
        0f0, 0f0, 0f0, 1f0,
        1f0, 0f0, 0f0, 0f0,
        0f0, 1f0, 0f0, 0f0,
        0f0, 0f0, 1f0, 0f0,
    )
    b = Matrix4{Float32, S3, S1}(
        0f0, 0f0, 0f0, 1f0,
        1f0, 0f0, 0f0, 0f0,
        0f0, 1f0, 0f0, 0f0,
        0f0, 0f0, 1f0, 0f0,
    )

    # Act and assert
    @test_throws MethodError a*b
end

@testset "Approximate comparison; a and b are different matrices; Not approximately the same" begin
    # Arrange
    a = Matrix4{Float32, S1, S2}(
        1f0, 0f0, 0f0, 1f0,
        0f0, 1f0, 0f0, 0f0,
        0f0, 0f0, 1f0, 0f0,
        0f0, 0f0, 0f0, 1f0,
    )
    b = Matrix4{Float32, S1, S2}(
        3f0, 0f0, 0f0, 1f0,
        0f0, 3f0, 0f0, 0f0,
        0f0, 0f0, 3f0, 0f0,
        0f0, 0f0, 0f0, 3f0,
    )

    # Act and assert
    @test a ≉ b
end

end