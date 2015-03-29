module fastmath.math_private;
import std.traits;

@nogc void STRICT_ASSIGN(T)(ref T lval, T rval)
  { lval = rval; }

union ieee_double_shape_type
{
  double value;
  struct Parts {
    version(LittleEndian) {
      uint lsw;
      uint msw;
    } else version(BigEndian) {
      uint msw;
      uint lsw;
    }
  }; Parts parts;
  struct Xparts {
    ulong w;
  }; Xparts xparts;
}

union ieee_float_shape_type
{
  float value;
  uint word;
}

/* Get a 32 bit int from a float.  */

@nogc void GET_FLOAT_WORD(T)(ref T i, float d) if (is(Signed!T == int))
{
  ieee_float_shape_type gf_u;
  gf_u.value = d;
  i = gf_u.word;
}

/* Set a float from a 32 bit int.  */

@nogc void SET_FLOAT_WORD(ref float d, uint i)
{
  ieee_float_shape_type sf_u;
  sf_u.word = i;
  d = sf_u.value;
}

/* Set a double from two 32 bit ints.  */

@nogc void INSERT_WORDS(ref double d, uint ix0, uint ix1)
{
  ieee_double_shape_type iw_u;
  iw_u.parts.msw = ix0;
  iw_u.parts.lsw = ix1;
  d = iw_u.value;
}
