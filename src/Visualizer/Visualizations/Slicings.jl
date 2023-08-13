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

module Slicings

using ModernGL

using Alfar.Visualizer
using Alfar.Rendering.Cameras
using Alfar.Rendering.CameraViews
using Alfar.Rendering.Shaders
using Alfar.Rendering.Meshs
using Alfar.Rendering.Inputs
using Alfar.Rendering: World
using Alfar.Visualizer.Objects.Boxs
using Alfar.WIP.Math
using Alfar.WIP.Transformations

struct FrontBackVertex
    frontvertexindex::Int
    backvertexindex::Int
    fronttoback::Vector3{Float32, World}
end

function frontvertex(cameraview::CameraView) :: FrontBackVertex
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

    frontvertex = 0
    frontdistance = Inf
    backvertex = 0
    backdistance = -Inf

    for vertexindex = 1:8
        v = vertices[vertexindex]
        d = norm(cameraposition(cameraview) - v)

        if d < frontdistance
            frontdistance = d
            frontvertex = vertexindex
        end

        # Using >= here so that if several vertices have the same
        # distance, it uses the last one. This is what we want in the
        # current default camera setup, but is kind of hacky.
        if d >= backdistance
            backdistance = d
            backvertex = vertexindex
        end
    end

    fronttoback = vertices[frontvertex] - vertices[backvertex]

    # Convert from Julias one-indexing to OpenGLs zero-indexing
    FrontBackVertex(
        frontvertex - 1,
        backvertex - 1,
        fronttoback,
    )
end


struct IntersectingPolygon
    program::ShaderProgram
    polygon::VertexArray{GL_TRIANGLE_FAN}
    color::NTuple{4, Float32}

    function IntersectingPolygon(color::NTuple{4, Float32})
        program = ShaderProgram("shaders/visualization/vs_polygon_intersecting_box.glsl",
                                "shaders/visualization/uniformcolorfragment.glsl")

        # Instead of specifying actually vertices, or even vertex indexes to be looked up,
        # here we specify the intersection points that will make up the polygon.
        # There will be between 3-6 intersections, with intersection p0, p2, p4 being guaranteed.
        # This is a triangle fan, originating at intersection p0.
        intersectionindexes = GLint[
            0, 1, 2,
               2, 3,
               3, 4,
               4, 5,
        ]

        indexattribute = VertexAttribute(0, 1, GL_INT, GL_FALSE, C_NULL)
        indexdata = VertexData{GLint}(intersectionindexes, VertexAttribute[indexattribute])

        polygon = VertexArray{GL_TRIANGLE_FAN}(indexdata)

        new(program, polygon, color)
    end
end

function render(polygon::IntersectingPolygon,
                camera::Camera,
                cameraview::CameraView,
                normalcameraview::CameraView,
                distance::Float32,
                frontvertexindex::Int)
    use(polygon.program)

    projection = perspective(camera)
    model = identitytransform()
    view = CameraViews.lookat(cameraview)

    uniform(polygon.program, "projection", projection)
    uniform(polygon.program, "view", view)
    uniform(polygon.program, "model", model)
    uniform(polygon.program, "distance", distance)
    uniform(polygon.program, "color", polygon.color)
    uniform(polygon.program, "frontVertexIndex", frontvertexindex)

    # We define the slice to have a positive normal on its front facing side.
    # Since the slices should always be oriented to show their front facing sides to the camera,
    # it implies that the normal is the direction.
    normal = -direction(normalcameraview)
    uniform(polygon.program, "normal", normal)

    renderarray(polygon.polygon)
end

struct Slices
    polygon::IntersectingPolygon

    function Slices()
        polygon = IntersectingPolygon((0f0, 1f0, 0f0, 1f0))
        new(polygon)
    end
end

function render(slices::Slices, camera::Camera, cameraview::CameraView, normalcameraview::CameraView, n::Int)
    frontback = frontvertex(normalcameraview)

    # The slices are spread out across the distance between the front and the back vertex.
    # As long as the box has all sides with length 1, then this distance is always
    # sqrt(1^2 + 1^2 + 1^2) = sqrt(3)
    frontbackdistance = Float32(sqrt(3)) * dot(direction(normalcameraview), frontback.fronttoback)

    for whichslice = 1:n
        distanceratio = Float32(whichslice) / Float32(n + 1) - 0.5f0
        distance = distanceratio * frontbackdistance
        render(slices.polygon, camera, cameraview, normalcameraview, distance, frontback.frontvertexindex)
    end
end

struct Slicing <: Visualizer.Visualization
    box::Box
    slices::Slices

    function Slicing()
        new(Box(), Slices())
    end
end

struct SlicingState <: Visualizer.VisualizationState
    numberofslices::Int
    cameraview::CameraView
    fixedcameraview::CameraView
end

function Visualizer.setflags(::Slicing)
    glEnable(GL_BLEND)
    glEnable(GL_DEPTH_TEST)
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)
    glDisable(GL_CULL_FACE)
end

function Visualizer.setup(::Slicing) :: SlicingState
    position = Vector3{Float32, World}(0f0, 0f0, 3f0)
    target = Vector3{Float32, World}(0f0, 0f0, 0f0)
    up = Vector3{Float32, World}(0f0, 1f0, 0f0)
    cameraview = CameraView{Float32, World}(position, target, up)

    xaxis = Vector3{Float32, World}(1f0, 0f0, 0f0)
    yaxis = Vector3{Float32, World}(0f0, 1f0, 0f0)
    perspectiveshift = PointRotation{Float32, World}(3f0 * pi / 16f0, yaxis) ∘ PointRotation{Float32, World}(-3f0 * pi / 16f0, xaxis)
    fixedcameraview = rotatecamera(cameraview, perspectiveshift)

    SlicingState(5, cameraview, fixedcameraview)
end

function Visualizer.update(::Slicing, state::SlicingState) :: SlicingState
    state
end

function Visualizer.onmousedrag(::Slicing, state::SlicingState, ev::MouseDragStartEvent)
    newcameraview = onmousedrag(state.cameraview, ev)
    SlicingState(state.numberofslices, newcameraview, state.fixedcameraview)
end

function Visualizer.onmousedrag(::Slicing, state::SlicingState, ev::MouseDragEndEvent)
    newcameraview = onmousedrag(state.cameraview, ev)
    SlicingState(state.numberofslices, newcameraview, state.fixedcameraview)
end

function Visualizer.onmousedrag(::Slicing, state::SlicingState, ev::MouseDragPositionEvent)
    newcameraview = onmousedrag(state.cameraview, ev)
    SlicingState(state.numberofslices, newcameraview, state.fixedcameraview)
end

function Visualizer.render(camera::Camera, slicing::Slicing, state::SlicingState)
    # Viewport 1 (left)
    glViewport(0, 0, camera.windowwidth, camera.windowheight)

    Boxs.render(slicing.box, camera, state.cameraview)

    render(slicing.slices, camera, state.cameraview, state.cameraview, state.numberofslices)

    # Viewport 2 (right)
    glViewport(camera.windowwidth, 0, camera.windowwidth, camera.windowheight)

    Boxs.render(slicing.box, camera, state.fixedcameraview)

    render(slicing.slices, camera, state.fixedcameraview, state.cameraview, state.numberofslices)
end

end # module Slicings