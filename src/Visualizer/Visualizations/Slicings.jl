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

using Alfar.Visualizer
using Alfar.Rendering.Cameras

struct Slicing <: Visualizer.Visualization

end

struct SlicingState <: Visualizer.VisualizationState
    numberofslices::Int
end

function Visualizer.setflags(::Slicing)

end

function Visualizer.setup(::Slicing) :: SlicingState
    SlicingState(5)
end

function Visualizer.update(::Slicing, state::SlicingState) :: SlicingState
    state
end

function Visualizer.render(::Camera, ::Slicing, ::SlicingState)

end

end # module Slicings