using System;
using Godot;

namespace SMB;

[Meta(typeof(IAutoNode))]
public partial class GameMode : Node,
    IScoreAwarder,
    ICoinCollector,
    IProvide<GameMode>,
    IProvide<GameRules>,
    IProvide<TextSpawner>,
    IProvide<IScoreAwarder>,
    IProvide<ICoinCollector>
{
    public event Action SessionEnded;
    public event Action OneUpAwarded;
    public event Action<int> ScoreChanged;
    public event Action<int> CoinsChanged;
    public event Action<int> LivesChanged;
    public event Action<string> LevelChanged;
    public event Action<float> TimeRemainingChanged;

    private const float DeathPauseSeconds = 1.5f;

    public SaveData SaveData { get; } = new();
    public GameRules Rules { get; private set; }
    public LevelScope CurrentLevel { get; private set; }
    public PlayerController CurrentPlayer => _currentPlayer;
    public TextSpawner TextSpawner { get; private set; }
    public int Score { get; private set; }
    public int Coins { get; private set; }
    public int Lives { get; private set; }
    public PlayerPowerState PowerState { get; private set; } = PlayerPowerState.Small;
    public string CurrentLevelName { get; private set; } = "";
    public float TimeRemaining { get; private set; }

    [Dependency] public MusicManager Music => this.DependOn<MusicManager>();
    [Dependency] public SfxManager Sfx => this.DependOn<SfxManager>();

    private Campaign _campaign;
    private int _currentLevelIndex;
    private Hud _hud;
    private PackedScene _playerScene;
    private PackedScene _fireballScene;
    private PlayerController _currentPlayer;

    public override void _Notification(int what) => this.Notify(what);

    GameMode IProvide<GameMode>.Value() => this;
    GameRules IProvide<GameRules>.Value() => Rules;
    TextSpawner IProvide<TextSpawner>.Value() => TextSpawner;
    IScoreAwarder IProvide<IScoreAwarder>.Value() => this;
    ICoinCollector IProvide<ICoinCollector>.Value() => this;

    public void Start(int startLevelIndex = 0)
    {
        _campaign = GD.Load<Campaign>(Config.CampaignPath);
        Rules = GD.Load<GameRules>(Config.GameRulesPath);
        _playerScene = GD.Load<PackedScene>(Config.PlayerScenePath);
        _fireballScene = GD.Load<PackedScene>(Config.FireballScenePath);
        _currentLevelIndex = startLevelIndex;
        Lives = Rules.StartingLives;

        OneUpAwarded += OnOneUpAwarded;

        var hudScene = GD.Load<PackedScene>(Config.HudScenePath);
        _hud = hudScene.Instantiate<Hud>();
        AddChild(_hud);

        TextSpawner = new TextSpawner { Name = "TextSpawner" };
        AddChild(TextSpawner);

        LoadCurrentLevel();
        this.Provide();
    }

    public void SaveGame()
    {
        SaveData.Score = Score;
        SaveData.Coins = Coins;
        SaveData.Lives = Lives;
        SaveData.PowerState = PowerState;
        SaveData.CurrentLevelName = CurrentLevelName;
        SaveData.TimeRemaining = TimeRemaining;
    }

    public void EmitOneUpAwarded() => OneUpAwarded?.Invoke();

    public void AwardScore(int points)
    {
        AddScore(points);
    }

    public void CollectCoins(int coins)
    {
        AddCoins(coins);
    }

    private void OnOneUpAwarded()
    {
        SetLives(Lives + 1);
    }

    private void OnPlayerPowerStateChanged(PlayerPowerState newState)
    {
        PowerState = newState;
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
            Music.Play(def.MusicTrack);

        var level = def.LevelScene.Instantiate<LevelScope>();
        SwapLevel(level);
        level.GoalTrigger.Reached += OnLevelCompleted;

        var player = _playerScene.Instantiate<PlayerController>();
        player.Initialize(PowerState);
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
        if (TimeRemaining <= 0f) return;

        SetTimeRemaining(TimeRemaining - (float)delta);
        if (TimeRemaining <= 0f)
            _currentPlayer.KillPlayer();
    }

    private void OnLevelCompleted()
    {
        Sfx.PlayFlagpole();
        Sfx.PlayStageClear();
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
        PowerState = PlayerPowerState.Small;
        SetLives(Lives - 1);

        var timer = GetTree().CreateTimer(DeathPauseSeconds);
        timer.Timeout += () =>
        {
            if (!IsInsideTree()) return;
            if (Lives <= 0)
                SessionEnded?.Invoke();
            else
                LoadCurrentLevel();
        };
    }

    private void AddScore(int points)
    {
        Score += points;
        ScoreChanged?.Invoke(Score);
    }

    private void AddCoins(int coins)
    {
        Coins += coins;
        if (Coins >= Rules.CoinsPerLife)
        {
            var livesEarned = Coins / Rules.CoinsPerLife;
            Coins %= Rules.CoinsPerLife;
            SetLives(Lives + livesEarned);
        }

        CoinsChanged?.Invoke(Coins);
    }

    private void SetLives(int lives)
    {
        Lives = lives;
        LivesChanged?.Invoke(Lives);
    }

    private void SetLevel(string name, float timeLimit)
    {
        CurrentLevelName = name;
        LevelChanged?.Invoke(CurrentLevelName);
        SetTimeRemaining(timeLimit);
    }

    private void SetTimeRemaining(float seconds)
    {
        TimeRemaining = seconds < 0f ? 0f : seconds;
        TimeRemainingChanged?.Invoke(TimeRemaining);
    }

    private void SwapLevel(LevelScope next)
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
