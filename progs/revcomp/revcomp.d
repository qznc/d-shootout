// The Computer Language Benchmarks Game
// http://shootout.alioth.debian.org/
// Modified from my Python version by bearophile


import std.stdio, std.string;

void show(string[] seq, string table) {
    int tot, pos;

    foreach(word; seq)
        tot += word.length;
    auto seq2 = new char[tot]; // initial guess

    foreach(word; seq)
        foreach(c; word)
            if (c != '\n') {
                seq2[pos] = table[c];
                pos++;
            }
    seq2.length = pos;

    seq2.reverse;

    for(int i = 0; i < seq2.length; i += 60)
        writefln(seq2[i .. (i+60 > $) ? $ : i+60]);
}

void main() {
    string[] seq;
    auto tab = makeTrans("ACBDGHKMNSRUTWVYacbdghkmnsrutwvy",
                         "TGVHCDMKNSYAAWBRTGVHCDMKNSYAAWBR");

    foreach(line; stdin.byLine)
        if (line[0] == '>' || line[0] == ';') {
            show(seq, tab);
            writef(line);
            seq.length = 0;
        } else
            seq ~= line.idup;
    show(seq, tab);
}
