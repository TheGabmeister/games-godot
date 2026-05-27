using System;
using Godot;

namespace SMB;

public partial class QuestionBlock : StaticBody2D, IBumpable
{
    [Export] public Bumpable Bumpable;
    [Export] public ColorRect Visual;
    [Export] public Color UsedColor = new Color(0.55f, 0.35f, 0.10f);

    public event Action<int> ScoreEarned;
    public event Action<int> CoinsCollected;

    private bool _used;

    public static QuestionBlock Create(Vector2 globalPosition)
    {
        var scene = GD.Load<PackedScene>(Config.QuestionBlockScenePath);
        var qb = scene.Instantiate<QuestionBlock>();
        qb.GlobalPosition = globalPosition;
        return qb;
    }

    public void OnBumped(PlayerController player)
    {
        if (_used) return;
        _used = true;
        Visual.Color = UsedColor;
        ScoreEarned?.Invoke(Constants.CoinValue);
        CoinsCollected?.Invoke(1);
        Bumpable.Bump();
    }
}
