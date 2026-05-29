using Godot;

namespace SMB;

[Meta(typeof(IAutoNode))]
public partial class QuestionBlock : StaticBody2D, IBumpable
{
    [Export] public Bumpable Bumpable;
    [Export] public ColorRect Visual;
    [Export] public Color UsedColor = new Color(0.55f, 0.35f, 0.10f);

    private bool _used;

    [Dependency] public IScoreAwarder ScoreAwarder => this.DependOn<IScoreAwarder>();
    [Dependency] public ICoinCollector CoinCollector => this.DependOn<ICoinCollector>();
    [Dependency] public SfxManager Sfx => this.DependOn<SfxManager>();
    [Dependency] public GameRules Rules => this.DependOn<GameRules>();

    public override void _Notification(int what) => this.Notify(what);

    public override void _Ready()
    {
    }

    public void OnBumped(PlayerController player)
    {
        if (_used) return;
        _used = true;
        Visual.Color = UsedColor;
        ScoreAwarder.AwardScore(Rules.CoinScore);
        CoinCollector.CollectCoins(1);
        Sfx.PlayCoin();
        Bumpable.Bump();
    }
}
