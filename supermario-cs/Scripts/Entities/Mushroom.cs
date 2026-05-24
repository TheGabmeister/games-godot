using Godot;

namespace SuperMario;

public partial class Mushroom : CharacterBody2D
{
    [Export] public Area2D PickupTrigger;

    private bool _collected;

    public override void _Ready()
    {
        if (PickupTrigger != null)
            PickupTrigger.BodyEntered += OnPickedUp;
    }

    private void OnPickedUp(Node2D body)
    {
        if (_collected || body is not PlayerController player) return;
        _collected = true;
        GameManager.Instance?.State?.AddScore(Constants.MushroomScore);
        ScorePopup.Spawn(GameManager.Instance?.CurrentLevel, GlobalPosition, Constants.MushroomScore);
        player.ApplyMushroom();
        QueueFree();
    }
}
