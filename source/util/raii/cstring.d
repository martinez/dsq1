module raii.cstring;
import core.stdc.stdlib: free;
import core.stdc.string: strlen;

struct RAII_cstring
{
  char *ptr = null;

  @disable this(this);

  this(char *ptr) {
    this.ptr = ptr;
  }

  ~this() {
    free(ptr);
  }

  char[] array()
  {
    return ptr ? ptr[0..strlen(ptr)] : null;
  }
}
