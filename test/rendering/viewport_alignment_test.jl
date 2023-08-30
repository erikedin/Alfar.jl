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
using Alfar.Math

# These tests are for a test implementation of the viewport alignment intersection code.
# The real implementation runs in a vertex shader, written in GLSL, and is hard to test.
# This implementation is meant to be an aid in developing the real implementation.

@testset "Viewport Alignment Test" begin

function sliceintersection(distance::Float64, normal::Vector3{Float64, World}, vi::Vector3{Float64, World}, vj::Vector3{Float64, World})
    ndotvi = dot(normal, vi)
    eij = vj - vi
    ndoteij = dot(normal, eij)
    if abs(ndoteij) < 0.01
        return nothing
    end
    λ = (distance - ndotvi) / ndoteij

    vi + λ * eij
end

struct IntersectionTestCase
    distance::Float64
    normal::Vector3{Float64, World}
    vi::Int
    vj::Int
    expected
end

NormalX = Vector3{Float64, World}(1.0, 0.0, 0.0)
NormalY = Vector3{Float64, World}(0.0, 1.0, 0.0)
NormalZ = Vector3{Float64, World}(0.0, 0.0, 1.0)

intersection_test_cases = [
    IntersectionTestCase( 0.0,   NormalZ, 1, 2, Vector3{Float64, World}(0.5, 0.5, 0.0)),
    IntersectionTestCase( 0.25,  NormalZ, 1, 2, Vector3{Float64, World}(0.5, 0.5, 0.25)),
    IntersectionTestCase(-0.25,  NormalZ, 1, 2, Vector3{Float64, World}(0.5, 0.5, -0.25)),
    IntersectionTestCase( 0.0,   NormalX, 1, 5, Vector3{Float64, World}(0.0, 0.5, 0.5)),
    IntersectionTestCase( 0.0,  -NormalX, 1, 5, Vector3{Float64, World}(0.0, 0.5, 0.5)),
]

no_intersection_test_cases = [
    # No valid intersections
    IntersectionTestCase( 0.0,  NormalX, 1, 2, nothing),
]

for testcase in no_intersection_test_cases
    @testset "No intersection; $(testcase.vi) -> $(testcase.vj), d = $(testcase.distance), normal $(testcase.normal); Intersection at $(testcase.expected)" begin
        # Arrange
        vertices = [
            Vector3{Float64, World}( 0.5,  0.5,  0.5),
            Vector3{Float64, World}( 0.5,  0.5, -0.5),
            Vector3{Float64, World}( 0.5, -0.5, -0.5),
            Vector3{Float64, World}( 0.5, -0.5,  0.5),
            Vector3{Float64, World}(-0.5,  0.5,  0.5),
            Vector3{Float64, World}(-0.5,  0.5, -0.5),
            Vector3{Float64, World}(-0.5, -0.5, -0.5),
            Vector3{Float64, World}(-0.5, -0.5,  0.5),
        ]
        vi = vertices[testcase.vi]
        vj = vertices[testcase.vj]

        # Act
        result = sliceintersection(testcase.distance, testcase.normal, vi, vj)

        # Assert
        @test isnothing(result)
    end
end

end