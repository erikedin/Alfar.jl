module Equoid

include("Render.jl")

using GLFW
using ModernGL

function run()
    # Create a window and its OpenGL context
    window = GLFW.CreateWindow(640, 480, "Equoid")

    # Make the window's context current
    GLFW.MakeContextCurrent(window)

    program, vao = Render.setupgraphics()

    # Loop until the user closes the window
    while !GLFW.WindowShouldClose(window)
        glClearColor(0.2f0, 0.3f0, 0.3f0, 1.0f0)
        glClear(GL_COLOR_BUFFER_BIT)

	    # Render here
        glUseProgram(program)
        glBindVertexArray(vao)
        glDrawArrays(GL_TRIANGLES, 0, 3)

	    # Swap front and back buffers
	    GLFW.SwapBuffers(window)

	    # Poll for and process events
	    GLFW.PollEvents()
    end

    GLFW.DestroyWindow(window)
end

end # module Equoid
