using System;
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
        qb.Initialize(scoreAwarder, coinCollector);
        return qb;
    }

    public void Initialize(IScoreAwarder scoreAwarder, ICoinCollector coinCollector)
    {
        _scoreAwarder = scoreAwarder ?? throw new ArgumentNullException(nameof(scoreAwarder));
        _coinCollector = coinCollector ?? throw new ArgumentNullException(nameof(coinCollector));
    }

    public override void _Ready()
    {
        EnsureInitialized();
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

    private void EnsureInitialized()
    {
        if (_scoreAwarder == null || _coinCollector == null)
            throw new InvalidOperationException($"{nameof(QuestionBlock)} requires score and coin services before it enters the tree.");
    }
}
