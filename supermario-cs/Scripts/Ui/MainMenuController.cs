using Godot;

namespace supermariocs.Ui;

public partial class MainMenuController : Control
{
    [Signal] public delegate void StartPressedEventHandler();

    public override void _Ready()
    {
        var btn = GetNodeOrNull<Button>("CenterContainer/VBoxContainer/StartButton");
        if (btn != null)
            btn.Pressed += () => EmitSignal(SignalName.StartPressed);
        else
            GD.PushError("MainMenuController: StartButton not found.");
    }
}
