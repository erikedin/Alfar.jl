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

vector_scalar_left_multiplication_tests = [
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
]

for testcase in vector_scalar_left_multiplication_tests
    @testset "add $(testcase.a) and $(testcase.b); result is $(testcase.result)" begin
        # Act
        result = testcase.a * testcase.b

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

#
# Miscellaneous test during development.
#

@testset "Approximate comparison of (1,2,3,4) and (1,2,3,5); vectors are not approximately equal" begin
    # Assert
    @test !(Vector4{Float32, S}(1f0, 2f0, 3f0, 4f0) ≈ Vector4{Float32, S}(1f0, 2f0, 3f0, 5f0))
end

end
