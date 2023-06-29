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

struct ViewportAlignment <: Visualizer.Visualization
    program::Union{Nothing, ShaderProgram}
    wireframe::VertexArray{GL_LINES}

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
        wireframecolors = GLuint[
            0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12
        ]
        #numberofelementspervertex = 3
        #attributetype = GL_FLOAT
        #positionattribute = MeshAttribute(0, numberofelementspervertex, attributetype, GL_FALSE, C_NULL)
        #meshdefinition = MeshDefinition(wireframevertices, numberofelementspervertex, [positionattribute])
        #mesh = MeshBuffer(meshdefinition)

        positionattribute = VertexAttribute(0, 3, GL_FLOAT, GL_FALSE, C_NULL)
        wireframedata = VertexData{GLfloat}(wireframevertices, VertexAttribute[positionattribute])

        colorattribute = VertexAttribute(1, 1, GL_UINT, GL_FALSE, C_NULL)
        wireframecolordata = VertexData{GLuint}(wireframecolors, VertexAttribute[colorattribute])

        wireframe = VertexArray{GL_LINES}(wireframedata, wireframecolordata)

        new(program, wireframe)
    end
end

struct ViewportAlignmentState <: Visualizer.VisualizationState end

Visualizer.setflags(::ViewportAlignment) = nothing
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

    # Set a single color, RED, for the wireframe
    uniform(v.program, "color", (1f0, 0f0, 0f0, 1f0))

    use(v.program)
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

    # Set a single color, GREEN, for the wireframe
    uniform(v.program, "color", (0f0, 1f0, 0f0, 1f0))

    use(v.program)
    renderarray(v.wireframe)
end

end