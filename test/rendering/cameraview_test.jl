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
    expectedright::Vector3{Float64, S}
end

DirectionAlongX = Vector3{Float64, S}( 1f0,  0f0,  0f0)
DirectionAlongY = Vector3{Float64, S}( 0f0,  1f0,  0f0)
DirectionAlongZ = Vector3{Float64, S}( 0f0,  0f0,  1f0)

UpAlongX = Vector3{Float64, S}( 1f0,  0f0,  0f0)
UpAlongY = Vector3{Float64, S}( 0f0,  1f0,  0f0)
UpAlongZ = Vector3{Float64, S}( 0f0,  0f0,  1f0)

RightAlongX = Vector3{Float64, S}( 1f0,  0f0,  0f0)
RightAlongY = Vector3{Float64, S}( 0f0,  1f0,  0f0)
RightAlongZ = Vector3{Float64, S}( 0f0,  0f0,  1f0)

mousedragdirectiontestcases = [
    # All these test cases start off with the default direction -Z.

    # This block of test cases all rotate the camera at 90 degree angles,
    # always along the same axis. This means that the axis around which we rotate
    # doesn't change, and that is the simplest case.
    # Around the X axis, 90 degree turns
    MouseDragDirectionTestCase([(0.0, 0.5)], DirectionAlongY, UpAlongZ, RightAlongX),
    MouseDragDirectionTestCase([(0.0, -0.5)], -DirectionAlongY, -UpAlongZ, RightAlongX),
    MouseDragDirectionTestCase([(0.0, 0.5), (0.0, 0.5)], DirectionAlongZ, -UpAlongY, RightAlongX),
    MouseDragDirectionTestCase([(0.0, 0.5), (0.0, 0.5), (0.0, 0.5)], -DirectionAlongY, -UpAlongZ, RightAlongX),
    MouseDragDirectionTestCase([(0.0, 0.5), (0.0, 0.5), (0.0, 0.5), (0.0, 0.5)], -DirectionAlongZ, UpAlongY, RightAlongX),
    # Around the Y axis, 90 degrees
    MouseDragDirectionTestCase([(0.5, 0.0)], DirectionAlongX, UpAlongY, RightAlongZ),
    MouseDragDirectionTestCase([(0.5, 0.0), (0.5, 0.0)], DirectionAlongZ, UpAlongY, -RightAlongX),
    MouseDragDirectionTestCase([(0.5, 0.0), (0.5, 0.0), (0.5, 0.0)], -DirectionAlongX, UpAlongY, -RightAlongZ),
    MouseDragDirectionTestCase([(0.5, 0.0), (0.5, 0.0), (0.5, 0.0), (0.5, 0.0)], -DirectionAlongZ, UpAlongY, RightAlongX),

    # Here are some test cases for 180 degree turns.
    # Since the starting direction is -Z, any 180 degree turn will end up at +Z.
    # Drag the camera 180 degrees around the X axis
    MouseDragDirectionTestCase([(0.0, 1.0)], DirectionAlongZ, -UpAlongY, RightAlongX),
    MouseDragDirectionTestCase([(0.0, -1.0)], DirectionAlongZ, -UpAlongY, RightAlongX),
    # Drag the camera 180 degrees around the Y axis
    MouseDragDirectionTestCase([(1.0, 0.0)], DirectionAlongZ, UpAlongY, -RightAlongX),
    MouseDragDirectionTestCase([(-1.0, 0.0)], DirectionAlongZ, UpAlongY, -RightAlongX),

    # These test cases rotate both horizontally and vertically.
    # 1. Horizontal rotation 90 degrees (around the Y axis
    #    The `right` vector is now +Z.
    # 2. Vertical rotation 90 degrees, which is around the Z axis.
    # Result: Direction is in the +Y direction.
    MouseDragDirectionTestCase([(0.5, 0.0), (0.0, 0.5)], DirectionAlongY, -UpAlongX, RightAlongZ),
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
        @test right(cameraview) ≈ testcase.expectedright
    end
end

# Helper names fo the position test cases.
Position = Vector3{Float64, S}

# CameraViewPositionTestCase checks the position after a series of mouse drags.
# The CameraView starts at position (0, 0, 1).
# The initial direction is (0, 0, -1).
# The initial up is (0, 1, 0).
# The initial right is (1, 0, 0)
struct CameraViewPositionTestCase
    mousedrags::Vector{NTuple{2, Float64}}
    expectedposition::Vector3{Float64, S}
end

cameraview_position_testcases = [
    CameraViewPositionTestCase([], Position(0.0, 0.0, 1.0)),

    # Rotation around the Y axis, camera moves to the left, in a counterclockwise rotation.
    CameraViewPositionTestCase([(0.5, 0.0)], Position(-1.0, 0.0, 0.0)),
    CameraViewPositionTestCase([(0.5, 0.0), (0.5, 0.0)], Position(0.0, 0.0, -1.0)),
    CameraViewPositionTestCase([(0.5, 0.0), (0.5, 0.0), (0.5, 0.0)], Position(1.0, 0.0, 0.0)),
    CameraViewPositionTestCase([(0.5, 0.0), (0.5, 0.0), (0.5, 0.0), (0.5, 0.0)], Position(0.0, 0.0, 1.0)),

    # Rotation around the Y axis, camera moves to the right, in a clockwise rotation.
    CameraViewPositionTestCase([(-0.5, 0.0)], Position(1.0, 0.0, 0.0)),
    CameraViewPositionTestCase([(-0.5, 0.0), (-0.5, 0.0)], Position(0.0, 0.0, -1.0)),
    CameraViewPositionTestCase([(-0.5, 0.0), (-0.5, 0.0), (-0.5, 0.0)], Position(-1.0, 0.0, 0.0)),
    CameraViewPositionTestCase([(-0.5, 0.0), (-0.5, 0.0), (-0.5, 0.0), (-0.5, 0.0)], Position(0.0, 0.0, 1.0)),

    # Rotation around the X axis. Camera moves down, in a clockwise rotation.
    CameraViewPositionTestCase([(0.0, 0.5)], Position(0.0, -1.0, 0.0)),
    CameraViewPositionTestCase([(0.0, 0.5), (0.0, 0.5)], Position(0.0, 0.0, -1.0)),
    CameraViewPositionTestCase([(0.0, 0.5), (0.0, 0.5), (0.0, 0.5)], Position(0.0, 1.0, 0.0)),
    CameraViewPositionTestCase([(0.0, 0.5), (0.0, 0.5), (0.0, 0.5), (0.0, 0.5)], Position(0.0, 0.0, 1.0)),

    # Rotation around the X axis. Camera moves up, in a counterclockwise rotation.
    CameraViewPositionTestCase([(0.0, -0.5)], Position(0.0, 1.0, 0.0)),
    CameraViewPositionTestCase([(0.0, -0.5), (0.0, -0.5)], Position(0.0, 0.0, -1.0)),
    CameraViewPositionTestCase([(0.0, -0.5), (0.0, -0.5), (0.0, -0.5)], Position(0.0, -1.0, 0.0)),
    CameraViewPositionTestCase([(0.0, -0.5), (0.0, -0.5), (0.0, -0.5), (0.0, -0.5)], Position(0.0, 0.0, 1.0)),
]

for testcase in cameraview_position_testcases
    @testset "CameraView position: $(testcase.mousedrags): $(testcase.expectedposition)" begin
        # Arrange
        initialposition = Vector3{Float64, S}(0.0, 0.0, 1.0)
        initialdirection = Vector3{Float64, S}(0.0, 0.0, -1.0)
        initialup = Vector3{Float64, S}(0.0, 1.0, 0.0)
        cameraview = CameraView{Float64, S}()

        # Act
        for drag in testcase.mousedrags
            cameraview = onmousedrag(cameraview, MouseDragStartEvent())
            cameraview = onmousedrag(cameraview, MouseDragPositionEvent(drag))
            cameraview = onmousedrag(cameraview, MouseDragEndEvent())
        end

        # Assert
        @test cameraposition(cameraview) ≈ testcase.expectedposition
    end
end

# Tests for the CameraView position during mouse drags, but no mouse drag end event.
# This means that the latest position event is the one that determines the camera view position.
# This is actually the most realistic test case, as lots of position events are sent
# for every mouse drag, as the cursor moves.
cameraview_position_noendevent_testcases = [
    # Rotation around the Y axis, camera moves to the left, in a counterclockwise rotation.
    CameraViewPositionTestCase([(0.5, 0.0)], Position(-1.0, 0.0, 0.0)),
    CameraViewPositionTestCase([(0.25, 0.0), (0.5, 0.0)], Position(-1.0, 0.0, 0.0)),
    CameraViewPositionTestCase([(0.25, 0.0), (0.25, 0.1), (0.5, 0.0)], Position(-1.0, 0.0, 0.0)),

    # Rotation around the X axis. Camera moves up, in a counterclockwise rotation.
    CameraViewPositionTestCase([(0.0, -0.5)], Position(0.0, 1.0, 0.0)),
    CameraViewPositionTestCase([(0.0, -0.25), (0.0, -0.5)], Position(0.0, 1.0, 0.0)),
    CameraViewPositionTestCase([(0.0, -0.25), (0.1, -0.25), (0.0, -0.5)], Position(0.0, 1.0, 0.0)),
]

for testcase in cameraview_position_noendevent_testcases
    @testset "CameraView position with no end event: $(testcase.mousedrags): $(testcase.expectedposition)" begin
        # Arrange
        initialposition = Vector3{Float64, S}(0.0, 0.0, 1.0)
        initialdirection = Vector3{Float64, S}(0.0, 0.0, -1.0)
        initialup = Vector3{Float64, S}(0.0, 1.0, 0.0)
        cameraview = CameraView{Float64, S}()

        # Act
        cameraview = onmousedrag(cameraview, MouseDragStartEvent())
        for drag in testcase.mousedrags
            cameraview = onmousedrag(cameraview, MouseDragPositionEvent(drag))
        end

        # Assert
        @test cameraposition(cameraview) ≈ testcase.expectedposition
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

@testset "Right axis; Up is (0, 2, 0); Right axis is normalized" begin
    # Arrange
    position = Vector3{Float32, S}(0f0, 0f0, 3f0)
    target = Vector3{Float32, S}(0f0, 0f0, 0f0)
    up = Vector3{Float32, S}(0f0, 2f0, 0f0)
    cameraview = CameraView{Float32, S}(position, target, up)

    # Act
    r = right(cameraview)

    # Assert
    @test norm(r) ≈ 1
end

@testset "Direction; Position is (0, 0, 10) and target is (0, 0, 0); Direction axis is normalized" begin
    # Arrange
    position = Vector3{Float32, S}(0f0, 0f0, 10f0)
    target = Vector3{Float32, S}(0f0, 0f0, 0f0)
    up = Vector3{Float32, S}(0f0, 2f0, 0f0)
    cameraview = CameraView{Float32, S}(position, target, up)

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
    target = Vector3{Float32, S}(0f0, 0f0, 0f0)
    initialup = Vector3{Float32, S}(0f0, 2f0, 0f0)
    cameraview = CameraView{Float32, S}(initialposition, target, initialup)

    # Act
    u = up(cameraview)

    # Assert
    @test norm(u) ≈ 1
end

@testset "Target; Target is (0, 0, 0) and position (0, 0, 1); Direction is (0, 0, -1)" begin
    # Arrange
    position = Vector3{Float32, S}(0f0, 0f0, 1f0)
    target = Vector3{Float32, S}(0f0, 0f0, 0f0)
    up = Vector3{Float32, S}(0f0, 1f0, 0f0)
    cameraview = CameraView{Float32, S}(position, target, up)

    # Act
    d = direction(cameraview)

    # Assert
    @test d ≈ Vector3{Float32, S}(0f0, 0f0, -1f0)
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
    right::Vector4{Float64, CameraViewSpace}
end

ViewDirectionAlongX = Vector4{Float64, CameraViewSpace}(1f0,  0f0,  0f0, 0f0)
ViewDirectionAlongY = Vector4{Float64, CameraViewSpace}(0f0,  1f0,  0f0, 0f0)
ViewDirectionAlongZ = Vector4{Float64, CameraViewSpace}(0f0,  0f0,  1f0, 0f0)

ViewUpAlongX = Vector4{Float64, CameraViewSpace}(1f0,  0f0,  0f0, 0f0)
ViewUpAlongY = Vector4{Float64, CameraViewSpace}(0f0,  1f0,  0f0, 0f0)
ViewUpAlongZ = Vector4{Float64, CameraViewSpace}(0f0,  0f0,  1f0, 0f0)

ViewRightAlongX = Vector4{Float64, CameraViewSpace}(1f0,  0f0,  0f0, 0f0)
ViewRightAlongY = Vector4{Float64, CameraViewSpace}(0f0,  1f0,  0f0, 0f0)
ViewRightAlongZ = Vector4{Float64, CameraViewSpace}(0f0,  0f0,  1f0, 0f0)

lookat_tests = [
    # Rotate the model 90 degrees by dragging up.
    LookAtTestCase([(0.0, 0.5)], -ViewDirectionAlongY, -ViewUpAlongZ, ViewRightAlongX),
    # Rotate the model 90 degrees by dragging left.
    LookAtTestCase([(-0.5, 0.0)], ViewDirectionAlongX, ViewUpAlongY, ViewRightAlongZ),
]

for testcase in lookat_tests
    @testset "Lookat: $(testcase.positions); Result direction is $(testcase.direction) and up is $(testcase.up)" begin
        # Arrange
        cameraview = CameraView{Float64, S}()
        initialdirection = Vector4{Float64, S}(direction(cameraview))
        initialup = Vector4{Float64, S}(up(cameraview))
        initialright = Vector4{Float64, S}(right(cameraview))

        # Act
        for dragposition in testcase.positions
            cameraview = onmousedrag(cameraview, MouseDragStartEvent())
            cameraview = onmousedrag(cameraview, MouseDragPositionEvent(dragposition))
            cameraview = onmousedrag(cameraview, MouseDragEndEvent())
        end

        m = lookat(cameraview)
        resultdirection = m * initialdirection
        resultup = m * initialup
        resultright = m * initialright

        # Assert
        @test resultdirection ≈ testcase.direction
        @test resultup ≈ testcase.up
        @test resultright ≈ testcase.right
    end
end

#
# Transformation functionality
# Essentially just tests that we have a functioning method to transform a
# CameraView programmatically, instead of doing it via mouse drag.
#

@testset "Transform; Rotate default CameraView 90 degrees around Y; Direction is -X, right is -Z" begin
    # Arrange
    cameraview = CameraView{Float32, S}()
    rotation = PointRotation{Float32, S}(0.5f0 * pi, Vector3{Float32, S}(0f0, 1f0, 0f0))

    # Act
    newcameraview = rotatecamera(cameraview, rotation)

    # Assert
    @test direction(newcameraview) ≈ Vector3{Float32, S}(-1f0, 0f0, 0f0)
    @test right(newcameraview) ≈ Vector3{Float32, S}(0f0, 0f0, -1f0)
end

@testset "Transform; Rotate default CameraView -90 degrees around Y; Direction is X, right is Z" begin
    # Arrange
    cameraview = CameraView{Float32, S}()
    rotation = PointRotation{Float32, S}(-0.5f0 * pi, Vector3{Float32, S}(0f0, 1f0, 0f0))

    # Act
    newcameraview = rotatecamera(cameraview, rotation)

    # Assert
    @test direction(newcameraview) ≈ Vector3{Float32, S}(1f0, 0f0, 0f0)
    @test right(newcameraview) ≈ Vector3{Float32, S}(0f0, 0f0, 1f0)
end

@testset "Transform; Target is (1,1,1) and rotate default CameraView -90 degrees around Y; Target is still (1, 1, 1)" begin
    # Arrange
    initialposition = Vector3{Float32, S}(0f0, 0f0, 1f0)
    initialtarget = Vector3{Float32, S}(1f0, 1f0, 1f0)
    initialup = Vector3{Float32, S}(0f0, 1f0, 0f0)
    cameraview = CameraView{Float32, S}(initialposition, initialtarget, initialup)
    rotation = PointRotation{Float32, S}(-0.5f0 * pi, Vector3{Float32, S}(0f0, 1f0, 0f0))

    # Act
    newcameraview = rotatecamera(cameraview, rotation)

    # Assert
    @test newcameraview.target ≈ Vector3{Float32, S}(1f0, 1f0, 1f0)
end

# Rotating the camera by mouse drag and programmatically should probably not be done
# at the same time. However, it's good to have the behavior defined should it happen.
@testset "Transform; Transform during a mouse drag 45 degrees around X; Drag rotation is still 45 degrees around X" begin
    # Arrange
    initialposition = Vector3{Float32, S}(0f0, 0f0, 1f0)
    initialtarget = Vector3{Float32, S}(0f0, 0f0, 0f0)
    initialup = Vector3{Float32, S}(0f0, 1f0, 0f0)
    cameraview = CameraView{Float32, S}(initialposition, initialtarget, initialup)
    rotation = PointRotation{Float32, S}(-0.5f0 * pi, Vector3{Float32, S}(0f0, 1f0, 0f0))

    # Act
    newcameraview = onmousedrag(cameraview, MouseDragStartEvent())
    newcameraview = onmousedrag(newcameraview, MouseDragPositionEvent((0f0, 0.25f0)))
    # No MouseDragEndEvent because the mouse drag is ongoing
    # Now the rotation ought to be 45 degrees around the X axis.
    newcameraview = rotatecamera(newcameraview, rotation)

    # Assert
    expecteddragrotation = PointRotation{Float32, S}(0.25f0 * pi, Vector3{Float32, S}(1f0, 0f0, 0f0))
    @test newcameraview.dragrotation ≈ expecteddragrotation
end
#
# Regression tests
#

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