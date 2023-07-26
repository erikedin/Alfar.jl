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
    cameraview = CameraView{Float64, S}()

    # Assert
    @test direction(cameraview) ≈ Vector3{Float64, S}(0f0, 0f0, -1f0)
end

struct MouseDragDirectionTestCase
    positions::Vector{NTuple{2, Float64}}
    resultdirection::Vector3{Float64, S}
    resultup::Vector3{Float64, S}
end

DirectionAlongXPositive = Vector3{Float64, S}( 1f0,  0f0,  0f0)
DirectionAlongXNegative = Vector3{Float64, S}(-1f0,  0f0,  0f0)
DirectionAlongYPositive = Vector3{Float64, S}( 0f0,  1f0,  0f0)
DirectionAlongYNegative = Vector3{Float64, S}( 0f0, -1f0,  0f0)
DirectionAlongZPositive = Vector3{Float64, S}( 0f0,  0f0,  1f0)
DirectionAlongZNegative = Vector3{Float64, S}( 0f0,  0f0, -1f0)

UpAlongXPositive = Vector3{Float64, S}( 1f0,  0f0,  0f0)
UpAlongXNegative = Vector3{Float64, S}(-1f0,  0f0,  0f0)
UpAlongYPositive = Vector3{Float64, S}( 0f0,  1f0,  0f0)
UpAlongYNegative = Vector3{Float64, S}( 0f0, -1f0,  0f0)
UpAlongZPositive = Vector3{Float64, S}( 0f0,  0f0,  1f0)
UpAlongZNegative = Vector3{Float64, S}( 0f0,  0f0, -1f0)

mousedragdirectiontestcases = [
    # All these test cases start off with the default direction -Z.

    # This block of test cases all rotate the camera at 90 degree angles,
    # always along the same axis. This means that the axis around which we rotate
    # doesn't change, and that is the simplest case.
    # Around the X axis, 90 degree turns
    MouseDragDirectionTestCase([(0.0, 0.5)], DirectionAlongYPositive, UpAlongZPositive),
    MouseDragDirectionTestCase([(0.0, -0.5)], DirectionAlongYNegative, UpAlongZNegative),
    MouseDragDirectionTestCase([(0.0, 0.5), (0.0, 0.5)], DirectionAlongZPositive, UpAlongYNegative),
    MouseDragDirectionTestCase([(0.0, 0.5), (0.0, 0.5), (0.0, 0.5)], DirectionAlongYNegative, UpAlongZNegative),
    MouseDragDirectionTestCase([(0.0, 0.5), (0.0, 0.5), (0.0, 0.5), (0.0, 0.5)], DirectionAlongZNegative, UpAlongYPositive),
    # Around the Y axis, 90 degrees
    MouseDragDirectionTestCase([(0.5, 0.0)], DirectionAlongXPositive, UpAlongYPositive),
    MouseDragDirectionTestCase([(0.5, 0.0), (0.5, 0.0)], DirectionAlongZPositive, UpAlongYPositive),
    MouseDragDirectionTestCase([(0.5, 0.0), (0.5, 0.0), (0.5, 0.0)], DirectionAlongXNegative, UpAlongYPositive),
    MouseDragDirectionTestCase([(0.5, 0.0), (0.5, 0.0), (0.5, 0.0), (0.5, 0.0)], DirectionAlongZNegative, UpAlongYPositive),

    # Here are some test cases for 180 degree turns.
    # Since the starting direction is -Z, any 180 degree turn will end up at +Z.
    # Drag the camera 180 degrees around the X axis
    MouseDragDirectionTestCase([(0.0, 1.0)], DirectionAlongZPositive, UpAlongYNegative),
    MouseDragDirectionTestCase([(0.0, -1.0)], DirectionAlongZPositive, UpAlongYNegative),
    # Drag the camera 180 degrees around the Y axis
    MouseDragDirectionTestCase([(1.0, 0.0)], DirectionAlongZPositive, UpAlongYPositive),
    MouseDragDirectionTestCase([(-1.0, 0.0)], DirectionAlongZPositive, UpAlongYPositive),

    # These test cases rotate both horizontally and vertically.
    # 1. Horizontal rotation 90 degrees (around the Y axis
    #    The `right` vector is now +Z.
    # 2. Vertical rotation 90 degrees, which is around the Z axis.
    # Result: Direction is in the +Y direction.
    MouseDragDirectionTestCase([(0.5, 0.0), (0.0, 0.5)], DirectionAlongYPositive, UpAlongXNegative),
]

for testcase in mousedragdirectiontestcases
    @testset "Dragging: $(testcase.positions); Result direction is $(testcase.resultdirection)" begin
        # Arrange
        cameraview = CameraView{Float64, S}()

        # Act
        for dragposition in testcase.positions
            cameraview = onmousedrag(cameraview, MouseDragStartEvent())
            cameraview = onmousedrag(cameraview, MouseDragPositionEvent(dragposition))
            cameraview = onmousedrag(cameraview, MouseDragEndEvent())
        end

        # Assert
        @test direction(cameraview) ≈ testcase.resultdirection
        @test up(cameraview) ≈ testcase.resultup
    end
end

@testset "Dragging; 90 degrees around Y; No mouse drag event; Result direction is X" begin
    # Arrange
    cameraview = CameraView{Float64, S}()

    # Act
    cameraview = onmousedrag(cameraview, MouseDragStartEvent())
    cameraview = onmousedrag(cameraview, MouseDragPositionEvent((0.5, 0.0)))

    # Assert
    @test direction(cameraview) ≈ Vector3{Float64, S}(1.0, 0.0, 0.0)
    @test up(cameraview) ≈ Vector3{Float64, S}(0.0, 1.0, 0.0)
end

@testset "Dragging; 45 and then 90 degrees around Y; No mouse drag event; Result direction is X" begin
    # Arrange
    cameraview = CameraView{Float64, S}()

    # Act
    cameraview = onmousedrag(cameraview, MouseDragStartEvent())
    cameraview = onmousedrag(cameraview, MouseDragPositionEvent((0.25, 0.0)))
    cameraview = onmousedrag(cameraview, MouseDragPositionEvent((0.5, 0.0)))

    # Assert
    @test direction(cameraview) ≈ Vector3{Float64, S}(1.0, 0.0, 0.0)
    @test up(cameraview) ≈ Vector3{Float64, S}(0.0, 1.0, 0.0)
end

@testset "Right axis; Direction is (0, 0, -10) and up is (0, 2, 0); Right axis is normalized" begin
    # Arrange
    position = Vector3{Float32, S}(0f0, 0f0, -3f0)
    direction = Vector3{Float32, S}(0f0, 0f0, -10f0)
    up = Vector3{Float32, S}(0f0, 2f0, 0f0)
    cameraview = CameraView{Float32, S}(position, direction, up)

    # Act
    r = right(cameraview)

    # Assert
    @test norm(r) ≈ 1
end

@testset "Direction; Direction is (0, 0, -10); Direction axis is normalized" begin
    # Arrange
    position = Vector3{Float32, S}(0f0, 0f0, -3f0)
    initialdirection = Vector3{Float32, S}(0f0, 0f0, -10f0)
    up = Vector3{Float32, S}(0f0, 2f0, 0f0)
    cameraview = CameraView{Float32, S}(position, initialdirection, up)

    # Act
    d = direction(cameraview)

    # Assert
    @test norm(d) ≈ 1
end

@testset "Direction; Default CameraView; Direction axis is normalized" begin
    # Arrange
    cameraview = CameraView{Float32, S}()

    # Act
    d = direction(cameraview)

    # Assert
    @test norm(d) ≈ 1
end

@testset "Direction; Update direction with (0, 0, -2); Direction axis is normalized" begin
    # Arrange
    cameraview0 = CameraView{Float32, S}()
    newdirection = Vector3{Float32, S}(0, 0, -2f0)
    newup = Vector3{Float32, S}(0, 1f0, 0)
    cameraview = CameraView{Float32, S}(cameraview0, newdirection, newup)

    # Act
    d = direction(cameraview)

    # Assert
    @test norm(d) ≈ 1
end

@testset "Normalization; Default CameraView; Up vector is normalized" begin
    # Arrange
    cameraview = CameraView{Float32, S}()

    # Act
    u = up(cameraview)

    # Assert
    @test norm(u) ≈ 1
end

@testset "Normalization; Up is (0, 2, 0); Up vector is normalized" begin
    # Arrange
    initialposition = Vector3{Float32, S}(0f0, 0f0, -3f0)
    initialdirection = Vector3{Float32, S}(0f0, 0f0, -1f0)
    initialup = Vector3{Float32, S}(0f0, 2f0, 0f0)
    cameraview = CameraView{Float32, S}(initialposition, initialdirection, initialup)

    # Act
    u = up(cameraview)

    # Assert
    @test norm(u) ≈ 1
end

@testset "Normalization; Update up to (0, 2, 0); Up vector is normalized" begin
    # Arrange
    cameraview0 = CameraView{Float32, S}()
    newdirection = Vector3{Float32, S}(0f0, 0f0, -1f0)
    newup = Vector3{Float32, S}(0f0, 2f0, 0f0)
    cameraview = CameraView{Float32, S}(cameraview0, newdirection, newup)

    # Act
    u = up(cameraview)

    # Assert
    @test norm(u) ≈ 1
end

#
# These are test cases for the `lookat` matrix, calculated from the camera view.
# Essentially, the look-at matrix is the inverse of the camera view. If the camera is rotated
# 90 degrees around the Y axis, then the lookat matrix represents a rotation of -90 degrees around
# the Y axis. The test cases are basically the same as the ones above.
#

struct LookAtTestCase
    positions::Vector{NTuple{2, Float64}}
    direction::Vector4{Float64, CameraViewSpace}
    up::Vector4{Float64, CameraViewSpace}
end

ViewDirectionAlongX = Vector4{Float64, CameraViewSpace}(1f0,  0f0,  0f0, 0f0)
ViewDirectionAlongY = Vector4{Float64, CameraViewSpace}(0f0,  1f0,  0f0, 0f0)
ViewDirectionAlongZ = Vector4{Float64, CameraViewSpace}(0f0,  0f0,  1f0, 0f0)

ViewUpAlongX = Vector4{Float64, CameraViewSpace}(1f0,  0f0,  0f0, 0f0)
ViewUpAlongY = Vector4{Float64, CameraViewSpace}(0f0,  1f0,  0f0, 0f0)
ViewUpAlongZ = Vector4{Float64, CameraViewSpace}(0f0,  0f0,  1f0, 0f0)

lookat_tests = [
    LookAtTestCase([(0.0, 0.5)], -ViewDirectionAlongY, -ViewUpAlongZ),
]

for testcase in lookat_tests
    @testset "Lookat: $(testcase.positions); Result direction is $(testcase.direction) and up is $(testcase.up)" begin
        # Arrange
        cameraview = CameraView{Float64, S}()
        initialdirection = Vector4{Float64, S}(direction(cameraview))
        initialup = Vector4{Float64, S}(up(cameraview))

        # Act
        for dragposition in testcase.positions
            cameraview = onmousedrag(cameraview, MouseDragStartEvent())
            cameraview = onmousedrag(cameraview, MouseDragPositionEvent(dragposition))
            cameraview = onmousedrag(cameraview, MouseDragEndEvent())
        end

        m = lookat(cameraview)
        resultdirection = m * initialdirection
        resultup = m * initialup

        # Assert
        @test resultdirection ≈ testcase.direction
        @test resultup ≈ testcase.up
    end
end

#
# Regression tests
#

    #MouseDragDirectionTestCase([(0.0, 0.5)], DirectionAlongYPositive, UpAlongZPositive),
@testset "Drag; CameraView{Float32, S} drag with Float64 Input; Expected values" begin
    # Arrange
    cameraview = CameraView{Float32, S}()

    # Act
    cameraview = onmousedrag(cameraview, MouseDragStartEvent())
    cameraview = onmousedrag(cameraview, MouseDragPositionEvent((0.0, 0.5)))
    cameraview = onmousedrag(cameraview, MouseDragEndEvent())

    # Assert
    @test direction(cameraview) ≈ Vector3{Float32, S}(0f0, 1f0, 0f0)
end

end