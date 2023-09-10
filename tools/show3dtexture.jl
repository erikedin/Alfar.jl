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

using Alfar.Visualizer
using Alfar.Visualizer.Show3DTextures
using Alfar.Rendering.Textures

context = Ref{Visualizer.VisualizerContext}()

context[] = Visualizer.start()

ev = Visualizer.SelectVisualizationEvent("Show3DTexture")
put!(context[].channel, ev)

slices = ARGS[:]

textureinputs2d = IntensityTextureInput{2, UInt16}[]
for slicepath in slices
    textureinput = open(slicepath, "r") do io
        flatformat = FlatBinaryFormat{UInt16}(io)
        dimension = TextureDimension{2}(256, 256)
        IntensityTextureInput{2, UInt16}(dimension, flatformat)
    end
    push!(textureinputs2d, textureinput)
end

dimension = TextureDimension{2}(256, 256)
textureinput = IntensityTextureInput{3, UInt16}(dimension, textureinputs2d)
println("Sending texture $(textureinput.dimension)")

ev = Show3DTextures.New3DTexture(textureinput)
put!(context[].channel, ev)

if !isinteractive()
    Visualizer.waituntilstop(context[])
end