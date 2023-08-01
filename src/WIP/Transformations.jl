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

module Transformations

using Alfar.WIP.Math

export PointRotation, transform

struct Quaternion{T}
    e0::T
    ei::T
    ej::T
    ek::T
end

function complement(q::Quaternion{T}) where {T}
    Quaternion{T}(q.e0, -q.ei, -q.ej, -q.ek)
end

function Base.:*(q::Quaternion{T}, p::Quaternion{T}) where {T}
    e0 = q.e0 * p.e0 - q.ei * p.ei - q.ej * p.ej - q.ek * p.ek
    ei = q.e0 * p.ei + q.ei * p.e0 + q.ej * p.ek - q.ek * p.ej
    ej = q.e0 * p.ej + q.ej * p.e0 + q.ek * p.ei - q.ei * p.ek
    ek = q.e0 * p.ek + q.ek * p.e0 + q.ei * p.ej - q.ej * p.ei
    Quaternion{T}(e0, ei, ej, ek)
end

# PointRotation is a rotation that rotates a vector `v` in the same
# coordinate system that it originates in.
struct PointRotation{T, System}
    q::Quaternion{T}

    function PointRotation{T, System}(θ::T, axis::Vector3{T, System}) where {T, System}
        # This defines the quaternion that will rotate the vector `v`.
        normalizedaxis = normalize(axis)
        q = Quaternion{T}(
            cos(θ / 2),
            sin(θ / 2) * normalizedaxis.x,
            sin(θ / 2) * normalizedaxis.y,
            sin(θ / 2) * normalizedaxis.z,
        )
        new{T, System}(q)
    end

    function PointRotation{T, System}(q::Quaternion{T}) where {T, System}
        new{T, System}(q)
    end
end

function transform(r::PointRotation{T, System}, v::Vector3{T, System}) :: Vector3{T, System} where {T, System}
    # The operator is q*v*qstar
    qstar = complement(r.q)
    # Reinterpret `v` as a pure quaternion (with zero for its scalar value)
    vq = Quaternion{T}(zero(T), v.x, v.y, v.z)
    # This is the actual rotation.
    result = r.q * vq * qstar
    # This reinterprets the resulting quaternion as a vector.
    # This is assumed to be a pure quaternion, but we can make a debug assert here
    # if we want.
    Vector3{T, System}(result.ei, result.ej, result.ek)
end

# Composition of two rotations
function Base.:∘(a::PointRotation{T, System}, b::PointRotation{T, System}) :: PointRotation{T, System} where {T, System}
    PointRotation{T, System}(a.q * b.q)
end

# Comparison
function Base.isapprox(a::PointRotation{T, System}, b::PointRotation{T, System}) where {T, System}
    atol = sqrt(eps(T))
    isapprox(a.q.e0, b.q.e0; atol=atol) &&
    isapprox(a.q.ei, b.q.ei; atol=atol) &&
    isapprox(a.q.ej, b.q.ej; atol=atol) &&
    isapprox(a.q.ek, b.q.ek; atol=atol)
end

# Convert a point rotation to a Matrix4
function Base.convert(::Type{Matrix4{T, ToSystem, FromSystem}}, r::PointRotation{S, Other}) :: Matrix4{T, ToSystem, FromSystem} where {T, ToSystem, FromSystem, S, Other}
    q0 = r.q.e0
    q1 = r.q.ei
    q2 = r.q.ej
    q3 = r.q.ek

    a11 = 2*q0*q0 - 1 + 2*q1*q1
    a12 = 2*q1*q2 - 2*q0*q3
    a13 = 2*q1*q3 + 2*q0*q2
    a14 = 0f0

    a21 = 2*q1*q2 + 2*q0*q3
    a22 = 2*q0*q0 - 1 + 2*q2*q2
    a23 = 2*q2*q3 - 2*q0*q1
    a24 = 0f0

    a31 = 2*q1*q3 - 2*q0*q2
    a32 = 2*q2*q3 + 2*q0*q1
    a33 = 2*q0*q0 - 1 + 2*q3*q3
    a34 = 0f0

    a41 = 0f0
    a42 = 0f0
    a43 = 0f0
    a44 = 1f0
    Matrix4{T, ToSystem, FromSystem}(
        a11, a12, a13, a14,
        a21, a22, a23, a24,
        a31, a32, a33, a34,
        a41, a42, a43, a44,
    )
end

# FrameRotation rotates a vector `v` from one coordinate system to another.

end