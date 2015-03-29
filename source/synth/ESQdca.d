module ESQdca;
import ESQsynth;
import ESQvoice;
import ESQpatch;

/// TODO

class ESQdca
{
  ESQ_Voice *vc;
  float *output;

  void init(ESQ_Voice *vc)
  {
    this.vc = vc;
    ESQ_Synth *synth = vc.synth;
    uint buffer_size = synth.buffer_size;
    output = new float[buffer_size].ptr;
  }

  /+ @nogc +/ ESQ_Misc *get_parameters()
  {
    ESQ_Synth *synth = vc.synth;
    ESQ_Program *pgm = synth.active_program;
    return &pgm.misc;
  }

  /+@nogc+/ void reset()
  {
  }

  /+@nogc+/ void run(uint nframes)
  {
    float *input = vc.filt.output;
    float *output = this.output;

    ESQ_Misc *params = get_parameters();

    int *mod = vc.egs[3].output;
    int modamt = params.DCA4MODAMT;

    for (uint i = 0; i < nframes; ++i) {
      output[i] = input[i] * (mod[i]*(modamt/63.0f)/63.0f);
    }
  }
}
