using Godot;

namespace SMB;

public partial class Mushroom : CharacterBody2D
{
    [Export] public Area2D PickupTrigger;

    private IScoreAwarder _scoreAwarder;
    private bool _collected;

    public static Mushroom Create(Vector2 globalPosition, IScoreAwarder scoreAwarder)
    {
        var scene = GD.Load<PackedScene>(Config.MushroomScenePath);
        var m = scene.Instantiate<Mushroom>();
        m.GlobalPosition = globalPosition;
        m._scoreAwarder = scoreAwarder;
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
        _scoreAwarder.AwardScore(Constants.MushroomScore);
        Bus<EV_TextSpawn>.Emit(new EV_TextSpawn { text = Constants.MushroomScore.ToString(), position = GlobalPosition });
        player.ApplyMushroom();
        QueueFree();
    }
}
