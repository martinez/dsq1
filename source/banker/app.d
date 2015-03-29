module app;
import editors;
import properties;
import global;
import ESQpatch;
import tkd.tkdapplication;
import std.stdio;
import std.algorithm: map;
import std.array: array, join;
import std.string: format;
import std.conv: to;
import std.file: read;

class Application: TkdApplication
{
  BasicEditor[] lfoEditor;
  BasicEditor[] envEditor;
  BasicEditor[] oscEditor;
  BasicEditor miscEditor;
  Entry nameEntry;

  override protected void initInterface()
  {
    this.mainWindow.setTitle("Banker");

    {
      auto menuBar = new MenuBar(this.mainWindow);
      auto fileMenu = new Menu(menuBar, "File", 0)
                      .addEntry("Open", &onFileOpen, "Ctrl-O")
                      .addSeparator()
                      .addEntry("Quit", &onQuit, "Ctrl-Q")
                      ;

      this.mainWindow.bind("<Control-o>", &onFileOpen);
      this.mainWindow.bind("<Control-q>", &onQuit);
    }

    int pos = 0;

    {
      pos += 10;
      auto frame = new LabelFrame("Patch");
      frame.grid(10, pos, 0, 0, 1, 1);

      new Label(frame, "Name")
          .grid(10, 10, 0, 0, 1, 1);
      nameEntry = new Entry(frame)
                  .grid(20, 10, 0, 0, 1, 1);

      // TODO tkd: don't have validation
      nameEntry.bind("<KeyPress>", &onNameEdit);

      frame = new LabelFrame("Bank");
      frame.grid(20, pos, 0, 0, 1, 1);

      new Button(frame, "Previous")
          .grid(10, 10, 0, 0, 1, 1)
          .setCommand(&onBankPrevious);
      new Button(frame, "Next")
          .grid(20, 10, 0, 0, 1, 1)
          .setCommand(&onBankNext);
    }

    lfoEditor = [new LfoEditor!0,
                 new LfoEditor!1,
                 new LfoEditor!2];

    envEditor = [new EnvEditor!0,
                 new EnvEditor!1,
                 new EnvEditor!2,
                 new EnvEditor!3,];

    oscEditor = [new OscEditor!0,
                 new OscEditor!1,
                 new OscEditor!2];

    miscEditor = new MiscEditor;

    pos += 10;
    foreach (uint i, Frame editor; lfoEditor)
      editor.grid(10 * i, pos, 0, 0, 1, 1);

    pos += 10;
    foreach (uint i, Frame editor; envEditor)
      editor.grid(10 * i, pos, 0, 0, 1, 1);

    pos += 10;
    foreach (uint i, Frame editor; oscEditor)
      editor.grid(10 * i, pos, 0, 0, 1, 1);

    pos += 10;
    miscEditor.grid(10, pos, 0, 0, 1, 1);

    updateDisplay();
  }

  void updateDisplay()
  {
    nameEntry.setValue(active_program.name);
    foreach (BasicEditor ed; lfoEditor ~ envEditor ~ oscEditor ~ [miscEditor])
      ed.showValues();
  }

 private:
  void onQuit(CommandArgs rgs)
  {
    exit();
  }

  void onFileOpen(CommandArgs args)
  {
    auto filedialog = new OpenFileDialog()
                      .addFileType("{{Bank files} {.mdx .syx}}")
                      .addFileType("{{All files} {*}}")
                      .show();
    string[] results = filedialog.getResults();
    if (results !is null && results[0] != "") {
      string filename = results[0];
      try {
        ESQ_Bank bnk = ESQ_load_bank(cast(ubyte[])read(filename));
        *global_bank = bnk;
        active_program_number = 0;
      } catch (Exception ex) {
        new MessageDialog()
            .setMessage("Error opening")
            .setDetailMessage("The operation has failed: " ~ ex.msg)
            .setIcon(MessageDialogIcon.error)
            .show();
      }

      updateDisplay();
    }
  }

  void onNameEdit(CommandArgs args)
  {
    string val = (cast(Entry)args.element).getValue();
    if (val.length > 6) val = val[0..6];
    active_program.name = val;
  }

  void onBankPrevious(CommandArgs args)
  {
    if (active_program_number > 0) {
      --active_program_number;
      updateDisplay();
    }
  }

  void onBankNext(CommandArgs args)
  {
    if (active_program_number + 1 < active_bank.num_patches) {
      ++active_program_number;
      updateDisplay();
    }
  }
}

///

void main(string[] args)
{
  auto app = new Application();
  app.run();
}
