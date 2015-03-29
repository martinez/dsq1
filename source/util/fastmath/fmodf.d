module fastmath.fmodf;
import fastmath.math_private;

@nogc float fmodf(float x, float y)
{
  int n;

  int hx, hy;
  GET_FLOAT_WORD(hx, x);
  GET_FLOAT_WORD(hy, y);
  int sx = hx&0x80000000;		/* sign of x */
  hx ^=sx;		/* |x| */
  hy &= 0x7fffffff;	/* |y| */

  static if (false) {
    /* purge off exception values */
    if(hy==0||(hx>=0x7f800000)||		/* y=0,or x not finite */
       (hy>0x7f800000))			/* or y is NaN */
      return (x*y)/(x*y);
  }
  if(hx<hy) return x;			/* |x|<|y| return x */
  if(hx==hy)
    return Zero[cast(uint)sx>>31];	/* |x|=|y| return x*0*/

  /* determine ix = ilogb(x) */
  int ix;
  static if (true) {
    ix = (hx>>23)-127;
  } else {
    if(hx<0x00800000) {	/* subnormal x */
      ix = -126;
      for (int i=(hx<<8); i>0; i<<=1) ix -=1;
    } else ix = (hx>>23)-127;
  }

  /* determine iy = ilogb(y) */
  int iy;
  static if (true) {
    iy = (hy>>23)-127;
  } else {
    if(hy<0x00800000) {	/* subnormal y */
      iy = -126;
      for (int i=(hy<<8); i>=0; i<<=1) iy -=1;
    } else iy = (hy>>23)-127;
  }

  static if (true) {
    hx = 0x00800000|(0x007fffff&hx);
    hy = 0x00800000|(0x007fffff&hy);
  } else {
    /* set up {hx,lx}, {hy,ly} and align y to x */
    if(ix >= -126)
      hx = 0x00800000|(0x007fffff&hx);
    else {		/* subnormal x, shift x to normal */
      n = -126-ix;
      hx = hx<<n;
    }
    if(iy >= -126)
      hy = 0x00800000|(0x007fffff&hy);
    else {		/* subnormal y, shift y to normal */
      n = -126-iy;
      hy = hy<<n;
    }
  }

  /* fix point fmod */
  int hz;
  n = ix - iy;
  while(n--) {
    hz=hx-hy;
    if(hz<0){hx = hx+hx;}
    else {
      if(hz==0) 		/* return sign(x)*0 */
        return Zero[cast(uint)sx>>31];
      hx = hz+hz;
    }
  }
  hz=hx-hy;
  if(hz>=0) {hx=hz;}

  /* convert back to floating value and restore the sign */
  if(hx==0) 			/* return sign(x)*0 */
    return Zero[cast(uint)sx>>31];
  while(hx<0x00800000) {		/* normalize x */
    hx = hx+hx;
    iy -= 1;
  }

  static if (true) {
    hx = ((hx-0x00800000)|((iy+127)<<23));
    SET_FLOAT_WORD(x,hx|sx);
  } else {
    if(iy>= -126) {		/* normalize output */
      hx = ((hx-0x00800000)|((iy+127)<<23));
      SET_FLOAT_WORD(x,hx|sx);
    } else {		/* subnormal output */
      n = -126 - iy;
      hx >>= n;
      SET_FLOAT_WORD(x,hx|sx);
      x *= one;		/* create necessary signal */
    }
  }

  return x;		/* exact output */
}

private:

enum float one = 1.0;
enum float[2] Zero = [0.0, -0.0,];
