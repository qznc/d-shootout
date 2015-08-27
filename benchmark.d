#!/usr/bin/env rdmd
import std.stdio : writeln, File;
import std.system;
import std.process : executeShell;
import core.cpuid : vendor, processor, coresPerCPU, threadsPerCPU;
import std.algorithm.iteration : splitter, uniq, map;
import std.algorithm.sorting : sort;
import std.string : strip;
import std.range : drop;
import std.file : SpanMode, dirEntries, chdir, getcwd;
import std.conv : text;
import std.datetime : StopWatch, TickDuration;
import std.experimental.logger : log, Logger;
import std.array : array;

immutable RUN_COUNT = 3;

string[string] test_benches()
{
    return [
        //"binarytrees": "17",
        //"fasta": "10000000",
        "binarytrees": "13",
        "fasta": "1000000",
        "knucleotide": "1",
        "mandelbrot": "1",
        "meteor": "1",
        "nbody": "1",
        "pidigits": "1",
        "regexdna": "1",
        //"revcomp": "1",
        "spectralnorm": "1",
        "threadring": "1",
        ];
}

string firstLineExecuteShell(string cmd)
{
    auto dmd = executeShell(cmd);
    if (dmd.status != 0) return "error";
    auto i = dmd.output;
    foreach(line; dmd.output.splitter("\n")) {
        return line;
    }
    return "no output";
}

string versionDMD()
{
    return firstLineExecuteShell("dmd --version");
}

string versionGCC()
{
    return firstLineExecuteShell("gcc --version");
}

string versionGDC()
{
    return firstLineExecuteShell("gdc --version");
}

string lsbDescription()
{
    auto r = firstLineExecuteShell("lsb_release -d");
    foreach(line; r.splitter(":").drop(1)) {
        return line.strip();
    }
    return "no output";
}

T median(T)(T[] nums) pure nothrow {
    nums.sort();
    if (nums.length & 1)
        return nums[$ / 2];
    else
        return (nums[$ / 2 - 1] + nums[$ / 2]) / 2.0;
}

/// Run all the benchmarks
RunResults[] benchmark()
{
    RunResults[] results;
    foreach(prog, args; test_benches()) {
        const cwd = getcwd();
        scope(exit) chdir(cwd);
        chdir("progs/"~prog);
        results ~= allRuns("gcc", prog,
                "gcc -Wall -O3 -std=c11 "~prog~".c -lm -lgmp -o"~prog~".gcc.exe",
                "./"~prog~".gcc.exe "~args);
        results ~= allRuns("g++", prog,
                "g++ -Wall -O3 -std=c++11 "~prog~".cpp -lm -lgmp -o"~prog~".g++.exe",
                "./"~prog~".g++.exe "~args);
        results ~= allRuns("dmd", prog,
                "dmd -O -release "~prog~".d -of"~prog~".dmd.exe",
                "./"~prog~".dmd.exe "~args);
    }
    results.sort!"a.compiler < b.compiler";
    return results;
}

TickDuration timedRun(string cmd)
{
    StopWatch sw;
    log(cmd);
    sw.start();
    auto res = executeShell(cmd);
    sw.stop();
    if (res.status != 0) return TickDuration.zero();
    return sw.peek();
}

struct RunResults {
    string compiler, prog, cmd_compile, cmd_exec;
    long[] durations;
    public this(string compiler, string prog, string cmd_compile, string cmd_exec)
    {
        this.compiler = compiler;
        this.prog = prog;
        this.cmd_compile = cmd_compile;
        this.cmd_exec = cmd_exec;
    }
}

RunResults allRuns(string compiler, string prog, string cmd_compile, string cmd_exec)
{
    auto ret = RunResults(compiler, prog, cmd_compile, cmd_exec);
    const compile = timedRun(cmd_compile);
    if (compile.msecs() == 0) return ret;
    foreach(_; 0..RUN_COUNT) {
        ret.durations ~= timedRun(cmd_exec).msecs();
    }
    ret.durations.sort();
    //writeln(compiler, ret.durations);
    return ret;
}

void benchmarkD(string prog)
{
    //timedRun("dmd -O -release "~prog~".d -of"~prog~".dmd.exe");
    //timedRun("gdc -O -release "~prog~".d -of"~prog~".gdc.exe");
}

void generateWebsite(const RunResults[] results)
{
    auto f = File("index.html", "w");
    f.writeln("<html><head><title>Shootout</title></head><body>");
    f.writeln("<h1>Timings</h1>");
    f.writeln("<table><tr>");
    f.write("<td></td>");
    auto compilers = results.map!"a.compiler".uniq.array;
    foreach(compiler; compilers) {
        f.write("<th>", compiler, "</th>");
    }
    f.writeln("</tr>");
    foreach(prog, args; test_benches()) {
        f.write("<tr>");
        f.write("<th>", prog, "</th>");
        foreach(compiler; compilers) {
            foreach(res; results) {
                if (res.compiler != compiler || res.prog != prog) continue;
                f.write("<td>", res.durations, "</td>");
                break;
            }
        }
        f.writeln("</tr>");
    }
    f.writeln("</table>");
    f.writeln("</body></html>");
}

void main()
{
    writeln("Vendor: ",vendor());
    writeln("Processor: ",processor());
    writeln("Parallelism: ",coresPerCPU(), " cores, ", threadsPerCPU(), " threads");
    writeln("dmd: ", versionDMD());
    writeln("gcc: ", versionGCC());
    writeln("gdc: ", versionGDC());
    writeln("OS: ", lsbDescription());
    const results = benchmark();
    generateWebsite(results);
    foreach(res; results) {
        writeln(res.compiler, " ", res.prog, " ", res.durations);
    }
}
