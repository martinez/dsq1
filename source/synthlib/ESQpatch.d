
module ESQpatch;
import ESQints;
public import ESQdefs;
import std.stdio;
import std.algorithm: startsWith, endsWith;
import jsonizer;

__gshared ESQ_Bank ESQ_init_bank = ESQ_load_bank(cast(ubyte[])import("init-bank.mdx"));
__gshared ESQ_Bank ESQ_default_bank = ESQ_load_bank(cast(ubyte[])import("default-bank.mdx"));
__gshared ESQ_Program ESQ_init_program = ESQ_load_patch(cast(ubyte[])import("init-program.dat"));

ESQ_Bank ESQ_load_bank(ubyte[] data)
{
  ESQ_Bank bank;

  if (! data.startsWith([0xf0, 0x0f, 0x02, 0x00, 0x02]))
    throw new ESQFormatError("incorrect sysex header");
  if (! data.endsWith([0xf7]))
    throw new ESQFormatError("incorrect sysex footer");

  data = data[5..$-1];
  if (data.length % 204 != 0)
    throw new ESQFormatError("bad format: the file size is invalid");

  uint npatch = cast(uint)data.length / 204;
  if (npatch == 0)
    throw new ESQFormatError("bad format: the bank does not contain any programs");
  if (npatch > 128)
    throw new ESQFormatError("bad format: the bank contain too many programs");

  uint i = 0;
  for (; i < npatch; ++i) {
    uint off = i * 204;
    ubyte[] patchdata = data[off..off+204];
    bank.patchbuf[i] = ESQ_load_patch(patchdata);
  }
  bank.num_patches = cast(ubyte)npatch;
  for (; i < 128; ++i)
    bank.patchbuf[i] = ESQ_load_patch(cast(ubyte[])import("init-program.dat"));

  return bank;
}

ESQ_Program ESQ_load_patch(ubyte[] data)
{
  ESQ_Program patch;

  for (int i = 0; i < 6; ++i) {
    uint ch = ((data[2*i+1] & 0xf) << 4) | (data[2*i] & 0xf);
    patch.namebuf[i] = cast(char)ch;
  }
  data = data[12..$];

  ///

  foreach (ref ESQ_Env env; patch.envs) {
    env.L1 = ESQ_sl!7(data[0..2]);
    env.L2 = ESQ_sl!7(data[2..4]);
    env.L3 = ESQ_sl!7(data[4..6]);
    env.T1 = ESQ_ur!6(data[6..8]);
    env.T2 = ESQ_ur!6(data[8..10]);
    env.T3 = ESQ_ur!6(data[10..12]);
    env.T4 = ESQ_ur!6(data[12..14]);
    env.LV = ESQ_ul!6(data[14..16]);
    env.T1V = ESQ_ur!6(data[16..18]);
    env.TK = ESQ_ur!6(data[18..20]);
    data = data[20..$];
  }

  foreach (ref ESQ_Lfo lfo; patch.lfos) {
    int tmp1 = ESQ_ul!8(data[0..2]);
    lfo.FREQ = tmp1 & 0x3f;
    lfo.WAV = cast(ESQ_LfoWave)((tmp1 & 0xc0) >> 6);

    tmp1 = ESQ_ul!8(data[2..4]);
    int tmp2 = ESQ_ul!8(data[4..6]);
    lfo.L1 = tmp1 & 0x3f;
    lfo.L2 = tmp2 & 0x3f;
    lfo.MOD = cast(ESQ_Mod)(
        ((tmp2 & 0x40) ? 0x1 : 0) | ((tmp2 & 0x80) ? 0x2 : 0) |
        ((tmp1 & 0x40) ? 0x4 : 0) | ((tmp1 & 0x80) ? 0x8 : 0));

    tmp1 = ESQ_ul!8(data[6..8]);
    lfo.DELAY = tmp1 & 0x3f;
    lfo.HUMAN = (tmp1 & 0x40) != 0;
    lfo.RESET = (tmp1 & 0x80) != 0;

    data = data[8..$];
  }

  foreach (ref ESQ_Osc osc; patch.oscs) {
    osc.SEMI = ESQ_ur!7(data[0..2]);
    osc.FINE = ESQ_ul!5(data[2..4]);
    osc.FMSRC1 = cast(ESQ_Mod)(data[4] & 0xf);
    osc.FMSRC2 = cast(ESQ_Mod)(data[5] & 0xf);
    osc.FCMODAMT1 = ESQ_sl!7(data[6..8]);
    osc.FCMODAMT2 = ESQ_sl!7(data[8..10]);
    osc.WAVEFORM = cast(ESQ_OscWave)ESQ_ul!8(data[10..12]);
    int tmp = ESQ_ul!7(data[12..14]);
    osc.DCAENABLE = (tmp & 0x40) != 0;
    osc.DCALEVEL = tmp & 0x3f;
    osc.AMSRC1 = cast(ESQ_Mod)(data[14] & 0xf);
    osc.AMSRC2 = cast(ESQ_Mod)(data[15] & 0xf);
    osc.AMAMT1 = ESQ_sl!7(data[16..18]);
    osc.AMAMT2 = ESQ_sl!7(data[18..20]);
    data = data[20..$];
  }

  ESQ_Misc *misc = &patch.misc;
  misc.DCA4MODAMT = ESQ_ul!7(data[0..2]) & 0x3f;
  misc.AM = (data[1] & 0x8) != 0;
  misc.FLTFC = ESQ_ur!7(data[2..4]);
  misc.SYNC = (data[3] & 0x8) != 0;
  misc.Q = ESQ_ur!5(data[4..6]);
  misc.FCSRC1 = cast(ESQ_Mod)(data[6] & 0xf);
  misc.FCSRC2 = cast(ESQ_Mod)(data[7] & 0xf);
  misc.FCMODAMT1 = ESQ_sr!7(data[8..10]);
  misc.VC = (data[9] & 0x8) != 0;
  misc.FCMODAMT2 = ESQ_sr!7(data[10..12]);
  misc.MONO = (data[11] & 0x8) != 0;
  misc.KEYBD = ESQ_ul!7(data[12..14]) & 0x3f;
  misc.ENV = (data[13] & 0x8) != 0;
  misc.GLIDE = ESQ_ur!6(data[14..16]);
  misc.OSC = (data[15] & 0x8) != 0;
  misc.SPLITPOINT = ESQ_ur!7(data[16..18]);
  misc.SPLITDIR = (data[17] & 0x8) != 0;
  misc.LAYERPRG = ESQ_ur!7(data[18..20]);
  misc.LAYER = (data[19] & 0x8) != 0;
  misc.SPLITPRG = ESQ_ur!7(data[20..22]);
  misc.SPLIT = (data[21] & 0x8) != 0;
  misc.SPLITLAYERPRG = ESQ_ur!7(data[22..24]);
  misc.SPLITLAYER = (data[23] & 0x8) != 0;
  misc.PANMODSRC = cast(ESQ_Mod)(data[24] & 0xf);
  misc.PAN = data[25] & 0xf;
  misc.PANMODAMT = ESQ_ur!7(data[26..28]);
  misc.CYCLE = (data[27] & 0x8) != 0;
  data = data[28..$];

  return patch;
}

struct ESQ_Bank {
  mixin JsonizeMe;
  @jsonize {
    /+@nogc+/ @property ESQ_Program[] patches()
    {
      return patchbuf[0..num_patches];
    }

    @property void patches(ESQ_Program[] p)
    {
      if (p.length > 128)
        throw new ESQFormatError("too many programs for bank");
      num_patches = cast(ubyte) p.length;
      patchbuf[0..num_patches] = p[0..num_patches];
    }
  }

  ESQ_Program[128] patchbuf;
  ubyte num_patches;
}

struct ESQ_Program {
  mixin JsonizeMe;
  char[6] namebuf;

  @jsonize {
    @property string name()
    {
      uint n = 0;
      for (; n < 6 && namebuf[n] != 0; ++n) {}
      return namebuf[0..n].dup;
    }

    @property void name(string s)
    {
      uint i = 0;
      for (; i < s.length; ++i) namebuf[i] = s[i];
      for (; i < 6; ++i) namebuf[i] = 0;
    }

    ESQ_Env[4] envs;
    ESQ_Lfo[3] lfos;
    ESQ_Osc[3] oscs;
    ESQ_Misc misc;
  }
}

struct ESQ_Env {
  mixin JsonizeMe;
  @jsonize {
    byte L1, L2, L3;
    ubyte T1, T2, T3, T4, LV, T1V, TK;
  }
}

struct ESQ_Lfo {
  mixin JsonizeMe;
  @jsonize {
    ubyte FREQ, L1, L2, DELAY;
    ESQ_Mod MOD;
    ESQ_LfoWave WAV;
    bool HUMAN, RESET;
  }
}

struct ESQ_Osc {
  mixin JsonizeMe;
  @jsonize {
    ubyte SEMI, FINE;
    ESQ_Mod FMSRC1, FMSRC2;
    byte FCMODAMT1, FCMODAMT2;
    ESQ_OscWave WAVEFORM;
    bool DCAENABLE;
    ubyte DCALEVEL;
    ESQ_Mod AMSRC1, AMSRC2;
    byte AMAMT1, AMAMT2;
  }
}

struct ESQ_Misc {
  mixin JsonizeMe;
  @jsonize {
    ubyte DCA4MODAMT;
    bool AM, SYNC, VC /+ aka ROTATE +/, MONO, ENV, OSC, CYCLE;
    ubyte FLTFC, Q;
    ESQ_Mod FCSRC1, FCSRC2;
    byte FCMODAMT1, FCMODAMT2;
    ubyte KEYBD /+ aka FCMODAMT3 +/;
    ubyte GLIDE;
    ubyte SPLITPOINT;
    bool SPLITDIR;
    ubyte LAYERPRG, SPLITPRG, SPLITLAYERPRG;
    bool LAYER, SPLIT, SPLITLAYER;
    ubyte PAN;
    ESQ_Mod PANMODSRC;
    byte PANMODAMT;
  }
}

final class ESQFormatError: Exception
{
  this(string msg)
  {
    super(msg);
  }
}
