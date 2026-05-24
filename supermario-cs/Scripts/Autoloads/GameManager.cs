using Godot;
using supermariocs.Level;
using supermariocs.Player;
using supermariocs.Resources;
using supermariocs.Ui;

namespace supermariocs.Autoloads;

public partial class GameManager : Node
{
    public static GameManager Instance { get; private set; }

    public GameState State { get; private set; }
    public LevelBase CurrentLevel { get; private set; }

    private const string MainMenuPath = "res://scenes/main_menu.tscn";
    private const string GameOverPath = "res://scenes/game_over.tscn";
    private const string CampaignPath = "res://resources/campaign.tres";

    private PackedScene _mainMenuScene;
    private PackedScene _gameOverScene;
    private Campaign _campaign;
    private int _currentLevelIndex;
    private Node _levelRoot;
    private Node _currentChild;

    public override void _Ready()
    {
        Instance = this;
        _levelRoot = new Node { Name = "LevelRoot" };
        AddChild(_levelRoot);

        if (ResourceLoader.Exists(MainMenuPath))
            _mainMenuScene = GD.Load<PackedScene>(MainMenuPath);
        if (ResourceLoader.Exists(GameOverPath))
            _gameOverScene = GD.Load<PackedScene>(GameOverPath);
        if (ResourceLoader.Exists(CampaignPath))
            _campaign = GD.Load<Campaign>(CampaignPath);
        else
            GD.PushWarning($"Campaign not found at {CampaignPath}");

        LoadMainMenu();
    }

    public void LoadMainMenu()
    {
        if (_mainMenuScene == null)
        {
            GD.PushWarning("_mainMenuScene not assigned on GameManager autoload.");
            return;
        }
        var menu = _mainMenuScene.Instantiate();
        SwapChild(menu);
        if (menu is MainMenuController controller)
            controller.StartPressed += OnStartPressed;
        CurrentLevel = null;
    }

    private void OnStartPressed() => StartGame();

    public void StartGame()
    {
        State = new GameState();
        _currentLevelIndex = 0;
        if (_campaign?.Levels == null || _campaign.Levels.Length == 0)
        {
            GD.PushError("Campaign has no levels.");
            return;
        }
        LoadLevel(_campaign.Levels[0]);
    }

    public void LoadLevel(LevelDefinition def)
    {
        if (def == null || def.LevelScene == null)
        {
            GD.PushError("LevelDefinition missing LevelScene.");
            return;
        }
        var level = def.LevelScene.Instantiate<LevelBase>();
        level.Config = def;
        level.LevelCompleted += () => OnLevelCompleted(def);
        level.PlayerDied += () => OnPlayerDied(def);
        SwapChild(level);
        CurrentLevel = level;
    }

    public void OnLevelCompleted(LevelDefinition def)
    {
        _currentLevelIndex++;
        if (_campaign?.Levels == null || _currentLevelIndex >= _campaign.Levels.Length)
        {
            LoadGameOver();
            return;
        }
        LoadLevel(_campaign.Levels[_currentLevelIndex]);
    }

    private const float DeathPauseSeconds = 1.5f;

    public void OnPlayerDied(LevelDefinition def)
    {
        if (State == null) return;
        State.PowerState = PlayerPowerState.Small;
        State.SetLives(State.Lives - 1);

        var timer = GetTree().CreateTimer(DeathPauseSeconds);
        timer.Timeout += () =>
        {
            if (State == null) return;
            if (State.Lives <= 0) LoadGameOver();
            else LoadLevel(def);
        };
    }

    private void LoadGameOver()
    {
        if (_gameOverScene == null)
        {
            GD.PushWarning("_gameOverScene not assigned on GameManager autoload.");
            LoadMainMenu();
            return;
        }
        var over = _gameOverScene.Instantiate();
        SwapChild(over);
        if (over is GameOverController controller)
            controller.Continue += LoadMainMenu;
        CurrentLevel = null;
    }

    private void SwapChild(Node next)
    {
        if (_currentChild != null)
        {
            _currentChild.QueueFree();
            _currentChild = null;
        }
        if (next != null)
        {
            _levelRoot.AddChild(next);
            _currentChild = next;
        }
    }
}
