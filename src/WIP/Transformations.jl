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
    θ::T
    axis::Vector3{T, System}
end

function transform(r::PointRotation{T, System}, v::Vector3{T, System}) :: Vector3{T, System} where {T, System}
    # This defines the quaternion that will rotate the vector `v`.
    axis = normalize(r.axis)
    q = Quaternion{T}(
        cos(r.θ / 2),
        sin(r.θ / 2) * axis.x, 
        sin(r.θ / 2) * axis.y, 
        sin(r.θ / 2) * axis.z, 
    )
    # ... along with its complement.
    qstar = complement(q)
    # Reinterpret `v` as a pure quaternion (with zero for its scalar value)
    vq = Quaternion{T}(zero(T), v.x, v.y, v.z)
    # This is the actual rotation.
    result = q * vq * qstar
    # This reinterprets the resulting quaternion as a vector.
    # This is assumed to be a pure quaternion, but we can make a debug assert here
    # if we want.
    Vector3{T, System}(result.ei, result.ej, result.ek)
end

# FrameRotation rotates a vector `v` from one coordinate system to another.

end