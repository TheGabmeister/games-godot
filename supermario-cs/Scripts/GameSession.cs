using System;
using Godot;

namespace SuperMario;

public partial class GameSession : Node
{
    public static GameSession Current { get; private set; }

    public event Action SessionEnded;
    public event Action<int> ScoreEarned;
    public event Action OneUpAwarded;
    public event Action<PlayerPowerState> PlayerPowerStateChanged;

    private const float DeathPauseSeconds = 1.5f;

    public GameState State { get; } = new();
    public LevelBase CurrentLevel { get; private set; }

    private Campaign _campaign;
    private int _currentLevelIndex;
    private Hud _hud;
    private PackedScene _playerScene;
    private PlayerController _currentPlayer;

    public override void _EnterTree()
    {
        Current = this;
    }

    public override void _ExitTree()
    {
        if (Current == this) Current = null;
    }

    public void Start()
    {
        _campaign = GD.Load<Campaign>(Config.CampaignPath);
        _playerScene = GD.Load<PackedScene>(Config.PlayerScenePath);
        _currentLevelIndex = 0;

        ScoreEarned += OnScoreEarned;
        OneUpAwarded += OnOneUpAwarded;
        PlayerPowerStateChanged += OnPlayerPowerStateChanged;

        var hudScene = GD.Load<PackedScene>(Config.HudScenePath);
        _hud = hudScene.Instantiate<Hud>();
        AddChild(_hud);
        _hud.Bind(State);

        LoadCurrentLevel();
    }

    public void EmitScoreEarned(int points) => ScoreEarned?.Invoke(points);
    public void EmitOneUpAwarded() => OneUpAwarded?.Invoke();
    public void EmitPlayerPowerStateChanged(PlayerPowerState state) => PlayerPowerStateChanged?.Invoke(state);

    private void OnScoreEarned(int points)
    {
        State.AddScore(points);
    }

    private void OnOneUpAwarded()
    {
        State.SetLives(State.Lives + 1);
    }

    private void OnPlayerPowerStateChanged(PlayerPowerState newState)
    {
        State.PowerState = newState;
    }

    private void LoadCurrentLevel()
    {
        var def = _campaign.Levels[_currentLevelIndex];
        State.SetLevel(def.Name, def.TimeLimit);

        if (def.MusicTrack != null)
            MusicManager.Instance?.Play(def.MusicTrack);

        var level = def.LevelScene.Instantiate<LevelBase>();
        
        SwapLevel(level);
        level.GoalTrigger.Reached += OnLevelCompleted;

        var player = _playerScene.Instantiate<PlayerController>();
        player.GlobalPosition = level.PlayerStart.GlobalPosition;
        level.AddChild(player);
        player.Died += OnPlayerDied;
        _currentPlayer = player;
    }

    public override void _Process(double delta)
    {
        if (_currentPlayer == null) return;
        if (State.TimeRemaining <= 0f) return;

        State.SetTimeRemaining(State.TimeRemaining - (float)delta);
        if (State.TimeRemaining <= 0f)
            _currentPlayer.KillPlayer();
    }

    private void OnLevelCompleted()
    {
        _currentLevelIndex++;
        if (_currentLevelIndex >= _campaign.Levels.Length)
        {
            SessionEnded?.Invoke();
            return;
        }

        LoadCurrentLevel();
    }

    private void OnPlayerDied()
    {
        _currentPlayer = null;
        State.PowerState = PlayerPowerState.Small;
        State.SetLives(State.Lives - 1);

        var timer = GetTree().CreateTimer(DeathPauseSeconds);
        timer.Timeout += () =>
        {
            if (!IsInsideTree()) return;
            if (State.Lives <= 0)
                SessionEnded?.Invoke();
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
