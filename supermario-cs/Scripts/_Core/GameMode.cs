using System;
using Godot;

namespace SMB;

public partial class GameMode : Node
{
    private const int CoinsPerLife = 100;

    public event Action SessionEnded;
    public event Action<int> ScoreChanged;
    public event Action<int> CoinsChanged;
    public event Action<int> LivesChanged;
    public event Action<string> LevelChanged;
    public event Action<float> TimeRemainingChanged;

    private const float DeathPauseSeconds = 1.5f;

    public SaveData SaveData { get; } = new();
    public LevelManager CurrentLevel { get; private set; }
    public TextSpawner TextSpawner { get; private set; }

    private Campaign _campaign;
    private int _currentLevelIndex;
    private Hud _hud;
    private PackedScene _playerScene;
    private PackedScene _fireballScene;
    private PlayerController _currentPlayer;

    public void Start(int startLevelIndex = 0)
    {
        _campaign = GD.Load<Campaign>(Config.CampaignPath);
        _playerScene = GD.Load<PackedScene>(Config.PlayerScenePath);
        _fireballScene = GD.Load<PackedScene>(Config.FireballScenePath);
        _currentLevelIndex = startLevelIndex;

        SubscribeEvents();

        var hudScene = GD.Load<PackedScene>(Config.HudScenePath);
        _hud = hudScene.Instantiate<Hud>();
        AddChild(_hud);
        _hud.Bind(this);

        TextSpawner = new TextSpawner { Name = "TextSpawner" };
        AddChild(TextSpawner);

        LoadCurrentLevel();
    }

    public override void _ExitTree()
    {
        UnsubscribeEvents();
    }

    private void SubscribeEvents()
    {
        Events.ScoreEarned += OnScoreEarned;
        Events.CoinPickedUp += OnCoinPickedUp;
        Events.MushroomPickedUp += OnMushroomPickedUp;
        Events.FireFlowerPickedUp += OnFireFlowerPickedUp;
        Events.StarmanPickedUp += OnStarmanPickedUp;
        Events.OneUpPickedUp += OnOneUpPickedUp;
    }

    private void UnsubscribeEvents()
    {
        Events.ScoreEarned -= OnScoreEarned;
        Events.CoinPickedUp -= OnCoinPickedUp;
        Events.MushroomPickedUp -= OnMushroomPickedUp;
        Events.FireFlowerPickedUp -= OnFireFlowerPickedUp;
        Events.StarmanPickedUp -= OnStarmanPickedUp;
        Events.OneUpPickedUp -= OnOneUpPickedUp;
    }

    private void OnScoreEarned(int value)
    {
        AddScore(value);
    }

    private void OnCoinPickedUp(int scoreValue, int coinValue, Vector2 position)
    {
        AddScore(scoreValue);
        AddCoins(coinValue);
        TextSpawner.SpawnText(scoreValue.ToString(), position);
    }

    private void OnMushroomPickedUp(int scoreValue, Vector2 position)
    {
        AddScore(scoreValue);
        TextSpawner.SpawnText(scoreValue.ToString(), position);
        _currentPlayer?.ApplyMushroom();
    }

    private void OnFireFlowerPickedUp(int scoreValue, Vector2 position)
    {
        AddScore(scoreValue);
        TextSpawner.SpawnText(scoreValue.ToString(), position);
        _currentPlayer?.ApplyFireFlower();
    }

    private void OnStarmanPickedUp(int scoreValue, Vector2 position)
    {
        AddScore(scoreValue);
        TextSpawner.SpawnText(scoreValue.ToString(), position);
        _currentPlayer?.ApplyStarman();
    }

    private void OnOneUpPickedUp()
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
            PlayMusic(def.MusicTrack);

        var level = def.LevelScene.Instantiate<LevelManager>();
        SwapLevel(level);
        level.GoalTrigger.Reached += OnLevelCompleted;

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
        if (SaveData.Coins >= CoinsPerLife)
        {
            var livesEarned = SaveData.Coins / CoinsPerLife;
            SaveData.Coins %= CoinsPerLife;
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

    private void SwapLevel(LevelManager next)
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
