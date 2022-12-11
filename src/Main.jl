# Copyright 2022 Erik Edin
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

module Main

export configureinput, render
export Camera, MouseState, AlfarMain

using GLFW
using Alfar.Math
using Alfar.Render
using Alfar.Meshs
using Alfar.Format.STL

mutable struct Camera
    position::Vector3{Float32}
    front::Vector3{Float32}
    up::Vector3{Float32}
    yaw::Float32
    pitch::Float32
    fov::Float32
end

function Camera() :: Camera
    fov = 0.25f0*pi
    Camera(
        (0f0, 0f0, 3f0),
        (0f0, 0f0, -1f0),
        (0f0, 1f0, 0f0),
        -pi/2f0,
        0f0,
        fov,
    )
end

mutable struct MouseState
    position::Vector2{Float64}
    isfirstmouseinput::Bool
end

MouseState() :: MouseState = MouseState((320, 240), true)

mutable struct Timing
    lastrender::Float64
    Timing() = new(time())
end
timesincelastrender(t::Timing) :: Float64 = time() - t.lastrender
rendered!(t::Timing) = t.lastrender = time()

struct AlfarMain
    camera::Camera
    mouse::MouseState
    timing::Timing
    program::ShaderProgram
    rendermesh::RenderMesh
end

function AlfarMain()
    program = ShaderProgram("shaders/vertex.glsl", "shaders/fragment.glsl")

    # Read hard coded STL file for now
    stl = open("mycube.stl", "r") do io
        STL.readbinary!(io)
    end
    rendermesh = makerendermesh(stl)

    AlfarMain(Camera(), MouseState(), Timing(), program, rendermesh)
end

function configureinput(app::AlfarMain, window::GLFW.Window)
    GLFW.SetInputMode(window, GLFW.CURSOR, GLFW.CURSOR_DISABLED)

    GLFW.SetKeyCallback(window, (_, key, scancode, action, mods) -> begin
        cameraspeed = 2.5f0 * Float32(timesincelastrender(app.timing))
        cameraright = normalize(cross(app.camera.front, app.camera.up))

        if key == GLFW.KEY_W && action == GLFW.PRESS
            app.camera.position += app.camera.front * cameraspeed
        end
        if key == GLFW.KEY_S && action == GLFW.PRESS
            app.camera.position -= app.camera.front * cameraspeed
        end
        if key == GLFW.KEY_A && action == GLFW.PRESS
            app.camera.position -= cameraright * cameraspeed
        end
        if key == GLFW.KEY_D && action == GLFW.PRESS
            app.camera.position += cameraright * cameraspeed
        end

        if key == GLFW.KEY_ESCAPE && action == GLFW.PRESS
            GLFW.SetWindowShouldClose(window, true)
        end
    end)

    GLFW.SetScrollCallback(window, (_, xoffset, yoffset) -> begin
        app.camera.fov -= Float32(yoffset)*2f0*pi/300
        if app.camera.fov < 2f0*pi/300f0
            app.camera.fov = 2f0*pi/300f0
        end
        if app.camera.fov > pi/4f0
            app.camera.fov = pi/4f0
        end
    end)

    GLFW.SetCursorPosCallback(window, (_, xpos, ypos) -> begin
        if app.mouse.isfirstmouseinput
            app.mouse.isfirstmouseinput = false
            app.mouse.position = (xpos, ypos)
        end
        lastposition = app.mouse.position
        newposition = (xpos, ypos)

        offset = (newposition[1] - lastposition[1], -(newposition[2] - lastposition[2]))

        app.mouse.position = newposition

        sensitivity = 0.005
        offset *= sensitivity

        app.camera.yaw += offset[1]
        app.camera.pitch += offset[2]

        if app.camera.pitch > (pi/2f0 - pi/100f0)
            app.camera.pitch = (pi/2f0 - pi/100f0)
        end
        if app.camera.pitch < -(pi/2f0 - pi/100f0)
            app.camera.pitch = -(pi/2f0 - pi/100f0)
        end

        cameradirection = (
            Float32(cos(app.camera.pitch) * cos(app.camera.yaw)),
            Float32(sin(app.camera.pitch)),
            Float32(cos(app.camera.pitch) * sin(app.camera.yaw))
        )
        app.camera.front = normalize(cameradirection)
    end)
end

function render(app::AlfarMain)
    angle = -1f0*pi*5f0/8f0

    scaling = Render.scale(1.0f0, 1.0f0, 1.0f0)

    view = Render.lookat(app.camera.position, app.camera.position + app.camera.front, app.camera.up)

    projection = Render.perspective(app.camera.fov, 640f0/480f0, 0.1f0, 100f0)

    use(app.program)

    uniform(app.program, "alpha", 1.0f0)
    uniform(app.program, "view", view)
    uniform(app.program, "projection", projection)
    uniform(app.program, "ambientStrength", 0.1f0)
    uniform(app.program, "lightColor", (1f0, 1f0, 1f0))
    uniform(app.program, "lightPosition", app.camera.position)

    bindmesh(app.rendermesh)
    rotation = Render.rotatex(angle) * Render.rotatez(angle)

    uniform(app.program, "model", rotation * scaling)
    draw(app.rendermesh)
    unbindmesh()

    rendered!(app.timing)
end

end