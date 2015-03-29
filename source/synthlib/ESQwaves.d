import ESQwaves;
import std.stdio;
import std.array: array, split;
import std.conv: to, parse;
import std.algorithm: filter, startsWith;
static import std.file;

struct ESQ_Wave {
  ubyte rom, addr, wsr, semi, fine;
  string name;
  bool oneshot;
  ubyte[] data;

  /+@nogc+/ @property uint size_index()
    {  return (wsr & 0b00111000) >> 3; }

  /+@nogc+/ @property uint table_size()
    {  return 1 << (8 + size_index); }

  /+@nogc+/ @property uint addr_register()
    { return wsr & 0b111; }
}

struct ESQ_Multisample {
  string name;
  ubyte[16] wavenum;
}

__gshared ESQ_Wave*[] g_waves;
__gshared ESQ_Multisample*[] g_multisamples;
static this() {
  ESQ_load_all_waves();
  ESQ_load_all_multisamples();
}

private:

ESQ_Wave*[] ESQ_load_all_waves()
{
  ESQ_Wave*[] wavetable;
  ubyte[] romdata = load_waverom();

  File wavefile = File("resources/waves.dat");
  foreach (char[] line; wavefile.byLine) {
    if (line.startsWith(";"))
      continue;
    char[][] elts = line.split(" ").filter!`a.length`.array;
    ESQ_Wave *wav = new ESQ_Wave;
    wav.rom = parse!ubyte(elts[0], 16);
    wav.addr = parse!ubyte(elts[1], 16);
    wav.wsr = parse!ubyte(elts[2], 16);
    wav.semi = parse!ubyte(elts[3], 16);
    wav.fine = parse!ubyte(elts[4], 16);
    wav.name = elts[5].idup;
    wav.oneshot = elts[6].to!bool;

    uint off = wav.rom * 65536 + wav.addr * 256;
    wav.data = romdata[off..off+wav.table_size];

    wavetable ~= wav;
  }
  g_waves = wavetable;
  return wavetable;
}

ESQ_Multisample*[] ESQ_load_all_multisamples()
{
  ESQ_Multisample*[] multis;
  File multifile = File("resources/multisample.dat");

  foreach (char[] line; multifile.byLine) {
    if (line.startsWith(";"))
      continue;
    char[][] elts = line.split(" ").filter!`a.length`.array;
    ESQ_Multisample *multi = new ESQ_Multisample;
    multi.name = elts[0].idup;
    for (uint i = 0; i < 16; ++i)
      multi.wavenum[i] = parse!ubyte(elts[i+1], 16);
    multis ~= multi;
  }
  g_multisamples = multis;
  return multis;
}

ubyte[] load_waverom()
{
  ubyte[] romdata;
  romdata.reserve(262144);
  romdata ~= cast(ubyte[])std.file.read("resources/sq80/2202.bin");
  romdata ~= cast(ubyte[])std.file.read("resources/sq80/2203.bin");
  romdata ~= cast(ubyte[])std.file.read("resources/sq80/2204.bin");
  romdata ~= cast(ubyte[])std.file.read("resources/sq80/2205.bin");
  return romdata;
}
