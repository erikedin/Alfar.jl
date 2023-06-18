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

@everywhere using Alfar.Visualizer

include("visualization.jl")

const PredefinedVisualizers = Dict{String, Type{<:Visualization}}([
    ("ViewportAnimated09", ViewportAnimated09),
    ("ViewportAlignment", ViewportAlignmentAlgorithm.ViewportAlignment),
])

struct VisualizationState
    visualizer::Union{Nothing, Visualization}
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
    println("Selecting visualizer $(ev.name)")
    visualizerfactory = get(PredefinedVisualizers, ev.name, nothing)
    println("Got visualizerfactory $(visualizerfactory)")
    visualizer = visualizerfactory()
    println("Got visualizer $(visualizer)")

    setflags(visualizer)
    setup(visualizer)

    VisualizationState(visualizer)
end


Shaders.use(::Nothing) = nothing

function runvisualizer(c::RemoteChannel)
    camera = Camera(1024, 800)

    # Create a window and its OpenGL context
    window = GLFW.CreateWindow(2048, 800, "Alfar Visualizer")

    # Make the window's context current
    GLFW.MakeContextCurrent(window)

    # Set background color to black
    glClearColor(0.0f0, 0.0f0, 0.0f0, 1.0f0)

    # Create the initial state of the visualizer
    state = VisualizationState()

    fullcircle = 20f0 # seconds to go around

    # Camera position
    # The first view sees the object from the front.
    originalcameraposition = CameraPosition((0f0, 0f0, -3f0), (0f0, 1f0, 0f0))

    # Key callbacks
    # We want to stop spinning when space is pressed, so listen to callbacks here, and
    # set a flag.
    isspinning = true

    togglespinningcallback = (window, key, scancode, action, mods) -> begin
        if action == GLFW.PRESS
            isspinning = !isspinning
        end
    end
    GLFW.SetKeyCallback(window, togglespinningcallback)

    startofmainloop = time()
    viewangle = 0f0

    # Loop until the user closes the window
    while !GLFW.WindowShouldClose(window)
        # If we have any events from the REPL, handle them.
        hasevents = isready(c)
        if hasevents
            println("Take event")
            ev = take!(c)
            println("Event: $(ev)")
            state = handle(window, ev, state)
        end

        now = time()
        timesincelastloop = Float32(now - startofmainloop)
        startofmainloop = now

        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)

        # Clear the full viewport
        glViewport(0, 0, camera.windowwidth * 2, camera.windowheight)

        # Calculate the viewing angle and transforms
        # Only when spinning. When spinning is disabled, don't update the angle.
        if isspinning
            # The viewangle is negative because we rotate the object in the opposite
            # direction, rather than rotating the camera.
            viewangle += Float32(-2f0 * pi * timesincelastloop / fullcircle)
        end

        zangle = 1f0 * pi / 8f0
        viewtransform = rotatez(zangle) * rotatey(viewangle)
        camerapositionviewport1 = transform(originalcameraposition, viewtransform)
        viewtransform2 = rotatez(zangle) * rotatey(viewangle - 5f0 * pi / 16f0)
        camerapositionviewport2 = transform(originalcameraposition, viewtransform2)

	    # Render here

        #
        # Viewport 1 (left)
        #
        glViewport(0, 0, camera.windowwidth, camera.windowheight)

        # Set uniforms
        cameratarget = (0f0, 0f0, 0f0)
        view = lookat(camerapositionviewport1, cameratarget)
        projection = perspective(camera)
        model = objectmodel()
        uniform(program(state.visualizer), "model", model)
        uniform(program(state.visualizer), "view", view)
        uniform(program(state.visualizer), "projection", projection)

        use(state.visualizer)
        render(state.visualizer)

        #
        # Viewport 2 (left)
        #
        glViewport(camera.windowwidth, 0, camera.windowwidth, camera.windowheight)

        # Set uniforms
        cameratarget = (0f0, 0f0, 0f0)
        view = lookat(camerapositionviewport2, cameratarget)
        projection = perspective(camera)
        model = objectmodel()
        uniform(program(state.visualizer), "model", model)
        uniform(program(state.visualizer), "view", view)
        uniform(program(state.visualizer), "projection", projection)

        use(state.visualizer)
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