module ESQenvg;
import ESQsynth;
import ESQvoice;
import ESQpatch;
import std.stdio;
import std.algorithm;

private enum DEBUG_TRANSITIONS = true;

private enum float[64] EG_time_table = [
    .00, .01, .01, .02, .02, .03, .03, .03, .04, .04, .04, .05, .06, .06, .07,
    .08, .09, .10, .11, .13, .14, .16, .18, .20, .23, .25, .29, .32, .36, .40,
    .45, .51, .57, .64, .72, .81, .91, 1.02, 1.14, 1.28, 1.44, 1.61, 1.81, 2.03,
    2.28, 2.56, 2.87, 3.23, 3.62, 4.06, 4.56, 5.12, 5.75, 6.45, 7.24, 8.13, 9.12,
    10.24, 11.49, 12.90, 14.48, 16.25, 18.25, 20.48 ];

private enum Phase {
  Off, Atk, Dcy, At2, Sus, Rel,
}

struct ESQ_Envg
{
  ESQ_Voice *vc;
  uint id;

  int *output; /+ range -63..+63 +/

  int T1, T2, T3, T4;
  int L1, L2, L3;

  bool released;
  int level;
  int t;

  void init(ESQ_Voice *vc, uint id)
  {
    this.vc = vc;
    this.id = id;
    ESQ_Synth *synth = vc.synth;
    uint buffer_size = synth.buffer_size;
    output = new int[buffer_size].ptr;
    reset();
  }

  /+@nogc+/ void reset()
  {
    released = false;
    level = 0;
    t = 0;
  }

  /+@nogc+/ ESQ_Env *get_parameters() {
    ESQ_Synth *synth = vc.synth;
    ESQ_Program *pgm = synth.active_program;
    return &pgm.envs[id];
  }

  /+@nogc+/ void trigger(uint vel)
  {
    compute_ts(vel);
    released = false;
    level = 0; // TODO retrig
    t = 0;
  }

  /+@nogc+/ void release()
  {
    released = true;
    T1 = -1;
    T2 = -1;
    T3 = -1;
    t = 0;
  }

  /+@nogc+/ @property Phase which_phase() {
    if (T1 >= 0) return Phase.Atk;
    else if (T2 >= 0) return Phase.Dcy;
    else if (T3 >= 0) return Phase.At2;
    else if (! released) return Phase.Sus;
    else if (T4 >= 0) return Phase.Rel;
    else return Phase.Off;
  }

  /+@nogc+/ @property bool running() {
    return T4 >= 0;
  }

  /+@nogc+/ void run(uint nframes)
  {
    generate(nframes);
  }

 private:

  /+@nogc+/ void generate(uint nframes)
  {
    uint i = 0;

    if (i < nframes && T1 >= 0) { // Atk
      int n = min(T1-t, cast(int)(nframes-i));
      float sl = cast(float)L1/T1;
      int start = level;
      level = (T1 == 0) ? L1 : cast(int)(sl*t);
      generate_linear(n, start, level, &output[i]);
      t += n;
      i += n;
      if (t == T1) { T1 = -1; t = 0; }
    }

    if (i < nframes && T2 >= 0) { // Dcy
      int n = min(T2-t, cast(int)(nframes-i));
      float sl = cast(float)(L2-L1)/(T2-T1);
      int start = level;
      level = (T2 == 0) ? L2 : cast(int)(L1+sl*t);
      generate_linear(n, start, level, &output[i]);
      t += n;
      i += n;
      if (t == T2) { T2 = -1; t = 0; }
    }

    if (i < nframes && T3 >= 0) { // At2
      int n = min(T3-t, cast(int)(nframes-i));
      float sl = cast(float)(L3-L2)/(T3-T2);
      int start = level;
      level = (T3 == 0) ? L3 : cast(int)(L2+sl*t);
      generate_linear(n, start, level, &output[i]);
      t += n;
      i += n;
      if (t == T3) { T3 = -1; t = 0; }
    }

    if (i < nframes && ! released) { // Sus
      int n = nframes - i;
      generate_const(n, L3, &output[i]);
      level = L3;
      i += n;
    }

    if (i < nframes && released && T4 >= 0) { // Rel
      int n = min(T4-t, cast(int)(nframes-i));

      float sl = cast(float)(-L3)/(T4-T3);

      int start = level;
      level = (T4 == 0) ? 0 : cast(int)(L3+sl*t);
      generate_linear(n, start, level, &output[i]);

      // stderr.writefln("Rel at %d/%d start=%d end=%d target=%d",
      //                 i+1, nframes, start, level, 0);

      t += n;
      i += n;
      if (t == T4) { T4 = -1; t = 0; }
    }

    output[i..nframes] = 0;
  }

  /+@nogc+/ static void generate_const(uint nframes, int target, int *output)
  {
    for (uint i = 0; i < nframes; ++i)
      output[i] = target;
  }

  /+@nogc+/ static void generate_linear(uint nframes, int start, int target, int *output)
  {
    for (uint i = 0; i < nframes; ++i)
      //output[i] = start+(target-start)*i/nframes;
      output[i] = cast(int)(start+cast(float)(target-start)*i/nframes);
  }

  /+@nogc+/ void compute_ts(uint vel)
  {
    ESQ_Synth *synth = vc.synth;
    ESQ_Env *params = &synth.active_program.envs[id];
    const float fs = synth.sample_rate;

    T1 = cast(int)(EG_time_table[params.T1] * fs);
    T2 = cast(int)(EG_time_table[params.T2] * fs);
    T3 = cast(int)(EG_time_table[params.T3] * fs);
    T4 = cast(int)(EG_time_table[params.T4] * fs);

    L1 = params.L1;
    L2 = params.L2;
    L3 = params.L3;

    // TO ADJUST: attack with T1v (0..63)
    enum float T1vA = 0.1f;
    // T1 = 1.0f / (1.0f + (vel/127.0f) * (params.T1V/(63.0f*T1vA)));
  }
}
