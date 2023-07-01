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

struct IntersectingPlane
    program::ShaderProgram
    color::NTuple{4, Float32}

    IntersectingPlane() = new(
        Program("shaders/visualization/mvp3dvertex.glsl", "shaders/visualization/uniformcolorfragment.glsl"),
        (0f0, 0f0, 1f0, 0.2f0))
end

function render(plane::IntersectingPlane, camera::Camera, camerastate::CameraState, distance::Float64)
    use(plane.program)

    # Camera transforms
    view = lookat(camerastate)
    projection = perspective(camera)
    model = objectmodel()
    uniform(v.program, "model", model)
    uniform(v.program, "view", view)
    uniform(v.program, "projection", projection)

    uniform(plane.program, "color", plane.color)
end

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

    fill1d!(transfer,  1, (  255,   0,   0,   255)) # RED
    fill1d!(transfer,  2, (    0, 255,   0,   255)) # GREEN
    fill1d!(transfer,  3, (    0,   0, 255,   255)) # BLUE
    fill1d!(transfer,  4, (   64,   0,   0,   255)) # LOW RED
    fill1d!(transfer,  5, (    0,  64,   0,   255)) # LOW GREEN
    fill1d!(transfer,  6, (    0,   0,  64,   255)) # LOW BLUE
    fill1d!(transfer,  7, (  255, 255,   0,   255)) # YELLOW
    fill1d!(transfer,  8, (  255, 255,   0,   255)) # YELLOW
    fill1d!(transfer,  9, (  255, 255,   0,   255)) # YELLOW
    fill1d!(transfer, 10, (  255, 255,   0,   255)) # YELLOW
    fill1d!(transfer, 11, (  255, 255,   0,   255)) # YELLOW
    fill1d!(transfer, 12, (  255, 255,   0,   255)) # YELLOW
    fill1d!(transfer, 13, (  255, 255,   0,   255)) # YELLOW
    fill1d!(transfer, 14, (  255, 255,   0,   255)) # YELLOW
    fill1d!(transfer, 15, (  255, 255,   0,   255)) # YELLOW
    fill1d!(transfer, 16, (  255, 255,   0,   255)) # YELLOW

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
             0.5f0, -0.5f0, -0.5f0, # Right bottom front
             0.5f0,  0.5f0, -0.5f0, # Right top    front

             0.5f0,  0.5f0, -0.5f0, # Right top    front
            -0.5f0,  0.5f0, -0.5f0, # Left  top    front

            -0.5f0,  0.5f0, -0.5f0, # Left  top    front
            -0.5f0, -0.5f0, -0.5f0, # Left  bottom front

            -0.5f0, -0.5f0, -0.5f0, # Left  bottom front
             0.5f0, -0.5f0, -0.5f0, # Right bottom front

            # Lines from front to back
             0.5f0, -0.5f0, -0.5f0, # Right bottom front
             0.5f0, -0.5f0,  0.5f0, # Right bottom back

             0.5f0,  0.5f0, -0.5f0, # Right top    front
             0.5f0,  0.5f0,  0.5f0, # Right top    back

            -0.5f0,  0.5f0, -0.5f0, # Left  top    front
            -0.5f0,  0.5f0,  0.5f0, # Left  top    back

            -0.5f0, -0.5f0, -0.5f0, # Left  bottom front
            -0.5f0, -0.5f0,  0.5f0, # Left  bottom back

            # Lines from back right bottom, around, counterclockwise
             0.5f0, -0.5f0,  0.5f0, # Right bottom back
             0.5f0,  0.5f0,  0.5f0, # Right top    back

             0.5f0,  0.5f0,  0.5f0, # Right top    back
            -0.5f0,  0.5f0,  0.5f0, # Left  top    back

            -0.5f0,  0.5f0,  0.5f0, # Left  top    back
            -0.5f0, -0.5f0,  0.5f0, # Left  bottom back

            -0.5f0, -0.5f0,  0.5f0, # Left  bottom back
             0.5f0, -0.5f0,  0.5f0, # Right bottom back
        ]
        wireframecolors = GLint[
            # Lines from front right bottom, around, counterclockwise
            1, 1, # GREEN     # v0 -> v2 # Right bottom front -> Right top front
            2, 2, # BLUE      # v0 -> v3 # Right top    front -> Left  top    front
            2, 2, # BLUE      # v3 -> v6 # Left  top    front -> Left  bottom front
            4, 4, # LOW GREEN # v2 -> v6 # Left  bottom front -> Right bottom front

            # Lines from front to back
            1, 1, # GREEN # v2 -> v5 # Right bottom front -> Right bottom back
            0, 0, # RED       # v0 -> v1 # Right top    front -> Right top    back
            5, 5, # LOW BLUE  # v3 -> v4 # Left  top    front -> Left  top    back
            2, 2, # BLUE      # v6 -> v7 # Left  bottom front -> Left  bottom back

            # Lines from back right bottom, around, counterclockwise
            3, 3, # LOW RED   # v1 -> v5 # Right bottom back -> Right top    back
            0, 0, # RED       # v1 -> v4 # Right top    back -> Left  top    back
            0, 0, # RED       # v4 -> v7 # Left  top    back -> Left  bottom back
            1, 1, # GREEN     # v5 -> v7 # Left  bottom back -> Right bottom back
        ]

        positionattribute = VertexAttribute(0, 3, GL_FLOAT, GL_FALSE, C_NULL)
        wireframedata = VertexData{GLfloat}(wireframevertices, VertexAttribute[positionattribute])

        colorattribute = VertexAttribute(1, 1, GL_INT, GL_FALSE, C_NULL)
        wireframecolordata = VertexData{GLint}(wireframecolors, VertexAttribute[colorattribute])

        wireframe = VertexArray{GL_LINES}(wireframedata, wireframecolordata)

        wireframetexture = Texture{1}(makewireframetexture())

        new(program, wireframe, wireframetexture)
    end
end

struct ViewportAlignmentState <: Visualizer.VisualizationState
    distance::Float64
end

function Visualizer.setflags(::ViewportAlignment)
end

Visualizer.setup(::ViewportAlignment) = ViewportAlignmentState(0f0)
Visualizer.update(::ViewportAlignment, state::ViewportAlignmentState) = state

function Visualizer.onmousescroll(::ViewportAlignment, state::ViewportAlignmentState, (xoffset, yoffset)::Tuple{Float64, Float64})
    ViewportAlignmentState(state.distance + yoffset / 10f0)
end

function Visualizer.render(camera::Camera, v::ViewportAlignment, ::ViewportAlignmentState)
    # Camera position
    # The first view sees the object from the front.
    originalcameraposition = CameraPosition((0f0, 0f0, -3f0), (0f0, 1f0, 0f0))

    camerastate = CameraState(originalcameraposition, (0f0, 0f0, 0f0))

    zangle = 1f0 * pi / 8f0
    viewtransform1 = rotatez(0f0) * rotatey(0f0)
    viewtransform2 = rotatez(zangle) * rotatey(- 5f0 * pi / 16f0)
    camerastateviewport1 = transform(camerastate, viewtransform1)
    camerastateviewport2 = transform(camerastate, viewtransform2)

    #
    # Viewport 1 (left)
    #
    glViewport(0, 0, camera.windowwidth, camera.windowheight)

    view = lookat(camerastateviewport1)
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

    view = lookat(camerastateviewport2)
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