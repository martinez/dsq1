module ESQlfog;
import ESQsynth;
import ESQvoice;
import ESQpatch;
import std.stdio;
import std.random;

// LFO frequency table
//  computed from formula (using info from Transoniq Hacker #26)
//  it is a piecewise function, with some imprecision at the beginning
//    (x<8)   : 0.04497357142857143 * x
//    else    : 0.629629 + 0.3148148 * (x-8)
enum float[64] lfo_freq_table = [
  0.0, 0.04497357142857143, 0.08994714285714286, 0.13492071428571428, 0.17989428571428573, 0.22486785714285717, 0.26984142857142857, 0.314815, 0.629629, 0.9444437999999999, 1.2592586, 1.5740734, 1.8888882, 2.203703, 2.5185178, 2.8333326, 3.1481474, 3.4629622, 3.777777, 4.0925918, 4.4074066, 4.7222214000000005, 5.037036199999999, 5.351851, 5.6666658000000005, 5.981480599999999, 6.2962954, 6.611110200000001, 6.925924999999999, 7.2407398, 7.555554600000001, 7.8703693999999995, 8.1851842, 8.499999, 8.8148138, 9.1296286, 9.444443399999999, 9.7592582, 10.074073, 10.3888878, 10.7037026, 11.0185174, 11.3333322, 11.648147, 11.9629618, 12.2777766, 12.5925914, 12.9074062, 13.222221, 13.5370358, 13.8518506, 14.1666654, 14.4814802, 14.796295, 15.1111098, 15.4259246, 15.7407394, 16.0555542, 16.370369, 16.6851838, 16.9999986, 17.314813400000002, 17.629628200000003, 17.944443000000003,
];

struct ESQ_Lfog
{
  ESQ_Voice *vc;
  uint id;

  int *output;

  uint t;
  MinstdRand rnd;

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
    t = 0;
  }

  /+@nogc+/ ESQ_Lfo *get_parameters()
  {
    ESQ_Synth *synth = vc.synth;
    ESQ_Program *pgm = synth.active_program;
    return &pgm.lfos[id];
  }

  /+@nogc+/ float get_hz_frequency()
  {
    ESQ_Lfo *params = get_parameters();
    return lfo_freq_table[params.FREQ];
  }

  /+@nogc+/ void run(uint nframes)
  {
    /// TODO

    ESQ_Synth *synth = vc.synth;
    float fs = synth.sample_rate;

    ESQ_Lfo *params = get_parameters();
    uint L1 = params.L1, L2 = params.L2;

    bool HUMAN = params.HUMAN;

    uint t = this.t;
    scope(success) { this.t = t; }

    enum TBITS = 23; // below 2^24, the last exactly represented int value
    enum TSIZE = (1<<TBITS);
    enum TMASK = TSIZE-1;

    /+@nogc+/ float depth(uint i) {
      return 1; // TODO depth
    }

    /+@nogc+/ uint humanize(uint t) {
      if (HUMAN)
        t = t; // TODO random
      return t;
    }

    float freq = lfo_freq_table[params.FREQ] / fs;
    ESQ_LfoWave wav = params.WAV;

    uint tstep = cast(uint)(freq * TSIZE);

    if (wav == ESQ_LfoWave.TRI) {
      // the triangle wave goes from -63 to +63
      //  ^        +63
      // / \ /  -- 0
      //    v      -63
      enum QUARTER = TSIZE/4, HALF = TSIZE/2;
      for (uint i = 0; i < nframes; ++i) {
        float v;
        if (t < QUARTER)
          v = 63 * (cast(float)t/QUARTER);
        else if (t < 3*QUARTER)
          v = 63 - 126 * (cast(float)(t-QUARTER)/HALF);
        else
          v = -63 + 63 * (cast(float)(t-3*QUARTER)/QUARTER);
        output[i] = cast(int)(depth(i) * v);
        t = (t + humanize(tstep)) & TMASK;
      }
    } else if (wav == ESQ_LfoWave.SQR) {
      // the square wave only goes positive 0 to +63
      //   __      +63
      //  |  |__|  0
      //
      for (uint i = 0; i < nframes; ++i) {
        float v = (t < TSIZE/2) ? 63 : 0;
        output[i] = cast(int)(depth(i) * v);
        t = (t + humanize(tstep)) & TMASK;
      }
    } else if (wav == ESQ_LfoWave.SAW) {
      // the sawtooth wave goes from -63 to +63
      //    /|  /| +63
      //   / | / | 0
      //  /  |/  | -63
      for (uint i = 0; i < nframes; ++i) {
        float v = (126 * (cast(float)t/TSIZE)) - 63;
        output[i] = cast(int)(depth(i) * v);
        t = (t + humanize(tstep)) & TMASK;
      }
    } else if (wav == ESQ_LfoWave.NOI) {
      // the noise wave goes from -63 to +63
      // it is essentially random
      for (uint i = 0; i < nframes; ++i) {
        float v = (rnd.front % 127) - 63;
        rnd.popFront();
        output[i] = cast(int)(depth(i) * v);
        t = (t + humanize(tstep)) & TMASK;
      }
    }
  }
}
