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

module Slicings

using ModernGL

using Alfar.Visualizer
using Alfar.Rendering.Cameras
using Alfar.Rendering.CameraViews
using Alfar.Rendering.Inputs
using Alfar.Rendering: World
using Alfar.Visualizer.Objects.Boxs
using Alfar.WIP.Math

struct Slicing <: Visualizer.Visualization
    box::Box

    function Slicing()
        new(Box())
    end
end

struct SlicingState <: Visualizer.VisualizationState
    numberofslices::Int
    cameraview::CameraView
end

function Visualizer.setflags(::Slicing)
    glEnable(GL_BLEND)
    glEnable(GL_DEPTH_TEST)
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)
    glDisable(GL_CULL_FACE)
end

function Visualizer.setup(::Slicing) :: SlicingState
    position = Vector3{Float32, World}(0f0, 0f0, 3f0)
    target = Vector3{Float32, World}(0f0, 0f0, 0f0)
    up = Vector3{Float32, World}(0f0, 1f0, 0f0)
    cameraview = CameraView{Float32, World}(position, target, up)
    SlicingState(5, cameraview)
end

function Visualizer.update(::Slicing, state::SlicingState) :: SlicingState
    state
end

function Visualizer.onmousedrag(::Slicing, state::SlicingState, ev::MouseDragStartEvent)
    newcameraview = onmousedrag(state.cameraview, ev)
    SlicingState(state.numberofslices, newcameraview)
end

function Visualizer.onmousedrag(::Slicing, state::SlicingState, ev::MouseDragEndEvent)
    newcameraview = onmousedrag(state.cameraview, ev)
    SlicingState(state.numberofslices, newcameraview)
end

function Visualizer.onmousedrag(::Slicing, state::SlicingState, ev::MouseDragPositionEvent)
    newcameraview = onmousedrag(state.cameraview, ev)
    SlicingState(state.numberofslices, newcameraview)
end

function Visualizer.render(camera::Camera, slicing::Slicing, state::SlicingState)
    # Viewport 1 (left)
    glViewport(0, 0, camera.windowwidth, camera.windowheight)

    Boxs.render(slicing.box, camera, state.cameraview)
end

end # module Slicings