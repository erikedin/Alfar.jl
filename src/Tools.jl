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

module Tools

using Alfar.Format.STL: V3, STLBinary

struct BoundingBox
    min::V3
    max::V3
end

function minv3(a::V3, b::V3) :: V3
    V3([
        min(a[1], b[1]),
        min(a[2], b[2]),
        min(a[3], b[3]),
    ])
end

function maxv3(a::V3, b::V3) :: V3
    V3([
        max(a[1], b[1]),
        max(a[2], b[2]),
        max(a[3], b[3]),
    ])
end

function boundingbox(stl::STLBinary) :: BoundingBox

    vmin = V3([0f0, 0f0, 0f0])
    vmax = V3([0f0, 0f0, 0f0])
    isfirst = true

    for triangle in stl.triangles
        if isfirst
            vmin = triangle.v1
            vmax = triangle.v1
            isfirst = false
        end

        vmin = minv3(vmin, triangle.v1)
        vmax = maxv3(vmax, triangle.v1)

        vmin = minv3(vmin, triangle.v2)
        vmax = maxv3(vmax, triangle.v2)

        vmin = minv3(vmin, triangle.v3)
        vmax = maxv3(vmax, triangle.v3)
    end

    BoundingBox(vmin, vmax)
end

end # module Tools