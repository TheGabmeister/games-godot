using Godot;

namespace SuperMario;

public partial class GameOverController : Control
{
    [Signal] public delegate void ContinueEventHandler();

    public override void _Ready()
    {
        var btn = GetNode<Button>("CenterContainer/VBoxContainer/ContinueButton");
        btn.Pressed += () => EmitSignal(SignalName.Continue);
    }
}
