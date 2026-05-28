using Godot;

namespace SMB;

[Meta(typeof(IAutoNode))]
public partial class FireFlower : Area2D
{
    private bool _collected;

    [Dependency] public IScoreAwarder ScoreAwarder => this.DependOn<IScoreAwarder>();
    [Dependency] public TextSpawner TextSpawner => this.DependOn<TextSpawner>();
    [Dependency] public SfxManager Sfx => this.DependOn<SfxManager>();
    [Dependency] public GameRules Rules => this.DependOn<GameRules>();

    public override void _Notification(int what) => this.Notify(what);

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
        ScoreAwarder.AwardScore(Rules.MushroomScore);
        TextSpawner.SpawnText(Rules.MushroomScore.ToString(), GlobalPosition);
        Sfx.PlayPlayerPowerUp();
        player.ApplyFireFlower();
        QueueFree();
    }
}
