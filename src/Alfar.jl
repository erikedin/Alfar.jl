# Copyright 2022 Erik Edin
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

module Alfar

include("Render.jl")

using GLFW
using ModernGL
using Alfar.Render

function run()
    # Create a window and its OpenGL context
    window = GLFW.CreateWindow(640, 480, "Alfar")

    # Make the window's context current
    GLFW.MakeContextCurrent(window)

    program, vao = Render.setupgraphics()

    starttime = time()

    glEnable(GL_BLEND)
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)

    # Loop until the user closes the window
    while !GLFW.WindowShouldClose(window)
        glClearColor(0.2f0, 0.3f0, 0.3f0, 1.0f0)
        glClear(GL_COLOR_BUFFER_BIT)

	    # Render here

        # Set alpha channel based on time
        timevalue = Float32(time() - starttime)
        # alpha = sin(2.0f0 * pi / 4.0f0 * timevalue) / 2.0f0 + 0.5f0

        angle = 2.0f0 * pi / 12.0f0 * timevalue
        translation = Render.translate(0.5f0, -0.5f0, 0.0f0)
        rotation = Render.rotatez(angle)
        scaling = Render.scale(0.5f0, 0.5f0, 0.5f0)

        use(program)

        uniform(program, "alpha", 1.0f0)
        uniform(program, "model", translation * rotation * scaling)

        glBindVertexArray(vao)
        glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_INT, C_NULL)
        glBindVertexArray(0)

	    # Swap front and back buffers
	    GLFW.SwapBuffers(window)

	    # Poll for and process events
	    GLFW.PollEvents()
    end

    GLFW.DestroyWindow(window)
end

end # module Alfar
