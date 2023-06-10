Alfar.Visualization
===================
The `Alfar.Visualization` module is for visualizing how the rendering works.
For instance, the first visualization is (will be) for viewport-aligned
slicing, to ensure that the code works properly.

# Running
To run the visualizer, do

```
$ julia --project=.
julia> using Alfar.Visualization
julia> Viz=Visualization            # For convience
julia> Viz.start()
```

# TODO
Here are some TODOs for Visualization:

- [ ] Viz.start() should start the OpenGL in the background and return

## Done

