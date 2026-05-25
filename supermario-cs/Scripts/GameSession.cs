using System;
using Godot;

namespace SuperMario;

public partial class GameSession : Node
{
    public static GameSession Instance { get; private set; }

    public event Action SessionEnded;
    public event Action OneUpAwarded;
    public event Action<int> ScoreChanged;
    public event Action<int> CoinsChanged;
    public event Action<int> LivesChanged;
    public event Action<string> LevelChanged;
    public event Action<float> TimeRemainingChanged;

    private const float DeathPauseSeconds = 1.5f;

    public SaveData SaveData { get; } = new();
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
        _hud.Bind(this);

        AddChild(new TextPopupSpawner());

        LoadCurrentLevel();
    }

    public void EmitOneUpAwarded() => OneUpAwarded?.Invoke();

    private void OnScoreEarned(int points)
    {
        AddScore(points);
    }

    private void OnCoinCollected(int coins)
    {
        AddCoins(coins);
    }

    private void OnOneUpAwarded()
    {
        SetLives(SaveData.Lives + 1);
    }

    private void OnPlayerPowerStateChanged(PlayerPowerState newState)
    {
        SaveData.PowerState = newState;
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
        SetLevel(def.Name, def.TimeLimit);

        if (def.MusicTrack != null)
            MusicManager.Instance?.Play(def.MusicTrack);

        var level = def.LevelScene.Instantiate<LevelBase>();
        
        SwapLevel(level);
        level.GoalTrigger.Reached += OnLevelCompleted;
        level.ScoreEarned += OnScoreEarned;
        level.CoinsCollected += OnCoinCollected;

        var player = _playerScene.Instantiate<PlayerController>();
        player.Initialize(SaveData.PowerState);
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
        if (SaveData.TimeRemaining <= 0f) return;

        SetTimeRemaining(SaveData.TimeRemaining - (float)delta);
        if (SaveData.TimeRemaining <= 0f)
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
        SaveData.PowerState = PlayerPowerState.Small;
        SetLives(SaveData.Lives - 1);

        var timer = GetTree().CreateTimer(DeathPauseSeconds);
        timer.Timeout += () =>
        {
            if (!IsInsideTree()) return;
            if (SaveData.Lives <= 0)
                SessionEnded?.Invoke();
            else
                LoadCurrentLevel();
        };
    }

    private void AddScore(int points)
    {
        SaveData.Score += points;
        ScoreChanged?.Invoke(SaveData.Score);
    }

    private void AddCoins(int coins)
    {
        SaveData.Coins += coins;
        if (SaveData.Coins >= Constants.CoinsPerLife)
        {
            var livesEarned = SaveData.Coins / Constants.CoinsPerLife;
            SaveData.Coins %= Constants.CoinsPerLife;
            SetLives(SaveData.Lives + livesEarned);
        }

        CoinsChanged?.Invoke(SaveData.Coins);
    }

    private void SetLives(int lives)
    {
        SaveData.Lives = lives;
        LivesChanged?.Invoke(SaveData.Lives);
    }

    private void SetLevel(string name, float timeLimit)
    {
        SaveData.CurrentLevelName = name;
        LevelChanged?.Invoke(SaveData.CurrentLevelName);
        SetTimeRemaining(timeLimit);
    }

    private void SetTimeRemaining(float seconds)
    {
        SaveData.TimeRemaining = seconds < 0f ? 0f : seconds;
        TimeRemainingChanged?.Invoke(SaveData.TimeRemaining);
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
