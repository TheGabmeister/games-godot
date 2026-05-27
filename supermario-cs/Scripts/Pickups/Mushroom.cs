using Godot;

namespace SMB;

public partial class Mushroom : CharacterBody2D
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
        Bus<EV_ScoreEarned>.Emit(new EV_ScoreEarned { value = ScoreValue });
        Bus<EV_Pickup_Mushroom>.Emit();
        Bus<EV_TextSpawn>.Emit(new EV_TextSpawn { text = ScoreValue.ToString(), position = GlobalPosition });
        QueueFree();
    }
}
