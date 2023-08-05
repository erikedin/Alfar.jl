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

# These tests are for a test implementation of the viewport alignment intersection code.
# The real implementation runs in a vertex shader, written in GLSL, and is hard to test.
# This implementation is meant to be an aid in developing the real implementation.

@testset "Viewport Alignment Test" begin

function sliceintersection(normal::Vector3{Float32, World}, distance::Float32)
    Vector3{Float32, World}(0.5f0, 0.5f0, distance)
end

@testset "Intersection for edge 1->2; Plane is at Z=0, normal is +Z; Edge 1->2 has intersection at (0.5, 0.5, 0)" begin
    # Arrange
    distance = 0f0
    normal = Vector3{Float32, World}(0f0, 0f0, 1f0)

    # Act
    intersection = sliceintersection(normal, distance)

    # Assert
    @test intersection == Vector3{Float32, World}(0.5f0, 0.5f0, 0f0)
end

@testset "Intersection for edge 1->2; Plane is at Z=0.25, normal is +Z; Edge 1->2 has intersection at (0.5, 0.5, 0.25)" begin
    # Arrange
    distance = 0.25f0
    normal = Vector3{Float32, World}(0f0, 0f0, 1f0)

    # Act
    intersection = sliceintersection(normal, distance)

    # Assert
    @test intersection == Vector3{Float32, World}(0.5f0, 0.5f0, 0.25f0)
end

@testset "Intersection for edge 1->2; Plane is at Z=-0.25, normal is +Z; Edge 1->2 has intersection at (0.5, 0.5, -0.25)" begin
    # Arrange
    distance = -0.25f0
    normal = Vector3{Float32, World}(0f0, 0f0, 1f0)

    # Act
    intersection = sliceintersection(normal, distance)

    # Assert
    @test intersection == Vector3{Float32, World}(0.5f0, 0.5f0, -0.25f0)
end

end