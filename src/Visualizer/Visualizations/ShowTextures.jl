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

struct ShowTexture <: Visualizer.Visualization

end

struct ShowTextureState <: Visualizer.VisualizationState
    cameraview::CameraView{Float32, World}
end

function Visualizer.setup(::ShowTexture)
    ShowTextureState(CameraView{Float32, World}())
end

function Visualizer.setflags(::ShowTexture)

end

function Visualizer.update(::ShowTexture, state::ShowTextureState)
    state
end

function Visualizer.render(camera::Camera, st::ShowTexture, state::ShowTextureState)
    # Viewport 1 (left)
    glViewport(0, 0, camera.windowwidth, camera.windowheight)

end

end