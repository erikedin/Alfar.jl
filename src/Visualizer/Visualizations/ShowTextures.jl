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

struct TextureDefinition1D
    width::Int
    data
end

function fill1d!(data, from, to, color)
    for i = from:to
        data[1, i] = UInt8(color[1])
        data[2, i] = UInt8(color[2])
        data[3, i] = UInt8(color[3])
        data[4, i] = UInt8(color[4])
    end
end

function generatetexturetransferfunction() :: TextureDefinition1D
    # The transfer function that calculates colors from intensities
    # is moved here from the fragment shader. The fragment shader
    # can now be re-used for different transfer functions by
    # binding a different 1D texture.
    channels = 4
    width = 256

    flattransfer = zeros(UInt8, channels*width)
    transfer = reshape(flattransfer, (channels, width))

    # Back octant 1, transparent
    fill1d!(transfer, 1, 32,   (  0,   0,   0,   0))
    # Back octant 2
    fill1d!(transfer, 33, 64,  (255,   0, 255, 255))
    # Back octant 3
    fill1d!(transfer, 65, 96,  (  0, 255, 255, 255))
    # Back octant 4
    fill1d!(transfer, 97, 128, (127, 255, 212, 255))

    # Front octant 1
    fill1d!(transfer, 129, 160, (255, 255, 255,  64))
    # Front octant 2
    fill1d!(transfer, 161, 192, (255,   0,   0, 255))
    # Front octant 3
    fill1d!(transfer, 193, 224, (  0, 255,   0, 255))
    # Front octant 4
    fill1d!(transfer, 225, 249, (  0,   0, 255, 255))

    # Yellow bar
    fill1d!(transfer, 250, 256, (255, 255,   0, 255))

    TextureDefinition1D(width, flattransfer)
end

function maketransfertexture(texturedefinition::TextureDefinition1D)
    glActiveTexture(GL_TEXTURE1)

    textureRef = Ref{GLuint}()
    glGenTextures(1, textureRef)
    textureid = textureRef[]

    glBindTexture(GL_TEXTURE_1D, textureid)

    glTexImage1D(GL_TEXTURE_1D,
                 0,
                 GL_RGBA,
                 texturedefinition.width,
                 0,
                 GL_RGBA,
                 GL_UNSIGNED_INT,
                 texturedefinition.data)
    glGenerateMipmap(GL_TEXTURE_1D)


    bordercolor = GLfloat[1f0, 1f0, 0f0, 1f0]
    glTexParameterfv(GL_TEXTURE_1D, GL_TEXTURE_BORDER_COLOR, Ref(bordercolor, 1))
    glTexParameterf(GL_TEXTURE_1D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_BORDER)
    glTexParameterf(GL_TEXTURE_1D, GL_TEXTURE_MIN_FILTER, GL_NEAREST)

    textureid
end

struct transparencytransfer() :: GLuint
    maketransfertexture(generatetexturetransferfunction())
end

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
    transfertextureid::GLuint

    function TexturePolygon()
        program = ShaderProgram("shaders/visualization/vs_box_2d_texture.glsl",
                                "shaders/visualization/fragment_transfer_2d_1d.glsl")

        indexes = GLint[
            0, 2, 3,
            0, 1, 3,
        ]

        attribute = VertexAttribute(0, 1, GL_INT, GL_FALSE, C_NULL)
        data = VertexData{GLint}(indexes, VertexAttribute[attribute])
        vertices = VertexArray{GL_TRIANGLES}(data)

        box = Box2D()
        transfertextureid = transparencytransfer()

        new(program, vertices, box, transfertextureid)
    end
end

function rendertexture(t::TexturePolygon, camera::Camera, cameraview::CameraView{Float32, World}, ::Nothing)
    render(t.box, camera, cameraview)
end

function rendertexture(t::TexturePolygon, camera::Camera, cameraview::CameraView{Float32, World}, textureid::GLuint)
    render(t.box, camera, cameraview)

    use(t.program)

    glBindTexture(GL_TEXTURE_2D, textureid)
    glBindTexture(GL_TEXTURE_2D, t.transfertextureid)

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