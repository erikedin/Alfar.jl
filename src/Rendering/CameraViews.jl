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
using Alfar.Rendering: World
using Alfar.Rendering.Inputs

export CameraView, direction, onmousedrag

struct CameraView
    direction::Vector4{Float32, World}

    CameraView() = new(Vector4{Float32, World}(0f0, 0f0, -1f0, 0f0))
    CameraView(direction::Vector4{Float32, World}) = new(direction)
end

direction(c::CameraView) = c.direction

onmousedrag(v::CameraView, ::MouseDragStartEvent) :: CameraView = v
onmousedrag(v::CameraView, ::MouseDragPositionEvent) :: CameraView = CameraView(Vector4{Float32, World}(0f0, 0f0, 1f0, 0f0))
onmousedrag(v::CameraView, ::MouseDragEndEvent) :: CameraView = v

end