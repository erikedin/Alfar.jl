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

using Alfar.Rendering.Cameras
using Alfar.Rendering.CameraViews
using Alfar.Rendering.Inputs
using Alfar.Rendering.Textures
using Alfar.Rendering: World, View, Object
using Alfar.Visualizer

struct Show3DTexture <: Visualizer.Visualization

end

struct Show3DTextureState <: Visualizer.VisualizationState
    textureid::Union{Nothing, GLuint}
    transfertextureid::Union{Nothing, GLuint}
    cameraview::CameraView{Float32, World}
end

function Visualizer.setflags(::Show3DTexture)
    glEnable(GL_DEPTH_TEST)
    glEnable(GL_BLEND)
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)
end

function Visualizer.setup(::Show3DTexture)
    cameraview = CameraView{Float32, World}()
    Show3DTextureState(nothing, nothing, cameraview)
end

function Visualizer.update(::Show3DTexture, state::Show3DTextureState)
    state
end

function Visualizer.render(camera::Camera, st::Show3DTexture, state::Show3DTextureState)

end

function Visualizer.onkeyboardinput(::Show3DTexture, state::Show3DTextureState, ev::KeyboardInputEvent) :: Show3DTextureState
    state
end

function Visualizer.onmousedrag(::Show3DTexture, state::Show3DTextureState, ev::MouseDragEvent) :: Show3DTextureState
    state
end


struct New3DTexture <: Visualizer.UserDefinedEvent
    input::IntensityTextureInput{3, UInt16}
end

function Visualizer.onevent(::Show3DTexture, state::Show3DTextureState, ev::New3DTexture)
    texture = IntensityTexture{3, UInt16}(input)
    Show3DTextureState(texture.id, state.transfertextureid, state.cameraview)
end

module Exports

end # module Exports

end # module Show3DTextures