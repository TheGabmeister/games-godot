using System;
using Godot;

namespace SMB;

public partial class Starman : CharacterBody2D
{
    [Export] public Area2D PickupTrigger;

    public event Action<int> ScoreEarned;

    private bool _collected;

    public static Starman Create(Vector2 globalPosition)
    {
        var scene = GD.Load<PackedScene>(Config.StarmanScenePath);
        var s = scene.Instantiate<Starman>();
        s.GlobalPosition = globalPosition;
        return s;
    }

    public override void _Ready()
    {
        PickupTrigger.BodyEntered += OnPickedUp;
    }

    private void OnPickedUp(Node2D body)
    {
        if (_collected || body is not PlayerController player) return;
        _collected = true;
        ScoreEarned?.Invoke(Constants.StarmanPickupScore);
        SpawnText(Constants.StarmanPickupScore.ToString(), GlobalPosition);
        player.ApplyStarman();
        QueueFree();
    }
}
