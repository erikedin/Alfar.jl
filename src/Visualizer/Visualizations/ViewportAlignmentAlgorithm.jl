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
using GLFW

using Alfar.Visualizer
using Alfar.Visualizer: MouseDragStartEvent, MouseDragEndEvent, MouseDragPositionEvent
using Alfar.Visualizer.Objects.XYZMarkerObject
using Alfar.Rendering.Cameras
using Alfar.Rendering.Inputs
using Alfar.Rendering.CameraViews
using Alfar.Rendering.Shaders
using Alfar.Rendering.Meshs
using Alfar.Rendering.Textures
using Alfar.Rendering: World, Object
using Alfar.WIP.Math
using Alfar.WIP.Transformations

struct IntersectingPlanePoints
    program::ShaderProgram
    pointvertices::VertexArray{GL_POINTS}

    function IntersectingPlanePoints()
        program = ShaderProgram("shaders/visualization/pointvertex.glsl", "shaders/visualization/uniformcoloralpha.glsl")

        vertices = GLint[
            0, 1,
            1, 4,
            4, 7,
            0, 2,
            2, 5,
            5, 7,
            0, 3,
            3, 6,
            6, 7,
            1, 5,
            2, 6,
            3, 4,
        ]
        attributevi = VertexAttribute(0, 1, GL_INT, GL_FALSE, C_NULL)
        attributevj = VertexAttribute(1, 1, GL_INT, GL_FALSE, Ptr{Cvoid}(1 * sizeof(GL_INT)))
        vertexdata = VertexData{GLint}(vertices, VertexAttribute[attributevi, attributevj])
        pointvertices = VertexArray{GL_POINTS}(vertexdata)

        new(program, pointvertices)
    end
end

function render(p::IntersectingPlanePoints, camera::Camera, cameraview::CameraView, normalcameraview::CameraView, distance::Float32)
    use(p.program)

    projection = perspective(camera)
    model = identitytransform()
    view = CameraViews.lookat(cameraview)

    color = (0f0, 1f0, 1f0)

    uniform(p.program, "projection", projection)
    uniform(p.program, "view", view)
    uniform(p.program, "model", model)
    uniform(p.program, "color", color)
    uniform(p.program, "distance", distance)

    # We define the slice to have a positive normal on its front facing side.
    # Since the slices should always be oriented to show their front facing sides to the camera,
    # it implies that the normal is the directio
    normal = -direction(normalcameraview)
    uniform(p.program, "normal", normal)

    renderarray(p.pointvertices)
end

struct IntersectingPlane
    program::ShaderProgram
    color::NTuple{4, Float32}
    planevertices::VertexArray{GL_TRIANGLES}

    function IntersectingPlane()
        program = ShaderProgram("shaders/visualization/mvp3dvertex.glsl", "shaders/visualization/uniformcolorfragment.glsl")
        color = (0f0, 0f0, 1f0, 0.1f0)

        vertices = GLfloat[
            # Lines from front right bottom, around, counterclockwise
             1.0f0, -1.0f0, 0.0f0, # Right bottom
             1.0f0,  1.0f0, 0.0f0, # Right top
            -1.0f0,  1.0f0, 0.0f0, # Left top

             1.0f0, -1.0f0, 0.0f0, # Right bottom
            -1.0f0,  1.0f0, 0.0f0, # Left top
            -1.0f0, -1.0f0, 0.0f0, # Left bottom
        ]
        attribute = VertexAttribute(0, 3, GL_FLOAT, GL_FALSE, C_NULL)
        vertexdata = VertexData{GLfloat}(vertices, VertexAttribute[attribute])
        planevertices = VertexArray{GL_TRIANGLES}(vertexdata)

        new(program, color, planevertices)
    end
end

function render(plane::IntersectingPlane, camera::Camera, cameraview::CameraView, rotation::PointRotation{Float32, World}, distance::Float32)
    use(plane.program)

    projection = perspective(camera)

    model_rotation = convert(Matrix4{Float32, World, World}, rotation)
    model_translation = Matrix4{Float32, World, Object}(
        1f0, 0f0, 0f0, 0f0,
        0f0, 1f0, 0f0, 0f0,
        0f0, 0f0, 1f0, distance,
        0f0, 0f0, 0f0, 1f0,
    )
    model = model_rotation * model_translation

    view = CameraViews.lookat(cameraview)
    uniform(plane.program, "projection", projection)
    uniform(plane.program, "view", view)
    uniform(plane.program, "model", model)

    uniform(plane.program, "distance", distance)
    uniform(plane.program, "color", plane.color)

    renderarray(plane.planevertices)
end

struct VertexHighlight
    program::ShaderProgram
    pointvertex::VertexArray{GL_POINTS}
    vertexdata::VertexData{GLfloat}
    color::NTuple{4, Float32}

    function VertexHighlight(color::NTuple{4, Float32})
        program = ShaderProgram("shaders/visualization/vertexhighlight.glsl", "shaders/visualization/uniformcolorfragment.glsl")

        vertices = GLfloat[
            0.5f0, 0.5f0, 0.5f0,
        ]
        attributevertex = VertexAttribute(0, 3, GL_FLOAT, GL_FALSE, C_NULL)
        vertexdata = VertexData{GLfloat}(vertices, VertexAttribute[attributevertex])
        pointvertex = VertexArray{GL_POINTS}(vertexdata)
        new(program, pointvertex, vertexdata, color)
    end
end

function render(highlight::VertexHighlight, camera::Camera, cameraview::CameraView, vertex::Vector3{Float32, World})
    use(highlight.program)

    vertices = GLfloat[vertex.x, vertex.y, vertex.z]
    Meshs.bufferdata(highlight.vertexdata.vbo, vertices, GL_DYNAMIC_DRAW)

    projection = perspective(camera)
    model = identitytransform()
    view = CameraViews.lookat(cameraview)

    uniform(highlight.program, "projection", projection)
    uniform(highlight.program, "view", view)
    uniform(highlight.program, "model", model)

    uniform(highlight.program, "color", highlight.color)

    renderarray(highlight.pointvertex)
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
    planepoints::IntersectingPlanePoints
    marker::XYZMarker
    fronthighlight::VertexHighlight
    backhighlight::VertexHighlight

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

        fronthighlight = VertexHighlight((0f0, 1f0, 0f0, 1f0))
        backhighlight = VertexHighlight((1f0, 0f0, 0f0, 1f0))

        new(program, wireframe, wireframetexture, IntersectingPlane(), IntersectingPlanePoints(), XYZMarker(), fronthighlight, backhighlight)
    end
end

struct ViewportAlignmentState <: Visualizer.VisualizationState
    distance::Float64
    cameraview::CameraView
    fixedcameraview::CameraView
end

function Visualizer.setflags(::ViewportAlignment)
    glEnable(GL_BLEND)
    glEnable(GL_DEPTH_TEST)
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)
    glPointSize(10f0)
    glEnable(GL_POINT_SMOOTH)
end

function Visualizer.setup(::ViewportAlignment)
    initialcameraposition = Vector3{Float32, World}(0f0, 0f0, 3f0)
    initialtarget = Vector3{Float32, World}(0f0, 0f0, 0f0)
    initialup = Vector3{Float32, World}(0f0, 1f0, 0f0)
    cameraview = CameraView{Float32, World}(initialcameraposition, initialtarget, initialup)

    # The fixed camera is shown from an angle to the original camera position
    xaxis = Vector3{Float32, World}(1f0, 0f0, 0f0)
    yaxis = Vector3{Float32, World}(0f0, 1f0, 0f0)
    fixedperspectiveshift = PointRotation{Float32, World}(3f0 * pi / 16f0, yaxis) ∘ PointRotation{Float32, World}(-3f0 * pi / 16f0, xaxis)
    #fixedperspectiveshift = PointRotation{Float32, World}(8f0 * pi / 16f0, yaxis)
    fixedcameraview = rotatecamera(cameraview, fixedperspectiveshift)

    ViewportAlignmentState(0f0, cameraview, fixedcameraview)
end

Visualizer.update(::ViewportAlignment, state::ViewportAlignmentState) = state

function Visualizer.onkeyboardinput(::ViewportAlignment, state::ViewportAlignmentState, ev::KeyboardInputEvent)
    distanceoffset = if ev.action == GLFW.PRESS && ev.key == GLFW.KEY_Q
            -0.1f0
    elseif ev.action == GLFW.PRESS && ev.key == GLFW.KEY_E
            0.1f0
    else
        0f0
    end
    ViewportAlignmentState(state.distance + distanceoffset, state.cameraview, state.fixedcameraview)
end

function Visualizer.onmousescroll(::ViewportAlignment, state::ViewportAlignmentState, (xoffset, yoffset)::Tuple{Float64, Float64})
    newdistance = state.distance + yoffset / 20.0
    ViewportAlignmentState(newdistance, state.cameraview, state.fixedcameraview)
end

function Visualizer.onmousedrag(::ViewportAlignment, state::ViewportAlignmentState, ev::MouseDragStartEvent)
    newcameraview = onmousedrag(state.cameraview, ev)
    ViewportAlignmentState(state.distance, newcameraview, state.fixedcameraview)
end

function Visualizer.onmousedrag(::ViewportAlignment, state::ViewportAlignmentState, ev::MouseDragEndEvent)
    newcameraview = onmousedrag(state.cameraview, ev)
    ViewportAlignmentState(state.distance, newcameraview, state.fixedcameraview)
end

function Visualizer.onmousedrag(::ViewportAlignment, state::ViewportAlignmentState, ev::MouseDragPositionEvent)
    newcameraview = onmousedrag(state.cameraview, ev)
    ViewportAlignmentState(state.distance, newcameraview, state.fixedcameraview)
end

function frontbackvertex(cameraview::CameraView) :: NTuple{2, Vector3{Float32, World}}
    vertices = Vector3{Float32, World}[
        Vector3{Float32, World}( 0.5f0,  0.5f0,  0.5f0), #v0
        Vector3{Float32, World}( 0.5f0,  0.5f0, -0.5f0), #v1
        Vector3{Float32, World}( 0.5f0, -0.5f0,  0.5f0), #v2
        Vector3{Float32, World}(-0.5f0,  0.5f0,  0.5f0), #v3
        Vector3{Float32, World}(-0.5f0,  0.5f0, -0.5f0), #v4
        Vector3{Float32, World}( 0.5f0, -0.5f0, -0.5f0), #v5
        Vector3{Float32, World}(-0.5f0, -0.5f0,  0.5f0), #v6
        Vector3{Float32, World}(-0.5f0, -0.5f0, -0.5f0), #v7
    ]

    frontvertex = Vector3{Float32, World}(0f0, 0f0, 0f0)
    frontdistance = Inf
    backvertex = Vector3{Float32, World}(0f0, 0f0, 0f0)
    backdistance = -Inf

    for v in vertices
        d = norm(cameraposition(cameraview) - v)

        if d < frontdistance
            frontdistance = d
            frontvertex = v
        end

        if d > backdistance
            backdistance = d
            backvertex = v
        end
    end

    (frontvertex, backvertex)
end

function Visualizer.render(camera::Camera, v::ViewportAlignment, state::ViewportAlignmentState)
    (frontvertex, backvertex) = frontbackvertex(state.cameraview)

    #
    # Viewport 1 (left)
    #
    glViewport(0, 0, camera.windowwidth, camera.windowheight)

    use(v.program)
    view = CameraViews.lookat(state.cameraview)
    projection = perspective(camera)
    model = identitytransform()
    uniform(v.program, "model", model)
    uniform(v.program, "view", view)
    uniform(v.program, "projection", projection)

    glBindTexture(GL_TEXTURE_1D, v.wireframetexture.textureid)
    renderarray(v.wireframe)

    XYZMarkerObject.render(v.marker, camera, state.cameraview)

    render(v.backhighlight, camera, state.cameraview, backvertex)
    render(v.planepoints, camera, state.cameraview, state.cameraview, Float32(state.distance))
    render(v.plane, camera, state.cameraview, camerarotation(state.cameraview), Float32(state.distance))
    render(v.fronthighlight, camera, state.cameraview, frontvertex)

    #
    # Viewport 2 (right)
    #
    glViewport(camera.windowwidth, 0, camera.windowwidth, camera.windowheight)

    use(v.program)
    view = CameraViews.lookat(state.fixedcameraview)
    projection = perspective(camera)
    model = identitytransform()
    uniform(v.program, "model", model)
    uniform(v.program, "view", view)
    uniform(v.program, "projection", projection)

    glBindTexture(GL_TEXTURE_1D, v.wireframetexture.textureid)
    renderarray(v.wireframe)

    XYZMarkerObject.render(v.marker, camera, state.fixedcameraview)

    # The plane is still rotated according to the first camera, not the fixed camera.
    # The idea is that the first viewport will define the orientation of the plane, and the second
    # viewport has a fixed perspective, and will allow us to see the plane from a different perspective.
    render(v.backhighlight, camera, state.fixedcameraview, backvertex)
    render(v.planepoints, camera, state.fixedcameraview, state.cameraview, Float32(state.distance))
    render(v.plane, camera, state.fixedcameraview, camerarotation(state.cameraview), Float32(state.distance))
    render(v.fronthighlight, camera, state.fixedcameraview, frontvertex)
end

end