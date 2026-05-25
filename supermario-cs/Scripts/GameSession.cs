using System;
using Godot;

namespace SuperMario;

public partial class GameSession : Node
{
    public static GameSession Instance { get; private set; }

    public event Action SessionEnded;
    public event Action OneUpAwarded;

    private const float DeathPauseSeconds = 1.5f;

    public GameState State { get; } = new();
    public LevelBase CurrentLevel { get; private set; }

    private Campaign _campaign;
    private int _currentLevelIndex;
    private Hud _hud;
    private PackedScene _playerScene;
    private PackedScene _fireballScene;
    private PlayerController _currentPlayer;

    public override void _EnterTree()
    {
        Instance = this;
    }

    public override void _ExitTree()
    {
        if (Instance == this) Instance = null;
    }

    public void Start()
    {
        _campaign = GD.Load<Campaign>(Config.CampaignPath);
        _playerScene = GD.Load<PackedScene>(Config.PlayerScenePath);
        _fireballScene = GD.Load<PackedScene>(Config.FireballScenePath);
        _currentLevelIndex = 0;

        OneUpAwarded += OnOneUpAwarded;

        var hudScene = GD.Load<PackedScene>(Config.HudScenePath);
        _hud = hudScene.Instantiate<Hud>();
        AddChild(_hud);
        _hud.Bind(State);

        LoadCurrentLevel();
    }

    public void EmitOneUpAwarded() => OneUpAwarded?.Invoke();

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

    private void OnTextPopupRequested(string text, Vector2 worldPosition)
    {
        TextPopupSpawner.Spawn(CurrentLevel, text, worldPosition);
    }

    private void OnFireballRequested(Vector2 position, int facing, PlayerController owner)
    {
        var fireball = _fireballScene.Instantiate<Fireball>();
        fireball.Init(position, facing, owner);
        CurrentLevel.AddChild(fireball);
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
        level.ScoreEarned += OnScoreEarned;
        level.TextPopupRequested += OnTextPopupRequested;

        var player = _playerScene.Instantiate<PlayerController>();
        player.Initialize(State.PowerState);
        player.GlobalPosition = level.PlayerStart.GlobalPosition;
        level.AddChild(player);
        player.Died += OnPlayerDied;
        player.PowerStateChanged += OnPlayerPowerStateChanged;
        player.FireballRequested += OnFireballRequested;
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
