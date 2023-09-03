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

using Alfar.Rendering.Cameras
using Alfar.Rendering.Inputs

export Visualization, VisualizationState, KeyboardInputEvent

abstract type Visualization end
abstract type VisualizationState end

#
# Abstract types for any events received from the Julia REPL.
#

abstract type VizEvent end
abstract type UserDefinedEvent <: VizEvent end

#
# Define the Visualization methods for `Nothing`, so that we don't have to
# handle that as a special case.
#

setflags(::Nothing) = nothing
setup(::Nothing) = nothing
update(::Nothing, ::Nothing) = nothing
render(camera::Camera, ::Nothing, ::Nothing) = nothing

#
# Define default input operations, that do nothing.
#

onkeyboardinput(::Visualization, state::VisualizationState, ::KeyboardInputEvent) = state
onmousescroll(::Visualization, state::VisualizationState, ::Tuple{Float64, Float64}) = state
onmousedrag(::Visualization, state::VisualizationState, ::MouseDragEvent) = state

#
# User defined events are sent from the Julia REPL to the specific visualization,
# currently in use.
# Default to just returning the state, so you can override only those events you need.
#

onevent(::Visualization, state::VisualizationState, ::UserDefinedEvent) = state

include("Objects/Objects.jl")

include("Visualizations/JustXYZMarker.jl")
include("Visualizations/ViewportAlignmentAlgorithm.jl")
include("Visualizations/ViewportAnimated09.jl")
include("Visualizations/Slicings.jl")
include("Visualizations/ShowTextures.jl")