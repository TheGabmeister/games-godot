using Godot;

namespace SMB;

[Meta(typeof(IAutoNode))]
public partial class Starman : CharacterBody2D
{
    [Export] public Area2D PickupTrigger;

    private bool _collected;

    [Dependency] public IScoreAwarder ScoreAwarder => this.DependOn<IScoreAwarder>();
    [Dependency] public TextSpawner TextSpawner => this.DependOn<TextSpawner>();
    [Dependency] public SfxManager Sfx => this.DependOn<SfxManager>();

    public override void _Notification(int what) => this.Notify(what);

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
        ScoreAwarder.AwardScore(Constants.StarmanPickupScore);
        TextSpawner.SpawnText(Constants.StarmanPickupScore.ToString(), GlobalPosition);
        Sfx.PlayPlayerPowerUp();
        player.ApplyStarman();
        QueueFree();
    }
}
