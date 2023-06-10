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

module Visualization

using GLFW

function start()
    # Create a window and its OpenGL context
    window = GLFW.CreateWindow(640, 480, "Alfar Visualization")

    # Make the window's context current
    GLFW.MakeContextCurrent(window)

    # Loop until the user closes the window
    while !GLFW.WindowShouldClose(window)

	    # Render here

	    # Swap front and back buffers
	    GLFW.SwapBuffers(window)

	    # Poll for and process events
	    GLFW.PollEvents()
    end

    GLFW.DestroyWindow(window)

end

end