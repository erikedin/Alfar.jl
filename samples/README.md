# Alfar samples
These samples are meant to show how to go from showing a 2D texture in OpenGL, to a 3D texture,
like one would use in volume rendering. The goal is that one should be able to diff one sample with the next
and see only changes that are relevant to this step, such as going from 2D to 3D.

The samples start with a static 2D texture and each next sample introduces a small change, ending up
with a 3D texture being displayed using volume rendering techniques.

The samples do not contain any controls to keep them as simple as possible.

# What does the texture look like?
The texture is a cube, currently 64x64x64 voxels.

The cube is mainly divided into octants, or front quadrants and back quadrants.

The front quadrants have the following colors:

```
|-----------------------|
| Q2: Red   | Q1: White |
|-----------|-----------|
| Q3: Green | Q4: Blue  |
|-----------------------|
```
Quadrant 1 is white, but semi-transparent, so that transparency can be demonstrated with the texture.

The back quadrants have the following colors:

```
|------------------------------|
| Q2: Purple | Q1: Transparent |
|------------|-----------------|
| Q3: Cyan   | Q4: Aquamarine  |
|------------------------------|
```

The center of the texture has a 16x16x64 yellow block. It extends from the front of the texture to the back,
but is centered along the width and height axis of the texture. This ensures that it is visible in every slice
of the texture.

# Sample: 01_2dtexture.jl
This is the first most basic sample. It creates a square and maps a 2D texture onto that square.

# Sample: 02_3dtexture.jl
This sample extends `01_2dtexture.jl` by making the texture 3D. It still uses the same square, and only
shows one slice of the 3D texture. The effect is that this will show the exact same thing as the previous sample.

# Sample: 03_animated3dtexture.jl
This sample extends `02_3dtexture.jl`.

The previous sample showed a single, static slice of the 3D texture. This sample still shows a single square,
but changes which slice of the 3D texture that is rendered onto the square. Essentially, it's as if it moves the
texture back and forth along the depth axis.