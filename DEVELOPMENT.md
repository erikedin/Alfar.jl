Development of Alfar
====================
This package is about volume rendering, and learning all about it. I'm aiming to make an application
that I can use for simulation and hopefully modeling.

# Rendering
First I need to complete the rendering. To do that, I need to have a concrete goal in mind.
I'm going to go with my initial idea, which is to combine some 3D fractals and use those for
demonstrating the volume rendering capabilities. I would also like to use some available data sets
from medical imaging, but that is a later goal to have in mind.

Some 3D fractals I can combine:

- Menger sponge (already implemented)
- Sierpienski tetrahedron
- Icosahedron flake
- Cantor dust

The first three are apparently different n-flakes.

What I'm thinking is that I'll combine these, so that the volume will look like a Menger sponge, but
at level 5 (or whatever) I'll replace one part with an Icosahedron flake, and in some level of that,
I'll replace it with a Sierpienski tetrahedron. Something like that.
You'll have to modify the transfer functions to expose the inner fractals.

Once I've done that, I have something that works and looks cool, and then I can work on other data
sets and other functionality.

## Volume data
The fractal data could maybe be intensities, which is what you would store in the 3D texture, like
a medical image. Each sponge could have different intensities, which would allow you to have
transfer functions that expose the inner fractals.

# Modeling
The obvious thing for me is to create models for my small hydroponics setup at home.
The first thing to do would just be a very rectangular pot for plants.