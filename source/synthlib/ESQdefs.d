module ESQdefs;
import std.algorithm: map;
import std.range: iota, join;
import std.string: format;

enum ESQ_Mod {
  LFO1, LFO2, LFO3,
  ENV1, ENV2, ENV3, ENV4,
  VEL, VEL2, KYBD, KYBD2,
  WHEEL, PEDAL, XCTRL, PRESS,
  OFF,
}

enum ESQ_LfoWave {
  TRI, SAW, SQR, NOI,
}

mixin(`
enum ESQ_OscWave {
  SAW, BELL, SINE, SQUARE, PULSE, NOISE_1, NOISE_2, NOISE_3, BASS,
  PIANO, EL_PNO, VOICE_1, VOICE_2, KICK, REED, ORGAN, SYNTH_1, SYNTH_2, SYNTH_3,
  FORMT_1, FORMT_2, FORMT_3, FORMT_4, FORMT_5, PULSE2, SQR_2, FOUR_OCTS, PRIME,
  BASS_2, E_PNO2, OCTAVE, OCT_PLUS5, SAW_2, TRIANG, REED_2, REED_3,
  GRIT_1, GRIT_2, GRIT_3, GLINT_1, GLINT_2, GLINT_3, CLAV, BRASS, STRING,
  DIGIT_1, DIGIT_2, BELL_2, ALIEN, BREATH, VOICE_3, STEAM, METAL, CHIME, BOWING,
  PICK_1, PICK_2, MALLET, SLAP, PLINK, PLUCK, PLUNK, CLICK, CHIFF, THUMP,
  LOGDRM, KICK_2, SNARE, TOMTOM, HI_HAT,
  DRUMS_1, DRUMS_2, DRUMS_3, DRUMS_4, DRUMS_5,`
  ~ hidden_wave_enums ~ `
}`);

/+@nogc+/ bool is_hidden_wave(ESQ_OscWave wav)
{
  return wav >= ESQ_OscWave.HIDDEN_75;
}

private:

string hidden_wave_enums()
{
  return iota(75, 256)
      .map!((int i) => format("HIDDEN_%d", i))
      .join(", ");
}
