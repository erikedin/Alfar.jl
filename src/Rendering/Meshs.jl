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

module Meshs

using ModernGL

export MeshBuffer, MeshAttribute, MeshDefinition
export VertexArray, VertexAttribute, VertexBuffer, VertexData
export renderarray

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

function MeshBuffer(meshdef::MeshDefinition) :: MeshBuffer
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

struct VertexAttribute
    attributeid::Int
    elementcount::Int
    attributetype::GLenum
    isnormalized::GLboolean
    offset::Ptr{Cvoid}
end

struct VertexData{T}
    data::Vector{T}
    attributes::Vector{VertexAttribute}
end

elementscount(v::VertexData{T}) where {T} = sum([a.elementcount for a in v.attributes])

function vertexAttribPointer(v::VertexData{T}, a::VertexAttribute) where {T}
    glVertexAttribPointer(a.attributeid, a.elementcount, a.attributetype, a.isnormalized, 0, a.offset)
end

function vertexAttribPointer(v::VertexData{GLint}, a::VertexAttribute)
    println(a.attributeid, " ", a.elementcount, " ", a.attributetype, " ", 0, " ", a.offset)
    glVertexAttribIPointer(a.attributeid, a.elementcount, a.attributetype, 0, a.offset)
end

struct VertexBuffer
    id::GLuint

    function VertexBuffer()
        vbo = Ref{GLuint}()
        glGenBuffers(1, vbo)
        new(vbo[])
    end
end

function bind(v::VertexBuffer)
    glBindBuffer(GL_ARRAY_BUFFER, v.id)
end

function bufferdata(vbo::VertexBuffer, data::Vector{T}, mode::GLenum) where {T}
    bind(vbo)
    glBufferData(GL_ARRAY_BUFFER, sizeof(data), data, mode)
end

struct VertexArray{Primitive}
    id::GLuint
    count::Int

    function VertexArray{Primitive}(vertexdatas...) where {Primitive}
        vaoid = Ref{GLuint}()
        glGenVertexArrays(1, vaoid)
        glBindVertexArray(vaoid[])

        firstvertexdata = vertexdatas[1]
        count = trunc(Int, length(firstvertexdata.data) / elementscount(firstvertexdata))

        for vertexdata in vertexdatas
            vbo = VertexBuffer()
            bufferdata(vbo, vertexdata.data, GL_DYNAMIC_DRAW)

            for attribute in vertexdata.attributes
                vertexAttribPointer(vertexdata, attribute)
                glEnableVertexAttribArray(attribute.attributeid)
            end
        end

        new(vaoid[], count)
    end

end

function renderarray(v::VertexArray{Primitive}) where {Primitive}
    glBindVertexArray(v.id)
    glDrawArrays(Primitive, 0, v.count)
end

end