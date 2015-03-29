module ESQsynth;
import std.stdio;
import core.stdc.string: memset;
import ESQpatch;
import ESQwaves;
import ESQvoice;
import ESQenvg;
import ESQoscg;

enum VOICE_DEBUG = false;
enum PROGRAM_DEBUG = true;
enum MIDI_DEBUG = false;

struct ESQ_Synth
{
  float sample_rate;
  uint buffer_size;

  uint bank;
  uint program;
  uint pending_bank_change = cast(uint)-1;

  uint midi_channel = 0; /+ 0: omni, 1-16: channel +/

  uint num_active_voices;
  ESQ_Voice[8] voices;

  ESQ_Bank*[127] bankbuf;

  this(float sample_rate, uint buffer_size)
  {
    ESQ_Bank *bank = new ESQ_Bank;
    *bank = ESQ_init_bank;
    for (uint i = 0; i < bankbuf.length; ++i)
      bankbuf[i] = bank;

    bank = new ESQ_Bank;
    *bank = ESQ_default_bank;
    bankbuf[0] = bank;

    this.sample_rate = sample_rate;
    this.buffer_size = buffer_size;
    foreach (uint i, ref ESQ_Voice vc; voices)
      vc.init(&this, i);
    num_active_voices = 0;

    program_change(0, 0);
  }

  /+@nogc+/ @property ESQ_Bank* active_bank() {
    return bankbuf[bank];
  }

  /+@nogc+/ @property ESQ_Program* active_program() {
    return &active_bank.patches[program];
  }

  /+@nogc+/ void run(float* outL, float* outR, uint nframes)
  {
    memset(outL, 0, nframes * float.sizeof);
    memset(outR, 0, nframes * float.sizeof);

    foreach (ref ESQ_Voice vc; voices) {
      if (! vc.active)
        continue;
      vc.update_all_mod_sources(nframes);
      vc.run_all_oscs(nframes);
      vc.compute_oscillator_sum(nframes);
      vc.run_filter(nframes);
    }

    foreach (ref ESQ_Voice vc; voices) {
      if (! vc.active) continue;
      for (uint i = 0; i < nframes; ++i) {
        float v = 0.05f * vc.filt.output[i];
        // TODO missing the final output stage
        outL[i] += v;
        outR[i] += v;
      }
    }

    free_some_voices();
  }

  /+@nogc+/ void process_event(uint time, ubyte *buffer, uint size)
  {
    uint op = buffer[0] & 0xf0;
    uint ch = (buffer[0] & 0x0f) + 1;

    uint pbc = this.pending_bank_change;
    this.pending_bank_change = cast(uint)-1;

    if (op == 0x80 && (midi_channel == 0 || midi_channel == ch))
      return process_noteoff(buffer[1] & 0x7f, buffer[2] & 0x7f);
    else if (op == 0x90 && (midi_channel == 0 || midi_channel == ch))
      return process_noteon(buffer[1] & 0x7f, buffer[2] & 0x7f);
    else if (op == 0xc0 && (midi_channel == 0 || midi_channel == ch))
      return process_program_change(buffer[1] & 0x7f, pbc);
    else if (op == 0xb0 && (midi_channel == 0 || midi_channel == ch))
      return process_control_change(buffer[1] & 0x7f, buffer[2] & 0x7f, pbc);
  }

  /+@nogc+/ void program_change(uint bnk, uint pgm)
  {
    if (bank == bnk && program == pgm)
      return;
    bank = bnk;
    program = pgm;
    foreach (ref ESQ_Voice vc; voices)
      vc.reset();
    static if (PROGRAM_DEBUG) {
      stderr.writefln("Program %d:%d name=%s",
                      bank, program, active_program.name);
    }
  }

  /+@nogc+/ void free_some_voices()
  {
    foreach (ref ESQ_Voice vc; voices) {
      if (vc.trykill()) {
        static if (VOICE_DEBUG)
          stderr.writefln("voice %d was killed", vc.id);
      }
    }
  }

  /+@nogc+/ void process_noteoff(ubyte note, ubyte vel)
  {
    static if (MIDI_DEBUG)
      stderr.writefln("noteoff note=%d vel=%d", note, vel);
    foreach (ref ESQ_Voice vc; voices) {
      if (! vc.active || vc.note != note)
        continue;
      vc.release();
      static if (VOICE_DEBUG)
        stderr.writefln("voice %d was released", vc.id);
      // break;
    }
  }

  /+@nogc+/ void process_noteon(ubyte note, ubyte vel)
  {
    if (vel == 0)
      return process_noteoff(note, vel);
    static if (MIDI_DEBUG)
      stderr.writefln("noteon note=%d vel=%d", note, vel);
    ESQ_Voice *vc = null;
    foreach (ref ESQ_Voice cur_vc; voices) {
      if (cur_vc.steal(note, vel)) {
        vc = &cur_vc;
        break;
      }
    }

    static if (true) { // agressive voice stealing
      if (! vc) {
        foreach (ref ESQ_Voice cur_vc; voices) {
          if (cur_vc.active_num == 0) { // take the oldest
            vc = &cur_vc;
            vc.kill();
            vc.steal(note, vel);
            break;
          }
        }
      }
    }

    static if (VOICE_DEBUG) {
      if (vc) stderr.writefln("voice %d was attributed to note=%d vel=%d",
                              vc.id, note, vel);
      else stderr.writefln("no voice could be attributed to note=%d vel=%d",
                           note, vel);
    }
  }

  /+@nogc+/ void process_control_change(ubyte ctl, ubyte value, uint pbc)
  {
    if (ctl == 0x00) {
      static if (MIDI_DEBUG)
        stderr.writefln("bankselect(MSB) value=%d", value);
      // ignored
      if (pbc == cast(uint)-1)
        pbc = 0;
      pbc = (pbc & 0x7f) | (value << 7);
    } else if (ctl == 0x20) {
      static if (MIDI_DEBUG)
        stderr.writefln("bankselect(LSB) value=%d", value);
      if (pbc == cast(uint)-1)
        pbc = 0;
      pbc = (((pbc >> 7) & 0x7f) << 7) | value;
    } else {
      static if (MIDI_DEBUG)
        stderr.writefln("control num=%d value=%d", ctl, value);
    }
    this.pending_bank_change = pbc;
  }

  /+@nogc+/ void process_program_change(uint pgm, uint pbc)
  {
    static if (MIDI_DEBUG)
      stderr.writefln("programchange pgm=%d", pgm);

    uint bnk = this.bank;
    if (pbc != cast(uint)-1) {
      if (pbc >= bankbuf.length)
        pbc = bankbuf.length - 1;
      stderr.writefln("bankchange bank=%d", pbc);
      bnk = pbc;
    }
    program_change(bnk, pgm);
  }
}
