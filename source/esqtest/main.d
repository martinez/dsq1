import ESQsynth;
import ESQvoice;
import ESQnote;
import ESQenvg;
import ESQlfog;
import ESQoscg;
import ESQwaves;
import ESQpatch;
import math.plot;
import sound.wavfile;
import sound.convert;
import sound.samplerate;
import std.stdio;
import std.string;
import std.array;
import std.range;
import std.algorithm;
import std.conv;
import std.file;
import std.process;
import std.exception;
import core.stdc.tgmath;

enum float sample_rate = 44100;
enum uint buffer_size = 512;
SignalPlotter plot;

ESQ_Synth *synth;

void main(string[] args)
{
  plot = new SignalPlotter(sample_rate);
  synth = new ESQ_Synth(sample_rate, buffer_size);

  ///

  synth.program_change(0, 13);

  ///

  // foreach (ESQ_Wave *wave; g_waves) {
  //   writefln("wave '%s' semi=%d fine=%d",
  //            wave.name, cast(byte)wave.semi, wave.fine);
  // }

  ///

  // foreach (ESQ_Wave *wave; g_waves) {
  //   if (wave.name == "tomtom")
  //     play_wave(wave, 110.0f, 1.0f);
  // }

  ///

  test_envelope(30, 100);
  // test_oscillator(1, 9);
  // test_lfo(10);

  readln();
}

void test_envelope(float duration, uint velocity)
{
  float t = 0;
  float[] output;

  output.reserve(cast(ulong)ceil((duration * 2) * sample_rate));

  ESQ_Voice *vc = &synth.voices[0];
  ESQ_Envg *eg = &vc.egs[0];

  eg.trigger(velocity);
  writefln("T %f %f %f %f", eg.T1/sample_rate, eg.T2/sample_rate, eg.T3/sample_rate, eg.T4/sample_rate);
  writefln("L %d %d %d", eg.L1, eg.L2, eg.L3);

  while (t < duration) {
    eg.run(buffer_size);
    output ~= eg.output[0..buffer_size].map!(to!float).array;
    t += buffer_size * (1.0f/sample_rate);
  }

  eg.release();
  while (eg.running) {
    eg.run(buffer_size);
    output ~= eg.output[0..buffer_size].map!(to!float).array;
    t += buffer_size * (1.0f/sample_rate);
  }

  plot.plot([output]);
}

void test_oscillator(float duration, ubyte note)
{
  float t = 0;
  float[] output;
  output.reserve(cast(ulong)ceil(duration * sample_rate));

  ESQ_Voice *vc = &synth.voices[0];
  ESQ_Oscg *og = &vc.oscs[0];

  writefln("note=%d F=%f T=%f)", note, mtof(note), 1.0/mtof(note));

  ESQ_Osc *params = og.get_parameters();
  // params.WAVEFORM = ESQ_OscWave.SINE;
  params.WAVEFORM = ESQ_OscWave.PIANO;

  writefln("wav=%s", params.WAVEFORM);

  vc.note = note;
  while (t < duration) {
    og.run(buffer_size);
    output ~= og.output[0..buffer_size].map!(to!float).array;
    t += buffer_size * (1.0f/sample_rate);
  }

  plot.plot([output]);
}

void test_lfo(float duration)
{
  float t = 0;
  float[] output;
  output.reserve(cast(ulong)ceil(duration * sample_rate));

  ESQ_Voice *vc = &synth.voices[0];
  ESQ_Lfog *lfo = &vc.lfos[0];

  ESQ_Lfo *params = lfo.get_parameters();
  // params.WAV = ESQ_LfoWave.TRI;
  // params.WAV = ESQ_LfoWave.SQR;
  // params.WAV = ESQ_LfoWave.SAW;
  // params.WAV = ESQ_LfoWave.NOI;

  writefln("LFO wave=%s frequency(Hz)=%f",
           lfo.get_parameters().WAV,
           lfo.get_hz_frequency());

  while (t < duration) {
    lfo.run(buffer_size);
    output ~= lfo.output[0..buffer_size].map!(to!float).array;
    t += buffer_size * (1.0f/sample_rate);
  }

  plot.plot([output]);
}

void play_wave(ESQ_Wave *wave, float freq, float duration)
{
  writefln("wave '%s' %fHz %fs",  wave.name, freq, duration);

  enum uint rate_shift = 0; // TODO how much?
  const(float) rate = 1.0f / (1 << (wave.addr_register + rate_shift));

  freq *= rate;

  float[] wave_signal = convert_samples!float(wave.data);

  float period_at_fs = (1/sample_rate) * wave.table_size;
  float period_at_f = (1/freq);

  double ratio = period_at_f / period_at_fs;
  wave_signal = resample(wave_signal, ratio, Quality.BestSinc);

  uint num_loops = cast(uint)(duration/((1/sample_rate) * wave_signal.length));

  ubyte[] wav_data = make_wav_data([wave_signal], cast(uint)sample_rate, num_loops);

  File tmpfile;
  string tmppath;

  { import core.sys.posix.stdlib: mkstemp;
    import core.sys.posix.unistd: close;
    char[] tmpl = (tempDir ~ "/wave.XXXXXX" ~ '\0').dup;
    int fd = mkstemp(tmpl.ptr);
    enforce(fd >= 0);
    scope(failure) close(fd);
    tmpfile.fdopen(fd, "wb");
    tmppath = cast(immutable)tmpl[0..$-1];
  }
  scope(exit) remove(tmppath);

  tmpfile.rawWrite(wav_data);
  tmpfile.close();

  execute(["play", "-t", ".wav", tmppath]);
}
