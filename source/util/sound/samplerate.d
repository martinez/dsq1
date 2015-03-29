module sound.samplerate;
import std.conv: to;

// TODO test me

enum Quality {
  BestSinc,
  MediumSinc,
  FastestSinc,
  ZeroOrderHold,
  Linear,
}

float[] resample(in float[] input, double ratio, Quality quality)
{
  float[] output = new float[cast(ulong)(input.length * ratio)];

  SRC_DATA data;
  data.data_in = input.ptr;
  data.data_out = output.ptr;
  data.input_frames = input.length;
  data.output_frames = output.length;
  data.input_frames_used = 0;
  data.output_frames_gen = 0;
  data.end_of_input = 1;
  data.src_ratio = ratio;

  int ret = src_simple(&data, quality, 1);
  if (ret != 0)
    throw new SamplerateError(src_strerror(ret).to!string);

  return output[0..data.output_frames_gen];
}

class SamplerateError: Exception
{
  this(string msg) {
    super(msg);
  }
}

private:
extern(C):

import core.stdc.config;
pragma(lib, "samplerate");

struct SRC_DATA
{
  const(float) *data_in;
  float        *data_out;
  c_long        input_frames, output_frames;
  c_long        input_frames_used, output_frames_gen;
  int           end_of_input;
  double        src_ratio;
}

int src_simple(SRC_DATA *data, int converter_type, int channels);
const(char) *src_strerror(int error);

enum
{
  SRC_SINC_BEST_QUALITY = 0,
  SRC_SINC_MEDIUM_QUALITY = 1,
  SRC_SINC_FASTEST = 2,
  SRC_ZERO_ORDER_HOLD = 3,
  SRC_LINEAR = 4,
}
