using System;
using Godot;

namespace SMB;

public partial class FireFlower : Area2D
{
    public event Action<int> ScoreEarned;

    private bool _collected;

    public static FireFlower Create(Vector2 globalPosition)
    {
        var scene = GD.Load<PackedScene>(Config.FireFlowerScenePath);
        var f = scene.Instantiate<FireFlower>();
        f.GlobalPosition = globalPosition;
        return f;
    }

    public override void _Ready()
    {
        BodyEntered += OnBodyEntered;
    }

    private void OnBodyEntered(Node2D body)
    {
        if (_collected || body is not PlayerController player) return;
        _collected = true;
        ScoreEarned?.Invoke(Constants.MushroomScore);
        SpawnText(Constants.MushroomScore.ToString(), GlobalPosition);
        player.ApplyFireFlower();
        QueueFree();
    }
}
