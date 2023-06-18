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

module ViewportAnimated09Visualization

using Alfar.Visualizer
using Alfar.Rendering.Meshs
using Alfar.Rendering.Shaders
using Alfar.Rendering.Textures

using ModernGL

function fill1d!(data, from, to, color)
    for i = from:to
        data[1, i] = UInt8(color[1])
        data[2, i] = UInt8(color[2])
        data[3, i] = UInt8(color[3])
        data[4, i] = UInt8(color[4])
    end
end

function generatetexturetransferfunction() :: TextureData{1}
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
    fill1d!(transfer, 225, 249, (  0,   0, 255, 255))

    # Yellow bar
    fill1d!(transfer, 250, 256, (255, 255,   0, 255))

    TextureData{1}(flattransfer, width)
end

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
    yellowbar = @view texturedata[halfwidth  - halfbarwidth  + 1:halfwidth  + halfbarwidth,
                                  halfheight - halfbarheight + 1:halfheight + halfbarheight,
                                  1:depth]
    fillintensity!(yellowbar, (barwidth, barheight, depth), 255)


    TextureData{3}(flattexturedata, width, height, depth)
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
struct Slices
    quads::Vector{MeshBuffer}
end

function render(mesh::MeshBuffer, textureid::GLuint, transfertextureid::GLuint)
    glBindTexture(GL_TEXTURE_3D, textureid)
    glBindTexture(GL_TEXTURE_1D, transfertextureid)
    glBindVertexArray(mesh.vao)
    glDrawArrays(GL_TRIANGLES, 0, mesh.numberofvertices)
end


function render(slices::Slices, textureid::GLuint, transfertextureid::GLuint)
    for quad in slices.quads
        render(quad, textureid, transfertextureid)
    end
end

struct ViewportAnimated09 <: Visualization
    program::ShaderProgram
    volumetexture::Texture{3}
    transfertexture::Texture{1}
    slices::Slices

    function ViewportAnimated09()
        program = ShaderProgram("shaders/visualization/basic3dvertex.glsl", "shaders/visualization/fragment1dtransfer.glsl")
        volumetexture = Texture{3}(generate3dintensitytexture(256, 256, 256))
        transfertexture = Texture{1}(generatetexturetransferfunction())

        cubedepth = 1.0f0
        numberofslices = 20
        distancebetweenslices = cubedepth / numberofslices

        quads = [MeshBuffer(squarevertices(z, z + 0.5f0)) for z in 0.5f0:-distancebetweenslices:-0.5f0]
        slices = Slices(quads)

        new(program, volumetexture, transfertexture, slices)
    end
end

function Visualizer.setflags(::ViewportAnimated09)
    println("setflags ViewportAnimated09")
    glEnable(GL_BLEND)
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)
    glEnable(GL_DEPTH_TEST)
    glEnable(GL_TEXTURE_1D)
end

function Visualizer.setup(::ViewportAnimated09)
    println("setup ViewportAnimated09")
end

function Visualizer.render(v::ViewportAnimated09)
    render(v.slices, v.volumetexture.textureid, v.transfertexture.textureid)
end
end