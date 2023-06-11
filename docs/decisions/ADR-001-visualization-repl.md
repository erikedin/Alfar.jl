---
status: accepted
date: 2023-06-11
deciders: Erik Edin
---
# Using Visualization from the Julia REPL

## Context and Problem Statement
We would like to use the `Visualization` tool from the Julia REPL, and control it from there.
This means that the `Visualization` tool needs to run in a separate thread or process, as the
REPL needs to continue running.

Should the `Visualization` tool use threads or a worker process to run?

## Decision Drivers

* `GLFW` has restrictions on which thread it must run in

## Considered Options

* Run in a separate thread
* Run in a worker process

## Decision Outcome

Chosen option: "Run in a worker process", because communication using Julia `Channel`s did
not function as expected when running the `GLFW` application in a separate thread. Running
it in a process allows the `GLFW` application to run in the main thread, as it is a separate
process. The `GLFW` documentation states that the application must run in the main thread.

### Consequences

* Good, because `GLFW` can be used properly from the main thread.

The Julia process must be started with the option `-p N`, which starts `N` worker processes.
