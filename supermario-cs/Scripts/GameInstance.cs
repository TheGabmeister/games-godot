using Godot;

namespace SMB;

public partial class GameInstance : Node
{
    public MusicManager Music { get; private set; }
    public SfxManager Sfx { get; private set; }
    public GameMode CurrentSession => _session;
    public Node LevelRoot => _levelRoot;

    private PackedScene _mainMenuScene;
    private PackedScene _gameOverScene;
    private GameMode _session;
    private Node _levelRoot;
    private Node _currentChild;

    public override void _Ready()
    {
        Music = new MusicManager { Name = "MusicManager" };
        AddChild(Music);

        Sfx = new SfxManager { Name = "SfxManager" };
        AddChild(Sfx);

        _levelRoot = new Node { Name = "LevelRoot" };
        AddChild(_levelRoot);

        _mainMenuScene = GD.Load<PackedScene>(Config.MainMenuScenePath);
        _gameOverScene = GD.Load<PackedScene>(Config.GameOverScenePath);

        CallDeferred(MethodName.PostBoot);
    }

    private void PostBoot()
    {
        var current = GetTree().CurrentScene;

        if (current == null || current.SceneFilePath == Config.BootScenePath)
        {
            LoadMainMenu();
            return;
        }

        if (OS.HasFeature("editor") && current is LevelManager level)
        {
            var index = LookupCampaignIndex(level.SceneFilePath);
            if (index >= 0)
            {
                GetTree().UnloadCurrentScene();
                StartGame(index);
                return;
            }
            GD.PushWarning($"GameInstance: F6'd level '{level.SceneFilePath}' is not in the campaign; leaving scene as-is.");
            return;
        }

        // Sandbox scene - services are available, no session is started.
    }

    private static int LookupCampaignIndex(string scenePath)
    {
        var campaign = GD.Load<Campaign>(Config.CampaignPath);
        for (int i = 0; i < campaign.Levels.Length; i++)
        {
            if (campaign.Levels[i].LevelScene?.ResourcePath == scenePath)
                return i;
        }
        return -1;
    }

    public void LoadMainMenu()
    {
        var menu = _mainMenuScene.Instantiate<MainMenuController>();
        menu.StartPressed += OnStartPressed;
        SetActiveNode(menu);
    }

    private void OnStartPressed() => StartGame();

    public void StartGame(int startLevelIndex = 0)
    {
        _session = new GameMode(Sfx, Music) { Name = "GameMode" };
        _session.SessionEnded += LoadGameOver;
        SetActiveNode(_session);
        _session.Start(startLevelIndex);
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
