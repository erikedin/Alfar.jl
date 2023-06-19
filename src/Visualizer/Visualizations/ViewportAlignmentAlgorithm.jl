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

module ViewportAlignmentAlgorithm

using Alfar.Visualizer
using Alfar.Rendering.Cameras
using Alfar.Rendering.Shaders

struct ViewportAlignment <: Visualizer.Visualization
    program::Union{Nothing, ShaderProgram}

    function ViewportAlignment()
        new(nothing)
    end
end

struct ViewportAlignmentState <: Visualizer.VisualizationState end

Visualizer.setflags(::ViewportAlignment) = nothing
Visualizer.setup(::ViewportAlignment) = ViewportAlignmentState()
Visualizer.update(::ViewportAlignment, ::ViewportAlignmentState) = ViewportAlignmentState()
Visualizer.render(::Camera, ::ViewportAlignment, ::ViewportAlignmentState) = nothing

end