# Copyright 2022 Erik Edin
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

module ShowTextures

using ModernGL
using GLFW

using Alfar.Visualizer
using Alfar.Rendering.Cameras
using Alfar.Rendering.CameraViews
using Alfar.Rendering: World, Object, View
using Alfar.Rendering.Shaders
using Alfar.Rendering.Meshs
using Alfar.Math

struct TexturePolygon
    program::ShaderProgram
    vertices::VertexArray{GL_TRIANGLES}

    function TexturePolygon()
        program = ShaderProgram("shaders/visualization/vs_box.glsl",
                                "shaders/visualization/uniformcolorfragment.glsl")

        indexes = GLint[
            0, 3, 6,
            0, 6, 2,
        ]

        attribute = VertexAttribute(0, 1, GL_INT, GL_FALSE, C_NULL)
        data = VertexData{GLint}(indexes, VertexAttribute[attribute])
        vertices = VertexArray{GL_TRIANGLES}(data)
        new(program, vertices)
    end
end

function rendertexture(t::TexturePolygon, camera::Camera, cameraview::CameraView{Float32, World})
    use(t.program)

    projection = perspective(camera)
    view = CameraViews.lookat(cameraview)
    model = identitytransform(View, Object)

    uniform(t.program, "projection", projection)
    uniform(t.program, "view", view)
    uniform(t.program, "model", model)

    uniform(t.program, "color", (1f0, 0f0, 0f0, 1f0))

    renderarray(t.vertices)
end

struct ShowTexture <: Visualizer.Visualization
    texturepolygon::TexturePolygon

    function ShowTexture()
        new(TexturePolygon())
    end
end

struct ShowTextureState <: Visualizer.VisualizationState
    cameraview::CameraView{Float32, World}
end

function Visualizer.setup(::ShowTexture)
    position = Vector3{Float32, World}(0f0, 0f0, 3f0)
    up = Vector3{Float32, World}(0f0, 1f0, 0f0)
    target = Vector3{Float32, World}(0f0, 0f0, 0f0)
    ShowTextureState(CameraView{Float32, World}(position, target, up))
end

function Visualizer.setflags(::ShowTexture)
    glEnable(GL_DEPTH_TEST)
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)
    glDisable(GL_CULL_FACE)
end

function Visualizer.update(::ShowTexture, state::ShowTextureState)
    state
end

function Visualizer.render(camera::Camera, st::ShowTexture, state::ShowTextureState)
    # Viewport 1 (left)
    glViewport(0, 0, camera.windowwidth, camera.windowheight)

    rendertexture(st.texturepolygon, camera, state.cameraview)
end

end