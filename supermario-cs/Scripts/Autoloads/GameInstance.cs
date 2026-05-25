using Godot;

namespace SuperMario;

public partial class GameInstance : Node
{
    public static GameInstance Instance { get; private set; }

    private PackedScene _mainMenuScene;
    private PackedScene _gameOverScene;
    private GameMode _session;
    private Node _levelRoot;
    private Node _currentChild;

    public override void _Ready()
    {
        Instance = this;
        _levelRoot = new Node { Name = "LevelRoot" };
        AddChild(_levelRoot);

        _mainMenuScene = GD.Load<PackedScene>(Config.MainMenuScenePath);
        _gameOverScene = GD.Load<PackedScene>(Config.GameOverScenePath);

        LoadMainMenu();
    }

    public void LoadMainMenu()
    {
        var menu = _mainMenuScene.Instantiate<MainMenuController>();
        menu.StartPressed += OnStartPressed;
        SetActiveNode(menu);
    }

    private void OnStartPressed() => StartGame();

    public void StartGame()
    {
        _session = new GameMode { Name = "GameMode" };
        _session.SessionEnded += LoadGameOver;
        SetActiveNode(_session);
        _session.Start();
    }

    private void LoadGameOver()
    {
        var over = _gameOverScene.Instantiate<GameOverController>();
        over.Continue += LoadMainMenu;
        SetActiveNode(over);
        _session = null;
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
        _levelRoot.AddChild(next);
        _currentChild = next;
    }
}
