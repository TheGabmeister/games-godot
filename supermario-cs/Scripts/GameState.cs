using System;

namespace SuperMario;

public class GameState
{
    public int Score { get; private set; }
    public int Lives { get; set; } = Constants.StartingLives;
    public PlayerPowerState PowerState { get; set; } = PlayerPowerState.Small;
    public string CurrentLevelName { get; private set; } = "";
    public float CurrentLevelTimeLimit { get; private set; }

    public event Action<int> ScoreChanged = delegate { };
    public event Action<int> LivesChanged = delegate { };
    public event Action<string, float> LevelChanged = delegate { };

    public void AddScore(int points)
    {
        Score += points;
        ScoreChanged(Score);
    }

    public void SetLives(int lives)
    {
        Lives = lives;
        LivesChanged(Lives);
    }

    public void SetLevel(string name, float timeLimit)
    {
        CurrentLevelName = name;
        CurrentLevelTimeLimit = timeLimit;
        LevelChanged(CurrentLevelName, CurrentLevelTimeLimit);
    }
}
