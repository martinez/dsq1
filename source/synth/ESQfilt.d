module ESQfilt;
import ESQsynth;
import ESQvoice;
import ESQpatch;
import std.stdio;

private enum FilterImpl
  { Dummy, Moog, }
private enum impl = FilterImpl.Moog;

// I ignore the original cutoff values: this is from the Yamaha SY77
enum float[128] cutoff_freq_table = [
    0, 1, 1.756, 3.082, 5.415, 9.506, 16.69, 29.29, 51.40, 54.10, 56.98, 59.92, 63.09, 66.38, 69.91, 73.56, 77.44, 81.45, 85.81, 90.29, 95.01, 100.1, 105.3, 110.7, 116.6, 122.7, 129.1, 136, 143.1, 150.7, 158.5, 166.9, 175.5, 184.4, 194.6, 204.6, 215.4, 226.7, 238.7, 251.2, 264.3, 278.3, 292.8, 308.3, 324.4, 341.4, 359.5, 378.1, 398.2, 419.4, 441.1, 464.4, 488.7, 514.1, 541.2, 569.3, 599.5, 630.9, 664.5, 699.2, 735.1, 774.3, 814.8, 857.6, 902.7, 950.3, 1e3, 1.052e3, 1.103e3, 1.167e3, 1.228e3, 1.292e3, 1.359e3, 1.431e3, 1.507e3, 1.585e3, 1.669e3, 1.756e3, 1.847e3, 1.994e3, 2.047e3, 2.155e3, 2.269e3, 2.388e3, 2.514e3, 2.643e3, 2.785e3, 2.930e3, 3.085e3, 3.243e3, 3.417e3, 3.596e3, 3.786e3, 3.982e3, 4.191e3, 4.415e3, 4.646e3, 4.886e3, 5.144e3, 5.412e3, 5.693e3, 5.996e3, 6.314e3, 6.649e3, 6.982e3, 7.357e3, 7.732e3, 8.157e3, 8.585e3, 9.015e3, 9.510e3, 10.01e3, 10.52e3, 11.08e3, 11.64e3, 12.27e3, 12.90e3, 13.61e3, 14.28e3, 15.02e3, 15.88e3, 16.68e3, 17.61e3, 18.45e3, 19.47e3, 20.59e3, 21.52e3, 22.43e3,
];

struct ESQ_Filter
{
  ESQ_Voice *vc;

  float *input;
  float *output;

  void init(ESQ_Voice *vc)
  {
    this.vc = vc;
    ESQ_Synth *synth = vc.synth;
    uint buffer_size = synth.buffer_size;
    input = new float[buffer_size].ptr;
    output = new float[buffer_size].ptr;
    reset();
  }

  /+@nogc+/ ESQ_Misc *get_parameters()
  {
    ESQ_Synth *synth = vc.synth;
    ESQ_Program *pgm = synth.active_program;
    return &pgm.misc;
  }

  static if (impl == FilterImpl.Dummy)
  {
    /+@nogc+/ void reset()
    {
    }

    /+@nogc+/ void run(uint nframes)
    {
      // TODO !
      for (uint i = 0; i < nframes; ++i)
        output[i] = input[i];
    }
  }

  static if (impl == FilterImpl.Moog)
  {
    float b0, b1, b2, b3, b4; // filter buffers (beware denormals!)
    float t1, t2; // temporary buffers

    /+@nogc+/ void reset()
    {
      b0 = b1 = b2 = b3 = b4 = 0;
      t1 = t2 = 0;
    }

    /+@nogc+/ void run(uint nframes)
    {
      // Moog 24 dB/oct resonant lowpass VCF
      // References: CSound source code, Stilson/Smith CCRMA paper.
      // Modified by paul.kellett@maxim.abel.co.uk July 2000

      ESQ_Misc *params = get_parameters();

      const(float) fs = vc.synth.sample_rate;

      // filter coefficients
      // float frequency = cutoff_freq_table[params.FLTFC] / fs;
      float frequency = cutoff_freq_table[100] / (fs * 0.5f);
      float resonance = params.Q / 31.0; /+ TODO ratio? +/

      float b0 = this.b0, b1 = this.b1, b2 = this.b2, b3 = this.b3, b4 = this.b4;
      float t1 = this.t1, t2 = this.t2;

      scope(success) {
        this.b0 = b0; this.b1 = b1; this.b2 = b2; this.b3 = b3; this.b4 = b4;
        this.t1 = t1; this.t2 = t2;
      }

      // Set coefficients given frequency & resonance [0.0...1.0]

      const(int) *fmsrc1 = vc.mods.get_mod_source(params.FCSRC1);
      const(int) *fmsrc2 = vc.mods.get_mod_source(params.FCSRC2);
      int fmamt1 = params.FCMODAMT1;
      int fmamt2 = params.FCMODAMT2;

      // stderr.writefln("Filter fm:%s,%s", params.FCSRC1, params.FCSRC2);

      for (uint i = 0; i < nframes; ++i)
      {
        float frequency_mod = frequency;
        frequency_mod *= 1.0f
                + 0.01f /+ TODO ratio? +/ * fmsrc1[i] * (fmamt1/63.0f) /+ -63..63 +/
                + 0.01f /+ TODO ratio? +/  * fmsrc2[i] * (fmamt2/63.0f) /+ -63..63 +/;

        float q = 1.0f - frequency_mod;
        float p = frequency_mod + 0.8f * frequency_mod * q;
        float f = p + p - 1.0f;
        q = resonance * (1.0f + 0.5f * q * (1.0f - q + 5.6f * q * q));

        float x = input[i];

        // Filter (in [-1.0...+1.0])

        x -= q * b4; //feedback
        t1 = b1; b1 = (x + b0) * p - b1 * f;
        t2 = b2; b2 = (b1 + t1) * p - b2 * f;
        t1 = b3; b3 = (b2 + t2) * p - b3 * f;
        b4 = (b3 + t1) * p - b4 * f;
        b4 = b4 - b4 * b4 * b4 * 0.166667f; //clipping
        b0 = x;

        // Lowpass output: b4
        // Highpass output: in - b4;
        // Bandpass output: 3.0f * (b3 - b4);

        output[i] = b4;
      }
    }
  }

}
