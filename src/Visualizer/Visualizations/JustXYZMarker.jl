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

module JustXYZMarkers

using ModernGL

using Alfar.Visualizer
import Alfar.Visualizer: onmousedrag
using Alfar.Visualizer: MouseDragEndEvent, MouseDragPositionEvent
using Alfar.Visualizer.Objects.XYZMarkerObject
using Alfar.Visualizer.Inputs
using Alfar.Rendering: World
using Alfar.Rendering.Cameras
using Alfar.Rendering.CameraViews
using Alfar.Math

struct JustXYZMarkerState <: Visualizer.VisualizationState
    cameraview::CameraView{Float32, World}
end

struct JustXYZMarker <: Visualizer.Visualization
    marker::XYZMarker

    JustXYZMarker() = new(XYZMarker())
end

function Visualizer.setflags(::JustXYZMarker)
    glEnable(GL_BLEND)
    glEnable(GL_DEPTH_TEST)
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)
end

function Visualizer.setup(::JustXYZMarker)
    position = Vector3{Float32, World}(0f0, 0f0, 3f0)
    target = Vector3{Float32, World}(0f0, 0f0, 0f0)
    up = Vector3{Float32, World}(0f0, 1f0, 0f0)
    cameraview = CameraView{Float32, World}(position, target, up)
    JustXYZMarkerState(cameraview)
end

Visualizer.update(::JustXYZMarker, state::JustXYZMarkerState) = state

function Visualizer.render(camera::Camera, j::JustXYZMarker, state::JustXYZMarkerState)
    #
    # Viewport 1 (left)
    #
    glViewport(0, 0, camera.windowwidth, camera.windowheight)

    XYZMarkerObject.render(j.marker, camera, state.cameraview)

    #
    # Viewport 2 (right)
    #

    # Leaving viewport 2 empty.
end

#onkeyboardinput(::Visualization, state::VisualizationState, ::KeyboardInputEvent) = state
#onmousescroll(::Visualization, state::VisualizationState, ::Tuple{Float64, Float64}) = state

function onmousedrag(::JustXYZMarker, state::JustXYZMarkerState, ev::MouseDragStartEvent)
    println("Drag: Start event")
    newcameraview = CameraViews.onmousedrag(state.cameraview, ev)
    JustXYZMarkerState(newcameraview)
end

function onmousedrag(::JustXYZMarker, state::JustXYZMarkerState, ev::MouseDragPositionEvent)
    println("Drag: Position $(ev)")
    newcameraview = CameraViews.onmousedrag(state.cameraview, ev)
    JustXYZMarkerState(newcameraview)
end

function onmousedrag(::JustXYZMarker, state::JustXYZMarkerState, ev::MouseDragEndEvent)
    println("Drag: End event")
    newcameraview = CameraViews.onmousedrag(state.cameraview, ev)
    JustXYZMarkerState(newcameraview)
end

end