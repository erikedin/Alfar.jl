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
using Alfar.Rendering.Cameras

export KeyboardInputEvent

@everywhere using Alfar.Visualizer

include("visualization.jl")

const PredefinedVisualizers = Dict{String, Type{<:Visualization}}([
    ("ViewportAnimated09", ViewportAnimated09Visualization.ViewportAnimated09),
    ("ViewportAlignment", ViewportAlignmentAlgorithm.ViewportAlignment),
])

mutable struct VisualizerState
    visualization::Union{Nothing, Visualization}
    visualizationstate::Union{Nothing, VisualizationState}
end

VisualizerState() = VisualizerState(nothing, nothing)

abstract type VizEvent end

struct ExitEvent <: VizEvent end

struct SelectVisualizationEvent <: VizEvent
    name::String
end

function handle(window, e::ExitEvent, state::VisualizerState)
    GLFW.SetWindowShouldClose(window, true)
    state
end

function handle(window, ev::SelectVisualizationEvent, state::VisualizerState)
    visualizerfactory = get(PredefinedVisualizers, ev.name, nothing)
    visualizer = visualizerfactory()

    setflags(visualizer)
    visualizationstate = setup(visualizer)

    VisualizerState(visualizer, visualizationstate)
end

Shaders.use(::Nothing) = nothing

function runvisualizer(c::RemoteChannel, exitchannel::RemoteChannel)
    camera = Camera(1024, 800)

    # Create a window and its OpenGL context
    window = GLFW.CreateWindow(2048, 800, "Alfar Visualizer")

    # Make the window's context current
    GLFW.MakeContextCurrent(window)

    # Set background color to black
    glClearColor(0.0f0, 0.0f0, 0.0f0, 1.0f0)

    # Create the initial state of the visualizer
    state = VisualizerState()

    keyboardcallback = (window, key, scancode, action, mods) -> begin
        if action == GLFW.PRESS && key == GLFW.KEY_ESCAPE
            GLFW.SetWindowShouldClose(window, true)
        else
            keyevent = KeyboardInputEvent(window, key, scancode, action, mods)
            state.visualizationstate = onkeyboardinput(state.visualization, state.visualizationstate, keyevent)
        end
    end
    GLFW.SetKeyCallback(window, keyboardcallback)

    # Scrolling callback
    scrollcallback = (window, xoffset, yoffset) -> begin
        state.visualizationstate = onmousescroll(state.visualization, state.visualizationstate, (xoffset, yoffset))
    end
    GLFW.SetScrollCallback(window, scrollcallback)

    # Loop until the user closes the window
    while !GLFW.WindowShouldClose(window)
        # If we have any events from the REPL, handle them.
        hasevents = isready(c)
        if hasevents
            ev = take!(c)
            state = handle(window, ev, state)
        end

        state.visualizationstate = update(state.visualization, state.visualizationstate)

        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)

        # Clear the full viewport
        glViewport(0, 0, camera.windowwidth * 2, camera.windowheight)

	    # Render here
        render(camera, state.visualization, state.visualizationstate)

	    # Swap front and back buffers
	    GLFW.SwapBuffers(window)

	    # Poll for and process events
	    GLFW.PollEvents()
    end

    GLFW.DestroyWindow(window)

    put!(exitchannel, ExitEvent())
end

struct VisualizerContext
    channel::RemoteChannel
    exitchannel::RemoteChannel
end

function start()
    channel = RemoteChannel(() -> Channel{Visualizer.VizEvent}(10))
    exitchannel = RemoteChannel(() -> Channel{Visualizer.VizEvent}(10))

    workerpid = Distributed.workers()[1]

    remote_do(Visualizer.runvisualizer, workerpid, channel, exitchannel)

    VisualizerContext(channel, exitchannel)
end

function stop(context::VisualizerContext)
    put!(context.channel, ExitEvent())
end

function waituntilstop(context::VisualizerContext)
    take!(context.exitchannel)
end

end