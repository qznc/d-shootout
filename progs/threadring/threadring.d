import std.conv : to;
import std.stdio : writeln;
import core.thread : ThreadGroup, Thread;

immutable uint NUM_THREADS = 503;
immutable uint STACK_SIZE = 32 * 1024;

struct pthread_mutex_t { byte[16]x; }

extern (C) {
    void _exit(int exit_code);
    int sched_setaffinity(int pid, size_t cpusetsize, int[4]* mask);
    int pthread_mutex_lock(pthread_mutex_t *mutex);
    int pthread_mutex_unlock(pthread_mutex_t *mutex);
    int pthread_mutex_init(pthread_mutex_t *mutex, void *attr);
}

__gshared pthread_mutex_t mutex[NUM_THREADS];
__gshared int data[NUM_THREADS];

void thread(int num)
{
   int l = num;
   int r = (l+1) % NUM_THREADS;

   while(true) {
      pthread_mutex_lock(&mutex[l]);
      int token = data[l];
      writeln("received ", token, " at ", l+1);
      if (token > 0) {
          data[r] = token - 1;
          pthread_mutex_unlock(&mutex[r]);
      } else {
          writeln(l+1);
          _exit(0);
          assert(false);
      }
   }
}

void delegate() do_thread(int i) {
    return (){ thread(i); };
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

    auto grp = new ThreadGroup;
    foreach(i; 0..NUM_THREADS) {
        pthread_mutex_init(&mutex[i], null);
        pthread_mutex_lock(&mutex[i]);
        auto thread = new Thread(do_thread(i), STACK_SIZE);
        grp.add(thread);
        thread.start();
        writeln("started ",i+1);
    }

    /// start the show
    writeln("start show with ", N, " at ", 1);
    data[0] = N;
    pthread_mutex_unlock(&mutex[0]);

    /// wait for the end
    grp.joinAll();
    return 0;
}
