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
using CUDA
using Adapt

export Mesh, RenderMesh
export numberofvertices
export mapresource, unmapresource

struct Mesh{A}
    vertices::A
end
Adapt.@adapt_structure Mesh

function Mesh(devicepointer::CUDA.CUdeviceptr, nbytes::Csize_t) :: Mesh
    vertexpointer = reinterpret(CuPtr{Float32}, devicepointer)
    len = nbytes / sizeof(Float32)
    vertices = unsafe_wrap(CuArray, vertexpointer, len)
    Mesh(vertices)
end

numberofvertices(mesh::Mesh) :: Int = length(mesh.vertices) / 6

# RenderMesh contains the OpenGL specific data of a mesh, while
# the Mesh contains the parts that CUDA will modify.
struct RenderMesh
    vao::GLuint
    vbo::GLuint
    graphicsResource::CUDA.CUgraphicsResource
end

function RenderMesh(vertices::Vector{Float32}) :: RenderMesh
    vao = Ref{GLuint}()
    glGenVertexArrays(1, vao)

    glBindVertexArray(vao[])

    vbo = Ref{GLuint}()
    glGenBuffers(1, vbo)

    glBindBuffer(GL_ARRAY_BUFFER, vbo[])
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_DYNAMIC_DRAW)

    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 6*sizeof(GLfloat), C_NULL)
    glEnableVertexAttribArray(0)

    glVertexAttribPointer(1, 3, GL_FLOAT, GL_FALSE, 6*sizeof(GLfloat), Ptr{Cvoid}(3 * sizeof(GLfloat)))
    glEnableVertexAttribArray(1)

    # Register the OpenGL buffer, with all the vertex data, with CUDA, so it may read and write
    # to that buffer.
    graphicsResourceRef = Ref{CUDA.CUgraphicsResource}()
    registerflags = CUDA.CU_GRAPHICS_REGISTER_FLAGS_WRITE_DISCARD
    CUDA.cuGraphicsGLRegisterBuffer(graphicsResourceRef, vbo[], registerflags)

    RenderMesh(vao[], vbo[], graphicsResourceRef[])
end

function mapresource(rendermesh::RenderMesh) :: Mesh
    CUDA.cuGraphicsMapResources(1, [rendermesh.graphicsResource], stream())

    devicepointer = Ref{CUDA.CUdeviceptr}()
    sizepointer = Ref{Csize_t}()
    CUDA.cuGraphicsResourceGetMappedPointer_v2(devicepointer, sizepointer, rendermesh.graphicsResource)

    Mesh(devicepointer[], sizepointer[])
end

function unmapresource(rendermesh::RenderMesh)
    CUDA.cuGraphicsUnmapResources(1, [rendermesh.graphicsResource], stream())
end

end
