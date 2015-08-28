# D Speed Shootout

Compare D to other languages like C.

## Dependencies

Of course, you need dmd, gdc, ldc and gcc.

Various C/C++ benchmarks need some dependencies.
For Ubuntu 14.04:

    sudo apt-get install libapr1-dev libglib2.0-dev tcl8.4-dev

## Usage

For a quick check, if everything works:

    ./benchmark.d --quickly

Remove the `--quickly` argument for a full run,
which will take a while.
Afterwards, look at the generated HTML report:

    xdg-open index.html

## TODO

* Try to find faster programs
* Do better automatic evaluation
