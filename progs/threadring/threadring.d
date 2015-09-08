import std.conv : to;
import std.stdio : writeln, stdout;
import core.sync.condition : Condition, Mutex;
import core.thread : ThreadGroup, Thread;

immutable uint NUM_THREADS = 503;
immutable uint STACK_SIZE = 16384;

extern (C) {
    void _exit(int exit_code);
    int sched_setaffinity(int pid, size_t cpusetsize, int[4]* mask);
}

__gshared int[NUM_THREADS+1] data;

void delegate() threadDelegate(int i, Condition curr, Condition next)
{
    return () {
        while (true) {
            synchronized (curr.mutex) { curr.wait(); }
            auto t = data[i-1];
            //writeln("at ",i, " received ",t);
            if (t > 0) {
                data[i%NUM_THREADS] = t-1;
                synchronized (next.mutex) { next.notify(); }
            } else {
                /// The End
                stdout.writeln(i);
                stdout.flush();
                _exit(0);
            }
        }
    };
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

    Condition curr = void;
    Condition next = new Condition(new Mutex);
    Condition first = next;

    auto grp = new ThreadGroup;
    foreach(i; 0..NUM_THREADS) {
        curr = next;
        next = (i == NUM_THREADS-1) ? first : new Condition(new Mutex);
        auto thread = new Thread(threadDelegate(i+1, curr, next), STACK_SIZE);
        grp.add(thread);
        thread.start();
        //if (i%20 == 0) writeln("created ",i);
    }

    /// start the show
    //writeln("start show");
    data[0] = N;
    synchronized (first.mutex) { first.notify(); }

    /// wait for the end
    grp.joinAll();
    return 0;
}
