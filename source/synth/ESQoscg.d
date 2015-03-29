module ESQoscg;
import ESQsynth;
import ESQpatch;
import ESQwaves;
import ESQvoice;
import ESQnote;
import fastmath.fmodf;
import std.stdio;

enum DEBUG_WAVES = true;

enum DISABLE_FM = true;
enum DISABLE_AM = true;

struct ESQ_Oscg
{
  // TODO oscillator sync

  ESQ_Voice *vc;
  uint id;
  int *output;

  float tab_index;
  bool end_of_wave;

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
    tab_index = 0;
    end_of_wave = false;
  }

  /+@nogc+/ ESQ_Osc *get_parameters()
  {
    ESQ_Synth *synth = vc.synth;
    ESQ_Program *pgm = synth.active_program;
    return &pgm.oscs[id];
  }

  enum R = 127; /+ the adjusted output range -R..+R of wavetable values +/

  /+ max value this oscillator implementation can produce.
   + may be useful in implementing the clipping sum of oscillators.
   +/
  enum max_output_value =
      R * /+ max from the wavetable (signed) +/
      (63 + 63 + 63);  /+ sum of max level and 2 amp mods +/

  enum min_output_value = -max_output_value;

  /+@nogc+/ void run(uint nframes)
  {
    /+ TODO: SEMI and FINE: from the waverom +/

    if (end_of_wave) {
      output[0..nframes] = 0;
      return;
    }

    ESQ_Synth *synth = vc.synth;
    const(float) fs = synth.sample_rate;
    ESQ_Osc *params = get_parameters();

    bool mute = ! params.DCAENABLE;

    ESQ_OscWave msnum = params.WAVEFORM;
    if (msnum.is_hidden_wave) {
      mute = true; // TODO hidden waves?
    }

    // compute the note pitched by the number of semitones
    int note = vc.note + cast(int)params.SEMI - 36;
    if (note < 0 || note >= 128)
      mute = true; // out of range, do not compute it

    if (mute) {
      for (uint i = 0; i < nframes; ++i)
        output[i] = 0;
      return;
    }

    ESQ_Multisample *ms = g_multisamples[msnum];
    uint wavenum = ms.wavenum[note/8];
    ESQ_Wave *wav = g_waves[wavenum];

    const(ubyte) *table = wav.data.ptr;
    uint table_size = wav.table_size;

    // add fine tune
    int cents = note * 100;
    cents += params.FINE;

    // TODO? add waverom tuning
    cents = cents + 100 * cast(byte)wav.semi + wav.fine;

    float index = this.tab_index;
    scope(success) this.tab_index = index;

    const(int) *fmsrc1 = vc.mods.get_mod_source(params.FMSRC1);
    const(int) *fmsrc2 = vc.mods.get_mod_source(params.FMSRC2);
    int fmamt1 = params.FCMODAMT1;
    int fmamt2 = params.FCMODAMT2;

    const(int) *amsrc1 = vc.mods.get_mod_source(params.AMSRC1);
    const(int) *amsrc2 = vc.mods.get_mod_source(params.AMSRC2);
    int amamt1 = params.AMAMT1;
    int amamt2 = params.AMAMT2;
    int level = params.DCALEVEL;

    const(bool) oneshot = wav.oneshot;

    static if (DEBUG_WAVES) {
      if (vc.id == 0 /+ && id == 0 +/) {
        stderr.writefln("Osc%d fm:%s,%s am:%s,%s note=%d->%d semi=%d fine=%d ms=%s wave=%s(%d) wave.semi=%d wave.fine=%d table_size=%d addr_register=%d",
                        id, params.FMSRC1, params.FMSRC2, params.AMSRC1, params.AMSRC2, vc.note, note, cast(int)params.SEMI - 36, params.FINE, msnum, wav.name, wavenum, wav.semi, wav.fine, wav.table_size, wav.addr_register);
        float cents_mod = cents
                          + fmsrc1[0] * (fmamt1/63.0f) /+ -63..63 +/
                          + fmsrc2[0] * (fmamt2/63.0f) /+ -63..63 +/;
        float f0 = mtof(cents/100.0f);
        float fmod0 = mtof(cents_mod/100.0f);
        stderr.writefln(" f0=%f fmod0=%f",
                        f0, fmod0);
      }
    }

    enum uint rate_shift = 0; // TODO how much?
    const(float) rate = 1.0f / (1 << (wav.addr_register + rate_shift));

    uint i = 0;
    for (; i < nframes; ++i) {
      // TODO adjust me: frequency modulation
      float cents_mod = cents;
      static if (! DISABLE_FM) {
        cents_mod = cents_mod
                    + fmsrc1[i] * (fmamt1/63.0f) /+ -63..63 +/
                    + fmsrc2[i] * (fmamt2/63.0f) /+ -63..63 +/;
      }
      float f = mtof(cents_mod/100.0f);

      index += (f/fs) * table_size * rate;
      float unwrapped_index = index;
      index = fmodf(index, cast(float)table_size);

      if (index != unwrapped_index && oneshot) {
        end_of_wave = true;
        break;
      }

      float v;
      static if (true) {
        // direct
        v = table[cast(uint)index];
      } else {
        // interpolate (linear)
        uint i1 = cast(uint)index;
        uint i2 = (i1+1) & (table_size-1);
        int x1 = table[i1];
        int x2 = table[i2];
        v = x1 + (x2-x1) * (index-i1);
      }
      v = (v/255)*(2*R) - R;                       /+ -R..+R +/
      /+ TODO: should quantize the result or not? +/
      // v = cast(int)v;

      // TODO adjust me: amplitude modulation
      float level_mod = level;                       /+ 0..63 +/
      static if (! DISABLE_AM) {
        level_mod = level_mod
                    + amsrc1[i] * (amamt1/63.0f)         /+ -63..63 +/
                    + amsrc2[i] * (amamt2/63.0f)         /+ -63..63 +/;
      }

      output[i] = cast(int)(v * level_mod);
    }

    output[i..nframes] = 0;
  }
}
