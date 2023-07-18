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

# Inputs defines some common types around inputs, such as keyboard and mouse.
module Inputs

export KeyboardInputEvent
export MouseDragEvent, MouseDragStartEvent, MouseDragEndEvent, MouseDragPositionEvent

struct KeyboardInputEvent
    window
    key
    scancode
    action
    mods
end

abstract type MouseDragEvent end
struct MouseDragStartEvent <: MouseDragEvent end
struct MouseDragEndEvent <: MouseDragEvent end
struct MouseDragPositionEvent <: MouseDragEvent
    direction::NTuple{2, Float64}
end

end