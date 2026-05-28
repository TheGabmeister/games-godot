using Godot;

namespace SMB;

[Meta(typeof(IAutoNode))]
public partial class OneUp : CharacterBody2D
{
    [Export] public Area2D PickupTrigger;

    private bool _collected;

    [Dependency] public GameMode GameMode => this.DependOn<GameMode>();
    [Dependency] public SfxManager Sfx => this.DependOn<SfxManager>();

    public override void _Notification(int what) => this.Notify(what);

    public override void _Ready()
    {
        PickupTrigger.BodyEntered += OnPickedUp;
    }

    private void OnPickedUp(Node2D body)
    {
        if (_collected || body is not PlayerController) return;
        _collected = true;
        GameMode.EmitOneUpAwarded();
        Sfx.PlayOneUp();
        QueueFree();
    }
}
