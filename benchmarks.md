# About the Benchmarks

## Binary Trees

Building and destroying lots of trees.
Is supposed to test garbage collectors.
In this benchmark scenario, nobody uses the GC though.

## Mandelbrot

Computing the classic Mandelbrot set image with resolution N.

Since each pixel is computed by itself, parallelisation is trivial.
Use a task for each line.

One trick that C/C++ does is to use __builtin_ia32_cmplepd and __builtin_ia32_movmskpd to compute two pixels in parallel.
This seems to provide roughly two time the throughput.

## N-Body

## Regex DNA

Use a regex engine to match and change some DNA sequence.

D can build the matcher at compile time,
which means it wins at a quick run.
On a full run, C (using TCL's regex engine) wins.

## Spectralnorm

## Fasta

Generate three DNA sequences.
One by repeating a predefined sequence.
Two by using a predefined probability distribution.

## K-Nucleotide

Count DNA subsequences of certain lengths in a hash map.

D uses builtin associative arrays, while C/C++ uses a custom hash map.
C/C++ also compresses DNA from ASCII into a 2bit representation.

## Meteor

Solve a little puzzle.

## Pi Digits

Compute N digits of Pi.

Requires an arbitrary precision data number.
C/C++ uses libGMP. D uses bignum from the standard library.

## Rev Comp

## Thread Ring

Spawn lots of threads and pass a token around for N steps.
