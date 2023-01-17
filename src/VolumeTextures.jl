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

module VolumeTextures

using ModernGL

export VolumeTexture
export bindvolume, textureimage

struct VolumeTexture
    id::Int
    width::Int
    height::Int
    depth::Int
end

function VolumeTexture(width::Int, height::Int, depth::Int) :: VolumeTexture
    textureRef = Ref{GLuint}()
    glGenTextures(1, textureRef)

    VolumeTexture(textureRef[], width, height, depth)
end

bindvolume(vt::VolumeTexture) = glBindTexture(GL_TEXTURE_3D, vt.id)

function textureimage(vt::VolumeTexture, data::AbstractVector{UInt8})
    bindvolume(vt)

    levelofdetail = 0 # No mipmaps
    internalformat = GL_RGBA
    border = 0 # Must be zero according to the documentation
    format = GL_RGBA
    type = GL_UNSIGNED_BYTE
    voxels = Ref(data, 1)
    glTexImage3D(GL_TEXTURE_3D, levelofdetail, internalformat, vt.width, vt.height, vt.depth, border, format, type, voxels)
end

end