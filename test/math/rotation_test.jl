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
end