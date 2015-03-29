module ESQvoice;
import ESQsynth;
import ESQenvg;
import ESQlfog;
import ESQoscg;
import ESQmodg;
import ESQfilt;
import std.stdio;
import core.stdc.math;

enum DEBUG_CLIPPING = true;

struct ESQ_Voice
{
  uint id;
  int active_num;
  ubyte note;
  float note_freq;
  ubyte vel;
  ESQ_Synth *synth;
  ESQ_Envg[4] egs;
  ESQ_Lfog[3] lfos;
  ESQ_Oscg[3] oscs;
  ESQ_ModSource mods;
  ESQ_Filter filt;

  void init(ESQ_Synth *synth, uint id)
  {
    this.synth = synth;
    this.id = id;
    this.active_num = -1;
    foreach (uint i, ref ESQ_Envg eg; egs)
      eg.init(&this, i);
    foreach (uint i, ref ESQ_Oscg og; oscs)
      og.init(&this, i);
    foreach (uint i, ref ESQ_Lfog lfo; lfos)
      lfo.init(&this, i);
    mods.init(&this);
    filt.init(&this);
    reset();
  }

  /+@nogc+/ @property bool active() {
    return active_num >= 0;
  }

  /+@nogc+/ void activate() {
    if (active_num < 0)
      active_num = synth.num_active_voices++;
  }

  /+@nogc+/ void deactivate() {
    int n = active_num;
    if (n >= 0) {
      foreach (ref ESQ_Voice vc; synth.voices)
        if (vc.active_num > n)
          vc.active_num--;
      synth.num_active_voices--;
      active_num = -1;
    }
  }

  /+@nogc+/ void reset()
  {
    deactivate();
    foreach (ref ESQ_Envg eg; egs)
      eg.reset();
    foreach (ref ESQ_Oscg og; oscs)
      og.reset();
    foreach (ref ESQ_Lfog lfo; lfos)
      lfo.reset();
    mods.reset();
    filt.reset();
  }

  /+@nogc+/ bool steal(ubyte note, ubyte vel)
  {
    if (active)
      return false;

    reset();
    activate();
    this.note = note;
    this.vel = vel;

    foreach (ref ESQ_Envg eg; egs)
      eg.trigger(vel);
    return true;
  }

  /+@nogc+/ bool trykill()
  {
    if (! active)
      return false;
    foreach (ref ESQ_Envg eg; egs)
      if (eg.running)
        return false;
    kill();
    return true;
  }

  /+@nogc+/ void kill()
  {
    deactivate();
  }

  /+@nogc+/ void update_all_mod_sources(uint nframes)
  {
    mods.compute_sources();
    foreach (ref ESQ_Envg eg; egs)
      eg.run(nframes);
    foreach (ref ESQ_Lfog lfo; lfos)
      lfo.run(nframes);
  }

  /+@nogc+/ void run_all_oscs(uint nframes)
  {
    foreach (ref ESQ_Oscg og; oscs)
      og.run(nframes);
  }

  /+@nogc+/ void compute_oscillator_sum(uint nframes)
  {
    float *output = filt.input; // it goes into the filter
    memset(output, 0, nframes * float.sizeof);

    // threshold beyond which the oscillator sum clips
    enum vmax = cast(int)(1.0 * ESQ_Oscg.max_output_value);
    enum vmin = -vmax;

    uint clip = 0;
    for (uint i = 0; i < nframes; ++i) {
      int v = 0;
      foreach (ref ESQ_Oscg og; oscs)
        v += og.output[i];
      if (v > vmax) { v = vmax; ++clip; }
      else if (v < vmin) { v = vmin; ++clip; }
      output[i] = cast(float)v/vmax;
    }

    static if (DEBUG_CLIPPING) {
      if (clip > 0)
        stderr.writefln("clipped %d of %d samples", clip, nframes);
    }
  }

  /+@nogc+/ void run_filter(uint nframes)
  {
    filt.run(nframes);
  }

  /+@nogc+/ void release()
  {
    foreach (ref ESQ_Envg eg; egs)
      eg.release();
  }
}
