using Godot;

namespace SMB;

public partial class Starman : CharacterBody2D
{
    [Export] public Area2D PickupTrigger;

    private IScoreAwarder _scoreAwarder;
    private bool _collected;

    public static Starman Create(Vector2 globalPosition, IScoreAwarder scoreAwarder)
    {
        var scene = GD.Load<PackedScene>(Config.StarmanScenePath);
        var s = scene.Instantiate<Starman>();
        s.GlobalPosition = globalPosition;
        s._scoreAwarder = scoreAwarder;
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
        _scoreAwarder.AwardScore(Constants.StarmanPickupScore);
        Bus<EV_TextSpawn>.Emit(new EV_TextSpawn { text = Constants.StarmanPickupScore.ToString(), position = GlobalPosition });
        player.ApplyStarman();
        QueueFree();
    }
}
