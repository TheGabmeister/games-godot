using Godot;

namespace SMB;

[GlobalClass]
public partial class PlayerTuning : Godot.Resource
{
    [Export] public float Gravity { get; set; } = 1200f;
    [Export] public float JumpForce { get; set; } = -680f;
    [Export] public float MaxFallSpeed { get; set; } = 600f;
    [Export] public float Speed { get; set; } = 280f;
    [Export] public float StompBounceForce { get; set; } = -420f;
    [Export] public float StompTopTolerance { get; set; } = 16f;
    [Export] public float InvulnerabilityDuration { get; set; } = 2f;
    [Export] public int MaxFireballs { get; set; } = 2;
    [Export] public int SmallWidth { get; set; } = 32;
    [Export] public int SmallHeight { get; set; } = 48;
    [Export] public int BigWidth { get; set; } = 32;
    [Export] public int BigHeight { get; set; } = 64;
    [Export] public float StarmanInvincibleDuration { get; set; } = 10f;
}
