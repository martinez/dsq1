module ESQmodg;
import ESQsynth;
import ESQvoice;
import ESQpatch;

enum int[128] vel2_table = [ /+ 63*sin(acos((127-x)/127)) +/
    0, 7, 11, 13, 15, 17, 19, 20, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32,
    33, 33, 34, 35, 36, 36, 37, 38, 38, 39, 40, 40, 41, 41, 42, 42, 43, 43, 44,
    44, 45, 45, 46, 46, 47, 47, 48, 48, 48, 49, 49, 50, 50, 50, 51, 51, 51, 52,
    52, 52, 53, 53, 53, 54, 54, 54, 54, 55, 55, 55, 56, 56, 56, 56, 57, 57, 57,
    57, 57, 58, 58, 58, 58, 58, 59, 59, 59, 59, 59, 59, 60, 60, 60, 60, 60, 60,
    60, 61, 61, 61, 61, 61, 61, 61, 61, 61, 62, 62, 62, 62, 62, 62, 62, 62, 62,
    62, 62, 62, 62, 62, 62, 62, 62, 62, 62, 62, 62, 62, 63 ];

struct ESQ_ModSource
{
  ESQ_Voice *vc;

  /+ all mod sources are [-63..+63] +/

  int *OFF;
  int *VEL;
  int *VEL2;
  int *KYBD;
  int *KYBD2;

  void init(ESQ_Voice *vc)
  {
    this.vc = vc;

    ESQ_Synth *synth = vc.synth;
    uint buffer_size = synth.buffer_size;

    OFF = new int[buffer_size].ptr;
    VEL = new int[buffer_size].ptr;
    VEL2 = new int[buffer_size].ptr;
    KYBD = new int[buffer_size].ptr;
    KYBD2 = new int[buffer_size].ptr;
  }

  /+@nogc+/ void reset()
  {
  }

  /+@nogc+/ void compute_sources()
  {
    ESQ_Synth *synth = vc.synth;
    uint buffer_size = synth.buffer_size;

    uint vel = vc.vel/2;
    uint vel2 = vel2_table[vc.vel];
    uint kybd = vc.note/2;
    uint kybd2 = (((vc.note*2)/4)*2) - 63;

    VEL[0..buffer_size] = vel;
    VEL2[0..buffer_size] = vel2;
    KYBD[0..buffer_size] = kybd;
    KYBD2[0..buffer_size] = kybd2;
  }

  /+@nogc+/ int *get_mod_source(ESQ_Mod mod)
  {
    final switch (mod) {
      case ESQ_Mod.LFO1:
        return vc.lfos[0].output;
      case ESQ_Mod.LFO2:
        return vc.lfos[1].output;
      case ESQ_Mod.LFO3:
        return vc.lfos[2].output;

      case ESQ_Mod.ENV1:
        return vc.egs[0].output;
      case ESQ_Mod.ENV2:
        return vc.egs[1].output;
      case ESQ_Mod.ENV3:
        return vc.egs[2].output;
      case ESQ_Mod.ENV4:
        return vc.egs[3].output;

      case ESQ_Mod.VEL:
        return VEL;
      case ESQ_Mod.VEL2:
        return VEL2;

      case ESQ_Mod.KYBD:
        return KYBD;
      case ESQ_Mod.KYBD2:
        return KYBD2;

      case ESQ_Mod.WHEEL:
        return OFF; // TODO

      case ESQ_Mod.PEDAL:
        return OFF; // TODO

      case ESQ_Mod.XCTRL:
        return OFF; // TODO

      case ESQ_Mod.PRESS:
        return OFF; // TODO

      case ESQ_Mod.OFF:
        return OFF;
    }
  }
}
