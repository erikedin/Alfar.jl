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

export TextureDimension
export FlatBinaryFormat, IntensityTextureInput
export IntensityTexture

# There are two aspects to textures:
# 1. Input textures, read from files or other sources.
# 2. OpenGL textures, which are used by OpenGL for rendering.
#
# OpenGL textures are created from input textures.

struct TextureDimension{D}
    dim::NTuple{D, Int}

    function TextureDimension{1}(width::Int)
        new((width,))
    end
    function TextureDimension{2}(width::Int, height::Int)
        new((width, height))
    end
    function TextureDimension{2}(width::Int, height::Int, depth::Int)
        new((width, height, depth))
    end
end

width(td::TextureDimension{D}) where {D} = td.dim[1]
height(td::TextureDimension{D}) where {D} = td.dim[2]
depth(td::TextureDimension{D}) where {D} = td.dim[3]

numberofelements(td::TextureDimension{D}) where {D} = prod(td.dim)

#
# Input textures
#

# FlatBinaryFormat reads texture files where each texel is a T, and no additonal format is used.
# That is, a NxM texture with 16 bit values in flat binary format has N*M*2 (16 bits = 2 bytes),
# bytes, and every 2 bytes is one texel.
struct FlatBinaryFormat{T} <: IO
    io::IO
end

read(fbf::FlatBinaryFormat{T}, ::Type{T}) where {T} = Base.read(fbf.io, T)

struct IntensityTextureInput{D, Type}
    data::Vector{Type}
    dimension::TextureDimension{D}

    function IntensityTextureInput{D, Type}(dimension::TextureDimension{D}, io::IO) where {D, Type}
        n = numberofelements(dimension)

        data = Vector{Type}()
        for i=1:n
            push!(data, read(io, Type))
        end

        new(data, dimension)
    end
end

#
# OpenGL textures.
#

function mapinternalformat(t::Type) :: GLenum
    types = Dict{Type, GLenum}(
        UInt16 => GL_R16,
    )
    types[t]
end

function maptexturetype(t::Type) :: GLenum
    types = Dict{Type, GLenum}(
        UInt16 => GL_UNSIGNED_SHORT,
    )
    types[t]
end

function texImage(texture::IntensityTexture{1, Type},
                  internalformat::GLenum
                  format::GLenum,
                  texturetype::GLenum,
                  textureid::GLuint) :: GLuint where {Type}

    glBindTexture(GL_TEXTURE_1D, textureid)
    glTexImage2D(GL_TEXTURE_1D,
                 0,                      # level: Mipmap level, keep at zero.
                 internalformat,
                 width(texture.dimension),
                 0,                      # Required to be zero.
                 format,
                 texturetype,
                 texture.data
                 )
    glGenerateMipmap(GL_TEXTURE_1D)
end

function texImage(texture::IntensityTexture{2, Type},
                  internalformat::GLenum
                  format::GLenum,
                  texturetype::GLenum,
                  textureid::GLuint) :: GLuint where {Type}

    glBindTexture(GL_TEXTURE_2D, textureid)
    glTexImage2D(GL_TEXTURE_2D,
                 0,                      # level: Mipmap level, keep at zero.
                 internalformat,
                 width(texture.dimension),
                 height(texture.dimension),
                 0,                      # Required to be zero.
                 format,
                 texturetype,
                 texture.data
                 )
    glGenerateMipmap(GL_TEXTURE_2D)
end

function texImage(texture::IntensityTexture{3, Type},
                  internalformat::GLenum
                  format::GLenum,
                  texturetype::GLenum,
                  textureid::GLuint) :: GLuint where {Type}

    glBindTexture(GL_TEXTURE_3D, textureid)

    glTexImage3D(GL_TEXTURE_3D,
                 0,                      # level: Mipmap level, keep at zero.
                 internalformat,
                 width(texture.dimension),
                 height(texture.dimension),
                 depth(texture.dimension),
                 0,                      # Required to be zero.
                 format,
                 texturetype,
                 texture.data
                )
    glGenerateMipmap(GL_TEXTURE_3D)
end

# IntensityTexture is an OpenGL texture where each texel is an intensity.
# An intensity is characterized by being a continuous scalar value.
# A scalar value implies that this is a single channel texture.
struct IntensityTexture{D, Type}
    id::GLuint

    function IntensityTexture{D, Type}(input::IntensityTextureInput{D, Type}) where {D, Type}
        # TODO: Make a parameter out of this.
        #       Decide if this is a constructor parameter or a struct type parameter.
        glActiveTexture(GL_TEXTURE0)

        textureref = Ref{GLuint}()
        glGenTextures(1, textureref)
        textureid = textureref[]

        # The internal format specifies how OpenGL should represent the texels internally.
        # For now, just map the input type to the closest corresponding OpenGL type.
        # OpenGL is capable of conversion, so one could have a different internal format
        # than the format that you pass in, but for now we just map them here.
        # For instance, if `Type` is `UInt16`, then this corresponds to an internal format
        # `GL_R16`, which has the same size and range.
        internalformat = mapinternalformat(Type)

        # The format specifies the format of the data you pass in, not how the texture is
        # stored by OpenGL (see internalformat above).
        # Since this is an intensity texture, there is a single scalar value stored, so
        # this goes in GL_RED.
        format = GL_RED

        # This is the type of the elements in the `input`. We simply map this from a Julia
        # type to an OpenGL type.
        # Example: UInt16 -> GL_UNSIGNED_SHORT
        texturetype = maptexturetype(Type)

        texImage{D, Type}(input, internalformat, format, texturetype, textureid)

        new(textureid)
    end
end

end