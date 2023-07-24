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

module CameraViews

using Alfar.WIP.Math
using Alfar.Rendering.Inputs
using Alfar.WIP.Transformations
using Alfar.WIP.Math

export CameraView, direction, up, onmousedrag

struct CameraView{T, System}
    direction::Vector3{T, System}
    up::Vector3{T, System}

    function CameraView(::Type{T}, ::Type{System}) where {T, System}
        direction = Vector3{T, System}(0.0, 0.0, -1.0)
        up = Vector3{T, System}(0.0, 1.0, 0.0)
        new{T, System}(direction, up)
    end
    CameraView(direction::Vector3{T, System}, up::Vector3{T, System}) where {T, System} = new{T, System}(direction, up)
end

function right(camera::CameraView{T, System}) :: Vector3{T, System} where {T, System}
    # TODO Ensure normalization
    cross(camera.direction, camera.up)
end

direction(c::CameraView) = c.direction
up(c::CameraView) = c.up

onmousedrag(v::CameraView, ::MouseDragStartEvent) :: CameraView = v

function onmousedrag(cameraview::CameraView{T, System}, ev::MouseDragPositionEvent) :: CameraView where {T, System}
    # ev.direction[1] is a horizontal mouse drag. This corresponds to a rotation around the `up` vector.
    # Why is there a minus sign here?
    # When dragging using the mouse, we want it to look like we drag the model, so when we drag the mouse to the
    # right, we want the camera to actually move to the left, around the `up` axis. Dragging to the right is a
    # positive value in the mouse position event.
    # This is a counter-clockwise rotation, looking down the positive `up` axis.
    # In a right-handed coordinate system, which we use, quaternion rotations are positive angles in the _clockwise_
    # direction. So, the minus sign ensures that the angle is for clockwise rotations.
    upangle = -ev.direction[1] * pi
    # ev.direction[2] is a vertical mouse drag. This corresponds to a rotation around the `right` vector.
    # Why is there no minus sign here?
    # Dragging the mouse up is a positive value in the mouse position event. Since we want the camera to move
    # in the opposite way, it moves in a counter-clockwise direction around the `right` axis, looking down at the
    # positive right axis. So it already has the right sign, unlike the above angle.
    rightangle = ev.direction[2] * pi
    # TODO Compose these rotations rather than do them consecutively.
    rightaxis = right(cameraview)
    aroundright = PointRotation{T, System}(rightangle, rightaxis)
    aroundup = PointRotation{T, System}(upangle, cameraview.up)
    newdirectionright = transform(aroundright, cameraview.direction)
    newdirection = transform(aroundup, newdirectionright)

    newupright = transform(aroundright, cameraview.up)
    newup = transform(aroundup, newupright)
    CameraView(newdirection, newup)
end

onmousedrag(v::CameraView, ::MouseDragEndEvent) :: CameraView = v

end