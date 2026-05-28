using System;
using Godot;

namespace SMB;

[Meta(typeof(IAutoNode))]
public partial class MainMenuController : Control
{
    public event Action StartPressed;

    [Dependency] public SfxManager Sfx => this.DependOn<SfxManager>();

    public override void _Notification(int what) => this.Notify(what);

    public override void _Ready()
    {
        var btn = GetNode<Button>("CenterContainer/VBoxContainer/StartButton");
        btn.Pressed += () =>
        {
            Sfx.PlayPipe();
            StartPressed?.Invoke();
        };
    }
}
