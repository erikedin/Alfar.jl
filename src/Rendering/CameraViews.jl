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

export CameraView, direction, up, right, onmousedrag, lookat, CameraViewSpace
export cameraposition, rotatecamera

struct CameraViewSpace end

struct CameraView{T, System}
    position::Vector3{T, System}
    target::Vector3{T, System}
    up::Vector3{T, System}
    rotation::PointRotation{T, System}
    dragrotation::PointRotation{T, System}

    function CameraView{T, System}(
            position::Vector3{T, System},
            target::Vector3{T, System},
            up::Vector3{T, System},
            rotation::PointRotation{T, System},
            dragrotation::PointRotation{T, System}) where {T, System}
        new{T, System}(position, target, normalize(up), rotation, dragrotation)
    end

    function CameraView{T, System}() where {T, System}
        defaultposition = Vector3{T, System}(0, 0, 1.0)
        defaulttarget = Vector3{T, System}(0.0, 0.0, 0.0)
        up = Vector3{T, System}(0.0, 1.0, 0.0)
        norotation = PointRotation{T, System}(zero(T), Vector3{T, System}(one(T), zero(T), zero(T)))
        CameraView{T, System}(defaultposition, defaulttarget, up, norotation, norotation)
    end

    function CameraView{T, System}(position::Vector3{T, System}, target::Vector3{T, System}, up::Vector3{T, System}) where {T, System}
        norotation = PointRotation{T, System}(zero(T), Vector3{T, System}(one(T), zero(T), zero(T)))
        CameraView{T, System}(position, target, up, norotation, norotation)
    end

    function CameraView{T, System}(cameraview::CameraView{T, System}, rotation::PointRotation{T, System}) where {T, System}
        norotation = PointRotation{T, System}(zero(T), Vector3{T, System}(one(T), zero(T), zero(T)))
        CameraView{T, System}(cameraview.position, cameraview.target, cameraview.up, norotation, rotation)
    end
end

function right(cameraview::CameraView{T, System}) :: Vector3{T, System} where {T, System}
    cross(direction(cameraview), up(cameraview))
end

function direction(cameraview::CameraView{T, System}) :: Vector3{T, System} where {T, System}
    direction = normalize(cameraview.target - cameraview.position)
    transform(cameraview.dragrotation, direction)
end
function up(cameraview::CameraView{T, System}) :: Vector3{T, System} where {T, System}
    transform(cameraview.dragrotation, cameraview.up)
end

cameraposition(c::CameraView{T, System}) where {T, System} = transform(c.dragrotation, c.position)

function rotatecamera(cameraview::CameraView{T, System}, rotation::PointRotation{T, System}) :: CameraView{T, System} where {T, System}
    newposition = transform(rotation, cameraview.position)
    newup = transform(rotation, cameraview.up)
    norotation = PointRotation{T, System}(zero(T), Vector3{T, System}(one(T), zero(T), zero(T)))
    CameraView{T, System}(newposition, cameraview.target, newup, norotation, cameraview.dragrotation)
end

onmousedrag(v::CameraView{T, System}, ::MouseDragStartEvent) where {T, System} = v

function onmousedrag(cameraview::CameraView{T, System}, ev::MouseDragPositionEvent) :: CameraView where {T, System}
    # ev.direction[1] is a horizontal mouse drag. This corresponds to a rotation around the `up` vector.
    # Why is there a minus sign here?
    # When dragging using the mouse, we want it to look like we drag the model, so when we drag the mouse to the
    # right, we want the camera to actually move to the left, around the `up` axis. Dragging to the right is a
    # positive value in the mouse position event.
    # This is a counter-clockwise rotation, looking down the positive `up` axis.
    # In a right-handed coordinate system, which we use, quaternion rotations are positive angles in the _clockwise_
    # direction. So, the minus sign ensures that the angle is for clockwise rotations.
    upangle = convert(T, -ev.direction[1] * pi)
    # ev.direction[2] is a vertical mouse drag. This corresponds to a rotation around the `right` vector.
    # Why is there no minus sign here?
    # Dragging the mouse up is a positive value in the mouse position event. Since we want the camera to move
    # in the opposite way, it moves in a counter-clockwise direction around the `right` axis, looking down at the
    # positive right axis. So it already has the right sign, unlike the above angle.
    rightangle = convert(T, ev.direction[2] * pi)
    direction = normalize(cameraview.target - cameraview.position)
    rightaxis = cross(direction, cameraview.up)
    aroundright = PointRotation{T, System}(rightangle, rightaxis)
    aroundup = PointRotation{T, System}(upangle, cameraview.up)
    rotation = aroundup ∘ aroundright

    CameraView{T, System}(cameraview, rotation)
end

function onmousedrag(c::CameraView{T, System}, ::MouseDragEndEvent) :: CameraView{T, System} where {T, System}
    # Create a new camera view with position and up vectors transformed by the rotation operator.
    # This constructor sets the rotation operator to no rotation.
    # Essentially, this saves the drag transformation that the user has done with the mouse.
    CameraView{T, System}(cameraposition(c), c.target, up(c))
end

struct CameraTranslationSpace end

function lookat(c::CameraView{T, System}) :: Matrix4{T, CameraViewSpace, System} where {T, System}
    d = -direction(c)
    u = up(c)
    r = right(c)
    p = cameraposition(c)
    translation = Matrix4{T, CameraTranslationSpace, System}(
         one(T), zero(T), zero(T), -p.x,
        zero(T),  one(T), zero(T), -p.y,
        zero(T), zero(T),  one(T), -p.z,
        zero(T), zero(T), zero(T), one(T),
    )
    directiontransform = Matrix4{T, CameraViewSpace, CameraTranslationSpace}(
        r.x,     r.y,     r.z,     zero(T),
        u.x,     u.y,     u.z,     zero(T),
        d.x,     d.y,     d.z,     zero(T),
        zero(T), zero(T), zero(T),  one(T),
    )
    directiontransform * translation
end

end