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
    [Dependency] public GameRules Rules => this.DependOn<GameRules>();

    public override void _Notification(int what) => this.Notify(what);

    public override void _Ready()
    {
        PickupTrigger.BodyEntered += OnPickedUp;
    }

    private void OnPickedUp(Node2D body)
    {
        if (_collected || body is not PlayerController player) return;
        _collected = true;
        ScoreAwarder.AwardScore(Rules.StarmanPickupScore);
        TextSpawner.SpawnText(Rules.StarmanPickupScore.ToString(), GlobalPosition);
        Sfx.PlayPlayerPowerUp();
        player.ApplyStarman();
        QueueFree();
    }
}
