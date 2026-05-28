using Godot;

namespace SMB;

public partial class FireFlower : Area2D
{
    [Export] public int ScoreValue = 1000;

    private bool _collected;

    public override void _Ready()
    {
        BodyEntered += OnBodyEntered;
    }

    private void OnBodyEntered(Node2D body)
    {
        if (_collected) return;
        _collected = true;
        PlaySfx(_clip);
        Events.EmitFireFlowerPickedUp(ScoreValue, GlobalPosition);
        QueueFree();
    }
}
