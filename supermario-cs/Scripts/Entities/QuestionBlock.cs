using System;
using Godot;

namespace SuperMario;

public partial class QuestionBlock : StaticBody2D, IBumpable, IScoreEventSource
{
    public event Action<int> ScoreEarned;

    [Export] public Bumpable Bumpable;
    [Export] public ColorRect Visual;
    [Export] public Color UsedColor = new Color(0.55f, 0.35f, 0.10f);

    private bool _used;

    public void OnBumped(PlayerController player)
    {
        if (_used) return;
        _used = true;
        Visual.Color = UsedColor;
        ScoreEarned?.Invoke(Constants.CoinValue);
        Bumpable.Bump();
    }
}
