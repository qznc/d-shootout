// transliterated from Mario Pernici's Python 3 program

import std.stdio : writefln;
import std.bigint : BigInt;
import std.conv : to;

void divmod(BigInt x, BigInt y, out BigInt q, out BigInt r) pure
{
    q = x / y;
    r = x % y;
}

int main(string[] args)
{
    int N;
    if (args.length != 2)
        return 1; /// required by spec
    else
        N = to!int(args[1]);

    long i, k;
    long k1 = 1;
    BigInt n=1, a=0, d=1, t=0, u=0, ns=0;
    while(true) {
        k += 1;
        t = n<<1;
        n *= k;
        a += t;
        k1 += 2;
        a *= k1;
        d *= k1;
        if (a >= n) {
            divmod(n*3 +a,d,t,u);
            u += n;
            if (d > u) {
                ns = ns*10 + t;
                i += 1;
                if (i % 10 == 0) {
                    writefln("%10d\t:%d", ns, i);
                    ns = 0;
                }
                if (i >= N) {
                    writefln("%-10d\t:%d", ns, i);
                    break;
                }
                a -= d*t;
                a *= 10;
                n *= 10;
            }
        }
    }
    return 0;
}
