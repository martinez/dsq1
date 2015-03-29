module math.fp;
static import std.conv;
static import std.math;
static import std.random;
static import core.stdc.tgmath;

struct FP(uint IntegralBits, uint DecimalBits)
    if (IntegralBits != 0 && DecimalBits != 0 &&
        IntegralBits + DecimalBits == 32 && IntegralBits % 4 == 0)
{
 private:
  int x;

 public:
  enum SHIFT = DecimalBits;
  enum SIZE = 1 << SHIFT;
  enum MASK = SIZE - 1;

  static FP max()
    { FP res; res.x = (((1 << (IntegralBits-1))-1) << SHIFT) | MASK; return res; }
  static FP min()
    { FP res; res.x = (1 << (IntegralBits-1)) << SHIFT; return res; }

  @property int raw_value()
    { return x; }

  this(T)(T i) if (__traits(isIntegral, T))
    { x = i << SHIFT; }

  this(T)(T r) if (__traits(isFloating, T)) {
    static if (false) /* beware of using this with constants, they probably won't be optimized */
      { x = cast(int)core.stdc.tgmath.lrint(r * cast(T)SIZE); }
    else
      { x = cast(int)(r * cast(T)SIZE); }
  }

  T to(T)() const if (__traits(isIntegral, T))
    { return x >> SHIFT; }
  T to(T)() const if (__traits(isFloating, T))
    { return cast(T)x * (cast(T)1 / cast(T)SIZE); }

  string toString()
    { return std.conv.to!string(this.to!double); }

  void opAssign(T)(T rhs) if(__traits(isIntegral, T) || __traits(isFloating, T))
    { x = FP(rhs).x; }
  void opAddAssign(const(FP) rhs)
    { x += rhs.x; }
  void opAddAssign(T)(T rhs) if(__traits(isIntegral, T) || __traits(isFloating, T))
    { x += FP(rhs).x; }
  void opSubAssign(const(FP) rhs)
    { x -= rhs.x; }
  void opSubAssign(T)(T rhs) if(__traits(isIntegral, T) || __traits(isFloating, T))
    { x -= FP(rhs).x; }
  void opMulAssign(const(FP) rhs)
    { x = cast(int)((cast(long)x * cast(long)rhs.x) >> SHIFT); }
  void opMulAssign(T)(T rhs) if(__traits(isIntegral, T))
    { x = cast(int)(cast(T)x * rhs); }
  void opMulAssign(T)(T rhs) if(__traits(isFloating, T))
    { x *= FP(rhs).x; }
  void opDivAssign(T)(T rhs) if(__traits(isIntegral, T))
    { x = cast(int)(cast(T)x / rhs); }
  void opDivAssign(T)(T rhs) if(__traits(isFloating, T))
    { x /= FP(rhs).x; }
  void opDivAssign(const(FP) rhs)
    { x = cast(int)((cast(long)x << SHIFT) / cast(long)rhs.x); }

  FP opBinary(string op, T)(const(T) rhs) const if((is(T == FP) || __traits(isIntegral, T) || __traits(isFloating, T)) &&
                                                   (op == "+" || op == "-" || op == "*" || op == "/"))
    { FP res; res.x = x; mixin("res "~op~"= rhs;"); return res; }
  FP opBinaryRight(string op, T)(T lhs) const if((__traits(isIntegral, T) || __traits(isFloating, T)) &&
                                                 (op == "+" || op == "-" || op == "*" || op == "/"))
    { FP f = FP(lhs); return mixin("f"~op~"this"); }

  bool opEquals(const(FP) rhs) const
    { return x == rhs.x; }
  int opCmp(const(FP) rhs) const
    { return x - rhs.x; }

  FP opUnary(string op)() const if (op == "+")
    { return this; }
  FP opUnary(string op)() const if (op == "-")
    { FP res; res.x = -x; return res; }

  FP abs() const
    { FP res; res.x = std.math.abs(x); return res; }

  static __gshared std.random.MinstdRand rnd;
  static this()
    { rnd = std.random.MinstdRand(std.random.unpredictableSeed); }

  static FP rand()
    {  FP res; res.x = rnd.front & MASK; rnd.popFront(); return res; }
}
