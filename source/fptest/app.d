
import math.fp;
import std.stdio;
import std.math;

void main(string[] args)
{
  // writeln(FP!(24,8).max.to!int);
  // writeln(FP!(24,8).min.to!int);
  // writeln(FP!(16,16).max.to!int);
  // writeln(FP!(16,16).min.to!int);
  // writeln(FP!(20,12).max.to!int);
  // writeln(FP!(20,12).min.to!int);
  // writeln(FP!(8,24).max.to!int);
  // writeln(FP!(8,24).min.to!int);

  FP!(16,16) fs = 48;
  FP!(16,16) ts = 1000/fs;
  writeln(fs);
  writeln(ts);

  FP!(16,16) f = 1e-3;
  FP!(16,16) t = 1000/f;
  writeln(f);
  writeln(t);
}
