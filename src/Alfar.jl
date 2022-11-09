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

    # Loop until the user closes the window
    while !GLFW.WindowShouldClose(window)
        glClearColor(0.2f0, 0.3f0, 0.3f0, 1.0f0)
        glClear(GL_COLOR_BUFFER_BIT)

	    # Render here

        # Set alpha channel based on time
        timevalue = Float32(time())
        alpha = sin(2.0f0 * pi / 4.0f0 * timevalue) / 2.0f0 + 0.5f0

        use(program)

        uniform(program, "alpha", alpha)

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
