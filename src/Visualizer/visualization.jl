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

abstract type Visualization end

use(viz::Visualization) = use(viz.program)

#
# Define the Visualization methods for `Nothing`, so that we don't have to
# handle that as a special case.
#

setflags(::Nothing) = nothing
setup(::Nothing) = nothing
render(::Nothing) = nothing

#
# Visualization: ViewportAnimated09
#

struct ViewportAnimated09 <: Visualization
    program::ShaderProgram

    function ViewportAnimated09()
        program = ShaderProgram("shaders/visualization/basic3dvertex.glsl", "shaders/visualization/fragment1dtransfer.glsl")
        new(program)
    end
end

function generatetexture(::ViewportAnimated09)
end

function setflags(::ViewportAnimated09)
    glEnable(GL_BLEND)
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)
    glEnable(GL_DEPTH_TEST)
    glEnable(GL_TEXTURE_1D)
end

function setup(::ViewportAnimated09)

end

function render(::ViewportAnimated09)

end
