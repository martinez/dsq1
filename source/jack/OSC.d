module OSC;
import raii.cstring;
import std.stdio;
import std.conv: to;
import lo.c.lo_highlevel;
import lo.c.lo_lowlevel;

final class OSCserver
{
  lo_server server;
  string url_client;
  bool running;

  this() {
    server = lo_server_new(null, null);
    install_methods(this);
  }

  ~this() {
    lo_server_free(server);
  }

  @property void is_running(bool b) { running = b; }
  @property bool is_running() { return running; }

  string get_url()
  {
    return RAII_cstring(lo_server_get_url(server)).array.dup;
  }

  OSCclient wait_for_client()
  {
    while (! url_client)
      lo_server_recv(server);
    return new OSCclient(url_client);
  }

  void run()
  {
    is_running = true;
    while (is_running) {
      lo_server_recv(server);
    }
  }

  void onReceiveUpdate(string url)
  {
    stderr.writefln("Update: %s", url);
    url_client = url;
  }

  void onReceiveOther(string path)
  {
    stderr.writefln("Unhandled message: %s", path);
  }

  void onQuit()
  {
    running = false;
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

  string get_url()
  {
    return cast(immutable)RAII_cstring(lo_address_get_url(address)).array ~ path;
  }
}

private:

void install_methods(OSCserver srv)
{
  extern(C) int handle_update(const(char) *, const(char) *,
                              lo_arg **argv, int argc, lo_message msg, void *user_data)
  {
    (cast(OSCserver)user_data).onReceiveUpdate((&argv[0].s).to!string);
    return 0;
  }
  extern(C) int handle_quit(const(char) *, const(char) *,
                            lo_arg **argv, int argc, lo_message msg, void *user_data)
  {
    (cast(OSCserver)user_data).onQuit();
    return 0;
  }

  extern(C) int handle_rest(const(char) *path, const(char) *,
                            lo_arg **argv, int argc, lo_message msg, void *user_data)
  {
    (cast(OSCserver)user_data).onReceiveOther(path.to!string);
    return 0;
  }

  lo_method method;
  method = lo_server_add_method(
      srv.server, "/update", "s", &handle_update, cast(void *)srv);
  method = lo_server_add_method(
      srv.server, "/quit", "", &handle_quit, cast(void *)srv);
  method = lo_server_add_method(
      srv.server, null, null, &handle_rest, cast(void *)srv);
}
