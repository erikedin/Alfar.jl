# Alfar samples
These samples are meant to show how to go from showing a 2D texture in OpenGL, to a 3D texture,
like one would use in volume rendering. The goal is that one should be able to diff one sample with the next
and see only changes that are relevant to this step, such as going from 2D to 3D.

The samples start with a static 2D texture and each next sample introduces a small change, ending up
with a 3D texture being displayed using volume rendering techniques.

The samples do not contain any controls to keep them as simple as possible.

# Sample: 01_2dtexture.jl
This is the first most basic sample. It creates a square and maps a 2D texture onto that square.
The square is shown from the front.

# Sample: 02_3dtexture.jl
This sample extends `01_2dtexture.jl` by making the texture 3D. It still uses the same square, and only
shows one slice of the 3D texture. The effect is that this will show the exact same thing as the previous sample.

# Sample: 03_animated3dtexture.jl
This sample extends `02_3dtexture.jl`.

The previous sample showed a single, static slice of the 3D texture. This sample still shows a single square,
but changes which slice of the 3D texture that is rendered onto the square. Essentially, it's as if it moves the
texture back and forth along the depth axis.