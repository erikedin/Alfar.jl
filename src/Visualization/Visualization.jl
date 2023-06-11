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
using ModernGL

using Distributed

@everywhere using Alfar.Visualization

abstract type VizEvent end

struct ExitEvent <: VizEvent end

function handle(window, e::ExitEvent)
    GLFW.SetWindowShouldClose(window, true)
end

function runvisualizer(c::RemoteChannel)
    # Create a window and its OpenGL context
    window = GLFW.CreateWindow(640, 480, "Alfar Visualization")

    # Make the window's context current
    GLFW.MakeContextCurrent(window)

    # Set background color to black
    glClearColor(0.0f0, 0.0f0, 0.0f0, 1.0f0)

    # Loop until the user closes the window
    while !GLFW.WindowShouldClose(window)
        glClear(GL_COLOR_BUFFER_BIT)

	    # Render here

	    # Swap front and back buffers
	    GLFW.SwapBuffers(window)

        # If we have any events from the REPL, handle them.
        hasevents = isready(c)
        if hasevents
            ev = take!(c)
            handle(window, ev)
        end

	    # Poll for and process events
	    GLFW.PollEvents()
    end

    GLFW.DestroyWindow(window)
end

struct VisualizationContext
    channel::RemoteChannel
end

function start()
    channel = RemoteChannel(() -> Channel{Visualization.VizEvent}(10))

    workerpid = Distributed.workers()[1]

    remote_do(Visualization.runvisualizer, workerpid, channel)

    VisualizationContext(channel)
end

function stop(context::VisualizationContext)
    put!(context.channel, ExitEvent())
end

end