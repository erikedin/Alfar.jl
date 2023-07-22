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

export CameraView, direction, onmousedrag

struct CameraView{T, System}
    direction::Vector3{T, System}

    CameraView(::Type{T}, ::Type{System}) where {T, System} = new{T, System}(Vector3{T, System}(0.0, 0.0, -1.0))
    CameraView(direction::Vector3{T, System}) where {T, System}= new{T, System}(direction)
end

direction(c::CameraView) = c.direction

onmousedrag(v::CameraView, ::MouseDragStartEvent) :: CameraView = v

function onmousedrag(cameraview::CameraView{T, System}, ev::MouseDragPositionEvent) :: CameraView where {T, System}
    aroundx = PointRotation{T, System}(Float64(pi), Vector3{T, System}(1.0, 0.0, 0.0))
    newdirection = transform(aroundx, cameraview.direction)
    CameraView(newdirection)
end

onmousedrag(v::CameraView, ::MouseDragEndEvent) :: CameraView = v

end