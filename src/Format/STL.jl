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

module STL

const V3 = NTuple{3, Float32}

struct Triangle
    normal::V3
end

struct STLBinary
    header::Vector{UInt8}
    ntriangles::UInt32
    triangles::Vector{Triangle}
end

abstract type STLBinaryParser end

abstract type ParserError end
struct GenericParserError <: ParserError end

struct OKParse{T}
    value::T
    position::Int
end

const ParseResult{T} = Union{OKParse{T}, ParserError}

struct HeaderParser <: STLBinaryParser end
struct NTrianglesParser <: STLBinaryParser end
struct V3Parser <: STLBinaryParser end

function parsestl(::HeaderParser, io::IO) :: ParseResult{Vector{UInt8}}
    value = read(io, 80)
    if length(value) == 80
        OKParse{Vector{UInt8}}(value, position(io))
    else
        GenericParserError()
    end
end

function parsestl(::NTrianglesParser, io::IO) :: ParseResult{UInt32}
    value = read(io, UInt32)
    OKParse{UInt32}(value, position(io))
end

function parsestl(::V3Parser, io::IO) :: ParseResult{V3}
    x = read(io, Float32)
    y = read(io, Float32)
    z = read(io, Float32)
    OKParse{V3}(V3([x, y, z]), position(io))
end

function readbinary!(io::IO) :: STLBinary
    parser = HeaderParser()
    result = parsestl(parser, io)
    if isa(result, ParserError)
        throw(result)
    end

    ntrianglesparser = NTrianglesParser()
    resultn = parsestl(ntrianglesparser, io)

    normalparser = V3Parser()
    resultnormal = parsestl(normalparser, io)

    STLBinary(result.value, resultn.value, Triangle[Triangle(resultnormal.value)])
end

end