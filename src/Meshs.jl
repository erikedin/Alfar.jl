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

using CUDA
using Adapt

export Mesh
export numberofvertices

struct Mesh{A}
    vertices::A
end
Adapt.@adapt_structure Mesh

function Mesh(vertices::Vector{Float32}) :: Mesh
    Mesh(CuArray(vertices))
end

numberofvertices(mesh::Mesh) :: Int = length(mesh.vertices) / 6

end