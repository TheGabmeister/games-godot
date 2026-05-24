using System;
using supermariocs.Player;

namespace supermariocs;

public class GameState
{
    public int Score { get; private set; }
    public int Lives { get; set; } = Constants.StartingLives;
    public PlayerPowerState PowerState { get; set; } = PlayerPowerState.Small;

    public event Action<int> ScoreChanged;
    public event Action<int> LivesChanged;

    public void AddScore(int points)
    {
        Score += points;
        ScoreChanged?.Invoke(Score);
    }

    public void SetLives(int lives)
    {
        Lives = lives;
        LivesChanged?.Invoke(Lives);
    }
}
