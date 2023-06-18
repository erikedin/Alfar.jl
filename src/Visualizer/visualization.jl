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

export Visualization

abstract type Visualization end

use(viz::Visualization) = Shaders.use(viz.program)
# TODO This program method is temporary, and should be removed as it breaks
# the abstraction.
program(viz::Visualization) = viz.program

#
# Define the Visualization methods for `Nothing`, so that we don't have to
# handle that as a special case.
#

setflags(::Nothing) = nothing
setup(::Nothing) = nothing
render(::Nothing) = nothing

include("Visualizations/ViewportAlignmentAlgorithm.jl")
include("Visualizations/ViewportAnimated09.jl")
