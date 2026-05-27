using Godot;

namespace SMB;

public partial class QuestionBlock : StaticBody2D, IBumpable
{
    [Export] public Bumpable Bumpable;
    [Export] public ColorRect Visual;
    [Export] public Color UsedColor = new Color(0.55f, 0.35f, 0.10f);

    private bool _used;

    public override void _Ready()
    {
    }

    public void OnBumped(PlayerController player)
    {
        if (_used) return;
        _used = true;
        Visual.Color = UsedColor;
        Bus<EV_ScoreEarned>.Emit(new EV_ScoreEarned { value = Constants.CoinValue });
        Bus<EV_Pickup_Coin>.Emit(new EV_Pickup_Coin { value = 1 });
        Bumpable.Bump();
    }
}
