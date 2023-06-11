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

using Alfar.Rendering.Shaders

@everywhere using Alfar.Visualization

struct VisualizationState
    program::Union{Nothing, ShaderProgram}
end

VisualizationState() = VisualizationState(nothing)

abstract type VizEvent end

struct ExitEvent <: VizEvent end

struct SelectShadersEvent <: VizEvent
    vertexshader::String
    fragmentshader::String
end

function handle(window, e::ExitEvent, state::VisualizationState)
    GLFW.SetWindowShouldClose(window, true)
    state
end

function handle(window, ev::SelectShadersEvent, state::VisualizationState)
    newprogram = ShaderProgram(ev.vertexshader, ev.fragmentshader)
    VisualizationState(newprogram)
end

Shaders.use(::Nothing) = nothing

function runvisualizer(c::RemoteChannel)
    # Create a window and its OpenGL context
    window = GLFW.CreateWindow(640, 480, "Alfar Visualization")

    # Make the window's context current
    GLFW.MakeContextCurrent(window)

    # Set background color to black
    glClearColor(0.0f0, 0.0f0, 0.0f0, 1.0f0)

    # Create the initial state of the visualizer
    state = VisualizationState()

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