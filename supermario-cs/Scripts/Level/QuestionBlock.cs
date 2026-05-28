using Godot;

namespace SMB;

public partial class QuestionBlock : StaticBody2D, IBumpable
{
    [Export] public Bumpable Bumpable;
    [Export] public ColorRect Visual;
    [Export] public Color UsedColor = new Color(0.55f, 0.35f, 0.10f);
    [Export] public int ScoreValue = 200;
    [Export] public int CoinValue = 1;

    private bool _used;

    public override void _Ready()
    {
    }

    public void OnBumped(PlayerController player)
    {
        if (_used) return;
        _used = true;
        Visual.Color = UsedColor;
        Events.EmitGotCoin(ScoreValue, CoinValue, GlobalPosition);
        Bumpable.Bump();
    }
}
