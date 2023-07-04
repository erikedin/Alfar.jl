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
using Alfar.Visualizer: MouseDragEndEvent, MouseDragPositionEvent
using Alfar.Rendering.Cameras
using Alfar.Rendering.Shaders
using Alfar.Rendering.Meshs
using Alfar.Rendering.Textures

struct IntersectingPlane
    program::ShaderProgram
    color::NTuple{4, Float32}
    planevertices::VertexArray{GL_TRIANGLES}

    function IntersectingPlane()
        program = ShaderProgram("shaders/visualization/vertex3dplane.glsl", "shaders/visualization/uniformcolorfragment.glsl")
        color = (0f0, 0f0, 1f0, 0.2f0)

        vertices = GLfloat[
            # Lines from front right bottom, around, counterclockwise
             1.0f0, -1.0f0, # Right bottom
             1.0f0,  1.0f0, # Right top
            -1.0f0,  1.0f0, # Left top

             1.0f0, -1.0f0, # Right bottom
            -1.0f0,  1.0f0, # Left top
            -1.0f0, -1.0f0, # Left bottom
        ]
        attribute = VertexAttribute(0, 2, GL_FLOAT, GL_FALSE, C_NULL)
        vertexdata = VertexData{GLfloat}(vertices, VertexAttribute[attribute])
        planevertices = VertexArray{GL_TRIANGLES}(vertexdata)

        new(program, color, planevertices)
    end
end

function render(plane::IntersectingPlane, camera::Camera, camerastate::CameraState, distance::Float32)
    use(plane.program)

    projection = perspective(camera)
    model = objectmodel()
    view = lookat(camerastate)
    uniform(plane.program, "projection", projection)
    uniform(plane.program, "view", view)
    uniform(plane.program, "model", model)

    uniform(plane.program, "distance", distance)
    uniform(plane.program, "color", plane.color)

    renderarray(plane.planevertices)
end

struct XYZMarker
    program::ShaderProgram
    lines::VertexArray{GL_LINES}

    function XYZMarker()
        program = ShaderProgram("shaders/visualization/vertex3dcolorlines.glsl", "shaders/visualization/fragmentcolorfromvertex.glsl")

        vertices = GLfloat[
            # X            # RED
            0f0, 0f0, 0f0, 1f0, 0f0, 0f0, 1f0,
            1f0, 0f0, 0f0, 1f0, 0f0, 0f0, 1f0,

            # Y            # GREEN
            0f0, 0f0, 0f0, 0f0, 1f0, 0f0, 1f0,
            0f0, 1f0, 0f0, 0f0, 1f0, 0f0, 1f0,

            # Z            # BLUE
            0f0, 0f0, 0f0, 0f0, 0f0, 1f0, 1f0,
            0f0, 0f0, 1f0, 0f0, 0f0, 1f0, 1f0,
        ]
        attribute = VertexAttribute(0, 3, GL_FLOAT, GL_FALSE, C_NULL)
        coloroffset = Ptr{Cvoid}(3 * sizeof(GLfloat))
        colorattribute = VertexAttribute(1, 4, GL_FLOAT, GL_FALSE, coloroffset)
        vertexdata = VertexData{GLfloat}(vertices, VertexAttribute[attribute, colorattribute])
        lines = VertexArray{GL_LINES}(vertexdata)

        new(program, lines)
    end
end

function render(marker::XYZMarker, camera::Camera, camerastate::CameraState)
    use(marker.program)

    projection = perspective(camera)
    model = objectmodel()
    view = lookat(camerastate)

    uniform(marker.program, "projection", projection)
    uniform(marker.program, "view", view)
    uniform(marker.program, "model", model)

    renderarray(marker.lines)
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
    plane::IntersectingPlane
    marker::XYZMarker

    function ViewportAlignment()
        program = ShaderProgram("shaders/visualization/vertexdiscrete3d.glsl",
                                "shaders/visualization/fragmentdiscrete1dtransfer.glsl")

        wireframevertices = GLfloat[
            # Lines from front right bottom, around, counterclockwise
             0.5f0, -0.5f0,  0.5f0, # Right bottom front
             0.5f0,  0.5f0,  0.5f0, # Right top    front

             0.5f0,  0.5f0,  0.5f0, # Right top    front
            -0.5f0,  0.5f0,  0.5f0, # Left  top    front

            -0.5f0,  0.5f0,  0.5f0, # Left  top    front
            -0.5f0, -0.5f0,  0.5f0, # Left  bottom front

            -0.5f0, -0.5f0,  0.5f0, # Left  bottom front
             0.5f0, -0.5f0,  0.5f0, # Right bottom front

            # Lines from front to back
             0.5f0, -0.5f0,  0.5f0, # Right bottom front
             0.5f0, -0.5f0, -0.5f0, # Right bottom back

             0.5f0,  0.5f0,  0.5f0, # Right top    front
             0.5f0,  0.5f0, -0.5f0, # Right top    back

            -0.5f0,  0.5f0,  0.5f0, # Left  top    front
            -0.5f0,  0.5f0, -0.5f0, # Left  top    back

            -0.5f0, -0.5f0,  0.5f0, # Left  bottom front
            -0.5f0, -0.5f0, -0.5f0, # Left  bottom back

            # Lines from back right bottom, around, counterclockwise
             0.5f0, -0.5f0, -0.5f0, # Right bottom back
             0.5f0,  0.5f0, -0.5f0, # Right top    back

             0.5f0,  0.5f0, -0.5f0, # Right top    back
            -0.5f0,  0.5f0, -0.5f0, # Left  top    back

            -0.5f0,  0.5f0, -0.5f0, # Left  top    back
            -0.5f0, -0.5f0, -0.5f0, # Left  bottom back

            -0.5f0, -0.5f0, -0.5f0, # Left  bottom back
             0.5f0, -0.5f0, -0.5f0, # Right bottom back
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

        new(program, wireframe, wireframetexture, IntersectingPlane(), XYZMarker())
    end
end

struct ViewportAlignmentState <: Visualizer.VisualizationState
    distance::Float64
    camerastate::CameraState
    planecamerastate::CameraState
    cameratransform::Matrix{GLfloat}
    boxtransform::Matrix{GLfloat}
    dragtransform::Matrix{GLfloat}
end

function camerastate(v::ViewportAlignmentState)
    #transform(v.camerastate, v.cameratransform * v.dragtransform)
    transform(v.camerastate, v.cameratransform)
end

planecamerastate(v::ViewportAlignmentState) = v.planecamerastate

function Visualizer.setflags(::ViewportAlignment)
    glEnable(GL_BLEND)
    glEnable(GL_DEPTH_TEST)
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)
end

function Visualizer.setup(::ViewportAlignment)
    originalcameraposition = CameraPosition((0f0, 0f0, 3f0), (0f0, 1f0, 0f0))
    camerastate = CameraState(originalcameraposition, (0f0, 0f0, 0f0))
    planecamerastate = CameraState(originalcameraposition, (0f0, 0f0, 0f0))
    cameratransform = identitytransform()

    ViewportAlignmentState(0f0, camerastate, planecamerastate, cameratransform, identitytransform(), identitytransform())
end

Visualizer.update(::ViewportAlignment, state::ViewportAlignmentState) = state

function Visualizer.onmousescroll(::ViewportAlignment, state::ViewportAlignmentState, (xoffset, yoffset)::Tuple{Float64, Float64})
    newdistance = state.distance + yoffset / 20.0
    ViewportAlignmentState(newdistance, state.camerastate, state.planecamerastate, state.cameratransform, state.boxtransform, state.dragtransform)
end

function Visualizer.onmousedrag(::ViewportAlignment, state::ViewportAlignmentState, ::MouseDragEndEvent)
    println("Drag: End")
    newboxtransform = state.dragtransform * state.boxtransform
    ViewportAlignmentState(state.distance, state.camerastate, state.planecamerastate, state.cameratransform, newboxtransform, identitytransform())
end

function Visualizer.onmousedrag(::ViewportAlignment, state::ViewportAlignmentState, drag::MouseDragPositionEvent)
    # The `drag` position is in the range [-1, 1] for both the X and Y coordinate, as long as the mouse is in
    # the window. Note that it can be outside that range when the mouse pointer goes outside the window during
    # a drag.
    # The idea is that dragging from one end of the other will lead to one full rotation. So dragging from 0 to 1
    # is a half rotation, or \pi radians.
    radians = drag.direction * Float64(pi) # This converts the coordinate to radians in the range [-pi, pi]

    dragtransform = rotatex(Float32(radians[2])) * rotatey(Float32(radians[1]))
    ViewportAlignmentState(state.distance, state.camerastate, state.planecamerastate, state.cameratransform, state.boxtransform, dragtransform)
end

function Visualizer.render(camera::Camera, v::ViewportAlignment, state::ViewportAlignmentState)
    zangle = 1f0 * pi / 16f0
    yangle = 3f0 * pi / 16f0
    #viewtransform2 = rotatez(zangle) * rotatey(- 5f0 * pi / 16f0)
    #viewtransform2 = rotatey(- 5f0 * pi / 16f0)
    perspectiveshift = rotatez(zangle) * rotatey(yangle)

    #
    # Viewport 1 (left)
    #
    glViewport(0, 0, camera.windowwidth, camera.windowheight)

    use(v.program)
    view = lookat(camerastate(state))
    projection = perspective(camera)
    #model = objectmodel()
    model = state.dragtransform * state.boxtransform
    uniform(v.program, "model", model)
    uniform(v.program, "view", view)
    uniform(v.program, "projection", projection)

    glBindTexture(GL_TEXTURE_1D, v.wireframetexture.textureid)
    renderarray(v.wireframe)

    render(v.marker, camera, camerastate(state))

    planecamerastate1 = planecamerastate(state)
    render(v.plane, camera, planecamerastate1, Float32(state.distance))

    #
    # Viewport 2 (right)
    #
    glViewport(camera.windowwidth, 0, camera.windowwidth, camera.windowheight)

    camerastateviewport2 = transform(camerastate(state), perspectiveshift)

    use(v.program)
    view = lookat(camerastateviewport2)
    projection = perspective(camera)
    model = state.dragtransform * state.boxtransform
    uniform(v.program, "model", model)
    uniform(v.program, "view", view)
    uniform(v.program, "projection", projection)

    glBindTexture(GL_TEXTURE_1D, v.wireframetexture.textureid)
    renderarray(v.wireframe)

    render(v.marker, camera, camerastateviewport2)

    planecamerastate2 = transform(planecamerastate1, perspectiveshift)
    render(v.plane, camera, planecamerastate2, Float32(state.distance))

end

end