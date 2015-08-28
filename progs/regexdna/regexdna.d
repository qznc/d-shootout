// The Computer Language Benchmarks Game
// http://shootout.alioth.debian.org/
// modified by bearophile, Dec 1 2007


import std.stdio, std.string, std.cstream;
import std.regex;

void main() {
    char[][] sseq;
    size_t n;
    char[1 << 15] cbuf;

    // auto seq = din.toString(); // SLOW
    while ((n = din.readBlock(cbuf.ptr, cbuf.length)) > 0)
        // sseq ~= cbuf[0 .. n][]; // slow
        sseq ~= cbuf[0 .. n].dup;
    auto seq = sseq.join("");
    auto ilen = seq.length;

    //seq = sub(seq, ">.*\n|\n", "", "g"); // SLOW!!
    seq = split(seq, ">.*\n|\n").join("");
    size_t clen = seq.length;

    foreach(p; split("agggtaaa|tttaccct
                      [cgt]gggtaaa|tttaccc[acg]
                      a[act]ggtaaa|tttacc[agt]t
                      ag[act]gtaaa|tttac[agt]ct
                      agg[act]taaa|ttta[agt]cct
                      aggg[acg]aaa|ttt[cgt]ccct
                      agggt[cgt]aa|tt[acg]accct
                      agggta[cgt]a|t[acg]taccct
                      agggtaa[cgt]|[acg]ttaccct")) {
        int m = 0;
        foreach(_; seq.matchAll(regex(p)))
            m++;
        writefln(p, ' ', m);
    }

    foreach(el; split("B(c|g|t) D(a|g|t) H(a|c|t) K(g|t) M(a|c)
                       N(a|c|g|t) R(a|g) S(c|g) V(a|c|g) W(a|t) Y(c|t)"))
        seq = seq.replaceAll(regex(el[0..1], "g"), el[1..$]);

    writefln("\n", ilen, "\n", clen, "\n", seq.length);
}
