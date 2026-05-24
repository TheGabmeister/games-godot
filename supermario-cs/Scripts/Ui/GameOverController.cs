using Godot;

namespace SuperMario;

public partial class GameOverController : Control
{
    [Signal] public delegate void ContinueEventHandler();

    public override void _Ready()
    {
        var btn = GetNodeOrNull<Button>("CenterContainer/VBoxContainer/ContinueButton");
        if (btn != null)
            btn.Pressed += () => EmitSignal(SignalName.Continue);
        else
            GD.PushError("GameOverController: ContinueButton not found.");
    }
}
