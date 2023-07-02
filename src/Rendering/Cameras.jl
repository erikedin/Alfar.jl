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

using Alfar.Math
using LinearAlgebra
using ModernGL

export Camera, CameraPosition, CameraState
export rotatex, rotatey, rotatez
export transform, identitytransform
export lookat, perspective, objectmodel

#
# Camera functionality
#
# The camera isn't actually important for what the samples are meant to
# do. Therefore, this file contains some things that are different between samples;
# differences that would otherwise be highlighted in the sample files themselves.
#

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

struct CameraPosition
    position::Vector3{Float32}
    up::Vector3{Float32}
end

function rotatex(angle::Float32) :: Matrix{GLfloat}
    Matrix{GLfloat}(GLfloat[
        1f0 0f0 0f0 0f0;
        0f0 cos(angle) -sin(angle) 0f0;
        0f0 sin(angle) cos(angle) 0f0;
        0f0 0f0 0f0 1f0;
    ])
end

function rotatey(angle::Float32) :: Matrix{GLfloat}
    Matrix{GLfloat}(GLfloat[
        cos(angle) 0f0 sin(angle) 0f0;
        0f0 1f0 0f0 0f0;
        -sin(angle) 0f0 cos(angle) 0f0;
        0f0 0f0 0f0 1f0;
    ])
end

function rotatez(angle::Float32) :: Matrix{GLfloat}
    Matrix{GLfloat}(GLfloat[
        cos(angle) -sin(angle) 0f0 0f0;
        sin(angle) cos(angle) 0f0 0f0;
        0f0 0f0 1f0 0f0;
        0f0 0f0 0f0 1f0;
    ])
end

transform(c::CameraPosition, t::Matrix{GLfloat}) :: CameraPosition = CameraPosition(t * c.position, t * c.up)
function identitytransform() :: Matrix{GLfloat}
    Matrix{GLfloat}([
        1f0 0f0 0f0 0f0;
        0f0 1f0 0f0 0f0;
        0f0 0f0 1f0 0f0;
        0f0 0f0 0f0 1f0;
    ])
end

objectmodel() = identitytransform()

function perspective(camera) :: Matrix{GLfloat}
    tanhalf = tan(camera.fov/2f0)
    aspect = Float32(camera.windowwidth) / Float32(camera.windowheight)
    far = camera.far
    near = camera.near

    Matrix{GLfloat}(GLfloat[
        1f0/(aspect*tanhalf) 0f0           0f0                          0f0;
        0f0                  1f0/(tanhalf) 0f0                          0f0;
        0f0                  0f0           -(far + near) / (far - near) -2f0*far*near / (far - near);
        0.0f0                0f0           -1f0 0f0;
    ])
end

function lookat(cameraposition::CameraPosition, cameratarget::Vector3{Float32}) :: Matrix{Float32}
    direction = Math.normalize(cameraposition.position - cameratarget)
    up = cameraposition.up
    right = Math.cross(direction, up)
    direction = Matrix{GLfloat}([
            right[1]     right[2]     right[3] 0f0;
               up[1]        up[2]        up[3] 0f0;
        direction[1] direction[2] direction[3] 0f0;
                 0f0          0f0          0f0 1f0;
    ])
    translation = Matrix{GLfloat}([
         1f0 0f0  0f0 -cameraposition.position[1];
         0f0 1f0  0f0 -cameraposition.position[2];
         0f0 0f0  1f0 -cameraposition.position[3];
         0f0 0f0  0f0                1f0;
    ])
    direction * translation
end

struct CameraState
    position::CameraPosition
    target::Vector3{Float32}
end

lookat(state::CameraState) :: Matrix{Float32} = lookat(state.position, state.target)
transform(state::CameraState, t::Matrix{GLfloat}) :: CameraState = CameraState(transform(state.position, t), state.target)

end