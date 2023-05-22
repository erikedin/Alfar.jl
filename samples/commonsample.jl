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

function uniform(program::GLuint, name::String, value::GLfloat)
    location = uniformlocation(program, name)
    glUniform1f(location, value)
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

function Base.:*(a::Matrix{T}, b::Vector3{T}) where {T}
    v = [b[1], b[2], b[3], zero(T)]
    result = a * v
    (result[1], result[2], result[3])
end

#
# Camera transforms
#

struct CameraPosition
    position::Vector3{Float32}
    up::Vector3{Float32}
end

function rotatex(angle::Float32) :: Matrix{GLfloat}
    Matrix{GLfloat}(GLfloat[
        1f0 0f0 0f0 0f0;
        0f0 cos(angle) -sin(angle) 0f0;
        0f0 sin(angle) cos(angle) 0f0;
        0f0 0f0 0f0 1f0;
    ])
end

function rotatey(angle::Float32) :: Matrix{GLfloat}
    Matrix{GLfloat}(GLfloat[
        cos(angle) 0f0 sin(angle) 0f0;
        0f0 1f0 0f0 0f0;
        -sin(angle) 0f0 cos(angle) 0f0;
        0f0 0f0 0f0 1f0;
    ])
end

function rotatez(angle::Float32) :: Matrix{GLfloat}
    Matrix{GLfloat}(GLfloat[
        cos(angle) -sin(angle) 0f0 0f0;
        sin(angle) cos(angle) 0f0 0f0;
        0f0 0f0 1f0 0f0;
        0f0 0f0 0f0 1f0;
    ])
end

transform(c::CameraPosition, t::Matrix{GLfloat}) :: CameraPosition = CameraPosition(t * c.position, t * c.up)

# TODO Add rotation functions
# Then send position and up into new lookat

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

#
# Textures
#

# This is a definition of a texture, which is used to create the OpenGL buffers
# in methods like `make2dtexture`.
struct TextureDefinition2D
    width::Int
    height::Int
    data
end


struct TextureDefinition3D
    width::Int
    height::Int
    depth::Int
    data
end

function fill!(data, (width, height, depth), color)
   for x = 1:width
        for y = 1:height
            for z = 1:depth
                data[1, x, y, z] = UInt8(color[1])
                data[2, x, y, z] = UInt8(color[2])
                data[3, x, y, z] = UInt8(color[3])
                data[4, x, y, z] = UInt8(color[4])
            end
        end
    end
end

# depthalpha calculates a transparency given the depth of the slice.
function depthalpha(depth, r) :: UInt8
    trunc(UInt8, (r - 1) / (depth - 1) * 255)
end

function fillwithalpha!(data, (width, height, depth), color, isalphareversed)
    for x = 1:width
        for y = 1:height
            for z = 1:depth
                alpha = if isalphareversed
                    255 - depthalpha(depth, z)
                else
                    depthalpha(depth, z)
                end

                data[1, x, y, z] = UInt8(color[1])
                data[2, x, y, z] = UInt8(color[2])
                data[3, x, y, z] = UInt8(color[3])
                data[4, x, y, z] = alpha
            end
        end
    end
end

# This defines a 3D texture with 8 differently colored blocks,
# and a yellow bar going through the middle.
# It is the same for all 3D texture samples. The 2D texture is made to have the same
# color as the front part of this texture (at texture depth 0).
function generate3dtexture(width, height, depth)
    channels = 4
    flattexturedata = zeros(UInt8, width*height*depth*channels)
    texturedata = reshape(flattexturedata, (channels, depth, height, width))

    halfwidth = trunc(Int, width/2)
    halfheight = trunc(Int, height/2)
    halfdepth = trunc(Int, depth/2)

    # Fill each quadrant
    frontquadrant1 = @view texturedata[:, halfwidth+1:width    , halfheight+1:height    , 1:halfdepth]
    frontquadrant2 = @view texturedata[:,           1:halfwidth, halfheight+1:height    , 1:halfdepth]
    frontquadrant3 = @view texturedata[:,           1:halfwidth,            1:halfheight, 1:halfdepth]
    frontquadrant4 = @view texturedata[:, halfwidth+1:width    ,            1:halfheight, 1:halfdepth]

    backquadrant1  = @view texturedata[:, halfwidth+1:width    , halfheight+1:height    , halfdepth+1:depth]
    backquadrant2  = @view texturedata[:,           1:halfwidth, halfheight+1:height    , halfdepth+1:depth]
    backquadrant3  = @view texturedata[:,           1:halfwidth,            1:halfheight, halfdepth+1:depth]
    backquadrant4  = @view texturedata[:, halfwidth+1:width    ,            1:halfheight, halfdepth+1:depth]

    quadrantsize = (halfwidth, halfheight, halfdepth)
    fill!(frontquadrant1, quadrantsize, (255, 255, 255, 128))
    fillwithalpha!(frontquadrant2, quadrantsize, (255,   0,   0), true)
    fillwithalpha!(frontquadrant3, quadrantsize, (  0, 255,   0), true)
    fillwithalpha!(frontquadrant4, quadrantsize, (  0,   0, 255), true)

    fill!(backquadrant1, quadrantsize, (  0,   0,   0, 0))
    fillwithalpha!(backquadrant2, quadrantsize, (255,   0, 255), false)
    fillwithalpha!(backquadrant3, quadrantsize, (  0, 255, 255), false)
    fillwithalpha!(backquadrant4, quadrantsize, (127, 255, 212), false)

    # Fill the center with a yellow bar.
    barwidth = trunc(Int, width / 4)
    barheight = trunc(Int, width / 4)
    halfbarheight = trunc(Int, height / 8)
    halfbarwidth = trunc(Int, width / 8)
    halfbarheight = trunc(Int, height / 8)
    yellowbar = @view texturedata[:,
                                  halfwidth  - halfbarwidth  + 1:halfwidth  + halfbarwidth,
                                  halfheight - halfbarheight + 1:halfheight + halfbarheight,
                                  1:depth]
    fill!(yellowbar, (barwidth, barheight, depth), (255, 255, 0, 255))


    TextureDefinition3D(width, height, depth, flattexturedata)
end
