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

module Meshs

using ModernGL

export RenderMesh
export numberofvertices
export draw, bindmesh, unbindmesh

struct RenderMesh
    vao::GLuint
    vbo::GLuint
    nvertices::Int
end

function RenderMesh(vertices::Vector{Float32}) :: RenderMesh
    vao = Ref{GLuint}()
    glGenVertexArrays(1, vao)

    glBindVertexArray(vao[])

    vbo = Ref{GLuint}()
    glGenBuffers(1, vbo)

    glBindBuffer(GL_ARRAY_BUFFER, vbo[])
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_DYNAMIC_DRAW)

    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 9*sizeof(GLfloat), C_NULL)
    glEnableVertexAttribArray(0)

    glVertexAttribPointer(1, 3, GL_FLOAT, GL_FALSE, 9*sizeof(GLfloat), Ptr{Cvoid}(3 * sizeof(GLfloat)))
    glEnableVertexAttribArray(1)

    glVertexAttribPointer(2, 3, GL_FLOAT, GL_FALSE, 9*sizeof(GLfloat), Ptr{Cvoid}(3 * sizeof(GLfloat)))
    glEnableVertexAttribArray(2)

    RenderMesh(vao[], vbo[], length(vertices))
end

numberofvertices(rendermesh::RenderMesh) :: Int = rendermesh.nvertices

function draw(rendermesh::RenderMesh)
    glDrawArrays(GL_TRIANGLES, 0, numberofvertices(rendermesh))
end

function bindmesh(rendermesh::RenderMesh)
    glBindVertexArray(rendermesh.vao)
end

function unbindmesh()
    glBindVertexArray(0)
end

end
