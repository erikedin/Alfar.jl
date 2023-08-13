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
    color::NTuple{4, Float32}

    function Box(color::NTuple{4, Float32} = (0f0, 0f0, 1f0, 1f0))
        program = ShaderProgram("shaders/visualization/vs_box.glsl",
                                "shaders/visualization/uniformcolorfragment.glsl")

        boxvertices = GLint[
            0, 1,
            1, 4,
            4, 7,
            1, 5,
            0, 2,
            2, 5,
            5, 7,
            2, 6,
            0, 3,
            3, 6,
            6, 7,
            3, 4,
        ]

        indexattribute = VertexAttribute(0, 1, GL_INT, GL_FALSE, C_NULL)
        indexdata = VertexData{GLint}(boxvertices, VertexAttribute[indexattribute])

        boxwireframe = VertexArray{GL_LINES}(indexdata)

        new(program, boxwireframe, color)
    end
end

function render(box::Box, camera::Camera, cameraview::CameraView)
    use(box.program)

    projection = perspective(camera)
    model = identitytransform()
    view = CameraViews.lookat(cameraview)

    uniform(box.program, "projection", projection)
    uniform(box.program, "view", view)
    uniform(box.program, "model", model)
    uniform(box.program, "color", box.color)

    renderarray(box.boxwireframe)
end


end # module