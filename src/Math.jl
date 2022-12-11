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

module Math

export Vector3, Matrix4
export cross, normalize

#
# Vector3
#

const Vector3{T} = NTuple{3, T}
const Vector2{T} = NTuple{2, T}

function Base.:-(a::Vector3{T}, b::Vector3{T}) :: Vector3{T} where {T}
    (a[1] - b[1], a[2] - b[2], a[3] - b[3])
end

function Base.:+(a::Vector3{T}, b::Vector3{T}) :: Vector3{T} where {T}
    (a[1] + b[1], a[2] + b[2], a[3] + b[3])
end

function Base.:-(a::Vector3{T}) :: Vector3{T} where {T}
    (-a[1], -a[2], -a[3])
end

function Base.:*(a::Vector3{T}, s::T) :: Vector3{T} where {T}
    (a[1]*s, a[2]*s, a[3]*s)
end
function Base.:*(a::Vector2{T}, s::T) :: Vector2{T} where {T}
    (a[1]*s, a[2]*s)
end

function cross(a::Vector3{T}, b::Vector3{T}) :: Vector3{T} where {T}
    (
        a[2]*b[3] - a[3]*b[2],
        a[3]*b[1] - a[1]*b[3],
        a[1]*b[2] - a[2]*b[1],
    )
end

function normalize(a::Vector3{T}) :: Vector3{T} where {T}
    m = sqrt(a[1]*a[1] + a[2]*a[2] + a[3]*a[3])
    (a[1]/m, a[2]/m, a[3]/m)
end

#
# Matrix4
#

struct Matrix4{T}
    e::Matrix{T}

    function Matrix4{T}(a::Matrix{T}) where {T}
        @assert size(a) == (4, 4)
        new{T}(a)
    end
end

function Base.:*(a::Matrix4{T}, b::Matrix4{T}) where {T}
    e = Array{T, 2}(undef, 4, 4)
    for row=1:4
        for col=1:4
            s = zero(T)
            for i=1:4
                s += a.e[row, i] * b.e[i, col]
            end
            e[row, col] = s
        end
    end
    Matrix4{T}(e)
end


end # module Math