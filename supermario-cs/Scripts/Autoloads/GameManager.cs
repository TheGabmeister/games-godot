using Godot;

namespace SuperMario;

public partial class GameManager : Node
{
    public static GameManager Instance { get; private set; }

    public GameState State => _session?.State;
    public LevelBase CurrentLevel => _session?.CurrentLevel;

    private PackedScene _mainMenuScene;
    private PackedScene _gameOverScene;
    private GameSession _session;
    private Node _levelRoot;
    private Node _currentChild;

    public override void _Ready()
    {
        Instance = this;
        _levelRoot = new Node { Name = "LevelRoot" };
        AddChild(_levelRoot);

        if (ResourceLoader.Exists(Config.MainMenuScenePath))
            _mainMenuScene = GD.Load<PackedScene>(Config.MainMenuScenePath);
        if (ResourceLoader.Exists(Config.GameOverScenePath))
            _gameOverScene = GD.Load<PackedScene>(Config.GameOverScenePath);

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
        _session = new GameSession { Name = "GameSession" };
        _session.SessionEnded += LoadGameOver;
        SwapChild(_session);
        if (!_session.Start())
            LoadMainMenu();
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
