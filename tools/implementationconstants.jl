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

#
# Display the values for some implementation defined constants
#

using GLFW
using ModernGL

# Create a window and its OpenGL context
window = GLFW.CreateWindow(640, 480, "Implementation Constants")

# Make the window's context current
GLFW.MakeContextCurrent(window)

println("GL_MAX_3D_TEXTURE_SIZE = ", ModernGL.GL_MAX_3D_TEXTURE_SIZE)

GLFW.DestroyWindow(window)