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

end