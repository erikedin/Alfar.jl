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

using Alfar.Fractal

m0 = MengerSponge{0}()
println("Menger sponge 0: ", fractal(m0))
println()

m1 = MengerSponge{1}()
println("Menger sponge 1: ", fractal(m1))
println("Menger sponge 1 size: $(size(fractal(m1)))")
println()

m2 = MengerSponge{2}()
println("Menger sponge 2: ", fractal(m2))
println("Menger sponge 2 size: $(size(fractal(m2)))")
println()