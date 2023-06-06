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
# Making it a square 64x64x64 pixel texture.
#

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

function render(mesh::MeshBuffer, textureid::GLuint)
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
    quads::Vector{MeshBuffer}
end

function render(slices::Slices, textureid::GLuint)
    for quad in slices.quads
        render(quad, textureid)
    end
end

function run()
    camera = Camera(1024, 800)

    # Create a window and its OpenGL context
    window = GLFW.CreateWindow(camera.windowwidth, camera.windowheight, "Alfar Sample 05: Multiple slices")

    # Make the window's context current
    GLFW.MakeContextCurrent(window)

    glEnable(GL_BLEND)
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)
    glEnable(GL_DEPTH_TEST)

    cubedepth = 1.0f0
    numberofslices = 20
    distancebetweenslices = cubedepth / numberofslices

    quads = [makemeshbuffer(squarevertices(z, z + 0.5f0)) for z in 0.5f0:-distancebetweenslices:-0.5f0]
    slices = Slices(quads)

    programid = makeprogram(vertexsource, fragmentsource)
    # Create a 256x256x256 3D texture that will be drawn onto the square above.
    texturedefinition = generate3dtexture(256, 256, 256)
    textureid = make3dtexture(texturedefinition)

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
        render(slices, textureid)

        # Swap front and back buffers
        GLFW.SwapBuffers(window)

        # Poll for and process events
        GLFW.PollEvents()
    end

    GLFW.DestroyWindow(window)
end

run()