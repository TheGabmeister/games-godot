using Godot;

namespace SuperMario;

public partial class Hud : CanvasLayer
{
    [Export] public Label ScoreLabel;
    [Export] public Label WorldLabel;
    [Export] public Label TimeLabel;
    [Export] public Label LivesLabel;

    private float _timeRemaining;
    private bool _timedOut;
    private GameState _gameState;

    public void Bind(GameState state)
    {
        _gameState = state;
        state.ScoreChanged += OnScoreChanged;
        state.LivesChanged += OnLivesChanged;
        state.LevelChanged += OnLevelChanged;
        _timeRemaining = state.CurrentLevelTimeLimit;

        RefreshLabels();
    }

    public override void _ExitTree()
    {
        UnbindState();
    }

    private void UnbindState()
    {
        if (_gameState == null) return;

        _gameState.ScoreChanged -= OnScoreChanged;
        _gameState.LivesChanged -= OnLivesChanged;
        _gameState.LevelChanged -= OnLevelChanged;
        _gameState = null;
    }

    private void RefreshLabels()
    {
        WorldLabel.Text = _gameState.CurrentLevelName;
        TimeLabel.Text = ((int)_timeRemaining).ToString();
        OnScoreChanged(_gameState.Score);
        OnLivesChanged(_gameState.Lives);
    }

    public override void _Process(double delta)
    {
        if (_gameState == null) return;
        if (_timedOut) return;

        _timeRemaining = Mathf.Max(0f, _timeRemaining - (float)delta);
        TimeLabel.Text = ((int)_timeRemaining).ToString();
        if (_timeRemaining <= 0f)
        {
            _timedOut = true;
            var player = GetTree().GetFirstNodeInGroup("player");
            ((PlayerController)player).KillPlayer();
        }
    }

    private void OnScoreChanged(int score)
    {
        ScoreLabel.Text = score.ToString("D6");
    }

    private void OnLivesChanged(int lives)
    {
        LivesLabel.Text = "x " + lives;
    }

    private void OnLevelChanged(string name, float timeLimit)
    {
        _timeRemaining = timeLimit;
        _timedOut = false;
        WorldLabel.Text = name;
        TimeLabel.Text = ((int)_timeRemaining).ToString();
    }
}
