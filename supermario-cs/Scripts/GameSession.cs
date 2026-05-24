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
    private Hud _hud;

    public void Start()
    {
        _campaign = GD.Load<Campaign>(Config.CampaignPath);
        _currentLevelIndex = 0;

        var hudScene = GD.Load<PackedScene>(Config.HudScenePath);
        _hud = hudScene.Instantiate<Hud>();
        _hud.Bind(State);
        AddChild(_hud);

        LoadCurrentLevel();
    }

    private void LoadCurrentLevel()
    {
        var def = GetCurrentLevelDefinition();
        State.SetLevel(def.Name, def.TimeLimit);

        if (def.MusicTrack != null)
            MusicManager.Instance?.Play(def.MusicTrack);

        var level = def.LevelScene.Instantiate<LevelBase>();
        level.Initialize(def);
        level.LevelCompleted += OnLevelCompleted;
        level.PlayerDied += OnPlayerDied;
        SwapLevel(level);
    }

    private LevelDefinition GetCurrentLevelDefinition()
    {
        return _campaign.Levels[_currentLevelIndex];
    }

    private void OnLevelCompleted()
    {
        _currentLevelIndex++;
        if (_currentLevelIndex >= _campaign.Levels.Length)
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

        AddChild(next);
        CurrentLevel = next;
    }
}
