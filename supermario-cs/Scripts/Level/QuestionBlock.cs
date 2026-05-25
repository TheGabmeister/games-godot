using Godot;

namespace SuperMario;

public partial class QuestionBlock : StaticBody2D, IBumpable
{
    [Export] public Bumpable Bumpable;
    [Export] public ColorRect Visual;
    [Export] public Color UsedColor = new Color(0.55f, 0.35f, 0.10f);

    private GameEvents _events;
    private bool _used;

    public static QuestionBlock Create(Vector2 globalPosition, GameEvents events)
    {
        var scene = GD.Load<PackedScene>(Config.QuestionBlockScenePath);
        var qb = scene.Instantiate<QuestionBlock>();
        qb.GlobalPosition = globalPosition;
        qb._events = events;
        return qb;
    }

    public void OnBumped(PlayerController player)
    {
        if (_used) return;
        _used = true;
        Visual.Color = UsedColor;
        _events.EmitScoreEarned(Constants.CoinValue);
        _events.EmitCoinsCollected(1);
        Bumpable.Bump();
    }
}
