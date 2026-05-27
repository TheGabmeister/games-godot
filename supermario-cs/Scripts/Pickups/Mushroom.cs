using System;
using Godot;

namespace SMB;

public partial class Mushroom : CharacterBody2D
{
    [Export] public Area2D PickupTrigger;

    public event Action<int> ScoreEarned;

    private bool _collected;

    public static Mushroom Create(Vector2 globalPosition)
    {
        var scene = GD.Load<PackedScene>(Config.MushroomScenePath);
        var m = scene.Instantiate<Mushroom>();
        m.GlobalPosition = globalPosition;
        return m;
    }

    public override void _Ready()
    {
        PickupTrigger.BodyEntered += OnPickedUp;
    }

    private void OnPickedUp(Node2D body)
    {
        if (_collected || body is not PlayerController player) return;
        _collected = true;
        ScoreEarned?.Invoke(Constants.MushroomScore);
        SpawnText(Constants.MushroomScore.ToString(), GlobalPosition);
        player.ApplyMushroom();
        QueueFree();
    }
}
