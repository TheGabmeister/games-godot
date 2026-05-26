using Godot;

namespace SMB;

public partial class Mushroom : CharacterBody2D
{
    [Export] public Area2D PickupTrigger;

    private GameEvents _events;
    private bool _collected;

    public static Mushroom Create(Vector2 globalPosition, GameEvents events)
    {
        var scene = GD.Load<PackedScene>(Config.MushroomScenePath);
        var m = scene.Instantiate<Mushroom>();
        m.GlobalPosition = globalPosition;
        m._events = events;
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
        _events.EmitScoreEarned(Constants.MushroomScore);
        SpawnText(Constants.MushroomScore.ToString(), GlobalPosition);
        player.ApplyMushroom();
        QueueFree();
    }
}
