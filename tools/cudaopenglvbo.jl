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

function createprogram()
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

    program
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
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_DYNAMIC_DRAW)

    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 6*sizeof(GLfloat), C_NULL)
    glEnableVertexAttribArray(0)

    glVertexAttribPointer(1, 3, GL_FLOAT, GL_FALSE, 6*sizeof(GLfloat), Ptr{Cvoid}(3 * sizeof(GLfloat)))
    glEnableVertexAttribArray(1)

    # CUDA: Register buffer
    graphicsResourceRef = Ref{CUDA.CUgraphicsResource}()
    registerflags = CUDA.CU_GRAPHICS_REGISTER_FLAGS_WRITE_DISCARD
    CUDA.cuGraphicsGLRegisterBuffer(graphicsResourceRef, vbo[], registerflags)

    vao[], 3, graphicsResourceRef[]
end

function wrapresource(devicepointer::CUDA.CUdeviceptr, n::Csize_t)
    devicearray = reinterpret(CuPtr{Float32}, devicepointer)
    len = trunc(Int, n / sizeof(Float32))
    unsafe_wrap(CuArray, devicearray, len)
end

function vertexgpu!(vertices, angle::Float32)
    if threadIdx().x == 1
        x1 = vertices[1]
        y1 = vertices[2]
        x2 = vertices[7]
        y2 = vertices[8]
        x3 = vertices[13]
        y3 = vertices[14]

        vertices[1] = x1*cos(angle) - y1*sin(angle)
        vertices[2] = x1*sin(angle) + y1*cos(angle)

        vertices[7] = x2*cos(angle) - y2*sin(angle)
        vertices[8] = x2*sin(angle) + y2*cos(angle)

        vertices[13] = x3*cos(angle) - y3*sin(angle)
        vertices[14] = x3*sin(angle) + y3*cos(angle)
    end
    return
end

function docudathings(graphicsResource::CUDA.CUgraphicsResource, angle::Float32)
    CUDA.cuGraphicsMapResources(1, [graphicsResource], stream())

    devicepointer = Ref{CUDA.CUdeviceptr}()
    sizepointer = Ref{Csize_t}()
    CUDA.cuGraphicsResourceGetMappedPointer_v2(devicepointer, sizepointer, graphicsResource)
    verticesdevice = wrapresource(devicepointer[], sizepointer[])

    CUDA.@sync @cuda threads=1 vertexgpu!(verticesdevice, angle::Float32)

    CUDA.cuGraphicsUnmapResources(1, [graphicsResource], stream())
end

function run()
    # Pre-compile the CUDA kernel, or it will happen on the first render.
    dummyvertices = CUDA.zeros(Float32, 18)
    CUDA.@sync @cuda threads=1 vertexgpu!(dummyvertices, 0f0)

    # Create a window and its OpenGL context
    window = GLFW.CreateWindow(640, 480, "Alfar")

    # Make the window's context current
    GLFW.MakeContextCurrent(window)

    # TODO Setup graphics
    vao, numberofvertices, graphicsResource = setupgraphics()
    program = createprogram()

    glEnable(GL_CULL_FACE)
    glEnable(GL_BLEND)
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)
    glEnable(GL_DEPTH_TEST)

    lastrender = time()

    # Loop until the user closes the window
    while !GLFW.WindowShouldClose(window)
        glClearColor(0.2f0, 0.3f0, 0.3f0, 1.0f0)
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)

	    # Render here
        elapsedtime = time() - lastrender
        lastrender = time()
        angle = 2.0 * pi * elapsedtime / 4.0
        docudathings(graphicsResource, Float32(angle))


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