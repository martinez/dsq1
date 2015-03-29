module sound.wavfile;
import sound.convert;

/+ convert audio channels to WAV PCM 16 bit +/
ubyte[] make_wav_data(T)(in T[][] channels, uint sample_rate, uint num_loops = 1)
{
  uint num_channels = cast(uint)channels.length;
  assert(channels.length > 0);

  uint sample_count = 0;
  foreach (const T[] channel; channels)
    if (channel.length > sample_count)
      sample_count = cast(uint)channel.length;

  struct header_t {
    align(1):
    char[4] type = "RIFF";
    uint size;
    char[4] format = "WAVE";
  }

  struct format_t {
    align(1):
    char[4] blockid = "fmt ";
    uint blocksize;
    ushort format = 1; // PCM
    ushort channels;
    uint samplerate;
    uint bytespersecond;
    ushort bytesperblock;
    ushort bitspersample;
  }

  struct data_t {
    align(1):
    char[4] blockid = "data";
    uint datasize;
  }

  uint filelen = cast(uint)(
      header_t.sizeof +
      format_t.sizeof +
      data_t.sizeof +
      sample_count * num_loops * num_channels * short.sizeof);

  header_t hdr;
  hdr.size = filelen - 8;

  format_t fmt;
  fmt.blocksize = format_t.sizeof - 8;
  fmt.channels = cast(ushort)num_channels;
  fmt.samplerate = sample_rate;
  fmt.bytespersecond = cast(uint)(num_channels * sample_rate * short.sizeof);
  fmt.bytesperblock = cast(ushort)(num_channels * short.sizeof);
  fmt.bitspersample = cast(ushort)(num_channels * short.sizeof * 8);

  data_t data;
  data.datasize = cast(uint)(num_channels * sample_count * num_loops * short.sizeof);

  ubyte[] wav;
  wav.reserve(filelen);
  wav ~= (cast(ubyte *)&hdr)[0..hdr.sizeof];
  wav ~= (cast(ubyte *)&fmt)[0..fmt.sizeof];
  wav ~= (cast(ubyte *)&data)[0..data.sizeof];

  for (uint l = 0; l < num_loops; ++l) {
    for (uint i = 0; i < sample_count; ++i) {
      foreach (const T[] channel; channels) {
        T sample = (i < channel.length) ? channel[i] : 0;
        short scaled = convert_sample!short(sample);
        wav ~= (cast(ubyte *)&scaled)[0..ushort.sizeof];
      }
    }
  }

  return wav;
}
