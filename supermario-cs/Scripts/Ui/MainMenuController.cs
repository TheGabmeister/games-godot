using System;
using Godot;

namespace SuperMario;

public partial class MainMenuController : Control
{
    public event Action StartPressed;

    public override void _Ready()
    {
        var btn = GetNode<Button>("CenterContainer/VBoxContainer/StartButton");
        btn.Pressed += () => StartPressed?.Invoke();
    }
}
