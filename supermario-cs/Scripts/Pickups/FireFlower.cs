using Godot;

namespace SMB;

public partial class FireFlower : Area2D
{
    private GameEvents _events;
    private bool _collected;

    public static FireFlower Create(Vector2 globalPosition, GameEvents events)
    {
        var scene = GD.Load<PackedScene>(Config.FireFlowerScenePath);
        var f = scene.Instantiate<FireFlower>();
        f.GlobalPosition = globalPosition;
        f._events = events;
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
        _events.EmitScoreEarned(Constants.MushroomScore);
        SpawnText(Constants.MushroomScore.ToString(), GlobalPosition);
        player.ApplyFireFlower();
        QueueFree();
    }
}
