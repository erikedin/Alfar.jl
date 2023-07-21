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

# PointRotation is a rotation that rotates a vector `v` in the same
# coordinate system that it originates in.
struct PointRotation{T, System}
    Θ::T
    axis::Vector3{T, System}
end

function transform(::PointRotation{T, System}, v::Vector3{T, System}) where {T, System}
    v
end

# FrameRotation rotates a vector `v` from one coordinate system to another.

end