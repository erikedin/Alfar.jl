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

struct ShaderCompilationError <: Exception
    msg::String
end

struct ShaderLinkingError <: Exception
    msg::String
end

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
        errormsg = "Shader '$(shaderpath)' failed to compile"
        throw(ShaderCompilationError(errormsg))
    end

    shader
end

function createprogram() :: GLuint
    vertexshader = createshader("shaders/vertex.glsl", GL_VERTEX_SHADER)
    fragmentshader = createshader("shaders/fragment.glsl", GL_FRAGMENT_SHADER)

    program = glCreateProgram()

    glAttachShader(program, vertexshader)
    glAttachShader(program, fragmentshader)
    glLinkProgram(program)

    issuccess = Ref{GLint}()
    glGetProgramiv(program, GL_LINK_STATUS, issuccess)
    if issuccess[] != GL_TRUE
        throw(ShaderLinkingError("Shaders failed to link"))
    end

    glDeleteShader(vertexshader)
    glDeleteShader(fragmentshader)

    program
end

function setupgraphics()
    # Hard code a simple triangle. Following the Learn OpenGL book.
    vertices = GLfloat[
        -0.5f0, -0.5f0, 0.0f0,
        0.5f0, -0.5f0, 0.0f0,
        0.0f0, 0.5f0, 0.0f0,
    ]

    vbo = Ref{GLuint}()
    glGenBuffers(1, vbo)
    glBindBuffer(GL_ARRAY_BUFFER, vbo[])
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW)

    program = createprogram()
    glUseProgram(program)
end

end