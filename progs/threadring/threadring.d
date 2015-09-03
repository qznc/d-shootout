import std.concurrency : spawn, thisTid, Tid, receive, send;
import std.conv : to;
import std.stdio : writeln, stdout;

immutable uint NUM_THREADS = 503;

extern (C) {
    void _exit(int exit_code);
    int sched_setaffinity(int pid, size_t cpusetsize, int[4]* mask);
}

void rec_ring(int i, Tid first, bool isFirst)
{
    if (isFirst) first = thisTid;
    Tid next = void;
    if (i < NUM_THREADS) {
        /// spawn threads recursively
        //writeln("spawn ",i+1);
        next = spawn(&rec_ring, i+1, first, false);
    } else {
        /// wrap around to form a ring
        next = first;
    }

    /// receive tokens and pass them further
    while (true) {
        receive((int n) {
            if (n > 0) {
                //writeln("received ",n," at ",i);
                next.send(n-1);
            } else {
                /// The End
                stdout.writeln(i);
                stdout.flush();
                _exit(0);
            }
        });
    }
}

int main(string[] args)
{
    int N = 1000; /// for this N, we should write "498"
    if (args.length != 2)
        return 1; /// required by spec
    else
        N = to!int(args[1]);

    int[4] cpu_set_t;
    sched_setaffinity(0, 0, &cpu_set_t);

    auto first = spawn(&rec_ring, 1, thisTid, true);
    first.send(N);
    /// block the main thread indefinitely
    receive((int n) { assert(false); });
    assert(false);
}
