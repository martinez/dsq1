module OSC;
import raii.cstring;
import std.stdio;
import std.conv: to;
import lo.c.lo_highlevel;
import lo.c.lo_lowlevel;

final class OSCserver
{
  lo_server server;

  this() {
    server = lo_server_new(null, null);
    install_methods(this);
  }

  ~this() {
    lo_server_free(server);
  }

  string get_url()
  {
    return RAII_cstring(lo_server_get_url(server)).array.dup;
  }

  void recv_some()
  {
    while (lo_server_wait(server, 0) > 0) {
      lo_server_recv(server);
    }
  }
}

final class OSCclient
{
  lo_address address;
  string path;

  this(string url)
  {
    address = lo_address_new_from_url(url.toStringz);
    path = RAII_cstring(lo_url_get_path(url.toStringz)).array.dup;
  }

  ~this()
  {
    lo_address_free(address);
  }

  void sendUpdate(string url)
  {
    lo_send(address, (path~"update").toStringz, "s", url.toStringz);
  }

  void sendQuit()
  {
    lo_send(address, (path~"quit").toStringz, "");
  }
}

private:

void install_methods(OSCserver srv)
{
}
