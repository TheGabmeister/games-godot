using Godot;

namespace SMB;

public partial class Starman : CharacterBody2D
{
    [Export] public Area2D PickupTrigger;
    [Export] public int ScoreValue = 1000;

    private bool _collected;

    public override void _Ready()
    {
        PickupTrigger.BodyEntered += OnPickedUp;
    }

    private void OnPickedUp(Node2D body)
    {
        if (_collected) return;
        _collected = true;
        Events.EmitGotStarman(ScoreValue, GlobalPosition);
        QueueFree();
    }
}
