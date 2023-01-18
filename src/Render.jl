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

module Render

using ModernGL

using Alfar.Format.STL: STLBinary
using Alfar.Math
using Alfar.VolumeTextures
using Alfar.Fractal

export ShaderProgram
export use, uniform
export translate, scale, rotatez, rotatex

#
# Shader exceptions
#

struct ShaderCompilationError <: Exception
    msg::String
end

struct ShaderLinkingError <: Exception
    msg::String
end

#
# Shader utilities
#

function readshader(path::String)
    open(path, "r") do io
        read(io, String)
    end
end

function createshader(shaderpath, shadertype)
    shadersource = readshader(shaderpath)

    shader = glCreateShader(shadertype)

    glShaderSource(shader, 1, Ptr{GLchar}[pointer(shadersource)], C_NULL)
    glCompileShader(shader)

    issuccess = Ref{GLint}()
    glGetShaderiv(shader, GL_COMPILE_STATUS, issuccess)
    if issuccess[] != GL_TRUE
        maxlength = 512
        actuallength = Ref{GLsizei}()
        infolog = Vector{GLchar}(undef, maxlength)
        glGetShaderInfoLog(shader, maxlength, actuallength, infolog)
        infomessage = String(infolog[1:actuallength[]])
        errormsg = "Shader '$(shaderpath)' failed to compile: $(infomessage)"
        throw(ShaderCompilationError(errormsg))
    end

    shader
end

#
# Shader types
#

struct Shader{T}
    id::GLuint
end

function Shader{T}(path::String) where {T}
    id = createshader(path, T)
    Shader{T}(id)
end

delete(s::Shader{T}) where {T} = glDeleteShader(s.id)

const VertexShader = Shader{GL_VERTEX_SHADER}
const FragmentShader = Shader{GL_FRAGMENT_SHADER}

#
# Shader programs
#

struct ShaderProgram
    id::GLuint
end

attach(program::ShaderProgram, shader::Shader{T}) where {T} = glAttachShader(program.id, shader.id)

function ShaderProgram(vertexShaderPath::String, fragmentShaderPath) :: ShaderProgram
    fragmentshader = FragmentShader(fragmentShaderPath)
    vertexshader = VertexShader(vertexShaderPath)

    program = ShaderProgram(glCreateProgram())

    attach(program, vertexshader)
    attach(program, fragmentshader)
    glLinkProgram(program.id)

    issuccess = Ref{GLint}()
    glGetProgramiv(program.id, GL_LINK_STATUS, issuccess)
    if issuccess[] != GL_TRUE
        throw(ShaderLinkingError("Shaders failed to link"))
    end

    delete(vertexshader)
    delete(fragmentshader)

    program
end

use(program::ShaderProgram) = glUseProgram(program.id)

uniformlocation(program::ShaderProgram, name::String) = glGetUniformLocation(program.id, Ptr{GLchar}(pointer(name)))

function uniform(program::ShaderProgram, name::String, value::Float32)
    location = uniformlocation(program, name)
    glUniform1f(location, value)
end

function uniform(program::ShaderProgram, name::String, value::NTuple{3, GLfloat})
    location = uniformlocation(program, name)
    array = Ref([value...], 1)
    glUniform3fv(location, 1, array)
end

function uniform(program::ShaderProgram, name::String, value::NTuple{4, GLfloat})
    location = uniformlocation(program, name)
    array = Ref([value...], 1)
    glUniform4fv(location, 1, array)
end

function uniform(program::ShaderProgram, name::String, value::Matrix4{GLfloat})
    location = uniformlocation(program, name)
    array = Ref([value.e...], 1)
    glUniformMatrix4fv(location, 1, GL_FALSE, array)
end

function lookat(cameraposition::Vector3{T}, cameratarget::Vector3{T}, up::Vector3{T}) :: Matrix4{T} where {T}
    direction = normalize(cameraposition - cameratarget)
    right = normalize(cross(up, direction))
    cameraup = normalize(cross(direction, right))

    # TODO complete the function
    cameratranslation = Matrix4{T}([
        1f0 0f0 0f0 -cameraposition[1];
        0f0 1f0 0f0 -cameraposition[2];
        0f0 0f0 1f0 -cameraposition[3];
        0f0 0f0 0f0 1f0;
    ])
    other = Matrix4{T}([
        right[1] right[2] right[3] 0f0;
        cameraup[1] cameraup[2] cameraup[3] 0f0;
        direction[1] direction[2] direction[3] 0f0;
        0f0 0f0 0f0 1f0;

    ])
    other*cameratranslation
end

#
# Hard coded demo graphics
#

function scale(sx::Float32, sy::Float32, sz::Float32) :: Matrix4{GLfloat}
    Matrix4{GLfloat}(GLfloat[
        sx  0f0 0f0 0f0;
        0f0 sy  0f0 0f0;
        0f0 0f0 sz  0f0;
        0f0 0f0 0f0 1f0;
    ])
end

function translate(sx::Float32, sy::Float32, sz::Float32) :: Matrix4{GLfloat}
    Matrix4{GLfloat}(GLfloat[
        1f0 0f0 0f0 sx;
        0f0 1f0 0f0 sy;
        0f0 0f0 1f0 sz;
        0f0 0f0 0f0 1f0;
    ])
end

function rotatex(angle::Float32) :: Matrix4{GLfloat}
    Matrix4{GLfloat}(GLfloat[
        1f0 0f0 0f0 0f0;
        0f0 cos(angle) -sin(angle) 0f0;
        0f0 sin(angle) cos(angle) 0f0;
        0f0 0f0 0f0 1f0;
    ])
end

function rotatez(angle::Float32) :: Matrix4{GLfloat}
    Matrix4{GLfloat}(GLfloat[
        cos(angle) -sin(angle) 0f0 0f0;
        sin(angle) cos(angle) 0f0 0f0;
        0f0 0f0 1f0 0f0;
        0f0 0f0 0f0 1f0;
    ])
end

function perspective(fov::Float32, aspect::Float32, near::Float32, far::Float32) :: Matrix4{GLfloat}
    tanhalf = tan(fov/2f0)
    Matrix4{GLfloat}(GLfloat[
        1f0/(aspect*tanhalf) 0f0           0f0                          0f0;
        0f0                  1f0/(tanhalf) 0f0                          0f0;
        0f0                  0f0           -(far + near) / (far - near) -2f0*far*near / (far - near);
        0.0f0                0f0           -1f0 0f0;
    ])
end

function transformidentity() :: Matrix4{GLfloat} where {}
    Matrix4{GLfloat}([
         one(GLfloat) zero(GLfloat) zero(GLfloat) zero(GLfloat);
        zero(GLfloat)  one(GLfloat) zero(GLfloat) zero(GLfloat);
        zero(GLfloat) zero(GLfloat)  one(GLfloat) zero(GLfloat);
        zero(GLfloat) zero(GLfloat) zero(GLfloat)  one(GLfloat);
    ])
end

#
# Viewing box
#

function viewingbox()
    vertices = GLfloat[
        # Position              # Normals         # Texture coordinate
        # Back side
         0.5f0, -0.5f0, -0.5f0,  0f0,  0f0, -1f0, 1.0f0, 0.0f0, 0.0f0, # Right bottom back
        -0.5f0,  0.5f0, -0.5f0,  0f0,  0f0, -1f0, 0.0f0, 1.0f0, 0.0f0, # Left  top    back
         0.5f0,  0.5f0, -0.5f0,  0f0,  0f0, -1f0, 1.0f0, 1.0f0, 0.0f0, # Right top    back
         0.5f0, -0.5f0, -0.5f0,  0f0,  0f0, -1f0, 1.0f0, 0.0f0, 0.0f0, # Right bottom back
        -0.5f0, -0.5f0, -0.5f0,  0f0,  0f0, -1f0, 0.0f0, 0.0f0, 0.0f0, # Left  bottom back
        -0.5f0,  0.5f0, -0.5f0,  0f0,  0f0, -1f0, 0.0f0, 1.0f0, 0.0f0, # Left  top    back

        # Front side
         0.5f0, -0.5f0,  0.5f0,  0f0,  0f0,  1f0, 1.0f0, 0.0f0, 1.0f0, # Right bottom front
         0.5f0,  0.5f0,  0.5f0,  0f0,  0f0,  1f0, 1.0f0, 1.0f0, 1.0f0, # Right top    front
        -0.5f0,  0.5f0,  0.5f0,  0f0,  0f0,  1f0, 0.0f0, 1.0f0, 1.0f0, # Left  top    front
         0.5f0, -0.5f0,  0.5f0,  0f0,  0f0,  1f0, 1.0f0, 0.0f0, 1.0f0, # Right bottom front
        -0.5f0,  0.5f0,  0.5f0,  0f0,  0f0,  1f0, 0.0f0, 1.0f0, 1.0f0, # Left  top    front
        -0.5f0, -0.5f0,  0.5f0,  0f0,  0f0,  1f0, 0.0f0, 0.0f0, 1.0f0, # Left  bottom front

        # Left side
        -0.5f0,  0.5f0, -0.5f0, -1f0,  0f0,  0f0, 0.0f0, 1.0f0, 0.0f0, # Left top    back
        -0.5f0, -0.5f0, -0.5f0, -1f0,  0f0,  0f0, 0.0f0, 0.0f0, 0.0f0, # Left bottom back
        -0.5f0, -0.5f0,  0.5f0, -1f0,  0f0,  0f0, 0.0f0, 0.0f0, 1.0f0, # Left bottom front
        -0.5f0,  0.5f0, -0.5f0, -1f0,  0f0,  0f0, 0.0f0, 1.0f0, 0.0f0, # Left top    back
        -0.5f0, -0.5f0,  0.5f0, -1f0,  0f0,  0f0, 0.0f0, 0.0f0, 1.0f0, # Left bottom front
        -0.5f0,  0.5f0,  0.5f0, -1f0,  0f0,  0f0, 0.0f0, 1.0f0, 1.0f0, # Left top    front

        # Right side
         0.5f0, -0.5f0, -0.5f0,  1f0,  0f0,  0f0, 1.0f0, 0.0f0, 0.0f0, # Right bottom back
         0.5f0,  0.5f0, -0.5f0,  1f0,  0f0,  0f0, 1.0f0, 1.0f0, 0.0f0, # Right top    back
         0.5f0, -0.5f0,  0.5f0,  1f0,  0f0,  0f0, 1.0f0, 0.0f0, 1.0f0, # Right bottom front
         0.5f0, -0.5f0,  0.5f0,  1f0,  0f0,  0f0, 1.0f0, 0.0f0, 1.0f0, # Right bottom front
         0.5f0,  0.5f0, -0.5f0,  1f0,  0f0,  0f0, 1.0f0, 1.0f0, 0.0f0, # Right top    back
         0.5f0,  0.5f0,  0.5f0,  1f0,  0f0,  0f0, 1.0f0, 1.0f0, 1.0f0, # Right top    front

        # Bottom side
        -0.5f0, -0.5f0, -0.5f0,  0f0, -1f0,  0f0, 0.0f0, 0.0f0, 0.0f0, # Left  bottom back
         0.5f0, -0.5f0, -0.5f0,  0f0, -1f0,  0f0, 1.0f0, 0.0f0, 0.0f0, # Right bottom back
         0.5f0, -0.5f0,  0.5f0,  0f0, -1f0,  0f0, 1.0f0, 0.0f0, 1.0f0, # Right bottom front
        -0.5f0, -0.5f0,  0.5f0,  0f0, -1f0,  0f0, 0.0f0, 0.0f0, 1.0f0, # Left  bottom front
        -0.5f0, -0.5f0, -0.5f0,  0f0, -1f0,  0f0, 0.0f0, 0.0f0, 0.0f0, # Left  bottom back
         0.5f0, -0.5f0,  0.5f0,  0f0, -1f0,  0f0, 1.0f0, 0.0f0, 1.0f0, # Right bottom front

        # Top side
        -0.5f0,  0.5f0, -0.5f0,  0f0,  1f0,  0f0, 0.0f0, 1.0f0, 0.0f0, # Left  top back
         0.5f0,  0.5f0,  0.5f0,  0f0,  1f0,  0f0, 1.0f0, 1.0f0, 1.0f0, # Right top front
         0.5f0,  0.5f0, -0.5f0,  0f0,  1f0,  0f0, 1.0f0, 1.0f0, 0.0f0, # Right top back
         0.5f0,  0.5f0,  0.5f0,  0f0,  1f0,  0f0, 1.0f0, 1.0f0, 1.0f0, # Right top front
        -0.5f0,  0.5f0, -0.5f0,  0f0,  1f0,  0f0, 0.0f0, 1.0f0, 0.0f0, # Left  top back
        -0.5f0,  0.5f0,  0.5f0,  0f0,  1f0,  0f0, 0.0f0, 1.0f0, 1.0f0, # Left  top front
    ]
end

function mengerspongetexture() :: VolumeTexture
    sponge = MengerSponge{4}()
    fractalvoxels = fractal(sponge)

    voxelcolor = x -> if x == 1 (UInt8(0), UInt8(255), UInt8(0), UInt8(64)) else (UInt8(0), UInt8(0), UInt8(255), UInt8(255)) end

    tupledvoxels = map(voxelcolor, fractalvoxels)
    colorvoxels = collect(Iterators.flatten(tupledvoxels))

    texturedata = reshape(colorvoxels, size(sponge)*4)

    vt = VolumeTexture(dimensions(sponge)...)
    textureimage(vt, texturedata)

    vt
end

function exampletexture() :: VolumeTexture
    width = 16
    height = 16
    depth = 16

    texturedata = UInt8[]
    for z = 1:depth
        for y = 1:height
            for x = 1:width
                isrightborder = x <= 2
                isleftborder = x >= width - 1
                istopborder = y <= 2
                isbottomborder = y >= height - 1
                isborder = isrightborder || isleftborder || istopborder || isbottomborder
                iscross = x == width / 2 || x == width / 2 + 1

                iscenterwidthquadrant1 = x == 3 * width / 4 || x == 3 * width / 4 + 1
                iscenterheightquadrant1 = y == 3 * height / 4 || y == 3 * height / 4 + 1
                iscenterquadrant1 = iscenterheightquadrant1 && iscenterwidthquadrant1

                iscenterwidthquadrant2 = x == width / 4 || x == width / 4 + 1
                iscenterheightquadrant2 = y == 3 * height / 4 || y == 3 * height / 4 + 1
                iscenterquadrant2 = iscenterheightquadrant2 && iscenterwidthquadrant2

                iscolormarkergreen = x >= 3 && x <= 8 && y >= 3 && y <= 8
                iscolormarkerred = x >= 9 && x <= 14 && y >= 3 && y <= 8

                if iscenterquadrant1
                    r = UInt8(255)
                    g = UInt8(0)
                    b = UInt8(255)
                    a = UInt8(255)
                elseif iscenterquadrant2
                    r = UInt8(0)
                    g = UInt8(0)
                    b = UInt8(0)
                    a = UInt8(255)
                elseif isborder || iscross
                    r = UInt8(0)
                    g = UInt8(0)
                    b = UInt8(255)
                    a = UInt8(255)
                elseif iscolormarkergreen
                    r = UInt8(0)
                    g = round(251)
                    b = UInt8(0)
                    a = UInt8(0)
                elseif iscolormarkerred
                    r = UInt8(251)
                    g = round(0)
                    b = UInt8(0)
                    a = UInt8(0)
                else
                    r = UInt8(0)
                    g = round(UInt8, 255f0 * (z - 1) / depth)
                    b = UInt8(0)
                    a = UInt8(255)

                    if x == 10 && y == 10
                        println("Texture z = $(z), g = ", g)
                    end
                end

                push!(texturedata, r)
                push!(texturedata, g)
                push!(texturedata, b)
                push!(texturedata, a)
            end
        end
    end

    vt = VolumeTexture(16, 16, 16)

    textureimage(vt, texturedata)

    vt
end

end