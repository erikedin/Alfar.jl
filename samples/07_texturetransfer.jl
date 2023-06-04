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

include("commonsample.jl")

#
# Shader sources
#

vertexsource = """
#version 420 core

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
#version 420 core

in vec3 TexCoord;
out vec4 FragColor;

layout (binding = 0) uniform sampler3D mytexture;
layout (binding = 1) uniform sampler1D transfer;

void main()
{
    vec4 intensity = texture(mytexture, TexCoord);
    FragColor = texture(transfer, intensity.r);
}
"""

#
# Generate a 3D texture
# The size needs to be a multiple of two at each dimension.
# Making it a square 64x64x64 pixel texture.
#

function fillintensity!(data, (width, height, depth), color)
   for x = 1:width
        for y = 1:height
            for z = 1:depth
                data[x, y, z] = UInt8(color)
            end
        end
    end
end

# This defines a 3D texture with a single channel of intensity, rather than a color
# as in the previous samples. The transfer function in the fragment shader converts these
# intensities to colors.
function generate3dintensitytexture(width, height, depth)
    flattexturedata = zeros(UInt8, width*height*depth)
    texturedata = reshape(flattexturedata, (depth, height, width))

    halfwidth = trunc(Int, width/2)
    halfheight = trunc(Int, height/2)
    halfdepth = trunc(Int, depth/2)

    # Fill each quadrant
    frontquadrant1 = @view texturedata[halfwidth+1:width    , halfheight+1:height    , 1:halfdepth]
    frontquadrant2 = @view texturedata[          1:halfwidth, halfheight+1:height    , 1:halfdepth]
    frontquadrant3 = @view texturedata[          1:halfwidth,            1:halfheight, 1:halfdepth]
    frontquadrant4 = @view texturedata[halfwidth+1:width    ,            1:halfheight, 1:halfdepth]

    backquadrant1  = @view texturedata[halfwidth+1:width    , halfheight+1:height    , halfdepth+1:depth]
    backquadrant2  = @view texturedata[          1:halfwidth, halfheight+1:height    , halfdepth+1:depth]
    backquadrant3  = @view texturedata[          1:halfwidth,            1:halfheight, halfdepth+1:depth]
    backquadrant4  = @view texturedata[halfwidth+1:width    ,            1:halfheight, halfdepth+1:depth]

    quadrantsize = (halfwidth, halfheight, halfdepth)
    fillintensity!(backquadrant1, quadrantsize, 16)
    fillintensity!(backquadrant2, quadrantsize, 48)
    fillintensity!(backquadrant3, quadrantsize, 80)
    fillintensity!(backquadrant4, quadrantsize, 112)

    fillintensity!(frontquadrant1, quadrantsize, 144)
    fillintensity!(frontquadrant2, quadrantsize, 176)
    fillintensity!(frontquadrant3, quadrantsize, 208)
    fillintensity!(frontquadrant4, quadrantsize, 240)

    # Fill the center with a yellow bar.
    barwidth = trunc(Int, width / 4)
    barheight = trunc(Int, width / 4)
    halfbarheight = trunc(Int, height / 8)
    halfbarwidth = trunc(Int, width / 8)
    halfbarheight = trunc(Int, height / 8)
    yellowbar = @view texturedata[halfwidth  - halfbarwidth  + 1:halfwidth  + halfbarwidth,
                                  halfheight - halfbarheight + 1:halfheight + halfbarheight,
                                  1:depth]
    fillintensity!(yellowbar, (barwidth, barheight, depth), 255)


    TextureDefinition3D(width, height, depth, flattexturedata)
end

function make3dtexture(texturedefinition::TextureDefinition3D)
    glActiveTexture(GL_TEXTURE0)

    textureRef = Ref{GLuint}()
    glGenTextures(1, textureRef)
    textureid = textureRef[]

    glBindTexture(GL_TEXTURE_3D, textureid)

    glTexImage3D(GL_TEXTURE_3D,
                 0,
                 GL_RED,
                 texturedefinition.width,
                 texturedefinition.height,
                 texturedefinition.depth,
                 0,
                 GL_RED,
                 GL_UNSIGNED_BYTE,
                 texturedefinition.data)
    glGenerateMipmap(GL_TEXTURE_3D)

    glTexParameterf(GL_TEXTURE_3D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE)
    glTexParameterf(GL_TEXTURE_3D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE)
    glTexParameterf(GL_TEXTURE_3D, GL_TEXTURE_WRAP_R, GL_CLAMP_TO_EDGE)

    textureid
end

struct TextureDefinition1D
    width::Int
    data
end

function fill1d!(data, from, to, color)
    for i = from:to
        data[1, i] = UInt8(color[1])
        data[2, i] = UInt8(color[2])
        data[3, i] = UInt8(color[3])
        data[4, i] = UInt8(color[4])
    end
end

function generatetexturetransferfunction() :: TextureDefinition1D
    # The transfer function that calculates colors from intensities
    # is moved here from the fragment shader. The fragment shader
    # can now be re-used for different transfer functions by
    # binding a different 1D texture.
    channels = 4
    width = 256

    flattransfer = zeros(UInt8, channels*width)
    transfer = reshape(flattransfer, (channels, width))

    # Back octant 1, transparent
    fill1d!(transfer, 1, 32,   (  0,   0,   0,   0))
    # Back octant 2
    fill1d!(transfer, 33, 64,  (255,   0, 255, 255))
    # Back octant 3
    fill1d!(transfer, 65, 96,  (  0, 255, 255, 255))
    # Back octant 4
    fill1d!(transfer, 97, 128, (127, 255, 212, 255))

    # Front octant 1
    fill1d!(transfer, 129, 160, (255, 255, 255,  64))
    # Front octant 2
    fill1d!(transfer, 161, 192, (255,   0,   0, 255))
    # Front octant 3
    fill1d!(transfer, 193, 224, (  0, 255,   0, 255))
    # Front octant 4
    fill1d!(transfer, 225, 254, (  0,   0, 255, 255))

    # Yellow bar
    fill1d!(transfer, 255, 255, (255, 255,   0, 255))

    TextureDefinition1D(width, flattransfer)
end

function maketransfertexture(texturedefinition::TextureDefinition1D)
    glActiveTexture(GL_TEXTURE1)

    textureRef = Ref{GLuint}()
    glGenTextures(1, textureRef)
    textureid = textureRef[]

    glBindTexture(GL_TEXTURE_1D, textureid)

    glTexImage1D(GL_TEXTURE_1D,
                 0,
                 GL_RGBA,
                 texturedefinition.width,
                 0,
                 GL_RGBA,
                 GL_UNSIGNED_BYTE,
                 texturedefinition.data)
    glGenerateMipmap(GL_TEXTURE_1D)

    glTexParameterf(GL_TEXTURE_1D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE)

    textureid
end

# vertexz is the Z coordinate of the vertex.
# texr is the corresponding coordinate of the texture.
# However, the texture coordinate varies in the range [0, 1],
# while the vertex coordinate varies from [-0.5, 0.5].
function squarevertices(vertexz, texr) :: MeshDefinition
    vertices = GLfloat[
        # Position             # Texture coordinate
         0.5f0, -0.5f0, vertexz,  1.0f0, 0.0f0, texr, # Right bottom
         0.5f0,  0.5f0, vertexz,  1.0f0, 1.0f0, texr, # Right top
        -0.5f0,  0.5f0, vertexz,  0.0f0, 1.0f0, texr, # Left  top
         0.5f0, -0.5f0, vertexz,  1.0f0, 0.0f0, texr, # Right bottom
        -0.5f0,  0.5f0, vertexz,  0.0f0, 1.0f0, texr, # Left  top
        -0.5f0, -0.5f0, vertexz,  0.0f0, 0.0f0, texr, # Left  bottom
    ]

    # positionid corresponds to layout 0 in the vertex program:
    # layout (location = 0) in vec3 aPos;
    positionid = 0
    positionelements = 3 # The three first elements in each row in `vertices`
    positionattribute = MeshAttribute(positionid, positionelements, GL_FLOAT, GL_FALSE, C_NULL)

    # textureid corresponds to the layout 1 in the vertex program:
    # layout (location = 1) in vec3 aTextureCoordinate;
    textureid = 1

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

function render(mesh::MeshBuffer, textureid::GLuint, transfertextureid::GLuint)
    glBindTexture(GL_TEXTURE_3D, textureid)
    glBindTexture(GL_TEXTURE_1D, transfertextureid)
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
    quads::Vector{MeshBuffer}
end

function render(slices::Slices, textureid::GLuint, transfertextureid::GLuint)
    for quad in slices.quads
        render(quad, textureid, transfertextureid)
    end
end

function run()
    camera = Camera(1024, 800)

    # Create a window and its OpenGL context
    window = GLFW.CreateWindow(camera.windowwidth, camera.windowheight, "Julia sliced 3D texture example")

    # # Make the window's context current
    GLFW.MakeContextCurrent(window)

    glEnable(GL_BLEND)
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)
    glEnable(GL_DEPTH_TEST)
    glEnable(GL_TEXTURE_1D)

    cubedepth = 1.0f0
    numberofslices = 20
    distancebetweenslices = cubedepth / numberofslices

    quads = [makemeshbuffer(squarevertices(z, z + 0.5f0)) for z in 0.5f0:-distancebetweenslices:-0.5f0]
    slices = Slices(quads)

    programid = makeprogram(vertexsource, fragmentsource)
    # Create a 256x256x256 3D texture that will be drawn onto the square above.
    texturedefinition = generate3dintensitytexture(256, 256, 256)
    textureid = make3dtexture(texturedefinition)

    # Create the 1D lookup texture which defines the transfer function
    transfertexture = generatetexturetransferfunction()
    transfertextureid = maketransfertexture(transfertexture)

    timeofstart = time()

    # Camera position
    # We'd like to see the volume from above and to the side, to see the transparency in effect.
    # Rotate it pi/4 radians along X, and then Y.
    originalcameraposition = CameraPosition((0f0, 0f0, -3f0), (0f0, 1f0, 0f0))
    t = rotatey(-5f0 * pi / 16f0) * rotatex(pi / 8f0)
    cameraposition = transform(originalcameraposition, t)


    # Loop until the user closes the window
    while !GLFW.WindowShouldClose(window)
        glClearColor(0.0f0, 0.0f0, 0.0f0, 1.0f0)
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)

        # Set uniforms
        cameratarget = (0f0, 0f0, 0f0)
        view = lookat(cameraposition, cameratarget)
        projection = perspective(camera)
        model = objectmodel()
        uniform(programid, "model", model)
        uniform(programid, "view", view)
        uniform(programid, "projection", projection)

        # Render here
        glUseProgram(programid)
        render(slices, textureid, transfertextureid)

        # Swap front and back buffers
        GLFW.SwapBuffers(window)

        # Poll for and process events
        GLFW.PollEvents()
    end

    GLFW.DestroyWindow(window)
end

run()