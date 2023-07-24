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

struct CameraViewCoordinateSystem1 end
S = CameraViewCoordinateSystem1

@testset "Default CameraView; Viewing direction is (0, 0, -1)" begin
    # Arrange
    cameraview = CameraView(Float64, S)

    # Assert
    @test direction(cameraview) ≈ Vector3{Float64, S}(0f0, 0f0, -1f0)
end

#@testset "CameraView mouse drag; Mouse dragged from center to top middle; Viewing direction is (0, 0, 1)" begin
#    # Arrange
#    cameraview0 = CameraView()
#    # Mouse is dragged from the center of the window (0, 0) to the top middle of the window (0, 1).
#    dragposition = MouseDragPositionEvent((0, 1))

#    # Act
#    cameraview1 = onmousedrag(cameraview0, MouseDragStartEvent())
#    cameraview2 = onmousedrag(cameraview1, dragposition)
#    cameraview3 = onmousedrag(cameraview2, MouseDragEndEvent())

#    # Assert
#    @test direction(cameraview3) ≈ Vector4{Float32, World}(0f0, 0f0, 1f0, 0f0)
#end

#@testset "CameraView mouse drag; Center to half way to right; Viewing direction is (-1, 0, 0)" begin
#    # Arrange
#    cameraview0 = CameraView()
#    # Mouse is dragged from the center of the window (0, 0) to the right of the window (1, 0).
#    dragposition = MouseDragPositionEvent((0.5, 0.0))

#    # Act
#    cameraview1 = onmousedrag(cameraview0, MouseDragStartEvent())
#    cameraview2 = onmousedrag(cameraview1, dragposition)
#    cameraview3 = onmousedrag(cameraview2, MouseDragEndEvent())

#    # Assert
#    @test direction(cameraview3) ≈ Vector4{Float32, World}(-1f0, 0f0, 0f0, 0f0)
#end

struct MouseDragDirectionTestCase
    positions::Vector{NTuple{2, Float64}}
    resultdirection::Vector3{Float64, S}
end

DirectionAlongXPositive = Vector3{Float64, S}( 1f0,  0f0,  0f0)
DirectionAlongXNegative = Vector3{Float64, S}(-1f0,  0f0,  0f0)
DirectionAlongYPositive = Vector3{Float64, S}( 0f0,  1f0,  0f0)
DirectionAlongYNegative = Vector3{Float64, S}( 0f0, -1f0,  0f0)
DirectionAlongZPositive = Vector3{Float64, S}( 0f0,  0f0,  1f0)
DirectionAlongZNegative = Vector3{Float64, S}( 0f0,  0f0, -1f0)

mousedragdirectiontestcases = [
    # All these test cases start off with the default direction -Z.

    # This block of test cases all rotate the camera at 90 degree angles,
    # always along the same axis. This means that the axis around which we rotate
    # doesn't change, and that is the simplest case.
    # Around the X axis, 90 degree turns
    MouseDragDirectionTestCase([(0.0, 0.5)], DirectionAlongYPositive),
    MouseDragDirectionTestCase([(0.0, -0.5)], DirectionAlongYNegative),
    MouseDragDirectionTestCase([(0.0, 0.5), (0.0, 0.5)], DirectionAlongZPositive),
    MouseDragDirectionTestCase([(0.0, 0.5), (0.0, 0.5), (0.0, 0.5)], DirectionAlongYNegative),
    MouseDragDirectionTestCase([(0.0, 0.5), (0.0, 0.5), (0.0, 0.5), (0.0, 0.5)], DirectionAlongZNegative),
    # Around the Y axis, 90 degrees
    MouseDragDirectionTestCase([(0.5, 0.0)], DirectionAlongXNegative),
    MouseDragDirectionTestCase([(0.5, 0.0), (0.5, 0.0)], DirectionAlongZPositive),
    MouseDragDirectionTestCase([(0.5, 0.0), (0.5, 0.0), (0.5, 0.0)], DirectionAlongXPositive),
    MouseDragDirectionTestCase([(0.5, 0.0), (0.5, 0.0), (0.5, 0.0), (0.5, 0.0)], DirectionAlongZNegative),

    # Here are some test cases for 180 degree turns.
    # Since the starting direction is -Z, any 180 degree turn will end up at +Z.
    # Drag the camera 180 degrees around the X axis
    MouseDragDirectionTestCase([(0.0, 1.0)], DirectionAlongZPositive),
    MouseDragDirectionTestCase([(0.0, -1.0)], DirectionAlongZPositive),
    # Drag the camera 180 degrees around the Y axis
    MouseDragDirectionTestCase([(1.0, 0.0)], DirectionAlongZPositive),
    MouseDragDirectionTestCase([(-1.0, 0.0)], DirectionAlongZPositive),

    # These test cases rotate both horizontally and vertically.
    # 1. Horizontal rotation 90 degrees (around the Y axis
    #    The `right` vector is now -Z.
    # 2. Vertical rotation 90 degrees, which is around the Z axis.
    # Result: Direction is in the -Y direction.
    MouseDragDirectionTestCase([(0.5, 0.0), (0.0, 0.5)], DirectionAlongYNegative),
]

for testcase in mousedragdirectiontestcases
    @testset "Dragging: $(testcase.positions); Result direction is $(testcase.resultdirection)" begin
        # Arrange
        cameraview = CameraView(Float64, S)

        # Act
        for dragposition in testcase.positions
            cameraview = onmousedrag(cameraview, MouseDragStartEvent())
            cameraview = onmousedrag(cameraview, MouseDragPositionEvent(dragposition))
            cameraview = onmousedrag(cameraview, MouseDragEndEvent())
        end

        # Assert
        @test direction(cameraview) ≈ testcase.resultdirection
    end
end

@testset "Dragging; 90 degrees right, then up; Looking down Y" begin
        # Arrange
        cameraview = CameraView(Float64, S)

        # Act
        # Right
        println("Before:", cameraview)
        cameraview = onmousedrag(cameraview, MouseDragStartEvent())
        cameraview = onmousedrag(cameraview, MouseDragPositionEvent((0.5, 0.0)))
        cameraview = onmousedrag(cameraview, MouseDragEndEvent())
        println("Rotation 1:", cameraview)

        # Up
        cameraview = onmousedrag(cameraview, MouseDragStartEvent())
        cameraview = onmousedrag(cameraview, MouseDragPositionEvent((0.0, 0.5)))
        cameraview = onmousedrag(cameraview, MouseDragEndEvent())

        # Assert
        println("Rotation 2:", cameraview)
        @test direction(cameraview) ≈ DirectionAlongYNegative
        @test cameraview.up ≈ DirectionAlongXNegative

end
end