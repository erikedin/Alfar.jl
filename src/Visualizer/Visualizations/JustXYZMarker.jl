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
using Alfar.Visualizer: MouseDragEndEvent, MouseDragPositionEvent
using Alfar.Rendering.Cameras

struct JustXYZMarkerState <: Visualizer.VisualizationState end

struct JustXYZMarker <: Visualizer.Visualization

end

function Visualizer.setflags(::JustXYZMarker)
    glEnable(GL_BLEND)
    glEnable(GL_DEPTH_TEST)
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)
end

Visualizer.setup(::JustXYZMarker) = JustXYZMarkerState()
Visualizer.update(::JustXYZMarker, state::JustXYZMarkerState) = state

function Visualizer.render(::Camera, ::JustXYZMarker, ::JustXYZMarkerState)
end

#onkeyboardinput(::Visualization, state::VisualizationState, ::KeyboardInputEvent) = state
#onmousescroll(::Visualization, state::VisualizationState, ::Tuple{Float64, Float64}) = state
#onmousedrag(::Visualization, state::VisualizationState, ::MouseDragEvent) = state

end