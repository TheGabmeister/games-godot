using Godot;

namespace SuperMario;

public partial class OneUp : CharacterBody2D
{
    [Export] public Area2D PickupTrigger;

    private bool _collected;

    public override void _Ready()
    {
        PickupTrigger.BodyEntered += OnPickedUp;
    }

    private void OnPickedUp(Node2D body)
    {
        if (_collected || body is not PlayerController) return;
        _collected = true;
        GameSession.Instance.EmitOneUpAwarded();
        QueueFree();
    }
}
