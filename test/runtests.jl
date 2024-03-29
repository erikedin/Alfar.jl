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

using Test

@testset "Alfar.Math  " begin

include("math/vector_test.jl")
include("math/matrix_test.jl")
include("math/rotation_test.jl")

end

@testset "Alfar.Rendering" begin

include("rendering/cameraview_test.jl")
include("rendering/viewport_alignment_test.jl")

end