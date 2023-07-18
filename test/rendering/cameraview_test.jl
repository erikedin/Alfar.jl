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

using Alfar.Rendering.CameraViews
using Alfar.Rendering: World
using Alfar.Rendering.Inputs

@testset "Alfar.Rendering.CameraViews" begin

@testset "Default CameraView; Viewing direction is (0, 0, -1)" begin
    # Arrange
    cameraview = CameraView()

    # Assert
    @test direction(cameraview) ≈ Vector4{Float32, World}(0f0, 0f0, -1f0, 0f0)
end

@testset "CameraView mouse drag; Mouse dragged from center to top middle; Viewing direction is (0, 0, 1)" begin
    # Arrange
    cameraview0 = CameraView()
    # Mouse is dragged from the center of the window (0, 0) to the top middle of the window (0, 1).
    dragposition = MouseDragPositionEvent((0, 1))

    # Act
    cameraview1 = onmousedrag(cameraview0, MouseDragStartEvent())
    cameraview2 = onmousedrag(cameraview1, dragposition)
    cameraview3 = onmousedrag(cameraview2, MouseDragEndEvent())

    # Assert
    @test direction(cameraview3) ≈ Vector4{Float32, World}(0f0, 0f0, 1f0, 0f0)
end

end