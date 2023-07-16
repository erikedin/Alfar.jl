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

#
# Data driven tests for vector type safety
#

# BinaryVectorTypeSafetyTestCase encapsulates test cases that checks that certain
# operations are not allowed.
struct BinaryVectorTypeSafetyTestCase
    description::String
    a::Vector3
    b::Vector3
end

# Short for Test Case Type Safety
TCTS = BinaryVectorTypeSafetyTestCase

vector_addition_tests = [
    TCTS("add two vectors with different value types; MethodError",
         Vector3{Float32, S}(1f0, 2f0, 3f0),
         Vector3{Float64, S}(2.0, 3.0, 4.0)),

    TCTS("add two vectors with different coordinate systems; MethodError",
         Vector3{Float32, S}(1f0, 2f0, 3f0),
         Vector3{Float32, R}(2f0, 3f0, 4f0)),
]

vector_comparison_tests = [
    TCTS("compare two vectors with different value types; MethodError",
         Vector3{Float32, S}(1f0, 2f0, 3f0),
         Vector3{Float64, S}(2.0, 3.0, 4.0)),

    TCTS("compare two vectors with different coordinate systems; MethodError",
         Vector3{Float32, S}(1f0, 2f0, 3f0),
         Vector3{Float32, R}(2f0, 3f0, 4f0)),
]

for testcase in vector_addition_tests
    @testset "$(testcase.description)" begin
        @test_throws MethodError testcase.a + testcase.b
    end
end

for testcase in vector_comparison_tests
    @testset "$(testcase.description)" begin
        @test_throws MethodError testcase.a ≈ testcase.b
    end
end

end

end