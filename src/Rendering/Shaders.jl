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

module Shaders

export ShaderProgram
export use, uniform
export VertexShader, FragmentShader

using ModernGL

using Alfar.Math

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

# TODO This is temporary, should be removed once we consistently use Matrix4
function uniform(program::ShaderProgram, name::String, value::Matrix{GLfloat})
    location = uniformlocation(program, name)
    array = Ref([value...], 1)
    glUniformMatrix4fv(location, 1, GL_FALSE, array)
end
end