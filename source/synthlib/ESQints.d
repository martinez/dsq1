module ESQints;

/// Decoding of integers in MIDI byte pairs

/// Read a left-aligned N-bit sign-extedend integer
/+@nogc+/ byte ESQ_sl(uint N)(ubyte[2] data) if (N > 0 && N < 8) {
  ubyte i = ESQ_ul!N(data);
  if (i & (1 << (N-1))) { // negative
    ubyte mask = (1 << (N-1)) - 1;
    i = cast(byte)-(((i & mask) - 1) ^ mask);
  }
  return cast(byte)i;
}

/// Read a right-aligned N-bit sign-extedend integer
/+@nogc+/ byte ESQ_sr(uint N)(ubyte[2] data) if (N > 0 && N < 8) {
  ubyte u = ESQ_ur!N(data);
  bool neg = (u & (1 << (N-1))) != 0;
  if (neg) u |= (1 << N);
  return cast(byte)u;
}

/// Read a left-aligned N-bit zero-extedend integer
/+@nogc+/ ubyte ESQ_ul(uint N)(ubyte[2] data) if (N >= 5 && N <= 8) {
  return cast(ubyte)((data[1].lo!4 << (N-4)) | (data[0].lo!4 >> (8-N)));
}

/// Read a right-aligned N-bit zero-extedend integer
/+@nogc+/ ubyte ESQ_ur(uint N)(ubyte[2] data) if (N >= 5 && N <= 8) {
  return cast(ubyte)((data[1].lo!(N-4) << 4) | data[0].lo!4);
}

private:

/+@nogc+/ ubyte lo(uint N)(ubyte x) if (N > 0 && N < 8) {
  return x & ((1 << N) - 1);
}

/+@nogc+/ ubyte hi(uint N)(ubyte x) if (N > 0 && N < 8) {
  return (x >> (8-N)) & ((1 << N) - 1);
}
