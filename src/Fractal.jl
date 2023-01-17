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

module Fractal

export MengerSponge
export fractal, size, dimensions

struct Empty{N} end

fractal(::Empty{0}) = [0]

function fractal(::Empty{N}) where {N}
    o = fractal(Empty{N-1}())
    [
        o o o
        o o o
        o o o;;;

        o o o
        o o o
        o o o;;;
        
        o o o
        o o o
        o o o
    ]
end

struct MengerSponge{N} end

side(m::MengerSponge{N}) where {N} = 3^N

function dimensions(m::MengerSponge{N}) where {N}
    s = side(m)
    (s, s, s)
end

function Base.size(m::MengerSponge{N}) where {N}
    (x,y,z) = dimensions(m)
    x*y*z
end

fractal(m::MengerSponge{0}) = [1]

function fractal(m::MengerSponge{N}) where {N}
    x = fractal(MengerSponge{N-1}())
    o = fractal(Empty{N-1}())
    [
        x x x
        x o x
        x x x;;;

        x o x
        o o o
        x o x;;;

        x x x
        x o x
        x x x;;;
    ]
end

end