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


module Rendering

using Alfar.WIP.Math

#
# Common coordinate systems
#
struct World end

World(x::T, y::T, z::T, w::T) where {T} = Vector4{T, World}(x, y, z, w)
World(x::T, y::T, z::T) where {T} = Vector3{T, World}(x, y, z)

include("Inputs.jl")
include("Shaders.jl")
include("Textures.jl")
include("Meshs.jl")
include("Cameras.jl")
include("CameraViews.jl")
end