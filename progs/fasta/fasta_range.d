// The Computer Language Benchmarks Game
// http://benchmarksgame.alioth.debian.org/
//
// by Andreas Zwinkau

import std.stdio : writeln;
import std.conv : to;
import std.exception : assumeUnique;
import std.range : cycle, take, chunks;
import std.array : array;

const size_t LINE_LENGTH = 60;
const IM = 139968;

struct IUB { float p; char c; }

struct IUB_norm { int p; char c; }

/// random number generator as input range
final class MyRandom(float max) {
    immutable int IA = 3877, IC = 29573, IM = 139968;
    int seed;
    this(int seed) { this.seed = seed; }
    auto front() @property { return max * seed / IM; }
    bool empty() @property { return false; }
    void popFront() { seed = (seed * IA + IC) % IM; }
}

/// Convert probabilities into cumulative probabilities
immutable(IUB_norm)[] accumulate_probabilities(const IUB[] data) {
    IUB_norm[] ret;
    ret.length = data.length;
    real acc = 0.0;
    foreach(i,d; data) {
        acc += d.p;
        ret[i] = IUB_norm(cast(int)(IM*acc), d.c);
    }
    return assumeUnique(ret);
}

/// input range to convert random numbers into characters
auto rand2char(R)(R rng, immutable(IUB_norm)[] chars) {
    static struct Result {
        R rng;
        immutable(IUB_norm)[] chars;
        char frnt = 'x';
        public this(R rng, immutable(IUB_norm)[] chars) {
            this.rng = rng;
            this.chars = chars;
            popFront();
        }
        auto front() @property { return frnt; }
        auto empty() @property { return rng.empty; }
        void popFront() {
            rng.popFront();
            auto r = rng.front;
            foreach (x; chars) {
                if (x.p >= r) {
                    frnt = x.c;
                    return;
                }
            }
            assert(false);
        }
    }
    return Result(rng, chars);
}

int main(string[] args) {
  if (args.length != 2) return -1;
  const n = to!int(args[1]);
  const alu =
      "GGCCGGGCGCGGTGGCTCACGCCTGTAATCCCAGCACTTT"~
      "GGGAGGCCGAGGCGGGCGGATCACCTGAGGTCAGGAGTTC"~
      "GAGACCAGCCTGGCCAACATGGTGAAACCCCGTCTCTACT"~
      "AAAAATACAAAAATTAGCCGGGCGTGGTGGCGCGCGCCTG"~
      "TAATCCCAGCTACTCGGGAGGCTGAGGCAGGAGAATCGCT"~
      "TGAACCCGGGAGGCGGAGGTTGCAGTGAGCCGAGATCGCG"~
      "CCACTGCACTCCAGCCTGGGCGACAGAGCGAGACTCCGTCT"~
      "CAAAAA";

  const iub = accumulate_probabilities([
      IUB(0.27, 'a'),
      IUB(0.12, 'c'),
      IUB(0.12, 'g'),
      IUB(0.27, 't'),
      IUB(0.02, 'B'),
      IUB(0.02, 'D'),
      IUB(0.02, 'H'),
      IUB(0.02, 'K'),
      IUB(0.02, 'M'),
      IUB(0.02, 'N'),
      IUB(0.02, 'R'),
      IUB(0.02, 'S'),
      IUB(0.02, 'V'),
      IUB(0.02, 'W'),
      IUB(0.02, 'Y')]);

  const homosapiens = accumulate_probabilities([
      IUB(0.3029549426680, 'a'),
      IUB(0.1979883004921, 'c'),
      IUB(0.1975473066391, 'g'),
      IUB(0.3015094502008, 't')]);

  writeln(">ONE Homo sapiens alu");
  foreach(line; alu.cycle.take(n*2).chunks(LINE_LENGTH)) {
    writeln(line);
  }

  auto rng = new MyRandom!IM(42);
  writeln(">TWO IUB ambiguity codes");
  foreach(line; rng.rand2char(iub).take(n*3).array.chunks(LINE_LENGTH)) {
    writeln(line);
  }

  auto rng2 = new MyRandom!IM(42);
  writeln(">THREE Homo sapiens frequency");
  foreach(line; rng2.rand2char(homosapiens).take(n*5).array.chunks(LINE_LENGTH)) {
    writeln(line);
  }

  return 0;
}

