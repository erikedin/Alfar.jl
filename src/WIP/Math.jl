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

module Math

export Vector3, Vector4
export Matrix4

# Vector3 is a 3-dimensional vector in the coordinate system `System`.
# The value type of the individual coordinates is `T`.
struct Vector3{T, System}
    x::T
    y::T
    z::T
end

# Vector4 is a 4-dimensional vector in the coordinate system `System`.
# The value type of the individual coordinates is `T`.
struct Vector4{T, System}
    x::T
    y::T
    z::T
    w::T
end

function Base.:+(a::Vector3{T, System}, b::Vector3{T, System}) where {T, System}
    Vector3{T, System}(a.x + b.x, a.y + b.y, a.z + b.z)
end

function Base.:+(a::Vector4{T, System}, b::Vector4{T, System}) where {T, System}
    Vector4{T, System}(a.x + b.x, a.y + b.y, a.z + b.z, a.w + b.w)
end

function Base.:*(a::S, b::Vector4{T, System}) where {S, T, System}
    Vector4{T, System}(a * b.x, a * b.y, a * b.z, a * b.w)
end

function Base.isapprox(a::Vector3{T, System}, b::Vector3{T, System}) where {T, System}
    isapprox(a.x, b.x) && isapprox(a.y, b.y) && isapprox(a.z, b.z)
end

function Base.isapprox(a::Vector4{T, System}, b::Vector4{T, System}) where {T, System}
    isapprox(a.x, b.x) && isapprox(a.y, b.y) && isapprox(a.z, b.z) && isapprox(a.w, b.w)
end

#
# Matrices
#

struct Matrix4{T, ToSystem, FromSystem}
    a11::T
    a12::T
    a13::T
    a14::T

    a21::T
    a22::T
    a23::T
    a24::T

    a31::T
    a32::T
    a33::T
    a34::T

    a41::T
    a42::T
    a43::T
    a44::T
end

function Base.one(::Type{Matrix4{T, ToSystem, FromSystem}}) where {T, ToSystem, FromSystem}
    Matrix4{T, ToSystem, FromSystem}(
        1f0, 0f0, 0f0, 0f0,
        0f0, 1f0, 0f0, 0f0,
        0f0, 0f0, 1f0, 0f0,
        0f0, 0f0, 0f0, 1f0,
    )
end

function Base.:*(m::Matrix4{T, ToSystem, FromSystem}, v::Vector4{S, OtherSystem}) where {T, ToSystem, FromSystem, OtherSystem, S}
    m.a11 * Vector4{S, ToSystem}(v.x, v.y, v.z, v.w)
end

end