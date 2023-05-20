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

#
# Shader creation
#

struct ShaderError <: Exception
    msg::String
end

function createshader(shadersource, shadertype)
    shader = glCreateShader(shadertype)

    glShaderSource(shader, 1, Ptr{GLchar}[pointer(shadersource)], C_NULL)
    glCompileShader(shader)

    issuccess = Ref{GLint}()
    glGetShaderiv(shader, GL_COMPILE_STATUS, issuccess)
    if issuccess[] != GL_TRUE
        maxlength = 512
        actuallength = Ref{GLsizei}()
        infolog = Vector{GLchar}(undef, maxlength)
        glGetShaderInfoLog(shader, maxlength, actuallength, infolog)
        infomessage = String(infolog[1:actuallength[]])
        errormsg = "Shader failed to compile: $(infomessage)"
        throw(ShaderError(errormsg))
    end

    shader
end

function makeprogram(vertexsource, fragmentsource)
    programid = glCreateProgram()
    vertexshader = createshader(vertexsource, GL_VERTEX_SHADER)
    fragmentshader = createshader(fragmentsource, GL_FRAGMENT_SHADER)

    glAttachShader(programid, vertexshader)
    glAttachShader(programid, fragmentshader)

    glLinkProgram(programid)

    issuccess = Ref{GLint}()
    glGetProgramiv(programid, GL_LINK_STATUS, issuccess)
    if issuccess[] != GL_TRUE
        throw(ShaderError("Shaders failed to link"))
    end

    programid
end

#
# Setting uniforms in shaders
#

uniformlocation(program::GLuint, name::String) = glGetUniformLocation(program, Ptr{GLchar}(pointer(name)))

function uniform(program::GLuint, name::String, value::Matrix{GLfloat})
    location = uniformlocation(program, name)
    array = Ref([value...], 1)
    glUniformMatrix4fv(location, 1, GL_FALSE, array)
end

#
# Vector types
#

const Vector3{T} = NTuple{3, T}

#
# Mesh type
#

# MeshBuffer is the OpenGL buffer that contains the mesh data.
struct MeshBuffer
    vao::GLuint
    numberofvertices::Int
end

#
# Mesh definition
# This defines the mesh and how the OpenGL buffer should be created to store it.
# The result will be a MeshBuffer, defined above.
#

# MeshAttribute contains the arguments for glVertexAttribPointer, which tells OpenGL
# what data is contained in the mesh and how it should be read from the buffer.
struct MeshAttribute
    attributeid::Int
    elementcount::Int
    attributetype::GLenum
    isnormalized::GLboolean
    offset::Ptr{Cvoid}
end

struct MeshDefinition
    # This stores the vertex data in a one-dimensional array of floats.
    vertices::Vector{GLfloat}
    # elementspervertex is the total number of elements for each vertex in `vertices`.
    # For instance, if each vertex has 3 positions elements (x, y, z), and the texture
    # positions have 2 elements each (s, t coordinates), the the total is 3+2 = 5.
    elementspervertex::Int
    attributes::Vector{MeshAttribute}
end

function makemeshbuffer(meshdef::MeshDefinition) :: MeshBuffer
    vao = Ref{GLuint}()
    glGenVertexArrays(1, vao)

    glBindVertexArray(vao[])

    vbo = Ref{GLuint}()
    glGenBuffers(1, vbo)

    # The stride is the number of bytes between one vertex element in vertices and the next.
    stride = meshdef.elementspervertex*sizeof(GLfloat)

    glBindBuffer(GL_ARRAY_BUFFER, vbo[])
    glBufferData(GL_ARRAY_BUFFER, sizeof(meshdef.vertices), meshdef.vertices, GL_DYNAMIC_DRAW)

    for meshattr in meshdef.attributes
        glVertexAttribPointer(meshattr.attributeid,
                              meshattr.elementcount,
                              meshattr.attributetype,
                              meshattr.isnormalized,
                              stride,
                              meshattr.offset)
        glEnableVertexAttribArray(meshattr.attributeid)
    end

    MeshBuffer(vao[], length(meshdef.vertices) / meshdef.elementspervertex)
end

#
# Camera functionality
#
# The camera isn't actually important for what the samples are meant to
# do. Therefore, this file contains some things that are different between samples;
# differences that would otherwise be highlighted in the sample files themselves.
#

struct Camera
    fov::Float32
    windowwidth::Int
    windowheight::Int
    near::Float32
    far::Float32
end

function Camera(width, height) :: Camera
    fov = 0.25f0*pi
    near = 0.1f0
    far = 100.0f0
    Camera(
        fov,
        width,
        height,
        near,
        far
    )
end

#
# Perspective and transformations
#

function objectmodel()
    Matrix{GLfloat}([
        1f0 0f0 0f0 0f0;
        0f0 1f0 0f0 0f0;
        0f0 0f0 1f0 0f0;
        0f0 0f0 0f0 1f0;

    ])
end

# This defines a "look at" matrix that looks at the square from the front,
# in the negative Z direction.
function lookatfromfront() :: Matrix{Float32}
    Matrix{GLfloat}([
        1f0 0f0  0f0  0f0;
        0f0 1f0  0f0  0f0;
        0f0 0f0 -1f0 -3f0;
        0f0 0f0  0f0  1f0;
    ])
end

function perspective(camera) :: Matrix{GLfloat}
    tanhalf = tan(camera.fov/2f0)
    aspect = Float32(camera.windowwidth) / Float32(camera.windowheight)
    far = camera.far
    near = camera.near

    Matrix{GLfloat}(GLfloat[
        1f0/(aspect*tanhalf) 0f0           0f0                          0f0;
        0f0                  1f0/(tanhalf) 0f0                          0f0;
        0f0                  0f0           -(far + near) / (far - near) -2f0*far*near / (far - near);
        0.0f0                0f0           -1f0 0f0;
    ])
end