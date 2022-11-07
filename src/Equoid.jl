module Equoid

include("Render.jl")

using GLFW

function run()
    # Create a window and its OpenGL context
    window = GLFW.CreateWindow(640, 480, "Equoid")

    # Make the window's context current
    GLFW.MakeContextCurrent(window)

    Render.setupgraphics()

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

end # module Equoid
