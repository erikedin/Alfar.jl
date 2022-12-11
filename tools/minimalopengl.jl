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

using GLFW
using ModernGL
using CUDA

const VERTEX_SHADER = """
#version 410

layout (location = 0) in vec3 VertexPosition;
layout (location = 1) in vec3 NormalIn;

out vec3 Normal;

void main() {
    Normal = NormalIn;
	gl_Position = vec4(VertexPosition, 1.0);
}
"""

# From
# https://github.com/Gnimuc/Videre/tree/master/OpenGL%204%20Tutorials/09_texture_mapping
const FRAGMENT_SHADER = """
#version 410

in vec3 Normal;
out vec4 FragColor;

void main() {
	FragColor = vec4(Normal, 1.0);
}
"""

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
        errormsg = "Shader '$(shadertype)' failed to compile: $(infomessage)"
        throw(errormsg)
    end

    shader
end

function setupgraphics()
    vertices = GLfloat[
        -0.5f0, -0.5f0, 0.5f0, 1f0, 0f0, 0f0,
         0.5f0,  0.5f0, 0.5f0, 0f0, 1f0, 0f0,
        -0.5f0,  0.5f0, 0.5f0, 0f0, 0f0, 1f0,
    ]
    vao = Ref{GLuint}()
    glGenVertexArrays(1, vao)

    glBindVertexArray(vao[])

    vbo = Ref{GLuint}()
    glGenBuffers(1, vbo)

    glBindBuffer(GL_ARRAY_BUFFER, vbo[])
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW)

    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 6*sizeof(GLfloat), C_NULL)
    glEnableVertexAttribArray(0)

    glVertexAttribPointer(1, 3, GL_FLOAT, GL_FALSE, 6*sizeof(GLfloat), Ptr{Cvoid}(3 * sizeof(GLfloat)))
    glEnableVertexAttribArray(1)

    vertexshader = createshader(VERTEX_SHADER, GL_VERTEX_SHADER)
    fragmentshader = createshader(FRAGMENT_SHADER, GL_FRAGMENT_SHADER)
    program = glCreateProgram()
    glAttachShader(program, vertexshader)
    glAttachShader(program, fragmentshader)
    glLinkProgram(program)

    issuccess = Ref{GLint}()
    glGetProgramiv(program, GL_LINK_STATUS, issuccess)
    if issuccess[] != GL_TRUE
        throw(ShaderLinkingError("Shaders failed to link"))
    end

    program, vao[], 3
end

function run()
    # Create a window and its OpenGL context
    window = GLFW.CreateWindow(640, 480, "Alfar")

    # Make the window's context current
    GLFW.MakeContextCurrent(window)

    # TODO Setup graphics
    program, vao, numberofvertices = setupgraphics()

    glEnable(GL_CULL_FACE)
    glEnable(GL_BLEND)
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)
    glEnable(GL_DEPTH_TEST)

    # Loop until the user closes the window
    while !GLFW.WindowShouldClose(window)
        glClearColor(0.2f0, 0.3f0, 0.3f0, 1.0f0)
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)

	    # Render here

        glUseProgram(program)

        glBindVertexArray(vao)
        glDrawArrays(GL_TRIANGLES, 0, numberofvertices)
        glBindVertexArray(0)

	    # Swap front and back buffers
	    GLFW.SwapBuffers(window)

	    # Poll for and process events
	    GLFW.PollEvents()
    end

    GLFW.DestroyWindow(window)
end

run()