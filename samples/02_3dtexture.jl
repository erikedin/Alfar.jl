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

include("commonsample.jl")

#
# Shader sources
#

vertexsource = """
#version 330 core

layout (location = 0) in vec3 aPos;
layout (location = 1) in vec3 aTextureCoordinate;

out vec3 TexCoord;

uniform mat4 model;
uniform mat4 view;
uniform mat4 projection;

void main()
{
    vec4 p = vec4(aPos.x, aPos.y, aPos.z, 1.0);
    gl_Position = projection * view * model * p;
    TexCoord = aTextureCoordinate;
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
# Generate a 3D texture
# The size needs to be a multiple of two at each dimension.
# Making a 64x64x64 pixel texture.
#

function fill!(data, (width, height, depth), color)
   for x = 1:width
        for y = 1:height
            for z = 1:depth
                data[1, x, y, z] = UInt8(color[1])
                data[2, x, y, z] = UInt8(color[2])
                data[3, x, y, z] = UInt8(color[3])
                data[4, x, y, z] = UInt8(color[4])
            end
        end
    end
end

function generatetexture(width, height, depth)
    channels = 4
    flattexturedata = zeros(UInt8, width*height*depth*channels)
    texturedata = reshape(flattexturedata, (channels, depth, height, width))

    halfwidth = trunc(Int, width/2)
    halfheight = trunc(Int, height/2)
    halfdepth = trunc(Int, depth/2)

    # Fill each quadrant
    frontquadrant1 = @view texturedata[:, halfwidth+1:width    , halfheight+1:height    , 1:halfdepth]
    frontquadrant2 = @view texturedata[:,           1:halfwidth, halfheight+1:height    , 1:halfdepth]
    frontquadrant3 = @view texturedata[:,           1:halfwidth,            1:halfheight, 1:halfdepth]
    frontquadrant4 = @view texturedata[:, halfwidth+1:width    ,            1:halfheight, 1:halfdepth]

    backquadrant1  = @view texturedata[:, halfwidth+1:width    , halfheight+1:height    , halfdepth+1:depth]
    backquadrant2  = @view texturedata[:,           1:halfwidth, halfheight+1:height    , halfdepth+1:depth]
    backquadrant3  = @view texturedata[:,           1:halfwidth,            1:halfheight, halfdepth+1:depth]
    backquadrant4  = @view texturedata[:, halfwidth+1:width    ,            1:halfheight, halfdepth+1:depth]

    quadrantsize = (halfwidth, halfheight, halfdepth)
    fill!(frontquadrant1, quadrantsize, (255, 255, 255, 32))
    fill!(frontquadrant2, quadrantsize, (255,   0,   0, 255))
    fill!(frontquadrant3, quadrantsize, (  0, 255,   0, 255))
    fill!(frontquadrant4, quadrantsize, (  0,   0, 255, 255))

    fill!(backquadrant1, quadrantsize, (  0,   0,   0,   0))
    fill!(backquadrant2, quadrantsize, (255,   0, 255, 255))
    fill!(backquadrant3, quadrantsize, (  0, 255, 255, 255))
    fill!(backquadrant4, quadrantsize, (127, 255, 212, 255))

    # Fill the center with a yellow bar.
    barwidth = trunc(Int, width / 4)
    barheight = trunc(Int, width / 4)
    halfbarheight = trunc(Int, height / 8)
    halfbarwidth = trunc(Int, width / 8)
    halfbarheight = trunc(Int, height / 8)
    yellowbar = @view texturedata[:,
                                  halfwidth  - halfbarwidth  + 1:halfwidth  + halfbarwidth,
                                  halfheight - halfbarheight + 1:halfheight + halfbarheight,
                                  1:depth]
    fill!(yellowbar, (barwidth, barheight, depth), (255, 255, 0, 255))


    TextureDefinition3D(width, height, depth, flattexturedata)
end

function generatetextureold(width, height, depth)
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
                    a = UInt8(255)
                end

                push!(texturedata, r)
                push!(texturedata, g)
                push!(texturedata, b)
                push!(texturedata, a)
            end
        end
    end

    TextureDefinition3D(width, height, depth, texturedata)
end

function make3dtexture(texturedefinition::TextureDefinition3D)
    textureRef = Ref{GLuint}()
    glGenTextures(1, textureRef)
    textureid = textureRef[]

    glBindTexture(GL_TEXTURE_3D, textureid)

    glTexImage3D(GL_TEXTURE_3D,
                 0,
                 GL_RGBA,
                 texturedefinition.width,
                 texturedefinition.height,
                 texturedefinition.depth,
                 0,
                 GL_RGBA,
                 GL_UNSIGNED_BYTE,
                 texturedefinition.data)
    glGenerateMipmap(GL_TEXTURE_3D)

    glTexParameterf(GL_TEXTURE_3D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE)
    glTexParameterf(GL_TEXTURE_3D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE)
    glTexParameterf(GL_TEXTURE_3D, GL_TEXTURE_WRAP_R, GL_CLAMP_TO_EDGE)

    textureid
end

#
# A square to draw the texture on
# This square is defined as two triangles.
# Note that this makes it have 6 vertices rather than the 4 that you would
# normally think a square would have. 2 of the vertices are written down twice
# in the list of vertices below.
#

function squarevertices() :: MeshDefinition
    vertices = GLfloat[
        # Position                  # Texture coordinate
         0.5f0, -0.5f0,  0.5f0,     1.0f0, 0.0f0, 0.0f0, # Right bottom
         0.5f0,  0.5f0,  0.5f0,     1.0f0, 1.0f0, 0.0f0, # Right top
        -0.5f0,  0.5f0,  0.5f0,     0.0f0, 1.0f0, 0.0f0, # Left  top
         0.5f0, -0.5f0,  0.5f0,     1.0f0, 0.0f0, 0.0f0, # Right bottom
        -0.5f0,  0.5f0,  0.5f0,     0.0f0, 1.0f0, 0.0f0, # Left  top
        -0.5f0, -0.5f0,  0.5f0,     0.0f0, 0.0f0, 0.0f0, # Left  bottom
    ]

    # positionid corresponds to layout 0 in the vertex program:
    # layout (location = 0) in vec3 aPos;
    positionid = 0
    positionelements = 3 # The three first elements in each row in `vertices`
    positionattribute = MeshAttribute(positionid, positionelements, GL_FLOAT, GL_FALSE, C_NULL)

    # textureid corresponds to the layout 1 in the vertex program:
    # layout (location = 1) in vec3 aTextureCoordinate;
    textureid = 1

    # The texture coordinate has three elements
    nooftextureelements = 3 # the three last elements in each row in `vertices`

    # textureoffset is how many bytes into the vertices array that the texture starts at.
    # Before the texture starts, we have 3 vertex positions, and each vertex position is the size of a float.
    textureoffset = Ptr{Cvoid}(positionelements * sizeof(GLfloat))

    textureattribute = MeshAttribute(textureid, nooftextureelements, GL_FLOAT, GL_FALSE, textureoffset)

    attributes = [positionattribute, textureattribute]

    elementspervertex = positionelements + nooftextureelements
    MeshDefinition(
        vertices,
        elementspervertex,
        attributes
    )
end

#
# Main loop
#

function render(mesh::MeshBuffer, textureid::GLuint)
    glBindTexture(GL_TEXTURE_3D, textureid)
    glBindVertexArray(mesh.vao)
    glDrawArrays(GL_TRIANGLES, 0, mesh.numberofvertices)
end

function run()
    camera = Camera(1024, 800)

    # Create a window and its OpenGL context
    window = GLFW.CreateWindow(camera.windowwidth, camera.windowheight, "Julia 3D texture example")

    # Make the window's context current
    GLFW.MakeContextCurrent(window)

    glEnable(GL_BLEND)
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)
    glEnable(GL_DEPTH_TEST)

    # Create an OpenGL vertex array object, using the mesh defined in `squarevertices`.
    # This is essentially a square that the texture will be drawn on.
    mesh = makemeshbuffer(squarevertices())
    programid = makeprogram(vertexsource, fragmentsource)

    # Create a 64x64x64 3D texture that will be drawn onto the square above.
    texturedefinition = generatetexture(64, 64, 64)
    textureid = make3dtexture(texturedefinition)

    # Loop until the user closes the window
    while !GLFW.WindowShouldClose(window)
        glClearColor(0.0f0, 0.0f0, 0.0f0, 1.0f0)
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)

        # Set uniforms
        view = lookatfromfront()
        projection = perspective(camera)
        model = objectmodel()
        uniform(programid, "model", model)
        uniform(programid, "view", view)
        uniform(programid, "projection", projection)

        # Render here
        glUseProgram(programid)
        render(mesh, textureid)

        # Swap front and back buffers
        GLFW.SwapBuffers(window)

        # Poll for and process events
        GLFW.PollEvents()
    end

    GLFW.DestroyWindow(window)
end

run()