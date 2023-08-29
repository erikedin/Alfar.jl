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

module XYZMarkerObject

using ModernGL

using Alfar.Visualizer
using Alfar.Rendering.Shaders
using Alfar.Rendering.Meshs
using Alfar.Rendering.Cameras
using Alfar.Rendering.CameraViews

export XYZMarker

struct XYZMarker
    program::ShaderProgram
    lines::VertexArray{GL_LINES}

    function XYZMarker()
        program = ShaderProgram("shaders/visualization/vertex3dcolorlines.glsl", "shaders/visualization/fragmentcolorfromvertex.glsl")

        vertices = GLfloat[
            # X            # RED
            0f0, 0f0, 0f0, 1f0, 0f0, 0f0, 1f0,
            1f0, 0f0, 0f0, 1f0, 0f0, 0f0, 1f0,

            # Y            # GREEN
            0f0, 0f0, 0f0, 0f0, 1f0, 0f0, 1f0,
            0f0, 1f0, 0f0, 0f0, 1f0, 0f0, 1f0,

            # Z            # BLUE
            0f0, 0f0, 0f0, 0f0, 0f0, 1f0, 1f0,
            0f0, 0f0, 1f0, 0f0, 0f0, 1f0, 1f0,
        ]
        attribute = VertexAttribute(0, 3, GL_FLOAT, GL_FALSE, C_NULL)
        coloroffset = Ptr{Cvoid}(3 * sizeof(GLfloat))
        colorattribute = VertexAttribute(1, 4, GL_FLOAT, GL_FALSE, coloroffset)
        vertexdata = VertexData{GLfloat}(vertices, VertexAttribute[attribute, colorattribute])
        lines = VertexArray{GL_LINES}(vertexdata)

        new(program, lines)
    end
end

function render(marker::XYZMarker, camera::Camera, cameraview::CameraView)
    use(marker.program)

    projection = perspective(camera)
    model = objectmodel()
    view = CameraViews.lookat(cameraview)

    uniform(marker.program, "projection", projection)
    uniform(marker.program, "view", view)
    uniform(marker.program, "model", model)

    renderarray(marker.lines)
end

end