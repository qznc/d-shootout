/* The Great Computer Language Shootout
   http://shootout.alioth.debian.org/

   Contributed by Dave Fladebo
   Parallelized by Andreas Zwinkau
   compile: dmd -O -inline -release mandelbrot2.d
*/

import std.stdio : writefln, stdout;
import std.conv : to;
import std.parallelism : parallel;

immutable iter = 50;
immutable lim = 2.0 * 2.0;

double norm(cdouble C) pure nothrow @nogc @safe
{
    return C.re*C.re + C.im*C.im;
}

char[] computeLine(ulong y, int n) pure nothrow @safe
{
    char[] result;
    result.capacity = n/8;
    char bit_num = 0, byte_acc = 0;
    foreach(x; 0..n)
    {
        auto Z = 0 + 0i;
        auto C = 2*cast(double)x/n - 1.5 + 2i*cast(double)y/n - 1i;

        for(auto i = 0; i < iter && norm(Z) <= lim; i++)
            Z = Z*Z + C;

        byte_acc = cast(byte) (byte_acc << 1) | ((norm(Z) > lim) ? 0x00:0x01);

        bit_num++;
        if(bit_num == 8)
        {
            result ~= byte_acc;
            bit_num = byte_acc = 0;
        }
    }
    byte_acc  <<= (8-n%8);
    result ~= byte_acc;
    bit_num = byte_acc = 0;
    return cast(char[]) result;
}

void main(string[] args)
{
    char bit_num = 0, byte_acc = 0;
    int n = args.length == 2 ? to!int(args[1]) : 1;

    writefln("P4\n%d %d",n,n);
    char[][] outbytes;
    outbytes.length = n;

    foreach(y, ref line; parallel(outbytes))
        line = computeLine(y,n);
    foreach(line; outbytes)
        stdout.write(line);
}
