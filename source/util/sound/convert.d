module sound.convert;

T[] convert_samples(T, U)(in U[] input)
{
  T[] output;
  output.reserve(input.length);
  foreach (U sample; input)
    output ~= convert_sample!(T, U)(sample);
  return output;
}

T convert_sample(T, U)(U sample)
    if (__traits(isFloating, T) && __traits(isFloating, U))
{
  return cast(T)sample;
}

T convert_sample(T, U)(U sample)
    if (__traits(isFloating, T) && __traits(isIntegral, U))
{
  return normalize!T(sample)*2-1;
}

T convert_sample(T, U)(U sample)
    if (__traits(isIntegral, T) && __traits(isFloating, U))
{
  // clip values out of range
  if (sample < -1) sample = -1;
  else if (sample > +1) sample = +1;

  enum T_range = T.max-T.min;
  return cast(T)(((sample+1)/2)*T_range+T.min);
}

T convert_sample(T, U)(U sample)
    if (__traits(isIntegral, T) && __traits(isIntegral, U))
{
  enum T_range = T.max-T.min;
  return cast(T)(normalize!double(sample)*T_range+T.min);
}

T normalize(T, U)(U sample)
    if (__traits(isIntegral, U))
{
  enum U_range = U.max-U.min;
  return (cast(T)sample-U.min)/U_range;
}
