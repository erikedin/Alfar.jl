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

module ViewportAlignmentAlgorithm

using ModernGL

using Alfar.Visualizer
using Alfar.Rendering.Cameras
using Alfar.Rendering.Shaders
using Alfar.Rendering.Meshs
using Alfar.Rendering.Textures

function fill1d!(data, i, color)
    data[1, i] = UInt8(color[1])
    data[2, i] = UInt8(color[2])
    data[3, i] = UInt8(color[3])
    data[4, i] = UInt8(color[4])
end

function makewireframetexture() :: TextureData{1}
    channels = 4
    # We need at most 12 colors, because there are 12 edges in a cube wireframe,
    # but use 16 because it's the closest larger power of two.
    width = 16

    flattransfer = zeros(UInt8, channels*width)
    transfer = reshape(flattransfer, (channels, width))

    fill1d!(transfer,  1, (  255,  20, 147,   255)) # DEEP PINK
    fill1d!(transfer,  2, (    0, 255,   0,   255)) # GREEN
    fill1d!(transfer,  3, (    0,   0, 255,   255)) # BLUE
    fill1d!(transfer,  4, (  255, 255,   0,   255)) # YELLOW
    fill1d!(transfer,  5, (  255,   0, 255,   255)) # FUCHSIA
    fill1d!(transfer,  6, (    0, 255, 255,   255)) # AQUA
    fill1d!(transfer,  7, (  128,   0,   0,   255)) # MAROON
    fill1d!(transfer,  8, (  128, 128,   0,   255)) # OLIVE
    fill1d!(transfer,  9, (  255, 165,   0,   255)) # ORANGE
    fill1d!(transfer, 10, (  255,   0,   0,   255)) # RED
    fill1d!(transfer, 11, (    0,   0, 255,   255)) # BLUE AGAIN
    fill1d!(transfer, 12, (    0, 128,   0,   255)) # LOW GREEN
    fill1d!(transfer, 13, (    0,   0, 128,   255)) # LOW BLUE
    fill1d!(transfer, 14, (    0, 128, 128,   255)) # TEAL
    fill1d!(transfer, 15, (  255, 255, 255,   255)) # WHITE
    fill1d!(transfer, 16, (  128, 128, 128,   255)) # GRAY

    TextureData{1}(flattransfer, width)
end

struct ViewportAlignment <: Visualizer.Visualization
    program::Union{Nothing, ShaderProgram}
    wireframe::VertexArray{GL_LINES}
    wireframetexture::Texture{1}

    function ViewportAlignment()
        program = ShaderProgram("shaders/visualization/vertexdiscrete3d.glsl",
                                "shaders/visualization/fragmentdiscrete1dtransfer.glsl")

        wireframevertices = GLfloat[
            # Lines from front right bottom, around, counterclockwise
             0.5f0, -0.5f0, -0.5f0, # Right bottom front # DEEP PINK
             0.5f0,  0.5f0, -0.5f0, # Right top    front

             0.5f0,  0.5f0, -0.5f0, # Right top    front # GREEN
            -0.5f0,  0.5f0, -0.5f0, # Left  top    front

            -0.5f0,  0.5f0, -0.5f0, # Left  top    front # BLUE
            -0.5f0, -0.5f0, -0.5f0, # Left  bottom front

            -0.5f0, -0.5f0, -0.5f0, # Left  bottom front # YELLOW
             0.5f0, -0.5f0, -0.5f0, # Right bottom front

            # Lines from front to back
             0.5f0, -0.5f0, -0.5f0, # Right bottom front # FUCHSIA
             0.5f0, -0.5f0,  0.5f0, # Right bottom back

             0.5f0,  0.5f0, -0.5f0, # Right top    front # AQUA
             0.5f0,  0.5f0,  0.5f0, # Right top    back

            -0.5f0,  0.5f0, -0.5f0, # Left  top    front # MAROON
            -0.5f0,  0.5f0,  0.5f0, # Left  top    back

            -0.5f0, -0.5f0, -0.5f0, # Left  bottom front # OLIVE
            -0.5f0, -0.5f0,  0.5f0, # Left  bottom back

            # Lines from back right bottom, around, counterclockwise
             0.5f0, -0.5f0,  0.5f0, # Right bottom back # ORANGE
             0.5f0,  0.5f0,  0.5f0, # Right top    back

             0.5f0,  0.5f0,  0.5f0, # Right top    back # RED
            -0.5f0,  0.5f0,  0.5f0, # Left  top    back

            -0.5f0,  0.5f0,  0.5f0, # Left  top    back # BLUE
            -0.5f0, -0.5f0,  0.5f0, # Left  bottom back

            -0.5f0, -0.5f0,  0.5f0, # Left  bottom back # LOW GREEN
             0.5f0, -0.5f0,  0.5f0, # Right bottom back
        ]
        wireframecolors = GLint[
            0, 0, 1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6, 7, 7, 8, 8, 9, 9, 10, 10, 11, 11
        ]

        #numberofelementspervertex = 3
        #attributetype = GL_FLOAT
        #positionattribute = MeshAttribute(0, numberofelementspervertex, attributetype, GL_FALSE, C_NULL)
        #meshdefinition = MeshDefinition(wireframevertices, numberofelementspervertex, [positionattribute])
        #mesh = MeshBuffer(meshdefinition)

        positionattribute = VertexAttribute(0, 3, GL_FLOAT, GL_FALSE, C_NULL)
        wireframedata = VertexData{GLfloat}(wireframevertices, VertexAttribute[positionattribute])

        colorattribute = VertexAttribute(1, 1, GL_INT, GL_FALSE, C_NULL)
        wireframecolordata = VertexData{GLint}(wireframecolors, VertexAttribute[colorattribute])

        wireframe = VertexArray{GL_LINES}(wireframedata, wireframecolordata)

        wireframetexture = Texture{1}(makewireframetexture())
        #bordercolor = GLfloat[1f0, 0f0, 0f0, 1f0]
        #glTexParameterfv(GL_TEXTURE_1D, GL_TEXTURE_BORDER_COLOR, Ref(bordercolor, 1))
        #glTexParameterf(GL_TEXTURE_1D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_BORDER)
        #glTexParameterf(GL_TEXTURE_1D, GL_TEXTURE_MIN_FILTER, GL_NEAREST)

        new(program, wireframe, wireframetexture)
    end
end

struct ViewportAlignmentState <: Visualizer.VisualizationState end

function Visualizer.setflags(::ViewportAlignment)
    #glEnable(GL_BLEND)
    #glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)
    #glEnable(GL_DEPTH_TEST)
    #glEnable(GL_TEXTURE_1D)
end

Visualizer.setup(::ViewportAlignment) = ViewportAlignmentState()
Visualizer.update(::ViewportAlignment, ::ViewportAlignmentState) = ViewportAlignmentState()

function Visualizer.render(camera::Camera, v::ViewportAlignment, ::ViewportAlignmentState)
    # Camera position
    # The first view sees the object from the front.
    originalcameraposition = CameraPosition((0f0, 0f0, -3f0), (0f0, 1f0, 0f0))

    zangle = 1f0 * pi / 8f0
    viewtransform1 = rotatez(0f0) * rotatey(0f0)
    viewtransform2 = rotatez(zangle) * rotatey(- 5f0 * pi / 16f0)
    camerapositionviewport1 = transform(originalcameraposition, viewtransform1)
    camerapositionviewport2 = transform(originalcameraposition, viewtransform2)

    #
    # Viewport 1 (left)
    #
    glViewport(0, 0, camera.windowwidth, camera.windowheight)

    cameratarget = (0f0, 0f0, 0f0)
    view = lookat(camerapositionviewport1, cameratarget)
    projection = perspective(camera)
    model = objectmodel()
    uniform(v.program, "model", model)
    uniform(v.program, "view", view)
    uniform(v.program, "projection", projection)

    use(v.program)
    glBindTexture(GL_TEXTURE_1D, v.wireframetexture.textureid)
    renderarray(v.wireframe)

    #
    # Viewport 2 (right)
    #
    glViewport(camera.windowwidth, 0, camera.windowwidth, camera.windowheight)

    cameratarget = (0f0, 0f0, 0f0)
    view = lookat(camerapositionviewport2, cameratarget)
    projection = perspective(camera)
    model = objectmodel()
    uniform(v.program, "model", model)
    uniform(v.program, "view", view)
    uniform(v.program, "projection", projection)

    use(v.program)
    glBindTexture(GL_TEXTURE_1D, v.wireframetexture.textureid)
    renderarray(v.wireframe)
end

end