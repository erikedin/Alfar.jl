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

end