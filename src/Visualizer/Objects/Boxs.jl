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

module Boxs

using ModernGL

using Alfar.Rendering.CameraViews
using Alfar.Rendering.Cameras
using Alfar.Rendering.Meshs
using Alfar.Rendering.Shaders

export Box

struct Box
    program::ShaderProgram
    boxwireframe::VertexArray{GL_LINES}

    function Box()
        program = ShaderProgram("shaders/visualization/vs_box.glsl",
                                "shaders/visualization/fragmentcolorfromvertex.glsl")

        # These vertex indices define all edges that are drawn, that
        # make up the box. Depending on which the front vertex is, the
        # edges will have different colors though. Instead of defining
        # that here, a translation is done in the vertex shader.
        boxvertices = GLint[
            0, 1, # RED path 1
            1, 4, # RED path 2
            4, 7, # RED path 3
            1, 5, # Dashed RED path
            0, 2, # GREEN path 1
            2, 5, # GREEN path 2
            5, 7, # GREEN path 3
            2, 6, # Dashed GREEN path
            0, 3, # BLUE path 1
            3, 6, # BLUE path 2
            6, 7, # BLUE path 3
            3, 4, # Dash BLUE path
        ]
        linecolors = GLfloat[
            1f0, 0f0, 0f0, 1f0, # RED
            1f0, 0f0, 0f0, 1f0, # RED
            1f0, 0f0, 0f0, 1f0, # RED
            1f0, 0f0, 0f0, 1f0, # RED
            1f0, 0f0, 0f0, 1f0, # RED
            1f0, 0f0, 0f0, 1f0, # RED
            0.5f0, 0f0, 0f0, 1f0, # RED, darker
            0.5f0, 0f0, 0f0, 1f0, # RED, darker
            0f0, 1f0, 0f0, 1f0, # GREEN
            0f0, 1f0, 0f0, 1f0, # GREEN
            0f0, 1f0, 0f0, 1f0, # GREEN
            0f0, 1f0, 0f0, 1f0, # GREEN
            0f0, 1f0, 0f0, 1f0, # GREEN
            0f0, 1f0, 0f0, 1f0, # GREEN
            0f0, 0.5f0, 0f0, 1f0, # GREEN, darker
            0f0, 0.5f0, 0f0, 1f0, # GREEN, darker
            0f0, 0f0, 1f0, 1f0, # BLUE
            0f0, 0f0, 1f0, 1f0, # BLUE
            0f0, 0f0, 1f0, 1f0, # BLUE
            0f0, 0f0, 1f0, 1f0, # BLUE
            0f0, 0f0, 1f0, 1f0, # BLUE
            0f0, 0f0, 1f0, 1f0, # BLUE
            0f0, 0f0, 0.5f0, 1f0, # BLUE, darker
            0f0, 0f0, 0.5f0, 1f0, # BLUE, darker
        ]

        indexattribute = VertexAttribute(0, 1, GL_INT, GL_FALSE, C_NULL)
        indexdata = VertexData{GLint}(boxvertices, VertexAttribute[indexattribute])

        colorattribute = VertexAttribute(1, 4, GL_FLOAT, GL_FALSE, C_NULL)
        colordata = VertexData{GLfloat}(linecolors, VertexAttribute[colorattribute])

        boxwireframe = VertexArray{GL_LINES}(indexdata, colordata)

        new(program, boxwireframe)
    end
end

function render(box::Box, camera::Camera, cameraview::CameraView, frontvertexindex::Int)
    use(box.program)

    projection = perspective(camera)
    model = identitytransform()
    view = CameraViews.lookat(cameraview)

    uniform(box.program, "projection", projection)
    uniform(box.program, "view", view)
    uniform(box.program, "model", model)
    # frontvertexindex is 1-indexed, because it's from Julia code, but should be
    # zero-indexed in the vertex shader.
    uniform(box.program, "frontVertexIndex", frontvertexindex - 1)

    renderarray(box.boxwireframe)
end


end # module