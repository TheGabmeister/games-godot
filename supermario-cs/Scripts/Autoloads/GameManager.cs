using Godot;

namespace SuperMario;

public partial class GameManager : Node
{
    public static GameManager Instance { get; private set; }

    public GameState State => _session?.State;
    public LevelBase CurrentLevel => _session?.CurrentLevel;

    private const string MainMenuPath = "res://scenes/main_menu.tscn";
    private const string GameOverPath = "res://scenes/game_over.tscn";
    private const string CampaignPath = "res://resources/campaign.tres";

    private PackedScene _mainMenuScene;
    private PackedScene _gameOverScene;
    private Campaign _campaign;
    private GameSession _session;
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
    }

    private void OnStartPressed() => StartGame();

    public void StartGame()
    {
        if (_campaign?.Levels == null || _campaign.Levels.Length == 0)
        {
            GD.PushError("Campaign has no levels.");
            return;
        }

        _session = new GameSession { Name = "GameSession" };
        _session.SessionEnded += LoadGameOver;
        SwapChild(_session);
        _session.Start(_campaign);
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
        _session = null;
    }

    private void SwapChild(Node next)
    {
        if (_currentChild != null)
        {
            if (_currentChild == _session)
                _session = null;
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
