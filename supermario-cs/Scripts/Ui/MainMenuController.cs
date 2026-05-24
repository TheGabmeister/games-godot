using Godot;

namespace SuperMario;

public partial class MainMenuController : Control
{
    [Signal] public delegate void StartPressedEventHandler();

    public override void _Ready()
    {
        var btn = GetNode<Button>("CenterContainer/VBoxContainer/StartButton");
        btn.Pressed += () => EmitSignal(SignalName.StartPressed);
    }
}
