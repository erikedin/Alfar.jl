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

module Render

using ModernGL

export use, uniform

#
# Shader exceptions
#

struct ShaderCompilationError <: Exception
    msg::String
end

struct ShaderLinkingError <: Exception
    msg::String
end

#
# Shader utilities
#

function readshader(path::String)
    open(path, "r") do io
        read(io, String)
    end
end

function createshader(shaderpath, shadertype)
    shadersource = readshader(shaderpath)

    shader = glCreateShader(shadertype)

    glShaderSource(shader, 1, Ptr{GLchar}[pointer(shadersource)], C_NULL)
    glCompileShader(shader)

    issuccess = Ref{GLint}()
    glGetShaderiv(shader, GL_COMPILE_STATUS, issuccess)
    if issuccess[] != GL_TRUE
        errormsg = "Shader '$(shaderpath)' failed to compile"
        throw(ShaderCompilationError(errormsg))
    end

    shader
end

#
# Shader types
#

struct Shader{T}
    id::GLuint
end

function Shader{T}(path::String) where {T}
    id = createshader(path, T)
    Shader{T}(id)
end

delete(s::Shader{T}) where {T} = glDeleteShader(s.id)

const VertexShader = Shader{GL_VERTEX_SHADER}
const FragmentShader = Shader{GL_FRAGMENT_SHADER}

#
# Shader programs
#

struct ShaderProgram
    id::GLuint
end

attach(program::ShaderProgram, shader::Shader{T}) where {T} = glAttachShader(program.id, shader.id)

function ShaderProgram(vertexShaderPath::String, fragmentShaderPath) :: ShaderProgram
    fragmentshader = FragmentShader(fragmentShaderPath)
    vertexshader = VertexShader(vertexShaderPath)

    program = ShaderProgram(glCreateProgram())

    attach(program, vertexshader)
    attach(program, fragmentshader)
    glLinkProgram(program.id)

    issuccess = Ref{GLint}()
    glGetProgramiv(program.id, GL_LINK_STATUS, issuccess)
    if issuccess[] != GL_TRUE
        throw(ShaderLinkingError("Shaders failed to link"))
    end

    delete(vertexshader)
    delete(fragmentshader)

    program
end

use(program::ShaderProgram) = glUseProgram(program.id)

uniformlocation(program::ShaderProgram, name::String) = glGetUniformLocation(program.id, Ptr{GLchar}(pointer(name)))

function uniform(program::ShaderProgram, name::String, value::Float32)
    location = uniformlocation(program, name)
    glUniform1f(location, value)
end

function uniform(program::ShaderProgram, name::String, value::NTuple{3, GLfloat})
    location = uniformlocation(program, name)
    array = Ref([value...], 1)
    glUniform3fv(location, 1, array)
end

function uniform(program::ShaderProgram, name::String, value::NTuple{4, GLfloat})
    location = uniformlocation(program, name)
    array = Ref([value...], 1)
    glUniform4fv(location, 1, array)
end

struct Matrix4{T}
    e::Matrix{T}

    function Matrix4{T}(a::Matrix{T}) where {T}
        @assert size(a) == (4, 4)
        new{T}(a)
    end
end

function Base.:*(a::Matrix4{T}, b::Matrix4{T}) where {T}
    e = Array{T, 2}(undef, 4, 4)
    for row=1:4
        for col=1:4
            s = zero(T)
            for i=1:4
                s += a.e[row, i] * b.e[i, col]
            end
            e[row, col] = s
        end
    end
    Matrix4{T}(e)
end

function uniform(program::ShaderProgram, name::String, value::Matrix4{GLfloat})
    location = uniformlocation(program, name)
    array = Ref([value.e...], 1)
    glUniformMatrix4fv(location, 1, GL_FALSE, array)
end

const Vector3{T} = NTuple{3, T}

function Base.:-(a::Vector3{T}, b::Vector3{T}) :: Vector3{T} where {T}
    (a[1] - b[1], a[2] - b[2], a[3] - b[3])
end

function Base.:-(a::Vector3{T}) :: Vector3{T} where {T}
    (-a[1], -a[2], -a[3])
end

function Base.:*(a::Vector3{T}, s::T) :: Vector3{T} where {T}
    (a[1]*s, a[2]*s, a[3]*s)
end

function cross(a::Vector3{T}, b::Vector3{T}) :: Vector3{T} where {T}
    (
        a[2]*b[3] - a[3]*b[2],
        a[3]*b[1] - a[1]*b[3],
        a[1]*b[2] - a[2]*b[1],
    )
end

function normalize(a::Vector3{T}) :: Vector3{T} where {T}
    m = sqrt(a[1]*a[1] + a[2]*a[2] + a[3]*a[3])
    (a[1]/m, a[2]/m, a[3]/m)
end

function lookat(cameraposition::Vector3{Float32}, cameratarget::Vector3{Float32}, up::Vector3{Float32}) :: Matrix4{Float32}
    direction = normalize(cameraposition - cameratarget)
    right = normalize(cross(up, direction))
    cameraup = normalize(cross(direction, right))

    # TODO complete the function
    cameratranslation = Matrix4{Float32}([
        1f0 0f0 0f0 -cameraposition[1];
        0f0 1f0 0f0 -cameraposition[2];
        0f0 0f0 1f0 -cameraposition[3];
        0f0 0f0 0f0 1f0;
    ])
    other = Matrix4{Float32}([
        right[1] right[2] right[3] 0f0;
        cameraup[1] cameraup[2] cameraup[3] 0f0;
        direction[1] direction[2] direction[3] 0f0;
        0f0 0f0 0f0 1f0;

    ])
    other*cameratranslation
end

#
# Hard coded demo graphics
#

function scale(sx::Float32, sy::Float32, sz::Float32) :: Matrix4{GLfloat}
    Matrix4{GLfloat}(GLfloat[
        sx  0f0 0f0 0f0;
        0f0 sy  0f0 0f0;
        0f0 0f0 sz  0f0;
        0f0 0f0 0f0 1f0;
    ])
end

function translate(sx::Float32, sy::Float32, sz::Float32) :: Matrix4{GLfloat}
    Matrix4{GLfloat}(GLfloat[
        1f0 0f0 0f0 sx;
        0f0 1f0 0f0 sy;
        0f0 0f0 1f0 sz;
        0f0 0f0 0f0 1f0;
    ])
end

function rotatex(angle::Float32) :: Matrix4{GLfloat}
    Matrix4{GLfloat}(GLfloat[
        1f0 0f0 0f0 0f0;
        0f0 cos(angle) -sin(angle) 0f0;
        0f0 sin(angle) cos(angle) 0f0;
        0f0 0f0 0f0 1f0;
    ])
end

function rotatez(angle::Float32) :: Matrix4{GLfloat}
    Matrix4{GLfloat}(GLfloat[
        cos(angle) -sin(angle) 0f0 0f0;
        sin(angle) cos(angle) 0f0 0f0;
        0f0 0f0 1f0 0f0;
        0f0 0f0 0f0 1f0;
    ])
end

function perspective(fov::Float32, aspect::Float32, near::Float32, far::Float32) :: Matrix4{GLfloat}
    tanhalf = tan(fov/2f0)
    Matrix4{GLfloat}(GLfloat[
        1f0/(aspect*tanhalf) 0f0           0f0                          0f0;
        0f0                  1f0/(tanhalf) 0f0                          0f0;
        0f0                  0f0           -(far + near) / (far - near) -2f0*far*near / (far - near);
        0.0f0                0f0           -1f0 0f0;
    ])
end

function transformidentity() :: Matrix4{GLfloat} where {}
    Matrix4{GLfloat}([
         one(GLfloat) zero(GLfloat) zero(GLfloat) zero(GLfloat);
        zero(GLfloat)  one(GLfloat) zero(GLfloat) zero(GLfloat);
        zero(GLfloat) zero(GLfloat)  one(GLfloat) zero(GLfloat);
        zero(GLfloat) zero(GLfloat) zero(GLfloat)  one(GLfloat);
    ])
end

function setupgraphics()
    vertices = GLfloat[
         0.5f0,  0.5f0, 0.5f0, 1.0f0, 0.0f0, 0.0f0, # Top right
         0.5f0, -0.5f0, 0.5f0, 0.0f0, 1.0f0, 0.0f0, # Bottom right
        -0.5f0, -0.5f0, 0.5f0, 0.0f0, 0.0f0, 1.0f0, # Bottom left
        -0.5f0,  0.5f0, 0.5f0, 0.0f0, 1.0f0, 1.0f0, # Top left

         0.5f0,  0.5f0, -0.5f0, 1.0f0, 0.0f0, 0.0f0, # Top right
         0.5f0, -0.5f0, -0.5f0, 0.0f0, 1.0f0, 0.0f0, # Bottom right
        -0.5f0, -0.5f0, -0.5f0, 0.0f0, 0.0f0, 1.0f0, # Bottom left
        -0.5f0,  0.5f0, -0.5f0, 0.0f0, 1.0f0, 1.0f0, # Top left
    ]
    indices = GLuint[
        # Front cube face
        0, 1, 3,
        1, 2, 3,

        # Back cube face
        4, 5, 7,
        5, 6, 7,

        # Left cube face
        3, 2, 6,
        3, 6, 7,
    ]

    vao = Ref{GLuint}()
    glGenVertexArrays(1, vao)

    glBindVertexArray(vao[])

    vbo = Ref{GLuint}()
    glGenBuffers(1, vbo)

    glBindBuffer(GL_ARRAY_BUFFER, vbo[])
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW)

    ebo = Ref{GLuint}()
    glGenBuffers(1, ebo)

    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, ebo[])
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(indices), indices, GL_STATIC_DRAW)


    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 6*sizeof(GLfloat), C_NULL)
    glEnableVertexAttribArray(0)

    glVertexAttribPointer(1, 3, GL_FLOAT, GL_FALSE, 6*sizeof(GLfloat), Ptr{Cvoid}(3 * sizeof(GLfloat)))
    glEnableVertexAttribArray(1)

    program = ShaderProgram("shaders/vertex.glsl", "shaders/fragment.glsl")

    program, vao[]
end

end