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

module Cameras

using ModernGL

using Alfar.WIP.Math
using Alfar.Rendering: World, View

export Camera
export identitytransform, perspective

struct Camera
    fov::Float32
    windowwidth::Int
    windowheight::Int
    near::Float32
    far::Float32
end

function Camera(width, height) :: Camera
    fov = 0.25f0*pi
    near = 0.1f0
    far = 100.0f0
    Camera(
        fov,
        width,
        height,
        near,
        far
    )
end

function identitytransform(::Type{ToSystem}, ::Type{FromSystem}) :: Matrix4{GLfloat, ToSystem, FromSystem} where {ToSystem, FromSystem}
    Matrix4{GLfloat, ToSystem, FromSystem}(
        1f0, 0f0, 0f0, 0f0,
        0f0, 1f0, 0f0, 0f0,
        0f0, 0f0, 1f0, 0f0,
        0f0, 0f0, 0f0, 1f0,
    )
end

function perspective(camera::Camera) :: Matrix4{GLfloat, World, View}
    tanhalf = tan(camera.fov/2f0)
    aspect = Float32(camera.windowwidth) / Float32(camera.windowheight)
    far = camera.far
    near = camera.near

    Matrix4{GLfloat, World, View}(
        1f0/(aspect*tanhalf), 0f0,           0f0,                          0f0,
        0f0,                  1f0/(tanhalf), 0f0,                          0f0,
        0f0,                  0f0,           -(far + near) / (far - near), -2f0*far*near / (far - near),
        0.0f0,                0f0,           -1f0,                         0f0,
    )
end

end