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

module Show3DTextures

using GLFW
using ModernGL

using Alfar.Math
using Alfar.Rendering.Cameras
using Alfar.Rendering.CameraViews
using Alfar.Rendering.Inputs
using Alfar.Rendering.Textures
using Alfar.Rendering: World, View, Object
using Alfar.Visualizer
using Alfar.Visualizer.Objects.ViewportAlignedSlicings
using Alfar.Visualizer.Objects.Boxs

#
#
#

function maketransfertexture() :: Texture{1, UInt16, GL_TEXTURE1, InternalRGBA{UInt16}, InputRGBA{UInt16}}
    dim = TextureDimension{1}(65536)
    data = UInt16[]
    for i = 1:width(dim)
        append!(data, UInt16[UInt16(65535), UInt16(0), UInt16(0), UInt16(i-1)])
    end
    Texture{1, UInt16, GL_TEXTURE1, InternalRGBA{UInt16}, InputRGBA{UInt16}}(dim, data)
end

function makesmalltransfertexture() :: Texture{1, UInt8, GL_TEXTURE1, InternalRGBA{UInt8}, InputRGBA{UInt8}}
    dim = TextureDimension{1}(256)
    data = UInt8[]
    for i = 1:width(dim)
        append!(data, UInt8[UInt8(255), UInt8(0), UInt8(0), UInt8(i-1)])
    end
    Texture{1, UInt8, GL_TEXTURE1, InternalRGBA{UInt8}, InputRGBA{UInt8}}(dim, data)
end

struct Show3DTexture <: Visualizer.Visualization
    box::Box

    Show3DTexture() = new(Box())
end

struct Show3DTextureState <: Visualizer.VisualizationState
    texture::Union{Nothing, IntensityTexture{3, UInt16}}
    #transfertexture::Union{Nothing, Texture{1, UInt16, GL_TEXTURE1, InternalRGBA{UInt16}, InputRGBA{UInt16}}}
    transfertexture::Union{Nothing, Texture{1, UInt8, GL_TEXTURE1, InternalRGBA{UInt8}, InputRGBA{UInt8}}}
    cameraview::CameraView{Float32, World}
    numberofslices::Int
    referencesamplingrate::Float32
end

function Visualizer.setflags(::Show3DTexture)
    glEnable(GL_DEPTH_TEST)
    glEnable(GL_BLEND)
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)
    glDisable(GL_CULL_FACE)
end

function Visualizer.setup(::Show3DTexture)
    position = Vector3{Float32, World}(0f0, 0f0, 3f0)
    target = Vector3{Float32, World}(0f0, 0f0, 0f0)
    up = Vector3{Float32, World}(0f0, 1f0, 0f0)
    cameraview = CameraView{Float32, World}(position, target, up)

    initialnumberofslices = 500
    referencesamplingrate = 5 # TODO: Hard coded according to CThead in the Stanford Volume Data Archive
    transfertexture = makesmalltransfertexture()
    Show3DTextureState(nothing, transfertexture, cameraview, initialnumberofslices, referencesamplingrate)
end

function Visualizer.update(::Show3DTexture, state::Show3DTextureState)
    state
end

function Visualizer.render(camera::Camera, st::Show3DTexture, state::Show3DTextureState)
    glViewport(0, 0, camera.windowwidth, camera.windowheight)

    # TODO: make methods for nothing
    if state.texture !== nothing && state.transfertexture !== nothing
        # TODO: We can't recreate ViewportAlignedSlicing in every frame.
        slicetransfer = SliceTransfer(state.texture.id, state.transfertexture.id, state.referencesamplingrate)
        viewportalignedslicing = ViewportAlignedSlicing(slicetransfer)
        render(viewportalignedslicing,
            camera,
            state.cameraview,
            state.cameraview,
            state.numberofslices)
    end

end

function Visualizer.onkeyboardinput(::Show3DTexture, state::Show3DTextureState, ev::KeyboardInputEvent) :: Show3DTextureState
    state
end

function Visualizer.onmousedrag(::Show3DTexture, state::Show3DTextureState, ev::MouseDragEvent) :: Show3DTextureState
    newcameraview = CameraViews.onmousedrag(state.cameraview, ev)
    Show3DTextureState(state.texture, state.transfertexture, newcameraview, state.numberofslices, state.referencesamplingrate)
end


struct New3DTexture <: Visualizer.UserDefinedEvent
    input::IntensityTextureInput{3, UInt16}
end

struct Load3DTexture <: Visualizer.UserDefinedEvent
    load::Function
    args
end

function Visualizer.onevent(::Show3DTexture, state::Show3DTextureState, ev::New3DTexture) :: Show3DTextureState
    println("New 3D texture: $(ev.input.dimension)")
    println("New 3D texture: Data size = $(length(ev.input.data))")
    texture = IntensityTexture{3, UInt16}(ev.input)
    Show3DTextureState(texture, state.transfertexture, state.cameraview, state.numberofslices, state.referencesamplingrate)
end

function Visualizer.onevent(::Show3DTexture, state::Show3DTextureState, ev::Load3DTexture) :: Show3DTextureState
    println("Load 3D texture...")
    textureinput = ev.load(ev.args...)
    texture = IntensityTexture{3, UInt16}(textureinput)
    Show3DTextureState(texture, state.transfertexture, state.cameraview, state.numberofslices, state.referencesamplingrate)
end

module Exports

end # module Exports

end # module Show3DTextures