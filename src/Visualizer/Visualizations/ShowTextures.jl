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

struct Box2D
    program::ShaderProgram
    vertices::VertexArray{GL_LINE_LOOP}

    function Box2D()
        program = ShaderProgram("shaders/visualization/vs_box_2d_texture.glsl",
                                "shaders/visualization/uniformcolorfragment.glsl")

        indexes = GLint[
            0, 2, 3, 1,
        ]

        attribute = VertexAttribute(0, 1, GL_INT, GL_FALSE, C_NULL)
        data = VertexData{GLint}(indexes, VertexAttribute[attribute])
        vertices = VertexArray{GL_LINE_LOOP}(data)

        new(program, vertices)
    end
end

function render(box::Box2D, camera::Camera, cameraview::CameraView)
    use(box.program)

    projection = perspective(camera)
    view = CameraViews.lookat(cameraview)
    model = identitytransform(View, Object)

    uniform(box.program, "projection", projection)
    uniform(box.program, "view", view)
    uniform(box.program, "model", model)

    uniform(box.program, "color", (1f0, 0f0, 0f0, 1f0))

    renderarray(box.vertices)
end

struct TexturePolygon
    program::ShaderProgram
    vertices::VertexArray{GL_TRIANGLES}
    box::Box2D

    function TexturePolygon()
        program = ShaderProgram("shaders/visualization/vs_box_2d_texture.glsl",
                                "shaders/visualization/uniformcolorfragment.glsl")

        indexes = GLint[
            0, 2, 3,
            0, 1, 3,
        ]

        attribute = VertexAttribute(0, 1, GL_INT, GL_FALSE, C_NULL)
        data = VertexData{GLint}(indexes, VertexAttribute[attribute])
        vertices = VertexArray{GL_TRIANGLES}(data)

        box = Box2D()
        new(program, vertices, box)
    end
end

function rendertexture(t::TexturePolygon, camera::Camera, cameraview::CameraView{Float32, World}, ::Nothing)
    render(t.box, camera, cameraview)
end

function rendertexture(t::TexturePolygon, camera::Camera, cameraview::CameraView{Float32, World}, textureid::GLuint)
    render(t.box, camera, cameraview)

    use(t.program)

    projection = perspective(camera)
    view = CameraViews.lookat(cameraview)
    model = identitytransform(View, Object)

    uniform(t.program, "projection", projection)
    uniform(t.program, "view", view)
    uniform(t.program, "model", model)

    uniform(t.program, "color", (0f0, 1f0, 0f0, 0.5f0))

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
    textureid::Union{Nothing, GLuint}
end

function Visualizer.setup(::ShowTexture)
    position = Vector3{Float32, World}(0f0, 0f0, 3f0)
    up = Vector3{Float32, World}(0f0, 1f0, 0f0)
    target = Vector3{Float32, World}(0f0, 0f0, 0f0)
    ShowTextureState(CameraView{Float32, World}(position, target, up), nothing)
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

    rendertexture(st.texturepolygon, camera, state.cameraview, state.textureid)
end

struct TextureSize2D
    width::Int
    height::Int
end

struct TextureData2D{T} <: Visualizer.UserDefinedEvent
    size::TextureSize2D
    data::Vector{T}
end

function make2dtexture(texturedata::TextureData2D{Float32})
    glActiveTexture(GL_TEXTURE0)

    textureRef = Ref{GLuint}()
    glGenTextures(1, textureRef)
    textureid = textureRef[]

    glBindTexture(GL_TEXTURE_2D, textureid)

    glTexImage2D(GL_TEXTURE_2D,
                 0,
                 GL_RED,
                 texturedata.size.width,
                 texturedata.size.height,
                 0,
                 GL_RED,
                 GL_FLOAT,
                 texturedata.data)
    glGenerateMipmap(GL_TEXTURE_2D)

    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE)
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE)

    textureid
end

function Visualizer.onevent(::ShowTexture, state::ShowTextureState, texturedata::TextureData2D{Float32}) :: ShowTextureState
    textureid = make2dtexture(texturedata)
    println("New texture id: $(textureid)")
    ShowTextureState(state.cameraview, textureid)
end

module Exports

using Alfar.Math
using ..ShowTextures: TextureData2D, TextureSize2D

export semitransparent

function semitransparent() :: TextureData2D
    size = TextureSize2D(16, 16)
    data = repeat(Float32[0.5f0], 16*16)
    TextureData2D(size, data)
end

end # Exports

end # module ShowTextures