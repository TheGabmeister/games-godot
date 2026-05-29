using System;
using Godot;

namespace SMB;

[Meta(typeof(IAutoNode))]
public partial class GameMode : Node,
    IScoreAwarder,
    ICoinCollector,
    IProvide<GameMode>,
    IProvide<GameRules>,
    IProvide<SaveData>,
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
    SaveData IProvide<SaveData>.Value() => SaveData;
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
        SaveData.Lives = Rules.StartingLives;

        OneUpAwarded += OnOneUpAwarded;

        var hudScene = GD.Load<PackedScene>(Config.HudScenePath);
        _hud = hudScene.Instantiate<Hud>();
        AddChild(_hud);

        TextSpawner = new TextSpawner { Name = "TextSpawner" };
        AddChild(TextSpawner);

        LoadCurrentLevel();
        this.Provide();
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
            Music.Play(def.MusicTrack);

        var level = def.LevelScene.Instantiate<LevelScope>();
        SwapLevel(level);
        SpawnLevelObjects(level);
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

    private void SpawnLevelObjects(LevelScope level)
    {
        foreach (var marker in level.Markers)
        {
            switch (marker)
            {
                case CoinMarker m:
                    level.AddChild(Coin.Create(m.GlobalPosition));
                    break;
                case QuestionBlockMarker m:
                    level.AddChild(QuestionBlock.Create(m.GlobalPosition));
                    break;
                case BrickBlockMarker m:
                    level.AddChild(BrickBlock.Create(m.GlobalPosition));
                    break;
                case MushroomMarker m:
                    level.AddChild(Mushroom.Create(m.GlobalPosition));
                    break;
                case StarmanMarker m:
                    level.AddChild(Starman.Create(m.GlobalPosition));
                    break;
                case FireFlowerMarker m:
                    level.AddChild(FireFlower.Create(m.GlobalPosition));
                    break;
            }
        }
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
        if (SaveData.Coins >= Rules.CoinsPerLife)
        {
            var livesEarned = SaveData.Coins / Rules.CoinsPerLife;
            SaveData.Coins %= Rules.CoinsPerLife;
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
