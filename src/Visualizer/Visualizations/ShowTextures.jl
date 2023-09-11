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

using Alfar
using Alfar.Visualizer
using Alfar.Rendering.Cameras
using Alfar.Rendering.CameraViews
using Alfar.Rendering: World, Object, View
using Alfar.Rendering.Shaders
using Alfar.Rendering.Textures
using Alfar.Rendering.Meshs
using Alfar.Math

struct Box2D
    program::ShaderProgram
    vertices::VertexArray{GL_LINE_LOOP}

    function Box2D()
        vshader = pkgdir(Alfar, "shaders", "visualization", "vs_box_2d_texture.glsl")
        fragmentshader = pkgdir(Alfar, "shaders", "visualization", "uniformcolorfragment.glsl")
        program = ShaderProgram(vshader, fragmentshader)

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

function maketransfertexture()
    dim = TextureDimension{1}(256)
    data = UInt8[ ]
    for i=1:256
        push!(data, 0)
        push!(data, 0)
        push!(data, 255)
        push!(data, i-1)
    end
    Texture{1, UInt8, GL_TEXTURE1, InternalRGBA{UInt8}, InputRGBA{UInt8}}(
        dim, data
    )
end

struct TexturePolygon
    program::ShaderProgram
    vertices::VertexArray{GL_TRIANGLES}
    box::Box2D
    transfertextureid::GLuint

    function TexturePolygon()
        vshader = pkgdir(Alfar, "shaders", "visualization", "vs_box_2d_texture.glsl")
        fragmentshader = pkgdir(Alfar, "shaders", "visualization", "fragment_transfer_2d_1d.glsl")
        program = ShaderProgram(vshader, fragmentshader)

        indexes = GLint[
            0, 2, 3,
            0, 1, 3,
        ]

        attribute = VertexAttribute(0, 1, GL_INT, GL_FALSE, C_NULL)
        data = VertexData{GLint}(indexes, VertexAttribute[attribute])
        vertices = VertexArray{GL_TRIANGLES}(data)

        box = Box2D()
        transfertexture = maketransfertexture()

        new(program, vertices, box, transfertexture.id)
    end
end

function rendertexture(t::TexturePolygon, camera::Camera, cameraview::CameraView{Float32, World}, ::Nothing)
    render(t.box, camera, cameraview)
end

function rendertexture(t::TexturePolygon, camera::Camera, cameraview::CameraView{Float32, World}, textureid::GLuint)
    render(t.box, camera, cameraview)

    use(t.program)

    glBindTexture(GL_TEXTURE_2D, textureid)
    glBindTexture(GL_TEXTURE_1D, t.transfertextureid)

    projection = perspective(camera)
    view = CameraViews.lookat(cameraview)
    model = identitytransform(View, Object)

    uniform(t.program, "projection", projection)
    uniform(t.program, "view", view)
    uniform(t.program, "model", model)

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
    glEnable(GL_BLEND)
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

struct NewTexture{T} <: Visualizer.UserDefinedEvent
    texture::T
end

function Visualizer.onevent(::ShowTexture, state::ShowTextureState, newtexture::NewTexture{T}) :: ShowTextureState where {T}
    texture = IntensityTexture{2, UInt16}(newtexture.texture)
    ShowTextureState(state.cameraview, texture.id)
end

struct Load2DTexture <: Visualizer.UserDefinedEvent
    load::Function
    args
end

function Visualizer.onevent(::ShowTexture, state::ShowTextureState, ev::Load2DTexture) :: ShowTextureState
    println("Load 2D texture...")
    texture = ev.load(ev.args...)
    ShowTextureState(state.cameraview, texture.id)
end

module Exports

using Alfar.Math
using ..ShowTextures: NewTexture, Load2DTexture


end # Exports

end # module ShowTextures