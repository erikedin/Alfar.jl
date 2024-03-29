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
export TextureInputIO, readtexel, FlatBinaryFormat
export IntensityTextureInput
export IntensityTexture
export InternalRGBA, InputRGBA
export Texture
export width, height, depth

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
    function TextureDimension{3}(width::Int, height::Int, depth::Int)
        new((width, height, depth))
    end

end

function TextureDimension{3}(dim::TextureDimension{2}, depth::Int)
    TextureDimension{3}(width(dim), height(dim), depth)
end

width(td::TextureDimension{D}) where {D} = td.dim[1]
height(td::TextureDimension{D}) where {D} = td.dim[2]
depth(td::TextureDimension{D}) where {D} = td.dim[3]

numberofelements(td::TextureDimension{D}) where {D} = prod(td.dim)

#
# Input textures
#

abstract type TextureInputIO{T} end

# FlatBinaryFormat reads texture files where each texel is a T, and no additonal format is used.
# That is, a NxM texture with 16 bit values in flat binary format has N*M*2 (16 bits = 2 bytes),
# bytes, and every 2 bytes is one texel.
struct FlatBinaryFormat{T} <: TextureInputIO{T}
    io::IO
end

readtexel(fbf::FlatBinaryFormat{T}, ::Type{T}) where {T} = Base.read(fbf.io, T)

struct IntensityTextureInput{D, Type}
    data::Vector{Type}
    dimension::TextureDimension{D}

    function IntensityTextureInput{D, Type}(dimension::TextureDimension{D}, io::TextureInputIO{Type}) where {D, Type}
        n = numberofelements(dimension)

        data = Vector{Type}()
        for i=1:n
            push!(data, readtexel(io, Type))
        end

        new(data, dimension)
    end

    function IntensityTextureInput{3, Type}(
        dimension::TextureDimension{2},
        inputs::Vector{IntensityTextureInput{2, Type}}) where {Type}

        newdimension = TextureDimension{3}(dimension, length(inputs))

        data = Vector{Type}()
        for input in inputs
            append!(data, input.data)
        end

        new(data, newdimension)
    end
end

#
# OpenGL textures.
#


abstract type InternalFormat end
struct InternalRGBA{T} <: InternalFormat end

abstract type InputFormat end
struct InputRGBA{T} <: InputFormat end

function mapinternalformat(t::Type) :: GLenum
    types = Dict{Type, GLenum}(
        UInt8 => GL_R8,
        UInt16 => GL_R16,
        Float16 => GL_R16F,
    )
    types[t]
end

mapinternalformat(::Type{InternalRGBA{UInt8}}) = GL_RGBA8
mapinternalformat(::Type{InternalRGBA{UInt16}}) = GL_RGBA16

function mapformat(::Type{InputRGBA{T}}) :: GLenum where {T}
    GL_RGBA
end

function maptexturetype(t::Type) :: GLenum
    types = Dict{Type, GLenum}(
        UInt8  => GL_UNSIGNED_BYTE,
        UInt16 => GL_UNSIGNED_SHORT,
        Float16 => GL_HALF_FLOAT,
    )
    types[t]
end

function maptexturetype(::Type{InputRGBA{T}}) :: GLenum where {T}
    maptexturetype(T)
end

function texImage(dimension::TextureDimension{1},
                  data::Vector{Type},
                  internalformat::GLenum,
                  format::GLenum,
                  texturetype::GLenum,
                  textureid::GLuint) where {Type}

    glBindTexture(GL_TEXTURE_1D, textureid)
    glTexImage1D(GL_TEXTURE_1D,
                 0,                      # level: Mipmap level, keep at zero.
                 internalformat,
                 width(dimension),
                 0,                      # Required to be zero.
                 format,
                 texturetype,
                 data
                 )
    glGenerateMipmap(GL_TEXTURE_1D)
end

function texImage(dimension::TextureDimension{2},
                  data::Vector{Type},
                  internalformat::GLenum,
                  format::GLenum,
                  texturetype::GLenum,
                  textureid::GLuint) where {Type}

    glBindTexture(GL_TEXTURE_2D, textureid)
    glTexImage2D(GL_TEXTURE_2D,
                 0,                      # level: Mipmap level, keep at zero.
                 internalformat,
                 width(dimension),
                 height(dimension),
                 0,                      # Required to be zero.
                 format,
                 texturetype,
                 data
                 )
    glGenerateMipmap(GL_TEXTURE_2D)
end

function texImage(dimension::TextureDimension{3},
                  data::Vector{Type},
                  internalformat::GLenum,
                  format::GLenum,
                  texturetype::GLenum,
                  textureid::GLuint) where {Type}

    glBindTexture(GL_TEXTURE_3D, textureid)

    glTexImage3D(GL_TEXTURE_3D,
                 0,                      # level: Mipmap level, keep at zero.
                 internalformat,
                 width(dimension),
                 height(dimension),
                 depth(dimension),
                 0,                      # Required to be zero.
                 format,
                 texturetype,
                 data
                )
    glGenerateMipmap(GL_TEXTURE_3D)
end

# IntensityTexture is an OpenGL texture where each texel is an intensity.
# An intensity is characterized by being a continuous scalar value.
# A scalar value implies that this is a single channel texture.
struct IntensityTexture{D, Type}
    id::GLuint
    dimension::TextureDimension{D}

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

        texImage(input.dimension, input.data, internalformat, format, texturetype, textureid)

        new(textureid, input.dimension)
    end

    function IntensityTexture{3, Type}(inputs::Vector{IntensityTextureInput{2, Type}}) where {Type}
        data = Vector{Type}()
        for input in inputs
            append!(data, input.data)
        end

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

        newdimension = TextureDimension{3}(input.dimension, length(inputs))
        texImage(newdimension, data, internalformat, format, texturetype, textureid)

        new(textureid, newdimension)

    end
end

#
# General textures
#

# Texture is a general texture type, where each OpenGL parameter can be chosen.
struct Texture{D, Type, TextureUnit, InternalFormat, Format}
    id::GLuint

    function Texture{D, Type, TextureUnit, InternalFormat, Format}(
                input::IntensityTextureInput{D, Type}) where {D, Type, TextureUnit, InternalFormat, Format}

        glActiveTexture(TextureUnit)

        textureref = Ref{GLuint}()
        glGenTextures(1, textureref)
        textureid = textureref[]

        texImage(input.dimension, input.data, InternalFormat, Format, TextureType, textureid)

        new(textureid)
    end

    function Texture{D, Type, TextureUnit, InternalFormat, Format}(
                dim::TextureDimension{D}, data::Vector{Type}) where {D, Type, TextureUnit, InternalFormat, Format}

        glActiveTexture(TextureUnit)

        textureref = Ref{GLuint}()
        glGenTextures(1, textureref)
        textureid = textureref[]

        # The internal format specifies how OpenGL should represent the texels internally.
        # For now, just map the input type to the closest corresponding OpenGL type.
        # OpenGL is capable of conversion, so one could have a different internal format
        # than the format that you pass in, but for now we just map them here.
        # For instance, if `Type` is `UInt16`, then this corresponds to an internal format
        # `GL_R16`, which has the same size and range.
        internalformat = mapinternalformat(InternalFormat)

        # The format specifies the format of the data you pass in, not how the texture is
        # stored by OpenGL (see internalformat above).
        # Since this is an intensity texture, there is a single scalar value stored, so
        # this goes in GL_RED.
        format = mapformat(Format)

        # This is the type of the elements in the `input`. We simply map this from a Julia
        # type to an OpenGL type.
        # Example: UInt16 -> GL_UNSIGNED_SHORT
        texturetype = maptexturetype(Format)

        texImage(dim, data, internalformat, format, texturetype, textureid)

        new(textureid)
    end
end

end