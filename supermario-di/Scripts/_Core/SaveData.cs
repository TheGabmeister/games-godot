using Godot;

namespace SMB;

public partial class SaveData : Resource
{
    [Export] public int Score { get; set; }
    [Export] public int Coins { get; set; }
    [Export] public int Lives { get; set; }
    [Export] public PlayerPowerState PowerState { get; set; } = PlayerPowerState.Small;
    [Export] public string CurrentLevelName { get; set; } = "";
    [Export] public float TimeRemaining { get; set; }
}
