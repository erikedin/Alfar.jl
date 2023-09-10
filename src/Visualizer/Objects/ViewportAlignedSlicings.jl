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

module ViewportAlignedSlicings

using ModernGL
using GLFW

using Alfar
using Alfar.Rendering.Cameras
using Alfar.Rendering.CameraViews
using Alfar.Rendering.Meshs
using Alfar.Rendering.Shaders
using Alfar.Rendering: World, View, Object
using Alfar.Visualizer.Objects.Boxs
using Alfar.Math

export ViewportAlignedSlicing, SliceTransfer, render

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

# SliceTransfer represents the input to the fragment shader
# `fragment1dtransfer.glsl`
struct SliceTransfer
    textureid::GLuint
    transfertextureid::GLuint
    referencesamplingrate::Float32
end

relativesamplingrate(t::SliceTransfer, n::Int) = t.referencesamplingrate / Float32(n)

function bind(t::SliceTransfer)
    glBindTexture(GL_TEXTURE_3D, t.textureid)
    glBindTexture(GL_TEXTURE_1D, t.transfertextureid)
end

function uniforms(program::ShaderProgram, t::SliceTransfer, n::Int)
    uniform(program, "relativeSamplingRate", relativesamplingrate(t, n))
end

# IntersectingPolygon creates the polygon that is the intersection of the box and a given
# slice, aligned by he viewport.
struct IntersectingPolygon
    program::ShaderProgram
    polygon::VertexArray{GL_TRIANGLE_FAN}
    # TODO Remove as it is obsolete.
    color::NTuple{4, Float32}

    function IntersectingPolygon(color::NTuple{4, Float32})
        vshader = pkgdir(Alfar, "shaders", "visualization", "vs_polygon_intersecting_box.glsl")
        fragmentshader = pkgdir(Alfar, "shaders", "visualization", "fragment1dtransfer.glsl")
        # TODO Note that the fragment shader and the `SliceTransfer` struct are connected
        # and depend on each other. The `SliceTransfer` struct will set the correct uniforms
        # as expected by the fragment shader and will also bind the correct textures.
        # Therefore, maybe the shader program should come from `SliceTransfer` instead.
        program = ShaderProgram(vshader, fragmentshader)

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
                frontvertexindex::Int,
                slicetransfer::SliceTransfer,
                numberofslices::Int)
    use(polygon.program)

    projection = perspective(camera)
    model = identitytransform(View, Object)
    view = CameraViews.lookat(cameraview)

    uniform(polygon.program, "projection", projection)
    uniform(polygon.program, "view", view)
    uniform(polygon.program, "model", model)
    uniform(polygon.program, "distance", distance)
    uniform(polygon.program, "color", polygon.color)
    uniform(polygon.program, "frontVertexIndex", frontvertexindex)

    uniforms(polygon.program, slicetransfer, numberofslices)

    # We define the slice to have a positive normal on its front facing side.
    # Since the slices should always be oriented to show their front facing sides to the camera,
    # it implies that the normal is the direction.
    normal = -direction(normalcameraview)
    uniform(polygon.program, "normal", normal)

    renderarray(polygon.polygon)
end

# Slices renders a configurable number of viewport aligned slices.
struct Slices
    polygon::IntersectingPolygon

    function Slices()
        polygon = IntersectingPolygon((0f0, 1f0, 0f0, 1f0))
        new(polygon)
    end
end

function render(slices::Slices,
                camera::Camera,
                cameraview::CameraView,
                normalcameraview::CameraView,
                n::Int,
                slicetransfer::SliceTransfer)
    bind(slicetransfer)

    frontback = frontvertex(normalcameraview)

    # The slices are spread out across the distance between the front and the back vertex.
    # As long as the box has all sides with length 1, then this distance is always
    # sqrt(1^2 + 1^2 + 1^2) = sqrt(3)
    frontbackdistance = Float32(sqrt(3)) * dot(direction(normalcameraview), frontback.fronttoback)

    for whichslice = n:-1:1
        distanceratio = Float32(whichslice) / Float32(n + 1) - 0.5f0
        distance = distanceratio * frontbackdistance
        render(slices.polygon, camera, cameraview, normalcameraview, distance, frontback.frontvertexindex, slicetransfer, n)
    end
end

# ViewportAlignedSlicing renders box and a configurable number of slices of that box.
struct ViewportAlignedSlicing
    box::Box
    slices::Slices
    slicetransfer::SliceTransfer

    function ViewportAlignedSlicing(slicetransfer::SliceTransfer)
        new(Box(), Slices(), slicetransfer)
    end
end

function render(v::ViewportAlignedSlicing, camera::Camera, cameraview::CameraView, normalcameraview::CameraView, numberofslices::Int)
    Boxs.render(v.box, camera, cameraview)
    render(v.slices, camera, cameraview, normalcameraview, numberofslices, v.slicetransfer)
end

end # module ViewportAlignedSlicings