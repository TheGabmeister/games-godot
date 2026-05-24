using Godot;

namespace SuperMario;

public partial class GameManager : Node
{
    public static GameManager Instance { get; private set; }

    public GameMode Mode { get; private set; } = GameMode.None;
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

        SetMode(GameMode.MainMenu);
    }

    public void LoadMainMenu() => SetMode(GameMode.MainMenu);

    private void ShowMainMenu()
    {
        if (_mainMenuScene == null)
        {
            GD.PushWarning("_mainMenuScene not assigned on GameManager autoload.");
            return;
        }
        var menu = _mainMenuScene.Instantiate<MainMenuController>();
        menu.StartPressed += OnStartPressed;
        SetActiveNode(menu);
    }

    private void OnStartPressed() => StartGame();

    public void StartGame() => SetMode(GameMode.Playing);

    private void StartSession()
    {
        _session = new GameSession { Name = "GameSession" };
        _session.SessionEnded += OnSessionEnded;
        SetActiveNode(_session);
        if (!_session.Start())
            SetMode(GameMode.MainMenu);
    }

    private void OnSessionEnded() => SetMode(GameMode.GameOver);

    private void ShowGameOver()
    {
        if (_gameOverScene == null)
        {
            GD.PushWarning("_gameOverScene not assigned on GameManager autoload.");
            LoadMainMenu();
            return;
        }
        var over = _gameOverScene.Instantiate<GameOverController>();
        over.Continue += LoadMainMenu;
        SetActiveNode(over);
        _session = null;
    }

    private void SetMode(GameMode mode)
    {
        if (Mode == mode) return;

        Mode = mode;
        switch (Mode)
        {
            case GameMode.MainMenu:
                ShowMainMenu();
                break;
            case GameMode.Playing:
                StartSession();
                break;
            case GameMode.GameOver:
                ShowGameOver();
                break;
            default:
                SetActiveNode(null);
                break;
        }
    }

    private void SetActiveNode(Node next)
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
