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

using GLFW
using ModernGL
using LinearAlgebra

#
# Example mesh
# This is just a quad, defined by two triangles, at z = 0.5.
#

struct Mesh
    vao::GLuint
    numberofvertices::Int
end

function makequad(z::GLfloat) :: Mesh
    vertices = GLfloat[
        # Position
         0.5f0, -0.5f0, z,
         0.5f0,  0.5f0, z,
        -0.5f0,  0.5f0, z,
         0.5f0, -0.5f0, z,
        -0.5f0,  0.5f0, z,
        -0.5f0, -0.5f0, z,
    ]

    vao = Ref{GLuint}()
    glGenVertexArrays(1, vao)

    glBindVertexArray(vao[])

    vbo = Ref{GLuint}()
    glGenBuffers(1, vbo)

    # 3 position elements, x, y, z.
    # The texture coordinates are determined from the vertex coordinates in the vertex shader.
    elementspervertex = 3

    glBindBuffer(GL_ARRAY_BUFFER, vbo[])
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_DYNAMIC_DRAW)

    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, elementspervertex*sizeof(GLfloat), C_NULL)
    glEnableVertexAttribArray(0)

    Mesh(vao[], length(vertices) / elementspervertex)
end

#
# Shader sources
#

vertexsource = """
#version 330 core

layout (location = 0) in vec3 aPos;

out vec3 TexCoord;

uniform mat4 model;
uniform mat4 view;
uniform mat4 projection;

void main()
{
    vec4 p = vec4(aPos.x, aPos.y, aPos.z, 1.0);
    gl_Position = projection * view * model * p;
    TexCoord = vec3(p.x, p.y, p.z) + 0.5;
}
"""

fragmentsource = """
#version 330 core

in vec3 TexCoord;
out vec4 FragColor;

uniform sampler3D mytexture;

void main()
{
    FragColor = texture(mytexture, TexCoord);
}
"""

#
# Shaders
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

function makeprogram()
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

uniformlocation(program::GLuint, name::String) = glGetUniformLocation(program, Ptr{GLchar}(pointer(name)))

function uniform(program::GLuint, name::String, value::Matrix{GLfloat})
    location = uniformlocation(program, name)
    array = Ref([value...], 1)
    glUniformMatrix4fv(location, 1, GL_FALSE, array)
end

function uniform(program::GLuint, name::String, value::GLfloat)
    location = uniformlocation(program, name)
    glUniform1f(location, value)
end

#
# Camera
#

const Vector3{T} = NTuple{3, T}

struct Camera
    fov::Float32
    windowwidth::Int
    windowheight::Int
    near::Float32
    far::Float32
end

function Camera(width, height) :: Camera
    fov = 0.25f0*pi
    near = 0.1f0
    far = 100.0f0
    Camera(
        fov,
        width,
        height,
        near,
        far
    )
end

#
# Perspective and transformations
#

function objectmodel()
    Matrix{GLfloat}([
        1f0 0f0 0f0 0f0;
        0f0 1f0 0f0 0f0;
        0f0 0f0 1f0 0f0;
        0f0 0f0 0f0 1f0;

    ])
end

function lookat() :: Matrix{Float32}
    direction = Matrix{GLfloat}([
         1f0 0f0  1.8f0  0f0;
         0f0 1f0  1.4f0  0f0;
         0f0 0f0 -1f0  0f0;
         0f0 0f0  0f0  1f0;
    ])
    translation = Matrix{GLfloat}([
         1f0 0f0  0f0 -5f0;
         0f0 1f0  0f0 -4f0;
         0f0 0f0  1f0  3f0;
         0f0 0f0  0f0  1f0;
    ])
    direction * translation
end

function perspective(camera) :: Matrix{GLfloat}
    tanhalf = tan(camera.fov/2f0)
    aspect = Float32(camera.windowwidth) / Float32(camera.windowheight)
    far = camera.far
    near = camera.near

    Matrix{GLfloat}(GLfloat[
        1f0/(aspect*tanhalf) 0f0           0f0                          0f0;
        0f0                  1f0/(tanhalf) 0f0                          0f0;
        0f0                  0f0           -(far + near) / (far - near) -2f0*far*near / (far - near);
        0.0f0                0f0           -1f0 0f0;
    ])
end

#
# Generate a 3D texture
# The size needs to be a multiple of two at each dimension.
# Making it a square 64x64x64 pixel texture.
#

function generatetexture(width, height, depth)
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
                    a = UInt8(255)
                elseif iscolormarkerred
                    r = UInt8(251)
                    g = round(0)
                    b = UInt8(0)
                    a = UInt8(255)
                else
                    r = round(UInt8, 255f0 * (depth - z) / depth)
                    g = round(UInt8, 255f0 * (z - 1) / depth)
                    b = UInt8(0)
                    a = round(UInt8, 255f0 * (z - 1) / depth)
                end

                push!(texturedata, r)
                push!(texturedata, g)
                push!(texturedata, b)
                push!(texturedata, a)
            end
        end
    end

    texturedata
end

function maketexture()
    textureRef = Ref{GLuint}()
    glGenTextures(1, textureRef)
    textureid = textureRef[]

    glBindTexture(GL_TEXTURE_3D, textureid)

    width = 64
    height = 64
    depth = 64
    data = generatetexture(width, height, depth)

    glTexImage3D(GL_TEXTURE_3D, 0, GL_RGBA, width, height, depth, 0, GL_RGBA, GL_UNSIGNED_BYTE, data)
    glGenerateMipmap(GL_TEXTURE_3D)

    glTexParameterf(GL_TEXTURE_3D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE)
    glTexParameterf(GL_TEXTURE_3D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE)
    glTexParameterf(GL_TEXTURE_3D, GL_TEXTURE_WRAP_R, GL_CLAMP_TO_EDGE)

    textureid
end

#
# Main loop
#

function render(mesh::Mesh, textureid::GLuint)
    glBindTexture(GL_TEXTURE_3D, textureid)
    glBindVertexArray(mesh.vao)
    glDrawArrays(GL_TRIANGLES, 0, mesh.numberofvertices)
end

function whichslice(timeofstart, timenow)
    timesincestart = Float32(timenow - timeofstart)

    # One full interval is 10 seconds
    interval = 10f0

    v = sin(2f0 * pi * timesincestart / interval)

    # v is in the range [-1, 1], but we want [-0.5, 0.5]
    # Note that this is different from the animated sample, which this sample originates from,
    # because here this represents a vertex Z coordinate in the range [-0.5, 0.5].
    # In the animated sample, this referred to a texture R coordinate in the range [0, 1].
    v / 2f0
end

struct Slices
    quads::Vector{Mesh}
end

function render(slices::Slices, textureid::GLuint)
    for quad in slices.quads
        render(quad, textureid)
    end
end

function run()
    camera = Camera(1024, 800)

    # Create a window and its OpenGL context
    window = GLFW.CreateWindow(camera.windowwidth, camera.windowheight, "Julia sliced 3D texture example")

    # Make the window's context current
    GLFW.MakeContextCurrent(window)

    glEnable(GL_BLEND)
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)
    glEnable(GL_DEPTH_TEST)

    cubedepth = 1.0f0
    numberofslices = 10
    distancebetweenslices = cubedepth / numberofslices

    quads = [makequad(z) for z in 0.5f0:-distancebetweenslices:-0.5f0]
    slices = Slices(quads)
    programid = makeprogram()
    textureid = maketexture()

    timeofstart = time()

    # Loop until the user closes the window
    while !GLFW.WindowShouldClose(window)
        glClearColor(0.0f0, 0.0f0, 0.0f0, 1.0f0)
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)

        # Set uniforms
        view = lookat()
        projection = perspective(camera)
        model = objectmodel()
        uniform(programid, "model", model)
        uniform(programid, "view", view)
        uniform(programid, "projection", projection)

        # Render here
        glUseProgram(programid)
        render(slices, textureid)

        # Swap front and back buffers
        GLFW.SwapBuffers(window)

        # Poll for and process events
        GLFW.PollEvents()
    end

    GLFW.DestroyWindow(window)
end

run()