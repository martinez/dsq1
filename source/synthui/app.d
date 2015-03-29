import OSC;
import tkd.tkdapplication;
import std.stdio;

class Application: TkdApplication
{
  OSCserver server_;
  OSCclient target_;

  this(OSCserver server, OSCclient target)
  {
    super();
    server_ = server;
    target_ = target;
  }

  override protected void initInterface()
  {
    this.mainWindow.setTitle("Synth");
    this.mainWindow.setIdleCommand(&this.onIdle, 1000);
  }

 private:
  void onIdle(CommandArgs args)
  {
    server_.recv_some();
    this.mainWindow.setIdleCommand(&this.onIdle, 1000);
  }
}

///

void main(string[] args)
{
  /// the OSC server
  scope OSCserver server = new OSCserver;
  stderr.writefln("the OSC server is listening at URL: %s",
                  server.get_url());

  /// the OSC client
  scope OSCclient target = new OSCclient(args[1]);

  target.sendUpdate(server.get_url());

  auto app = new Application(server, target);
  app.run();

  target.sendQuit();
}
