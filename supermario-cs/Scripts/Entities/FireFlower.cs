using Godot;
using supermariocs.Autoloads;
using supermariocs.Player;

namespace supermariocs.Entities;

public partial class FireFlower : Area2D
{
    private bool _collected;

    public override void _Ready()
    {
        BodyEntered += OnBodyEntered;
    }

    private void OnBodyEntered(Node2D body)
    {
        if (_collected || body is not PlayerController player) return;
        _collected = true;
        GameManager.Instance?.State?.AddScore(Constants.MushroomScore);
        Ui.ScorePopup.Spawn(GameManager.Instance?.CurrentLevel, GlobalPosition, Constants.MushroomScore);
        player.ApplyFireFlower();
        QueueFree();
    }
}
