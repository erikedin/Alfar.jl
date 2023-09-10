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

#
# Math helpers
# These are temporary methods until I make a 2D vector properly.
const Vector2{T} = NTuple{2, T}

function Base.:-(a::Vector2{T}, b::Vector2{T}) :: Vector2{T} where {T}
    (a[1] - b[1], a[2] - b[2])
end

#
# Visualizer
#

include("visualization.jl")

export onevent

const PredefinedVisualizers = Dict{String, Type{<:Visualization}}([
    #("ViewportAnimated09", ViewportAnimated09Visualization.ViewportAnimated09),
    ("ViewportAlignment", ViewportAlignmentAlgorithm.ViewportAlignment),
    ("JustXYZMarker", JustXYZMarkers.JustXYZMarker),
    ("Slicing", Slicings.Slicing),
    ("ShowTexture", ShowTextures.ShowTexture),
])

struct MouseInputState
    isdragging::Bool
    dragorigin::NTuple{2, Float64}
#
    MouseInputState() = new(false, (0.0, 0.0))
    MouseInputState(dragorigin) = new(true, dragorigin)
end

mutable struct VisualizerState
    visualization::Union{Nothing, Visualization}
    visualizationstate::Union{Nothing, VisualizationState}
end

VisualizerState() = VisualizerState(nothing, nothing)

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

function handle(window, ev::UserDefinedEvent, state::VisualizerState)
    newvisualizationstate = onevent(state.visualization, state.visualizationstate, ev)
    VisualizerState(state.visualization, newvisualizationstate)
end

Shaders.use(::Nothing) = nothing

function runvisualizer(c::RemoteChannel, exitchannel::RemoteChannel)
    windowwidth = 2048
    halfwindowwidth = windowwidth / 2
    windowheight = 800
    halfwindowheight = windowheight / 2
    camera = Camera(halfwindowwidth, windowheight)

    # Create a window and its OpenGL context
    window = GLFW.CreateWindow(windowwidth, windowheight, "Alfar Visualizer")

    # Make the window's context current
    GLFW.MakeContextCurrent(window)

    # Set background color to black
    glClearColor(0.0f0, 0.0f0, 0.0f0, 1.0f0)

    # Create the initial state of the visualizer
    state = VisualizerState()

    # State for input
    mousestate = MouseInputState()

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

    # Mouse button callback
    mousebuttoncallback = (window, button, action, mods) -> begin
        if button == GLFW.MOUSE_BUTTON_LEFT && action == GLFW.PRESS
            currentposition = GLFW.GetCursorPos(window)
            mousestate = MouseInputState((currentposition.x, currentposition.y))
            state.visualizationstate = onmousedrag(state.visualization, state.visualizationstate, MouseDragStartEvent())
        elseif button == GLFW.MOUSE_BUTTON_LEFT && action == GLFW.RELEASE
            mousestate = MouseInputState()
            state.visualizationstate = onmousedrag(state.visualization, state.visualizationstate, MouseDragEndEvent())
        end
    end
    GLFW.SetMouseButtonCallback(window, mousebuttoncallback)

    # Convert from window pixels [-half width, half width] to relative coordinate [-1, 1]
    relativepixels = (v::NTuple{2, Float64}) -> begin
        x = v[1]
        y = v[2]
        relativex = x / halfwindowwidth
        relativey = y / halfwindowheight
        (relativex, relativey)
    end
    # Mouse position callback
    mousepositioncallback = (window, xposition, yposition) -> begin
        if mousestate.isdragging
            fromorigin = (xposition, yposition) - mousestate.dragorigin
            direction = relativepixels(fromorigin)
            # The Y axis is positive in the down direction, which is opposite from the convention in the,
            # rest of the code, so this makes the Y axis positive in the up direction.
            direction = (direction[1], -direction[2])

            if !isnan(direction[1]) && !isnan(direction[2])
                positionevent = MouseDragPositionEvent(direction)
                state.visualizationstate = onmousedrag(state.visualization, state.visualizationstate, positionevent)
            end
        end
    end
    GLFW.SetCursorPosCallback(window, mousepositioncallback)

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