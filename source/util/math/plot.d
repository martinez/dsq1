module math.plot;
import std.range;
import std.process;

final class SignalPlotter
{
  double sample_rate_;
  ProcessPipes process_;

  this(double sample_rate)
  {
    this.sample_rate_ = sample_rate;
    process_ = pipeProcess(["gnuplot"], Redirect.stdin);
  }

  ~this()
  {
    ProcessPipes *proc = &process_;
    proc.stdin.writeln("quit");
    proc.stdin.flush();
    proc.stdin.close();
    proc.pid.wait();
  }

  void plot(F)(F[][] signals) if (__traits(isFloating, F))
  {
    const double fs = this.sample_rate_;
    const ulong nsig = signals.length;
    const ulong nsamp = signals[0].length;

    ProcessPipes *proc = &process_;
    proc.stdin.write("plot ");
    proc.stdin.writeln("'-' using 1:2 with lines".repeat().take(nsig).join(",\\\n     "));
    foreach (F[] sig; signals) {
      for (ulong i = 0; i < nsamp; ++i)
        proc.stdin.writef("\t%f %f\n", i / fs, sig[i]);
      proc.stdin.write("EOF\n");
    }
    proc.stdin.flush();
  }
}
