using Godot;

namespace SuperMario;

public partial class SaveData : Resource
{
    [Export] public int Score { get; set; }
    [Export] public int Coins { get; set; }
    [Export] public int Lives { get; set; } = Constants.StartingLives;
    [Export] public PlayerPowerState PowerState { get; set; } = PlayerPowerState.Small;
    [Export] public string CurrentLevelName { get; set; } = "";
    [Export] public float TimeRemaining { get; set; }
}
