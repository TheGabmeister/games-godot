using Godot;

namespace SMB;

public partial class SaveData : Resource
{
    private const int StartingLives = 3;

    [Export] public int Score { get; set; }
    [Export] public int Coins { get; set; }
    [Export] public int Lives { get; set; } = StartingLives;
    [Export] public PlayerPowerState PowerState { get; set; } = PlayerPowerState.Small;
    [Export] public string CurrentLevelName { get; set; } = "";
    [Export] public float TimeRemaining { get; set; }
}
