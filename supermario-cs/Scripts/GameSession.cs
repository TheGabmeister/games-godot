using Godot;

namespace SuperMario;

public partial class GameSession : Node
{
    [Signal] public delegate void SessionEndedEventHandler();

    private const float DeathPauseSeconds = 1.5f;

    public GameState State { get; } = new();
    public LevelBase CurrentLevel { get; private set; }

    private Campaign _campaign;
    private int _currentLevelIndex;

    public void Start(Campaign campaign)
    {
        _campaign = campaign;
        _currentLevelIndex = 0;

        if (_campaign?.Levels == null || _campaign.Levels.Length == 0)
        {
            GD.PushError("Campaign has no levels.");
            EmitSignal(SignalName.SessionEnded);
            return;
        }

        LoadCurrentLevel();
    }

    private void LoadCurrentLevel()
    {
        var def = GetCurrentLevelDefinition();
        if (def == null || def.LevelScene == null)
        {
            GD.PushError("LevelDefinition missing LevelScene.");
            EmitSignal(SignalName.SessionEnded);
            return;
        }

        State.SetLevel(def.Name, def.TimeLimit);

        var level = def.LevelScene.Instantiate<LevelBase>();
        level.Initialize(def, State);
        level.LevelCompleted += OnLevelCompleted;
        level.PlayerDied += OnPlayerDied;
        SwapLevel(level);
    }

    private LevelDefinition GetCurrentLevelDefinition()
    {
        if (_campaign?.Levels == null) return null;
        if (_currentLevelIndex < 0 || _currentLevelIndex >= _campaign.Levels.Length) return null;
        return _campaign.Levels[_currentLevelIndex];
    }

    private void OnLevelCompleted()
    {
        _currentLevelIndex++;
        if (_campaign?.Levels == null || _currentLevelIndex >= _campaign.Levels.Length)
        {
            EmitSignal(SignalName.SessionEnded);
            return;
        }

        LoadCurrentLevel();
    }

    private void OnPlayerDied()
    {
        State.PowerState = PlayerPowerState.Small;
        State.SetLives(State.Lives - 1);

        var timer = GetTree().CreateTimer(DeathPauseSeconds);
        timer.Timeout += () =>
        {
            if (!IsInsideTree()) return;
            if (State.Lives <= 0)
                EmitSignal(SignalName.SessionEnded);
            else
                LoadCurrentLevel();
        };
    }

    private void SwapLevel(LevelBase next)
    {
        if (CurrentLevel != null)
        {
            CurrentLevel.QueueFree();
            CurrentLevel = null;
        }

        if (next != null)
        {
            AddChild(next);
            CurrentLevel = next;
        }
    }
}
