// The Computer Language Benchmarks Game
// http://shootout.alioth.debian.org/
// by Andreas Zwinkau

import std.stdio, std.string;
import std.algorithm: sort, find, joiner, min;
import std.array: array;
import std.parallelism: taskPool, task;
import std.typecons: Tuple;

alias WorkUnit = Tuple!(string, "data", int, "length");
alias Result = Tuple!(size_t[string], "counts", size_t, "max");
immutable auto SPLIT_LENGTH = 30000;

void main() {
    string start = ">THREE Homo sapiens frequency";
    foreach (line; stdin.byLine) {
        if (line == start) break;
    }
    string data;
    foreach (line; stdin.byLine) {
        data ~= line.idup;
    }

    auto s1  = task!countNuc(WorkUnit(data,1));
    auto s2  = task!countNuc(WorkUnit(data,2));
    auto s3  = task!countNuc(WorkUnit(data,3));
    auto s4  = task!countNuc(WorkUnit(data,4));
    auto s6  = task!countNuc(WorkUnit(data,6));
    auto s12 = task!countNucParallel(WorkUnit(data,12));
    auto s18 = task!countNucParallel(WorkUnit(data,18));

    taskPool.put(s1);
    taskPool.put(s2);
    taskPool.put(s3);
    taskPool.put(s4);
    taskPool.put(s6);
    taskPool.put(s12);
    taskPool.put(s18);

    writeAll(s1.yieldForce, "a t g c".split);
    writeAll(s2.yieldForce, "aa at ta tt ca ga ag ac tg gt tc ct gg gc cg cc".split);
    writeln(s3 .yieldForce.counts["ggt"], "\tGGT");
    writeln(s4 .yieldForce.counts["ggta"], "\tGGTA");
    writeln(s6 .yieldForce.counts["ggtatt"], "\tGGTATT");
    writeln(s12.yieldForce.counts["ggtattttaatt"], "\tGGTATTTTAATT");
    writeln(s18.yieldForce.counts["ggtattttaatttatagt"], "\tGGTATTTTAATTTATAGT");
}

void writeAll(Result r, string[] order)
{
    auto counts = r.counts;
    foreach (l; order) {
        auto c = counts[l];
        writeln(l.toUpper," ", "%.3f".format(c*100.0/r.max));
    }
    writeln();
}

Result countNucParallel(WorkUnit u)
{
    auto split_count = u.data.length / SPLIT_LENGTH;
    //writeln("split into ", split_count);
    auto slen = u.data.length / split_count;
    WorkUnit[] splitted;
    splitted.reserve(split_count);
    foreach(n; 0..split_count) {
        auto i = n * slen;
        auto j = min(u.data.length, (n+1) * slen + u.length - 1);
        splitted ~= WorkUnit(u.data[i..j], u.length);
    }
    auto results = taskPool.amap!countNuc(splitted);
    auto ret = results[0];
    foreach (r; results[1..$]) {
        foreach (k,v; r.counts) {
            ret.counts[k] += v;
        }
    }
    const end = u.data.length - u.length;
    return ret;
}

Result countNuc(WorkUnit u) pure nothrow @safe
{
    assert (u.data.length > u.length);
    size_t[string] ret;
    const end = u.data.length - u.length + 1;
    for (size_t i; i < end; i++) {
        auto datum = u.data[i..(i+u.length)];
        ret[datum] += 1;
    }
    return Result(ret,end);
}
