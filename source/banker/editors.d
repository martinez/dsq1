module editors;
import properties;
import global;
import ESQpatch;
import tkd.tkdapplication;
import std.stdio;
import std.string: format;
import std.array: array;
import std.conv: to;
import std.traits: EnumMembers;

class BasicEditor: Frame
{
  this(UiElement parent, AccessTraits access) {
    super(parent);
    this.access = access;
  }

  T getValue(T)(string id) if (is(T == int))
  {
    UiElement elt = editables[id];
    if (Scale x = cast(Scale)elt)
      return cast(int)x.getValue();
    else if (ComboBox x = cast(ComboBox)elt)
      return x.getSelected();
    else if (CheckButton x = cast(CheckButton)elt)
      return x.isChecked();
    assert(0);
  }

  void showValues()
  {
    foreach (string id; editables.byKey) {
      UiElement elt = editables[id];
      if (Scale x = cast(Scale)elt) {
        x.setValue(access.getInt(active_program, id));
      } else if (ComboBox x = cast(ComboBox)elt) {
        x.select(access.getInt(active_program, id));
      } else if (CheckButton x = cast(CheckButton)elt) {
        (cast(bool)access.getInt(active_program, id)) ? x.check() : x.unCheck();
      } else {
        assert(0);
      }
    }
  }

protected:
  UiElement[string] editables;
  AccessTraits access;

  void createBindings()
  {
    foreach (string id; editables.byKey) {
      UiElement elt = editables[id];
      if (Scale x = cast(Scale)elt) {

        x.setCommand(delegate(CommandArgs args) {
            Scale elt = cast(Scale)args.element;
            string id = getId(elt);
            // writefln("%s: %s", id, elt.getValue());
            access.setInt(active_program, id, cast(int)elt.getValue());
          });

      } else if (ComboBox x = cast(ComboBox)elt) {

        x.bind("<<ComboboxSelected>>", delegate(CommandArgs args) {
            ComboBox elt = cast(ComboBox)args.element;
            string id = getId(elt);
            // writefln("%s: %s", id, elt.getValue());
            access.setInt(active_program, id, elt.getSelected());
          });

      } else if (CheckButton x = cast(CheckButton)elt) {

        x.setCommand(delegate(CommandArgs args) {
            CheckButton elt = cast(CheckButton)args.element;
            string id = getId(elt);
            // writefln("%s: %s", id, elt.getValue());
            access.setInt(active_program, id, elt.isChecked());
          });

      } else {
        assert(0);
      }
    }
  }

  string getId(UiElement elt)
  {
    /// XXX: not optimized
    foreach (string id; editables.byKey)
      if (editables[id] == elt)
        return id;
    assert(0);
  }
}

class LfoEditor(uint num): BasicEditor
{
  this(UiElement parent = null)
  {
    super(parent, new LfoPropertyTraits!num);

    string name = format("LFO%d", 1+num);
    auto labelFrame = new LabelFrame(this, name)
                      .pack(10, 0, GeometrySide.top, GeometryFill.both, AnchorPosition.center, true);

    int pos = 0;

    pos += 10;
    new Label(labelFrame, "FREQ")
        .grid(10, pos, 0, 0, 1, 1);
    editables["FREQ"] = new Scale(labelFrame)
                        .grid(20, pos, 0, 0, 1, 1, "we")
                        .setFromValue(0).setToValue(+63);

    pos += 10;
    new Label(labelFrame, "L1")
        .grid(10, pos, 0, 0, 1, 1);
    editables["L1"] = new Scale(labelFrame)
                      .grid(20, pos, 0, 0, 1, 1, "we")
                      .setFromValue(0).setToValue(+63);

    pos += 10;
    new Label(labelFrame, "L2")
        .grid(10, pos, 0, 0, 1, 1);
    editables["L2"] = new Scale(labelFrame)
                      .grid(20, pos, 0, 0, 1, 1, "we")
                      .setFromValue(0).setToValue(+63);

    pos += 10;
    new Label(labelFrame, "MOD")
        .grid(10, pos, 0, 0, 1, 1);
    editables["MOD"] = createSelectionBox!ESQ_Mod(labelFrame)
                       .grid(20, pos, 0, 0, 1, 1);

    pos += 10;
    new Label(labelFrame, "WAV")
        .grid(10, pos, 0, 0, 1, 1);
    editables["WAV"] = createSelectionBox!ESQ_LfoWave(labelFrame)
                       .grid(20, pos, 0, 0, 1, 1);

    pos += 10;
    editables["HUMAN"] = new CheckButton(labelFrame, "HUMAN")
                         .grid(10, pos, 0, 0, 1, 1);
    editables["RESET"] = new CheckButton(labelFrame, "RESET")
                         .grid(20, pos, 0, 0, 1, 1);

    createBindings();
  }

}

class EnvEditor(uint num): BasicEditor
{
  this(UiElement parent = null)
  {
    super(parent, new EnvPropertyTraits!num);

    auto labelFrame = new LabelFrame(this, format("ENV%d", 1+num))
                      .pack(10, 0, GeometrySide.top, GeometryFill.both, AnchorPosition.center, true);

    int pos;

    pos = 10;
    for (uint i = 0; i < 3; ++i) {
      string name = format("L%d", i+1);
      new Label(labelFrame, name)
          .grid(10, pos, 0, 0, 1, 1);
      editables[name] = new Scale(labelFrame)
                        .grid(20, pos, 0, 0, 1, 1, "we")
                        .setFromValue(-63).setToValue(+63);
      pos += 10;
    }

    pos = 10;
    for (uint i = 0; i < 4; ++i) {
      string name = format("T%d", i+1);
      new Label(labelFrame, name)
          .grid(30, pos, 0, 0, 1, 1);
      editables[name] = new Scale(labelFrame)
                        .grid(40, pos, 0, 0, 1, 1, "we")
                        .setFromValue(0).setToValue(+63);
      pos += 10;
    }

    new Label(labelFrame, "LV")
        .grid(10, pos, 0, 0, 1, 1);
    editables["LV"] = new Scale(labelFrame)
                    .grid(20, pos, 0, 0, 1, 1, "we")
                    .setFromValue(0).setToValue(+63);

    pos += 10;
    new Label(labelFrame, "T1V")
        .grid(10, pos, 0, 0, 1, 1);
    editables["T1V"] = new Scale(labelFrame)
                       .grid(20, pos, 0, 0, 1, 1, "we")
                       .setFromValue(0).setToValue(+63);

    pos += 10;
    new Label(labelFrame, "TK")
        .grid(10, pos, 0, 0, 1, 1);
    editables["TK"] = new Scale(labelFrame)
                       .grid(20, pos, 0, 0, 1, 1, "we")
                       .setFromValue(0).setToValue(+63);

    createBindings();
  }
}

class OscEditor(uint num): BasicEditor
{
  this(UiElement parent = null)
  {
    super(parent, new OscPropertyTraits!num);

    auto labelFrame = new LabelFrame(this, format("OSC%d", 1+num))
                      .pack(10, 0, GeometrySide.top, GeometryFill.both, AnchorPosition.center, true);

    int pos = 0;

    pos += 10;
    new Label(labelFrame, "SEMI")
        .grid(10, pos, 0, 0, 1, 1);
    editables["SEMI"] = new Scale(labelFrame)
                        .grid(20, pos, 0, 0, 1, 1, "we")
                        .setFromValue(0).setToValue(+127);

    pos += 10;
    new Label(labelFrame, "FINE")
        .grid(10, pos, 0, 0, 1, 1);
    editables["FINE"] = new Scale(labelFrame)
                        .grid(20, pos, 0, 0, 1, 1, "we")
                        .setFromValue(0).setToValue(+31);

    pos += 10;
    new Label(labelFrame, "FM1")
        .grid(10, pos, 0, 0, 1, 1);
    editables["FMSRC1"] = createSelectionBox!ESQ_Mod(labelFrame)
                          .grid(20, pos, 0, 0, 1, 1);
    editables["FCMODAMT1"] = new Scale(labelFrame)
                             .grid(30, pos, 0, 0, 1, 1, "we")
                             .setFromValue(-63).setToValue(+63);

    pos += 10;
    new Label(labelFrame, "FM2")
        .grid(10, pos, 0, 0, 1, 1);
    editables["FMSRC2"] = createSelectionBox!ESQ_Mod(labelFrame)
                          .grid(20, pos, 0, 0, 1, 1);
    editables["FCMODAMT2"] = new Scale(labelFrame)
                             .grid(30, pos, 0, 0, 1, 1, "we")
                             .setFromValue(-63).setToValue(+63);

    pos += 10;
    new Label(labelFrame, "WAVEFORM")
        .grid(10, pos, 0, 0, 1, 1);
    editables["WAVEFORM"] = createSelectionBox!ESQ_OscWave(labelFrame)
                          .grid(20, pos, 0, 0, 1, 1);

    pos += 10;
    editables["DCAENABLE"] = new CheckButton(labelFrame, "DCA")
                             .grid(10, pos, 0, 0, 1, 1);
    editables["DCALEVEL"] = new Scale(labelFrame)
                            .grid(20, pos, 0, 0, 1, 1, "we")
                            .setFromValue(0).setToValue(+63);

    pos += 10;
    new Label(labelFrame, "AM1")
        .grid(10, pos, 0, 0, 1, 1);
    editables["AMSRC1"] = createSelectionBox!ESQ_Mod(labelFrame)
                          .grid(20, pos, 0, 0, 1, 1);
    editables["AMAMT1"] = new Scale(labelFrame)
                             .grid(30, pos, 0, 0, 1, 1, "we")
                             .setFromValue(-63).setToValue(+63);

    pos += 10;
    new Label(labelFrame, "AM2")
        .grid(10, pos, 0, 0, 1, 1);
    editables["AMSRC2"] = createSelectionBox!ESQ_Mod(labelFrame)
                          .grid(20, pos, 0, 0, 1, 1);
    editables["AMAMT2"] = new Scale(labelFrame)
                             .grid(30, pos, 0, 0, 1, 1, "we")
                             .setFromValue(-63).setToValue(+63);

    createBindings();
  }
}

class MiscEditor: BasicEditor
{
  this(UiElement parent = null)
  {
    super(parent, new MiscPropertyTraits);

    auto labelFrame = new LabelFrame(this, "MISC")
                      .pack(10, 0, GeometrySide.top, GeometryFill.both, AnchorPosition.center, true);

    int pos = 0;

    pos += 10;
    new Label(labelFrame, "DCA4MODAMT")
        .grid(10, pos, 0, 0, 1, 1);
    editables["DCA4MODAMT"] = new Scale(labelFrame)
                              .grid(20, pos, 0, 0, 1, 1, "we")
                              .setFromValue(0).setToValue(+63);

    pos += 10;
    editables["AM"] = new CheckButton(labelFrame, "AM")
                      .grid(10, pos, 0, 0, 1, 1);
    editables["SYNC"] = new CheckButton(labelFrame, "SYNC")
                        .grid(20, pos, 0, 0, 1, 1);
    editables["VC"] = new CheckButton(labelFrame, "VC")
                      .grid(30, pos, 0, 0, 1, 1);
    editables["MONO"] = new CheckButton(labelFrame, "MONO")
                        .grid(40, pos, 0, 0, 1, 1);
    editables["ENV"] = new CheckButton(labelFrame, "ENV")
                       .grid(50, pos, 0, 0, 1, 1);
    editables["OSC"] = new CheckButton(labelFrame, "OSC")
                       .grid(60, pos, 0, 0, 1, 1);
    editables["CYCLE"] = new CheckButton(labelFrame, "CYCLE")
                         .grid(70, pos, 0, 0, 1, 1);

    pos += 10;
    new Label(labelFrame, "FLTFC")
        .grid(10, pos, 0, 0, 1, 1);
    editables["FLTFC"] = new Scale(labelFrame)
                         .grid(20, pos, 0, 0, 1, 1, "we")
                         .setFromValue(0).setToValue(+127);
    new Label(labelFrame, "Q")
        .grid(30, pos, 0, 0, 1, 1);
    editables["Q"] = new Scale(labelFrame)
                         .grid(40, pos, 0, 0, 1, 1, "we")
                         .setFromValue(0).setToValue(+31);

    pos += 10;
    new Label(labelFrame, "FC1")
        .grid(10, pos, 0, 0, 1, 1);
    editables["FCSRC1"] = createSelectionBox!ESQ_Mod(labelFrame)
                          .grid(20, pos, 0, 0, 1, 1);
    editables["FCMODAMT1"] = new Scale(labelFrame)
                             .grid(30, pos, 0, 0, 1, 1, "we")
                             .setFromValue(-63).setToValue(+63);

    pos += 10;
    new Label(labelFrame, "FC2")
        .grid(10, pos, 0, 0, 1, 1);
    editables["FCSRC2"] = createSelectionBox!ESQ_Mod(labelFrame)
                          .grid(20, pos, 0, 0, 1, 1);
    editables["FCMODAMT2"] = new Scale(labelFrame)
                             .grid(30, pos, 0, 0, 1, 1, "we")
                             .setFromValue(-63).setToValue(+63);

    pos += 10;
    new Label(labelFrame, "KEYBD")
        .grid(10, pos, 0, 0, 1, 1);
    editables["KEYBD"] = new Scale(labelFrame)
                         .grid(20, pos, 0, 0, 1, 1, "we")
                         .setFromValue(0).setToValue(+63);

    pos += 10;
    new Label(labelFrame, "GLIDE")
        .grid(10, pos, 0, 0, 1, 1);
    editables["GLIDE"] = new Scale(labelFrame)
                         .grid(20, pos, 0, 0, 1, 1, "we")
                         .setFromValue(0).setToValue(+63);

    pos += 10;
    new Label(labelFrame, "SPLITPOINT")
        .grid(10, pos, 0, 0, 1, 1);
    editables["SPLITPOINT"] = new Scale(labelFrame)
                         .grid(20, pos, 0, 0, 1, 1, "we")
                         .setFromValue(0).setToValue(+127);
    editables["SPLITDIR"] = new CheckButton(labelFrame, "SPLITDIR")
                            .grid(30, pos, 0, 0, 1, 1);

    pos += 10;
    editables["LAYER"] = new CheckButton(labelFrame, "LAYER")
                            .grid(10, pos, 0, 0, 1, 1);
    editables["LAYERPRG"] = new Scale(labelFrame)
                         .grid(20, pos, 0, 0, 1, 1, "we")
                         .setFromValue(0).setToValue(+127);

    pos += 10;
    editables["SPLIT"] = new CheckButton(labelFrame, "SPLIT")
                            .grid(10, pos, 0, 0, 1, 1);
    editables["SPLITPRG"] = new Scale(labelFrame)
                         .grid(20, pos, 0, 0, 1, 1, "we")
                         .setFromValue(0).setToValue(+127);

    pos += 10;
    editables["SPLITLAYER"] = new CheckButton(labelFrame, "SPLITLAYER")
                            .grid(10, pos, 0, 0, 1, 1);
    editables["SPLITLAYERPRG"] = new Scale(labelFrame)
                         .grid(20, pos, 0, 0, 1, 1, "we")
                         .setFromValue(0).setToValue(+127);

    pos += 10;
    new Label(labelFrame, "PAN")
        .grid(10, pos, 0, 0, 1, 1);
    editables["PAN"] = new Scale(labelFrame)
                       .grid(20, pos, 0, 0, 1, 1, "we")
                       .setFromValue(0).setToValue(+15);

    pos += 10;
    new Label(labelFrame, "PANMOD")
        .grid(10, pos, 0, 0, 1, 1);
    editables["PANMODSRC"] = createSelectionBox!ESQ_Mod(labelFrame)
                             .grid(20, pos, 0, 0, 1, 1);
    editables["PANMODAMT"] = new Scale(labelFrame)
                             .grid(30, pos, 0, 0, 1, 1, "we")
                             .setFromValue(-63).setToValue(+63);

    createBindings();
  }
}

///

private BasicEditor getParentEditor(UiElement elt)
{
  UiElement parent = cast(UiElement)elt.parent;
  if (BasicEditor e = cast(BasicEditor)parent)
    return e;
  return getParentEditor(parent);
}

private ComboBox createSelectionBox(E)(UiElement parent, E defaultValue = E.init)
{
  return new ComboBox(parent)
      .setData([EnumMembers!E].map!(a => a.to!string).array)
      .setValue(defaultValue.to!string);
}
