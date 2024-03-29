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

using Alfar.Math

@testset "Vector +" begin

# Define two coordinate systems for the test cases.
struct TestCoordinateSystem end
struct OtherTestCoordinateSystem end
# Rename is S because it's too tedious to have `TestCoordinateSystem` everywhere.
S = TestCoordinateSystem
# Rename the other one R for the same reason.
R = OtherTestCoordinateSystem


# BinaryVectorTypeSafetyTestCase encapsulates test cases that checks that certain
# operations are not allowed.
struct BinaryVectorTypeSafetyTestCase
    description
    a
    b
end

# Short for Test Case Type Safety
TCTS = BinaryVectorTypeSafetyTestCase

struct BinaryVectorTestCase
    a
    b
    result
end

TC = BinaryVectorTestCase

#
# Test cases for vector addition
#

vector_addition_tests = [
    TC(
        Vector3{Float32, S}(1f0, 2f0, 3f0),
        Vector3{Float32, S}(2f0, 3f0, 4f0),
        Vector3{Float32, S}(3f0, 5f0, 7f0)
    ),

    TC(
        Vector4{Float32, S}(1f0, 2f0, 3f0, 4f0),
        Vector4{Float32, S}(5f0, 6f0, 7f0, 8f0),
        Vector4{Float32, S}(6f0, 8f0, 10f0, 12f0)
    )
]

for testcase in vector_addition_tests
    @testset "add $(testcase.a) and $(testcase.b); result is $(testcase.result)" begin
        # Act
        result = testcase.a + testcase.b

        # Assert
        @test result ≈ testcase.result
    end
end

vector_subtraction_tests = [
    TC(
        Vector3{Float32, S}(2f0, 4f0, 6f0),
        Vector3{Float32, S}(1f0, 2f0, 3f0),
        Vector3{Float32, S}(1f0, 2f0, 3f0)
    ),

    TC(
        Vector4{Float32, S}(0f0, 0f0, 0f0, 0f0),
        Vector4{Float32, S}(5f0, 6f0, 7f0, 8f0),
        Vector4{Float32, S}(-5f0, -6f0, -7f0, -8f0)
    )
]

for testcase in vector_subtraction_tests
    @testset "Subtraction; $(testcase.a) and $(testcase.b); result is $(testcase.result)" begin
        # Act
        result = testcase.a - testcase.b

        # Assert
        @test result ≈ testcase.result
    end
end

vector_scalar_multiplication_tests = [
    TC(
        1f0,
        Vector4{Float32, S}(1f0, 2f0, 3f0, 4f0),
        Vector4{Float32, S}(1f0, 2f0, 3f0, 4f0)
    )
    TC(
        2f0,
        Vector4{Float32, S}(1f0, 2f0, 3f0, 4f0),
        Vector4{Float32, S}(2f0, 4f0, 6f0, 8f0)
    )

    TC(
        Vector4{Float32, S}(1f0, 2f0, 3f0, 4f0),
        1f0,
        Vector4{Float32, S}(1f0, 2f0, 3f0, 4f0)
    )
    TC(
        Vector4{Float32, S}(1f0, 2f0, 3f0, 4f0),
        2f0,
        Vector4{Float32, S}(2f0, 4f0, 6f0, 8f0)
    )

    TC(
        1f0,
        Vector3{Float32, S}(1f0, 2f0, 3f0),
        Vector3{Float32, S}(1f0, 2f0, 3f0)
    )
    TC(
        2f0,
        Vector3{Float32, S}(1f0, 2f0, 3f0),
        Vector3{Float32, S}(2f0, 4f0, 6f0)
    )

    TC(
        Vector3{Float32, S}(1f0, 2f0, 3f0),
        1f0,
        Vector3{Float32, S}(1f0, 2f0, 3f0)
    )
    TC(
        Vector3{Float32, S}(1f0, 2f0, 3f0),
        2f0,
        Vector3{Float32, S}(2f0, 4f0, 6f0)
    )
]

for testcase in vector_scalar_multiplication_tests
    @testset "multiply $(testcase.a) and $(testcase.b); result is $(testcase.result)" begin
        # Act
        result = testcase.a * testcase.b

        # Assert
        @test result ≈ testcase.result
    end
end

for testcase in vector_scalar_multiplication_tests
    @testset "multiply $(testcase.b) and $(testcase.a); result is $(testcase.result)" begin
        # Act
        result = testcase.b * testcase.a

        # Assert
        @test result ≈ testcase.result
    end
end

#
# Test cases for type safety when adding vectors
#

vector_addition_type_safety_tests = [
    TCTS("add two vectors with different value types; MethodError",
         Vector3{Float32, S}(1f0, 2f0, 3f0),
         Vector3{Float64, S}(2.0, 3.0, 4.0)),

    TCTS("add two vectors with different coordinate systems; MethodError",
         Vector3{Float32, S}(1f0, 2f0, 3f0),
         Vector3{Float32, R}(2f0, 3f0, 4f0)),

    TCTS("add two vectors with different value types; MethodError",
         Vector4{Float32, S}(1f0, 2f0, 3f0, 0f0),
         Vector4{Float64, S}(2.0, 3.0, 4.0, 0.0)),

    TCTS("add two vectors with different coordinate systems; MethodError",
         Vector4{Float32, S}(1f0, 2f0, 3f0, 0f0),
         Vector4{Float32, R}(2f0, 3f0, 4f0, 0f0)),
]

#
# Test cases for type safety when comparing vectors
#

vector_comparison_type_safety_tests = [
    TCTS("compare two vectors with different value types; MethodError",
         Vector3{Float32, S}(1f0, 2f0, 3f0),
         Vector3{Float64, S}(2.0, 3.0, 4.0)),

    TCTS("compare two vectors with different coordinate systems; MethodError",
         Vector3{Float32, S}(1f0, 2f0, 3f0),
         Vector3{Float32, R}(2f0, 3f0, 4f0)),

    TCTS("compare two vectors with different value types; MethodError",
         Vector4{Float32, S}(1f0, 2f0, 3f0, 0f0),
         Vector4{Float64, S}(2.0, 3.0, 4.0, 5.0)),

    TCTS("compare two vectors with different coordinate systems; MethodError",
         Vector4{Float32, S}(1f0, 2f0, 3f0, 0f0),
         Vector4{Float32, R}(2f0, 3f0, 4f0, 0f0)),
]

#
# Test cases for type safety during left scalar multiplication of vectors
#

vector_scalar_left_multiplication_type_safety_tests = [
    TCTS(
        "multiply a Float64 with a Float32 vector",
        1.0,
        Vector4{Float32, S}(1f0, 2f0, 3f0, 4f0),
    )
]

#
# Generate test sets for the above test cases
#

for testcase in vector_addition_type_safety_tests
    @testset "$(testcase.description)" begin
        @test_throws MethodError testcase.a + testcase.b
    end
end

for testcase in vector_comparison_type_safety_tests
    @testset "$(testcase.description)" begin
        @test_throws MethodError testcase.a ≈ testcase.b
    end
end

for testcase in vector_scalar_left_multiplication_type_safety_tests
    @testset "$(testcase.description)" begin
        @test_throws MethodError testcase.a * testcase.b
    end
end

#
# Other vector operations
#

struct NormTestCase
    v
    expected
end

norm_test_cases = [
    NormTestCase(Vector4{Float32, S}(1f0, 0f0, 0f0, 0f0), 1f0),
    NormTestCase(Vector4{Float32, S}(0f0, 1f0, 0f0, 0f0), 1f0),
    NormTestCase(Vector4{Float32, S}(0f0, 0f0, 1f0, 0f0), 1f0),
    NormTestCase(Vector4{Float32, S}(0f0, 0f0, 0f0, 1f0), 1f0),
    NormTestCase(Vector4{Float32, S}(1f0, 1f0, 0f0, 0f0), sqrt(2f0)),
    NormTestCase(Vector4{Float32, S}(0f0, 1f0, 1f0, 0f0), sqrt(2f0)),
    NormTestCase(Vector4{Float32, S}(0f0, 0f0, 1f0, 1f0), sqrt(2f0)),
    NormTestCase(Vector4{Float32, S}(1f0, 0f0, 0f0, 1f0), sqrt(2f0)),
    NormTestCase(Vector4{Float32, S}(1f0, 2f0, 3f0, 4f0), sqrt(1 + 4 + 9 + 16)),
]

for testcase in norm_test_cases
    @testset "Norm; $(testcase.v); Expected is $(testcase.expected)" begin
        # Act
        result = norm(testcase.v)

        # Assert
        @test result ≈ testcase.expected
    end
end

@testset "Norm; (1, 0, 0); Norm is 1" begin
    # Arrange
    v = Vector3{Float32, S}(1f0, 0f0, 0f0)

    # Act
    length = norm(v)

    # Assert
    @test length ≈ 1f0
end

@testset "Norm; (1, 1, 1); Norm is sqrt(3)" begin
    # Arrange
    v = Vector3{Float32, S}(1f0, 1f0, 1f0)

    # Act
    length = norm(v)

    # Assert
    @test length ≈ sqrt(3f0)
end

@testset "Norm; (3, 4, 0); Norm is 5" begin
    # Arrange
    v = Vector3{Float32, S}(3f0, 4f0, 0f0)

    # Act
    length = norm(v)

    # Assert
    @test length ≈ 5f0
end

@testset "Normalize; (1, 0, 0); result is (1, 0, 0)" begin
    # Arrange
    v = Vector3{Float32, S}(1f0, 0f0, 0f0)

    # Act
    p = normalize(v)

    # Assert
    @test p ≈ Vector3{Float32, S}(1f0, 0f0, 0f0)
end

@testset "Normalize; (17, 0, 0); result is (1, 0, 0)" begin
    # Arrange
    v = Vector3{Float32, S}(17f0, 0f0, 0f0)

    # Act
    p = normalize(v)

    # Assert
    @test p ≈ Vector3{Float32, S}(1f0, 0f0, 0f0)
end

@testset "Normalize; (3, 4, 0); result is 1/5*(3, 4, 0)" begin
    # Arrange
    v = Vector3{Float32, S}(3f0, 4f0, 0f0)

    # Act
    p = normalize(v)

    # Assert
    @test p ≈ 0.2f0 * Vector3{Float32, S}(3f0, 4f0, 0f0)
end

@testset "Cross product; X cross Y; Result is Z" begin
    # Arrange
    a = Vector3{Float32, S}(1f0, 0f0, 0f0)
    b = Vector3{Float32, S}(0f0, 1f0, 0f0)

    # Act
    p = cross(a, b)

    # Assert
    @test p ≈ Vector3{Float32, S}(0f0, 0f0, 1f0)
end

@testset "Cross product; Y cross Z; Result is X" begin
    # Arrange
    a = Vector3{Float32, S}(0f0, 1f0, 0f0)
    b = Vector3{Float32, S}(0f0, 0f0, 1f0)

    # Act
    p = cross(a, b)

    # Assert
    @test p ≈ Vector3{Float32, S}(1f0, 0f0, 0f0)
end

@testset "Cross product; Z cross X; Result is Y" begin
    # Arrange
    a = Vector3{Float32, S}(0f0, 0f0, 1f0)
    b = Vector3{Float32, S}(1f0, 0f0, 0f0)

    # Act
    p = cross(a, b)

    # Assert
    @test p ≈ Vector3{Float32, S}(0f0, 1f0, 0f0)
end

@testset "Cross product; -Z cross Y; Result is X" begin
    # This test is specifically important as -Z is the default direction of the camera,
    # and Y is the default up vector. Crossing them should lead to the right vector,
    # which in this case is X.
    # Arrange
    a = Vector3{Float32, S}(0f0, 0f0, -1f0)
    b = Vector3{Float32, S}(0f0, 1f0, 0f0)

    # Act
    p = cross(a, b)

    # Assert
    @test p ≈ Vector3{Float32, S}(1f0, 0f0, 0f0)
end

@testset "Dot product; (1,2,3)⋅(4,5,6); Result is 4+10+18 = 32" begin
    # This test is specifically important as -Z is the default direction of the camera,
    # and Y is the default up vector. Crossing them should lead to the right vector,
    # which in this case is X.
    # Arrange
    a = Vector3{Float32, S}(1f0, 2f0, 3f0)
    b = Vector3{Float32, S}(4f0, 5f0, 6f0)

    # Act
    p = dot(a, b)

    # Assert
    @test p ≈ 32f0
end

#
# Miscellaneous test during development.
#

@testset "Approximate comparison of (1,2,3,4) and (1,2,3,5); vectors are not approximately equal" begin
    # Assert
    @test !(Vector4{Float32, S}(1f0, 2f0, 3f0, 4f0) ≈ Vector4{Float32, S}(1f0, 2f0, 3f0, 5f0))
end

approximate_equality_testcases = [
    (Vector3{Float32, S}(0f0, 1f0, 0f0), Vector3{Float32, S}(1e-4, 1f0, 0f0)),
    (Vector3{Float32, S}(1f0, 0f0, 0f0), Vector3{Float32, S}(1f0, 1e-4, 0f0)),
    (Vector3{Float32, S}(1f0, 0f0, 0f0), Vector3{Float32, S}(1f0, 0f0, 1e-4)),
    (Vector3{Float64, S}(0.0, 1.0, 0.0), Vector3{Float64, S}(1e-8, 1.0, 0.0)),
    (Vector3{Float64, S}(1.0, 0.0, 0.0), Vector3{Float64, S}(1.0, 1e-8, 0.0)),
    (Vector3{Float64, S}(1.0, 0.0, 0.0), Vector3{Float64, S}(1.0, 0.0, 1e-8)),

    (Vector4{Float32, S}(0f0, 1f0, 0f0, 0f0), Vector4{Float32, S}(1e-4, 1f0, 0f0, 0f0)),
    (Vector4{Float32, S}(1f0, 0f0, 0f0, 0f0), Vector4{Float32, S}(1f0, 1e-4, 0f0, 0f0)),
    (Vector4{Float32, S}(1f0, 0f0, 0f0, 0f0), Vector4{Float32, S}(1f0, 0f0, 1e-4, 0f0)),
    (Vector4{Float32, S}(1f0, 0f0, 0f0, 0f0), Vector4{Float32, S}(1f0, 0f0, 0f0, 1e-4)),
    (Vector4{Float64, S}(0.0, 1.0, 0.0, 0.0), Vector4{Float64, S}(1e-8, 1.0, 0.0, 0.0)),
    (Vector4{Float64, S}(1.0, 0.0, 0.0, 0.0), Vector4{Float64, S}(1.0, 1e-8, 0.0, 0.0)),
    (Vector4{Float64, S}(1.0, 0.0, 0.0, 0.0), Vector4{Float64, S}(1.0, 0.0, 1e-8, 0.0)),
    (Vector4{Float64, S}(1.0, 0.0, 0.0, 0.0), Vector4{Float64, S}(1.0, 0.0, 0.0, 1e-8)),
]

for testcase in approximate_equality_testcases
    @testset "Inexact comparison; $(testcase[1]) and $(testcase[2]); Are nearly equal" begin
        # Arrange
        a = testcase[1]
        b = testcase[2]

        # Assert
        @test a ≈ b
    end
end

# Negation

@testset "Negation; Negate (1,2,3); Result is (-1, -2, -3)" begin
    # Act
    result = -Vector3{Float32, S}(1f0, 2f0, 3f0)

    # Assert
    @test result ≈ Vector3{Float32, S}(-1f0, -2f0, -3f0)
end

@testset "Negation; Negate (1,2,3,4); Result is (-1, -2, -3, -4)" begin
    # Act
    result = -Vector4{Float32, S}(1f0, 2f0, 3f0, 4f0)

    # Assert
    @test result ≈ Vector4{Float32, S}(-1f0, -2f0, -3f0, -4f0)
end

#
# Occasionally it's convenient to interpret a Vector3 as a Vector4 with homogeneous
# coordinates. For instance, if you want to use a Matrix4 to transform a Vector3.
#

@testset "Reinterpret 3->4; Vector3 is (1,2,3); Vector4 is by default (1,2,3,0)" begin
    # Arrange
    v3 = Vector3{Float32, S}(1f0, 2f0, 3f0)

    # Act
    v4 = Vector4{Float32, S}(v3)

    # Assert
    @test v4 ≈ Vector4{Float32, S}(1f0, 2f0, 3f0, 0f0)
end

end
