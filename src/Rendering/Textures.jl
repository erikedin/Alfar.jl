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

module Textures

using ModernGL

export TextureData, Texture

struct TextureData{N}
    data
    dimensions::NTuple{N, GLsizei}

    function TextureData{N}(data, dimensions...) where {N}
        new(data, dimensions)
    end
end

struct Texture{N}
    textureid::GLuint
end

function Texture{3}(texturedata::TextureData{3})

    textureRef = Ref{GLuint}()
    glGenTextures(1, textureRef)
    textureid = textureRef[]

    glBindTexture(GL_TEXTURE_3D, textureid)

    glTexImage3D(GL_TEXTURE_3D,
                 0,
                 GL_RED,
                 texturedata.dimensions...,
                 0,
                 GL_RED,
                 GL_UNSIGNED_BYTE,
                 texturedata.data)
    glGenerateMipmap(GL_TEXTURE_3D)

    Texture{3}(textureid)
end

function Texture{1}(texturedata::TextureData{1})
    textureRef = Ref{GLuint}()
    glGenTextures(1, textureRef)
    textureid = textureRef[]

    glBindTexture(GL_TEXTURE_1D, textureid)

    glTexImage1D(GL_TEXTURE_1D,
                 0,
                 GL_RGBA,
                 texturedata.dimensions...,
                 0,
                 GL_RGBA,
                 GL_UNSIGNED_BYTE,
                 texturedata.data)
    glGenerateMipmap(GL_TEXTURE_1D)

    Texture{1}(textureid)
end

end