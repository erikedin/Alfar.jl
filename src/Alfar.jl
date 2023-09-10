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

module Alfar

include("Math/Math.jl")
include("Fractal.jl")
include("Meshs.jl")
include("Rendering/Rendering.jl")
include("Visualizer/Visualizer.jl")

using GLFW
using ModernGL

end # module Alfar
