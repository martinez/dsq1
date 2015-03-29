
import ESQpatch;
import ESQsynth;
import OSC;
import std.stdio;
import std.string: format;
import std.path: dirName;
import std.process;
import std.file;
import core.stdc.stdint;
import core.stdc.stdlib: exit;
import jack.client;
import jack.midiport;

__gshared JackClient client = null;

void main(string[] args)
{
  run_synth();
  scope(exit) stop_synth();

  /// the OSC server
  scope OSCserver server = new OSCserver;
  stderr.writefln("the OSC server is listening at URL: %s",
                  server.get_url());

  string ui_exe = args[0].dirName~"/esq-synthui";
  Pid ui_process = spawnProcess([ui_exe, server.get_url()]);

  scope OSCclient client = server.wait_for_client();
  stderr.writefln("connected to OSC client at URL: %s",
                  client.get_url());

  server.run();
  ui_process.kill();
  ui_process.wait();
}

void run_synth()
{
  client = new JackClient;
  client.open("ESQ", JackOptions.JackNoStartServer, null);

  install_signal_handlers();

  uint sample_rate = client.get_sample_rate();
  uint buffer_size = client.get_buffer_size();

  ESQ_Synth *synth = new ESQ_Synth(sample_rate, buffer_size);

  JackPort[2] audioports;
  audioports[0] = client.register_port("out_1", JACK_DEFAULT_AUDIO_TYPE,
                                       JackPortFlags.JackPortIsOutput|JackPortFlags.JackPortIsTerminal, 0);
  audioports[1] = client.register_port("out_2", JACK_DEFAULT_AUDIO_TYPE,
                                       JackPortFlags.JackPortIsOutput|JackPortFlags.JackPortIsTerminal, 0);

  JackPort midiport;
  midiport = client.register_port("midi_in", JACK_DEFAULT_MIDI_TYPE,
                                  JackPortFlags.JackPortIsInput|JackPortFlags.JackPortIsTerminal, 0);

  client.thread_init_callback = delegate() {
    // thread_attachThis();
  };

  client.process_callback = delegate int(uint32_t nframes) {
    // try {

    float* outL = audioports[0].get_audio_buffer(nframes);
    float* outR = audioports[1].get_audio_buffer(nframes);

    JackMidiPortBuffer midibuf = midiport.get_midi_buffer(nframes);
    foreach (JackMidiEvent event; midibuf.iter_events())
      synth.process_event(event.time, event.buffer, cast(uint)event.size);

    synth.run(outL, outR, nframes);

    // } catch (Exception ex) {
    //   writeln(ex);
    // }

    return 0;
  };

  client.activate();
}

void stop_synth()
{
  if (client) {
    client.close();
    client = null;
  }
}

//

import core.sys.posix.signal;

extern(C)
void signal_handler(int sig)
{
  import core.stdc.stdio: puts;
  stop_synth();
  exit(1);
}

void install_signal_handlers()
{
  alias sigfn = extern(C) void function(int) nothrow @nogc @system;
  signal(SIGQUIT, cast(sigfn)&signal_handler);
  signal(SIGTERM, cast(sigfn)&signal_handler);
  signal(SIGHUP, cast(sigfn)&signal_handler);
  signal(SIGINT, cast(sigfn)&signal_handler);
}

