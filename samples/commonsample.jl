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

#
# Shader creation
#

struct ShaderError <: Exception
    msg::String
end

function createshader(shadersource, shadertype)
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
        errormsg = "Shader failed to compile: $(infomessage)"
        throw(ShaderError(errormsg))
    end

    shader
end

function makeprogram(vertexsource, fragmentsource)
    programid = glCreateProgram()
    vertexshader = createshader(vertexsource, GL_VERTEX_SHADER)
    fragmentshader = createshader(fragmentsource, GL_FRAGMENT_SHADER)

    glAttachShader(programid, vertexshader)
    glAttachShader(programid, fragmentshader)

    glLinkProgram(programid)

    issuccess = Ref{GLint}()
    glGetProgramiv(programid, GL_LINK_STATUS, issuccess)
    if issuccess[] != GL_TRUE
        throw(ShaderError("Shaders failed to link"))
    end

    programid
end

#
# Setting uniforms in shaders
#

uniformlocation(program::GLuint, name::String) = glGetUniformLocation(program, Ptr{GLchar}(pointer(name)))

function uniform(program::GLuint, name::String, value::Matrix{GLfloat})
    location = uniformlocation(program, name)
    array = Ref([value...], 1)
    glUniformMatrix4fv(location, 1, GL_FALSE, array)
end

#
# Vector types
#

const Vector3{T} = NTuple{3, T}

#
# Mesh type
#

struct Mesh
    vao::GLuint
    numberofvertices::Int
end