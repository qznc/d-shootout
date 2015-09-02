#!/usr/bin/env rdmd
//          Copyright Andreas Zwinkau 2015
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

import std.stdio : writeln, File;
import std.system;
import std.process : executeShell;
import core.cpuid : vendor, processor, coresPerCPU, threadsPerCPU;
import std.algorithm.iteration : splitter, uniq, map, sum;
import std.algorithm.sorting : sort;
import std.string : strip, replace;
import std.range : drop;
import std.file : SpanMode, dirEntries, chdir, getcwd, read, FileException;
import std.conv : text;
import std.datetime : StopWatch, TickDuration, Clock;
import std.experimental.logger : log, warning, Logger;
import std.array : array;
import std.getopt : getopt, defaultGetoptPrinter;
import std.math : sqrt;
import std.format : format;

/// How often to run each program
int RUN_COUNT = 5;

/// Provide a reason, why the benchmark is invalid
string INVALID_BENCHMARK = "";

immutable CFLAGS_GENERAL = "-Wall -O3 -fomit-frame-pointer -march=native";
immutable CFLAGS = CFLAGS_GENERAL~" -std=c99";
immutable CPPFLAGS = CFLAGS_GENERAL~" -std=c++11";
immutable DMDFLAGS = "-O -release -inline -boundscheck=off";
immutable GDCFLAGS = CFLAGS_GENERAL;
immutable LDCFLAGS = "-O -release -inline";

// global runtime configuration
bool quickly = false;
string prog = "";

string xpnd(string s, string prog) @property @safe nothrow
{
    string QUICKLY = quickly ? "-quickly" : "";
    return s
        .replace("GCC", "gcc -pipe "~CFLAGS)
        .replace("G++", "g++ -pipe "~CPPFLAGS)
        .replace("DMD", "dmd "~DMDFLAGS)
        .replace("GDC", "gdc -pipe "~GDCFLAGS)
        .replace("LDC", "ldc2 "~LDCFLAGS)
        .replace("QUICKLY", QUICKLY)
        .replace("PROG", prog);
}

struct Commands {
    string compile, run;
}

Commands[string][string] COMMANDS;

void command(string prog, string compiler, string run_args, string cmd_compile)
{
    auto run_cmd = "./"~prog~"."~compiler~".exe "~run_args;
    auto cmds = Commands(cmd_compile.xpnd(prog), run_cmd.xpnd(prog));
    if (!(prog in COMMANDS))
        COMMANDS[prog] = [compiler: cmds];
    else
        COMMANDS[prog][compiler] = cmds;
}

void setupCommands()
{
    string RUN_ARGS = quickly ? "10" : "20";
    string p = "binarytrees";
    if (prog == "" || prog == p) {
        command(p, "gcc", RUN_ARGS,
            "GCC -fopenmp -D_FILE_OFFSET_BITS=64 -I/usr/include/apr-1.0 PROG.c -o PROG.gcc.exe -lapr-1 -lgomp -lm");
        command(p, "g++", RUN_ARGS,
            "G++ -fopenmp PROG.cpp -o PROG.g++.exe -lboost_system");
        command(p, "dmd", RUN_ARGS,
            "DMD PROG.d -ofPROG.dmd.exe");
        command(p, "gdc", RUN_ARGS,
            "GDC PROG.d -o PROG.gdc.exe");
        command(p, "ldc", RUN_ARGS,
            "LDC PROG.d -ofPROG.ldc.exe");
    }

    RUN_ARGS = quickly ? "1000" : "100000";
    p = "fasta";
    if (prog == "" || prog == p) {
        command(p, "gcc", RUN_ARGS,
                "GCC -mfpmath=sse -msse3 -fopenmp PROG.c -o PROG.gcc.exe");
        command(p, "g++", RUN_ARGS,
                "G++ -mfpmath=sse -msse3 PROG.cpp -o PROG.g++.exe");
        command(p, "dmd", RUN_ARGS,
                "DMD PROG.d -ofPROG.dmd.exe");
        command(p, "gdc", RUN_ARGS,
                "GDC PROG.d -o p.gdc.exe");
        command(p, "ldc", RUN_ARGS,
                "LDC PROG.d -ofPROG.ldc.exe");
    }

    RUN_ARGS = "0 <PROG-inputQUICKLY.txt";
    p = "knucleotide";
    if (prog == "" || prog == p) {
        command(p, "gcc", RUN_ARGS,
                "GCC -fopenmp -include ../include/simple_hash3.h PROG.c -o PROG.gcc.exe");
        command(p, "g++", RUN_ARGS,
                "G++ -pthread PROG.cpp -o PROG.g++.exe -Wl,--no-as-needed");
        command(p, "dmd", RUN_ARGS,
                "DMD PROG.d -ofPROG.dmd.exe");
        command(p, "gdc", RUN_ARGS,
                "GDC PROG.d -o PROG.gdc.exe");
        command(p, "ldc", RUN_ARGS,
                "LDC PROG.d -ofPROG.ldc.exe");
    }

    RUN_ARGS = quickly ? "200" : "16000";
    p = "mandelbrot";
    if (prog == "" || prog == p) {
        command(p, "gcc", RUN_ARGS,
                "GCC -D_GNU_SOURCE -mfpmath=sse -msse2 -fopenmp PROG.c -o PROG.gcc.exe -lm");
        command(p, "g++", RUN_ARGS,
                "G++ -mfpmath=sse -msse2 -fopenmp PROG.cpp -o PROG.g++.exe");
        command(p, "dmd", RUN_ARGS,
                "DMD PROG.d -ofPROG.dmd.exe");
        command(p, "gdc", RUN_ARGS,
                "GDC PROG.d -o PROG.gdc.exe");
        command(p, "ldc", RUN_ARGS,
                "LDC PROG.d -ofPROG.ldc.exe");
    }

    RUN_ARGS = quickly ? "100" : "2098";
    p = "meteor";
    if (prog == "" || prog == p) {
        command(p, "gcc", RUN_ARGS,
                "GCC -mfpmath=sse -msse2 -fopenmp PROG.c -o PROG.gcc.exe -lm");
        command(p, "g++", RUN_ARGS,
                "G++ -mfpmath=sse -msse2 -fopenmp PROG.cpp -o PROG.g++.exe");
        command(p, "dmd", RUN_ARGS,
                "DMD PROG.d -ofPROG.dmd.exe");
        command(p, "gdc", RUN_ARGS,
                "GDC PROG.d -o PROG.gdc.exe");
        command(p, "ldc", RUN_ARGS,
                "LDC PROG.d -ofPROG.ldc.exe");
    }

    RUN_ARGS = quickly ? "27" : "10000";
    p = "pidigits";
    if (prog == "" || prog == p) {
        command(p, "gcc", RUN_ARGS,
                "GCC -mfpmath=sse -msse2 -fopenmp PROG.c -o PROG.gcc.exe -lgmp");
        command(p, "g++", RUN_ARGS,
                "G++ -mfpmath=sse -msse2 -fopenmp PROG.cpp -o PROG.g++.exe -lgmp -lgmpxx");
        command(p, "dmd", RUN_ARGS,
                "DMD PROG.d -ofPROG.dmd.exe");
        command(p, "gdc", RUN_ARGS,
                "GDC PROG.d -o PROG.gdc.exe");
        command(p, "ldc", RUN_ARGS,
                "LDC PROG.d -ofPROG.ldc.exe");
    }

    RUN_ARGS = "0 <PROG-inputQUICKLY.txt";
    p = "regexdna";
    if (prog == "" || prog == p) {
        command(p, "gcc", RUN_ARGS,
                "GCC -mfpmath=sse -msse2 -pthread -I/usr/include/tcl8.4 $(pkg-config --cflags --libs glib-2.0) PROG.c -o PROG.gcc.exe -ltcl8.4 -lglib-2.0");
        command(p, "g++", RUN_ARGS,
                "G++ -fopenmp -I/usr/local/src/re2/re2 PROG.cpp -o PROG.g++.exe");
        command(p, "dmd", RUN_ARGS,
                "DMD PROG.d -ofPROG.dmd.exe");
        command(p, "gdc", RUN_ARGS,
                "GDC PROG.d -o PROG.gdc.exe");
        command(p, "ldc", RUN_ARGS,
                "LDC PROG.d -ofPROG.ldc.exe");
    }

    RUN_ARGS = quickly ? "1000" : "50000000";
    p = "nbody";
    if (prog == "" || prog == p) {
        command(p, "gcc", RUN_ARGS,
                "GCC -mfpmath=sse -msse2 -fopenmp PROG.c -o PROG.gcc.exe -lm");
        command(p, "g++", RUN_ARGS,
                "G++ -mfpmath=sse -msse2 -fopenmp PROG.cpp -o PROG.g++.exe");
        command(p, "dmd", RUN_ARGS,
                "DMD PROG.d -ofPROG.dmd.exe");
        command(p, "gdc", RUN_ARGS,
                "GDC PROG.d -o PROG.gdc.exe");
        command(p, "ldc", RUN_ARGS,
                "LDC PROG.d -ofPROG.ldc.exe");
    }

    RUN_ARGS = "0 <PROG-inputQUICKLY.txt";
    p = "revcomp";
    if (prog == "" || prog == p) {
        command(p, "gcc", RUN_ARGS,
                "GCC -mfpmath=sse -msse2 -fopenmp PROG.c -o PROG.gcc.exe -lm");
        command(p, "g++", RUN_ARGS,
                "G++ -mfpmath=sse -msse2 -fopenmp PROG.cpp -o PROG.g++.exe");
        command(p, "dmd", RUN_ARGS,
                "DMD PROG.d -ofPROG.dmd.exe");
        command(p, "gdc", RUN_ARGS,
                "GDC PROG.d -o PROG.gdc.exe");
        command(p, "ldc", RUN_ARGS,
                "LDC PROG.d -ofPROG.ldc.exe");
    }

    RUN_ARGS = quickly ? "100" : "5500";
    p = "spectralnorm";
    if (prog == "" || prog == p) {
        command(p, "gcc", RUN_ARGS,
                "GCC -mfpmath=sse -msse2 -fopenmp PROG.c -o PROG.gcc.exe -lm");
        command(p, "g++", RUN_ARGS,
                "G++ -mfpmath=sse -msse2 -fopenmp PROG.cpp -o PROG.g++.exe");
        command(p, "dmd", RUN_ARGS,
                "DMD PROG.d -ofPROG.dmd.exe");
        command(p, "gdc", RUN_ARGS,
                "GDC PROG.d -o PROG.gdc.exe");
        command(p, "ldc", RUN_ARGS,
                "LDC PROG.d -ofPROG.ldc.exe");
    }

    RUN_ARGS = quickly ? "1000" : "50000000";
    p = "threadring";
    if (prog == "" || prog == p) {
        command(p, "gcc", RUN_ARGS,
                "GCC -pthread PROG.c -o PROG.gcc.exe");
        command(p, "g++", RUN_ARGS,
                "G++ -pthread PROG.cpp -o PROG.g++.exe");
        command(p, "dmd", RUN_ARGS,
                "DMD PROG.d -ofPROG.dmd.exe");
        command(p, "gdc", RUN_ARGS,
                "GDC PROG.d -o PROG.gdc.exe");
        command(p, "ldc", RUN_ARGS,
                "LDC PROG.d -ofPROG.ldc.exe");
    }
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

string compiler_version(string compiler)
{
    return firstLineExecuteShell(compiler~" --version");
}

string lsbDescription()
{
    auto r = firstLineExecuteShell("lsb_release -d");
    foreach(line; r.splitter(":").drop(1)) {
        return line.strip();
    }
    return "no output";
}

real median(T)(T[] nums) pure nothrow {
    //nums.sort(); // assume sorted
    if (nums.length == 0) return double.nan;
    if (nums.length & 1)
        return nums[$ / 2];
    else
        return (nums[$ / 2 - 1] + nums[$ / 2]) / 2.0;
}

real avg(T)(T[] nums) pure nothrow {
    if (nums.length == 0) return double.nan;
    return (cast(real)nums.sum()) / nums.length;
}

real stddev(T)(T[] nums) pure nothrow {
    if (nums.length == 0) return double.nan;
    const avg = avg(nums);
    const variance = nums.map!((a)=>(a-avg)*(a-avg)).sum() / nums.length;
    return sqrt(variance);
}

/// Run all the benchmarks
RunResults[] benchmark()
{
    RunResults[] results;
    foreach(prog, compilers; COMMANDS) {
        foreach(compiler, cmds; compilers) {
            const cwd = getcwd();
            scope(exit) chdir(cwd);
            chdir("progs/"~prog);
            results ~= allRuns(compiler, prog, cmds.compile, cmds.run);
        }
    }
    results.sort!"a.compiler < b.compiler";
    return results;
}

TickDuration timedRun(string cmd, string prog, out bool output_mismatch)
{
    StopWatch sw;
    sw.start();
    auto res = executeShell(cmd);
    sw.stop();
    if (res.status != 0) {
        warning(cmd, " ->", res.status);
        INVALID_BENCHMARK = "run failed: "~cmd;
        return TickDuration.zero();
    }
    // check output with reference
    auto postfix = quickly ? "-output-quickly.txt" : "-output.txt";
    try {
        string reference = cast(string) read(prog~postfix);
        if (reference != res.output) {
            warning("output mismatch: ", cmd);
            INVALID_BENCHMARK = "output mismatch: "~cmd;
            output_mismatch = true;
        }
    } catch (FileException e) {
        warning("reference output missing: ", cmd);
        INVALID_BENCHMARK = "reference output missing: "~cmd;
    }
    return sw.peek();
}

struct RunResults {
    string compiler, prog, cmd_compile, cmd_exec;
    long[] durations;
    bool output_mismatch = false;
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
    const compile = executeShell(cmd_compile);
    if (compile.status != 0) {
        warning(cmd_compile, " ->", compile.status);
        return ret;
    }
    foreach(_; 0..RUN_COUNT) {
        ret.durations ~= timedRun(cmd_exec, prog, ret.output_mismatch).msecs();
    }
    ret.durations.sort();
    //writeln(compiler, ret.durations);
    return ret;
}

void generateWebsite(const RunResults[] results)
{
    auto f = File("index.html", "w");
    f.writeln("<html><head><title>Shootout</title>");
    f.writeln("<meta charset=\"UTF-8\">");
    f.writeln("<link rel=\"stylesheet\" href=\"style.css\">");
    f.writeln("</head><body>");
    f.writeln("<h1>D Performance Shootout</h1>");
    if (INVALID_BENCHMARK != "") {
        f.writeln("<p class=\"invalid-msg\"><strong>Benchmark is invalid:</strong> ", INVALID_BENCHMARK, "</p>");
    }
    f.writeln("<h2>Timing Overview</h2>");
    f.writeln("<p>Format is \"fastest / average / median ±standard deviation\", each in milliseconds.</p>");
    f.writeln("<table><tr>");
    f.write("<td></td>");
    auto compilers = results.map!"a.compiler".uniq.array;
    foreach(compiler; compilers) {
        f.write("<th>", compiler, "</th>");
    }
    f.writeln("</tr>");
    foreach(prog, _; COMMANDS) {
        f.write("<tr>");
        f.write("<th>", prog);
        foreach(ext; ["d", "c", "cpp"]) {
            f.write(" <a href=\"progs/", prog, "/", prog, ".", ext, "\">.", ext, "</a>");
        }
        f.write("</th>");
        foreach(compiler; compilers) {
            foreach(res; results) {
                if (res.compiler != compiler || res.prog != prog) continue;
                const durs = res.durations;
                f.write("<td title=\"", durs);
                if (res.output_mismatch)
                    f.write(" output mismatch!");
                f.write("\"");
                if (durs.length == 0) {
                    f.write(" class=\"no-runs\">no runs");
                } else {
                    if (durs[$-1] == 0) {
                        f.write(" class=\"zero-time\">runs failed");
                    } else {
                        if (res.output_mismatch)
                            f.write(" class=\"output-mismatch\">");
                        else
                            f.write(">");
                        f.write(durs[0], " / ");
                        f.write(avg(durs), " / ", median(durs), " ±");
                        f.write("%2.1f".format(stddev(durs)));
                    }
                }
                f.write("</td>");
                break;
            }
        }
        f.writeln("</tr>");
    }
    f.writeln("</table>");
    f.writeln("<h2>Test Environment</h2>");
    f.writeln("<table>");
    f.writeln("<tr><th>OS</th><td>",lsbDescription(),"</td></tr>");
    f.writeln("<tr><th>CPU</th><td>",vendor()," ", processor(),"</td></tr>");
    f.writeln("<tr><th>Parallelism</th><td>",coresPerCPU()," cores, ", threadsPerCPU(), " threads</td></tr>");
    f.writeln("<tr><th>DMD</th><td>",compiler_version("dmd"),"</td></tr>");
    f.writeln("<tr><th>GCC</th><td>",compiler_version("gcc"),"</td></tr>");
    f.writeln("<tr><th>GDC</th><td>",compiler_version("gdc"),"</td></tr>");
    f.writeln("<tr><th>LDC</th><td>",compiler_version("ldc2"),"</td></tr>");
    f.writeln("<tr><th>Runs</th><td>",RUN_COUNT,"</td></tr>");
    f.writeln("<tr><th>Time</th><td>", Clock.currTime().toISOExtString() ,"</td></tr>");
    f.writeln("</table>");
    f.write("<footer><p>");
    f.write("This benchmarking report was generated by <a href=\"https://github.com/qznc/d-shootout\">d-shootout</a>.");
    f.write("</p></footer>");
    f.writeln("</body></html>");
}

void main(string[] args)
{
    auto helpInfo = getopt(args,
        "quickly", "quick runs to check everything works", &quickly,
        "runs|r",  "number of runs (default=5)", &RUN_COUNT,
        "prog|p",  "specific program to run (all by default)", &prog,
    );
    if (helpInfo.helpWanted) {
        defaultGetoptPrinter("Runs benchmarks to compare D performance.",
                helpInfo.options);
        return;
    }
    setupCommands();
    const results = benchmark();
    if (RUN_COUNT < 5) INVALID_BENCHMARK = "Need at least 5 runs.";
    if (quickly) INVALID_BENCHMARK = "Ran --quickly.";
    generateWebsite(results);
}
