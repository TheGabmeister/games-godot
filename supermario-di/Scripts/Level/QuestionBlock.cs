using Godot;

namespace SMB;

public partial class QuestionBlock : StaticBody2D, IBumpable
{
    [Export] public Bumpable Bumpable;
    [Export] public ColorRect Visual;
    [Export] public Color UsedColor = new Color(0.55f, 0.35f, 0.10f);

    private IScoreAwarder _scoreAwarder;
    private ICoinCollector _coinCollector;
    private bool _used;

    public static QuestionBlock Create(Vector2 globalPosition, IScoreAwarder scoreAwarder, ICoinCollector coinCollector)
    {
        var scene = GD.Load<PackedScene>(Config.QuestionBlockScenePath);
        var qb = scene.Instantiate<QuestionBlock>();
        qb.GlobalPosition = globalPosition;
        qb._scoreAwarder = scoreAwarder;
        qb._coinCollector = coinCollector;
        return qb;
    }

    public override void _Ready()
    {
    }

    public void OnBumped(PlayerController player)
    {
        if (_used) return;
        _used = true;
        Visual.Color = UsedColor;
        _scoreAwarder.AwardScore(Constants.CoinValue);
        _coinCollector.CollectCoins(1);
        Bumpable.Bump();
    }
}
