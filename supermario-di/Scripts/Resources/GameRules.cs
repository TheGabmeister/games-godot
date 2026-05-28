using Godot;

namespace SMB;

[GlobalClass]
public partial class GameRules : Godot.Resource
{
    [Export] public int StartingLives { get; set; } = 3;
    [Export] public int CoinsPerLife { get; set; } = 100;
    [Export] public int CoinScore { get; set; } = 200;
    [Export] public int BrickBreakScore { get; set; } = 50;
    [Export] public int MushroomScore { get; set; } = 1000;
    [Export] public int StarmanPickupScore { get; set; } = 1000;
}
