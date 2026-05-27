using System;
using Godot;

namespace SMB;

public partial class GameOverController : Control
{
    public event Action Continue;

    public override void _Ready()
    {
        var btn = GetNode<Button>("CenterContainer/VBoxContainer/ContinueButton");
        btn.Pressed += () => Continue?.Invoke();
    }
}
