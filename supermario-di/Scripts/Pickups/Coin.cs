using Godot;

namespace SMB;

[Meta(typeof(IAutoNode))]
public partial class Coin : Area2D
{
    private bool _collected;

    [Dependency] public IScoreAwarder ScoreAwarder => this.DependOn<IScoreAwarder>();
    [Dependency] public ICoinCollector CoinCollector => this.DependOn<ICoinCollector>();
    [Dependency] public TextSpawner TextSpawner => this.DependOn<TextSpawner>();
    [Dependency] public SfxManager Sfx => this.DependOn<SfxManager>();
    [Dependency] public GameRules Rules => this.DependOn<GameRules>();

    public override void _Notification(int what) => this.Notify(what);

    public override void _Ready()
    {
        BodyEntered += OnBodyEntered;
    }

    private void OnBodyEntered(Node2D body)
    {
        if (_collected || body is not PlayerController) return;
        _collected = true;
        ScoreAwarder.AwardScore(Rules.CoinScore);
        CoinCollector.CollectCoins(1);
        TextSpawner.SpawnText(Rules.CoinScore.ToString(), GlobalPosition);
        Sfx.PlayCoin();
        QueueFree();
    }
}
