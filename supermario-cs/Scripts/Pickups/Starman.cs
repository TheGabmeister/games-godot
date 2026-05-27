using Godot;

namespace SMB;

public partial class Starman : CharacterBody2D
{
    [Export] public Area2D PickupTrigger;

    private GameEvents _events;
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
        _events = GetGameEvents();
        PickupTrigger.BodyEntered += OnPickedUp;
    }

    private void OnPickedUp(Node2D body)
    {
        if (_collected || body is not PlayerController player) return;
        _collected = true;
        _events.EmitScoreEarned(Constants.StarmanPickupScore);
        SpawnText(Constants.StarmanPickupScore.ToString(), GlobalPosition);
        player.ApplyStarman();
        QueueFree();
    }
}
