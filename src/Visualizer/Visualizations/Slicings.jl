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
using GLFW

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

function render(slices::Slices,
                camera::Camera,
                cameraview::CameraView,
                normalcameraview::CameraView,
                n::Int,
                textureid::GLuint,
                transfertextureid::GLuint)
    glBindTexture(GL_TEXTURE_3D, textureid)
    glBindTexture(GL_TEXTURE_1D, transfertextureid)

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

#
# A 3D texture for demonstrating the Slicing.
# This is the texture from 09_viewportanimated.jl
# The size needs to be a multiple of two at each dimension.
#

struct TextureDefinition3D
    width::Int
    height::Int
    depth::Int
    data
end

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


    TextureDefinition3D(width, height, depth, flattexturedata)
end

# This is raw OpenGL code, not wrapped in Julia code. This is good for now,
# but should be wrapped for the real deal.
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

#
# This is the 1D texture transfer function that actually defines the colors.
# Also copied from samples/09_viewportanimated.jl.
#

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
    fill1d!(transfer, 225, 249, (  0,   0, 255, 255))

    # Yellow bar
    fill1d!(transfer, 250, 256, (255, 255,   0, 255))

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


    bordercolor = GLfloat[1f0, 1f0, 0f0, 1f0]
    glTexParameterfv(GL_TEXTURE_1D, GL_TEXTURE_BORDER_COLOR, Ref(bordercolor, 1))
    glTexParameterf(GL_TEXTURE_1D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_BORDER)
    glTexParameterf(GL_TEXTURE_1D, GL_TEXTURE_MIN_FILTER, GL_NEAREST)

    textureid
end

#
# Slicing visualization
#

struct Slicing <: Visualizer.Visualization
    box::Box
    slices::Slices
    textureid::GLuint
    transfertextureid::GLuint

    function Slicing()
        texturedefinition = generate3dintensitytexture(256, 256, 256)
        textureid = make3dtexture(texturedefinition)

        texturetransferdefinition = generatetexturetransferfunction()
        transfertextureid = maketransfertexture(texturetransferdefinition)
        new(Box(), Slices(), textureid, transfertextureid)
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

function Visualizer.onkeyboardinput(::Slicing, state::SlicingState, ev::KeyboardInputEvent)
    n = if ev.action == GLFW.PRESS && ev.key == GLFW.KEY_R
            1
    elseif ev.action == GLFW.PRESS && ev.key == GLFW.KEY_F
            -1
    else
        0
    end
    SlicingState(state.numberofslices + n, state.cameraview, state.fixedcameraview)
end

function Visualizer.render(camera::Camera, slicing::Slicing, state::SlicingState)
    # Viewport 1 (left)
    glViewport(0, 0, camera.windowwidth, camera.windowheight)

    Boxs.render(slicing.box, camera, state.cameraview)

    render(slicing.slices, camera, state.cameraview, state.cameraview, state.numberofslices, slicing.textureid, slicing.transfertextureid)

    # Viewport 2 (right)
    glViewport(camera.windowwidth, 0, camera.windowwidth, camera.windowheight)

    Boxs.render(slicing.box, camera, state.fixedcameraview)

    render(slicing.slices, camera, state.fixedcameraview, state.cameraview, state.numberofslices, slicing.textureid, slicing.transfertextureid)
end

end # module Slicings