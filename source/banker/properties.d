module properties;
import ESQpatch;
import std.string: format;

class AccessTraits
{
  abstract int getInt(ESQ_Program *data, string id);
  abstract void setInt(ESQ_Program *data, string id, int val);
}

class ProgramPropertyTraits(string access): AccessTraits
{
  T getStaticSlot(T, string field)(ESQ_Program *data) {
    return mixin("cast(T)(data."~access~")."~field);
  }
  void setStaticSlot(T, string field)(ESQ_Program *data, T val) {
    mixin("(data."~access~")."~field~" = cast(typeof((data."~access~")."~field~"))val;");
  }

  enum string make_getter(string slot) =
      `if (id == `~slot.stringof~`) return this.getStaticSlot!(T, `~slot.stringof~`)(data);`;
  template make_getters(string[] S) if (S.length == 0)
    { enum string make_getters = ""; }
  template make_getters(string[] S) if (S.length > 0)
    { enum string make_getters = make_getter!(S[0]) ~ make_getters!(S[1..$]); }

  enum string make_setter(string slot) =
      `if (id == `~slot.stringof~`) return this.setStaticSlot!(T, `~slot.stringof~`)(data, val);`;
  template make_setters(string[] S) if (S.length == 0)
    { enum string make_setters = ""; }
  template make_setters(string[] S) if (S.length > 0)
    { enum string make_setters = make_setter!(S[0]) ~ make_setters!(S[1..$]); }

  enum string slots_mixin = `
  T getSlot(T)(ESQ_Program *data, string id)
  {
    mixin(make_getters!slots);
    throw new Exception(format("no such slot: %s", id));
  }

  void setSlot(T)(ESQ_Program *data, string id, T val)
  {
    mixin(make_setters!slots);
    throw new Exception(format("no such slot: %s", id));
  }

  override int getInt(ESQ_Program *data, string id)
    { return getSlot!int(data, id); }
  override void setInt(ESQ_Program *data, string id, int val)
    { setSlot!int(data, id, val); }`;
}

class EnvPropertyTraits(uint num): ProgramPropertyTraits!(format("envs[%d]", num))
{
  enum string[] slots = ["L1", "L2", "L3", "T1", "T2", "T3", "T4", "LV", "T1V", "TK"];
  mixin(slots_mixin);
}

class LfoPropertyTraits(uint num): ProgramPropertyTraits!(format("lfos[%d]", num))
{
  enum string[] slots = ["FREQ", "L1", "L2", "DELAY", "MOD", "WAV", "HUMAN", "RESET"];
  mixin(slots_mixin);
}

class OscPropertyTraits(uint num): ProgramPropertyTraits!(format("oscs[%d]", num))
{
  enum string[] slots = ["SEMI", "FINE",
                         "FMSRC1", "FMSRC2",
                         "FCMODAMT1", "FCMODAMT2",
                         "WAVEFORM",
                         "DCAENABLE", "DCALEVEL",
                         "AMSRC1", "AMSRC2",
                         "AMAMT1", "AMAMT2"];
  mixin(slots_mixin);
}

class MiscPropertyTraits: ProgramPropertyTraits!"misc"
{
  enum string[] slots = ["DCA4MODAMT",
                         "AM", "SYNC", "VC" /+ aka ROTATE +/, "MONO", "ENV", "OSC", "CYCLE",
                         "FLTFC", "Q",
                         "FCSRC1", "FCSRC2",
                         "FCMODAMT1", "FCMODAMT2",
                         "KEYBD" /+ aka FCMODAMT3 +/,
                         "GLIDE",
                         "SPLITPOINT",
                         "SPLITDIR",
                         "LAYERPRG", "SPLITPRG", "SPLITLAYERPRG",
                         "LAYER", "SPLIT", "SPLITLAYER",
                         "PAN",
                         "PANMODSRC", "PANMODAMT"];
  mixin(slots_mixin);
}
