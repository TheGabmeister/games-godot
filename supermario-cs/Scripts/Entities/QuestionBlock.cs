using Godot;
using supermariocs.Autoloads;
using supermariocs.Components;
using supermariocs.Interfaces;
using supermariocs.Player;

namespace supermariocs.Entities;

public partial class QuestionBlock : StaticBody2D, IBumpable
{
    [Export] public Bumpable Bumpable;
    [Export] public ColorRect Visual;
    [Export] public Color UsedColor = new Color(0.55f, 0.35f, 0.10f);

    private bool _used;

    public void OnBumped(PlayerController player)
    {
        if (_used) return;
        _used = true;
        if (Visual != null) Visual.Color = UsedColor;
        GameManager.Instance?.State?.AddScore(Constants.CoinValue);
        Bumpable?.Bump();
    }
}
