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

export Menger
export fractal

struct Empty{N} end
fractal(::Empty{0}) = [0]
function fractal(::Empty{N}) where {N}
    o = Empty{N-1}()
    f = fractal
    [
        f(o) f(o) f(o)
        f(o) f(o) f(o)
        f(o) f(o) f(o);;;

        f(o) f(o) f(o)
        f(o) f(o) f(o)
        f(o) f(o) f(o);;;
        
        f(o) f(o) f(o)
        f(o) f(o) f(o)
        f(o) f(o) f(o)
    ]
end

struct Menger{N} end

side(m::Menger{N}) where {N} = 3^N
function dimensions(m::Menger{N}) where {N}
    s = side(m)
    (s, s, s)
end
function size(m::Menger{N}) where {N}
    (x,y,z) = dimensions(m)
    x*y*z
end



fractal(m::Menger{0}) = [1]

function fractal(m::Menger{N}) where {N}
    x = Menger{N-1}()
    o = Empty{N-1}()
    f = fractal
    subdivision = [
        f(x) f(x) f(x)
        f(x) f(o) f(x)
        f(x) f(x) f(x);;;

        f(x) f(o) f(x)
        f(o) f(o) f(o)
        f(x) f(o) f(x);;;

        f(x) f(x) f(x)
        f(x) f(o) f(x)
        f(x) f(x) f(x);;;
    ]
end

end