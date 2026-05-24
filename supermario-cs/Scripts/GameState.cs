using System;

namespace SuperMario;

public class GameState
{
    public int Score { get; private set; }
    public int Lives { get; set; } = Constants.StartingLives;
    public PlayerPowerState PowerState { get; set; } = PlayerPowerState.Small;
    public string CurrentLevelName { get; private set; } = "";
    public float TimeRemaining { get; private set; }

    public event Action<int> ScoreChanged;
    public event Action<int> LivesChanged;
    public event Action<string> LevelChanged;
    public event Action<float> TimeRemainingChanged;

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

    public void SetLevel(string name, float timeLimit)
    {
        CurrentLevelName = name;
        LevelChanged?.Invoke(CurrentLevelName);
        SetTimeRemaining(timeLimit);
    }

    public void SetTimeRemaining(float seconds)
    {
        TimeRemaining = seconds < 0f ? 0f : seconds;
        TimeRemainingChanged?.Invoke(TimeRemaining);
    }
}
