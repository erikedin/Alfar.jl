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

module Visualizer

using GLFW
using ModernGL

using Distributed

using Alfar.Rendering.Shaders

@everywhere using Alfar.Visualizer

include("visualization.jl")

const PredefinedVisualizers = Dict{String, Visualization}([
    ("ViewportAnimated09", ViewportAnimated09),
])

struct VisualizationState
    visualizer::Union{Nothing, Visualizer}
end

VisualizationState() = VisualizationState(nothing)

abstract type VizEvent end

struct ExitEvent <: VizEvent end

struct SelectVisualizationEvent <: VizEvent
    name::String
end

function handle(window, e::ExitEvent, state::VisualizationState)
    GLFW.SetWindowShouldClose(window, true)
    state
end

function handle(window, ev::SelectVisualizationEvent, state::VisualizationState)
    visualizer = get(PredefinedVisualizers, ev.name, nothing)

    setflags(visualizer)
    setup(visualizer)

    VisualizationState(ev.visualizer)
end


Shaders.use(::Nothing) = nothing

function runvisualizer(c::RemoteChannel)
    # Create a window and its OpenGL context
    window = GLFW.CreateWindow(640, 480, "Alfar Visualizer")

    # Make the window's context current
    GLFW.MakeContextCurrent(window)

    # Set background color to black
    glClearColor(0.0f0, 0.0f0, 0.0f0, 1.0f0)

    # Create the initial state of the visualizer
    state = VisualizationState()

    # Loop until the user closes the window
    while !GLFW.WindowShouldClose(window)
        # If we have any events from the REPL, handle them.
        hasevents = isready(c)
        if hasevents
            ev = take!(c)
            handle(window, ev)
        end

        glClear(GL_COLOR_BUFFER_BIT)

	    # Render here
        render(state.visualizer)

	    # Swap front and back buffers
	    GLFW.SwapBuffers(window)

	    # Poll for and process events
	    GLFW.PollEvents()
    end

    GLFW.DestroyWindow(window)
end

struct VisualizerContext
    channel::RemoteChannel
end

function start()
    channel = RemoteChannel(() -> Channel{Visualizer.VizEvent}(10))

    workerpid = Distributed.workers()[1]

    remote_do(Visualizer.runvisualizer, workerpid, channel)

    VisualizerContext(channel)
end

function stop(context::VisualizerContext)
    put!(context.channel, ExitEvent())
end

end