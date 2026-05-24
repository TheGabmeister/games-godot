using Godot;

namespace SuperMario;

public partial class Hud : CanvasLayer
{
    [Export] public Label ScoreLabel;
    [Export] public Label WorldLabel;
    [Export] public Label TimeLabel;
    [Export] public Label LivesLabel;

    private GameState _gameState;

    public void Bind(GameState state)
    {
        _gameState = state;
        state.ScoreChanged += OnScoreChanged;
        state.LivesChanged += OnLivesChanged;
        state.LevelChanged += OnLevelChanged;
        state.TimeRemainingChanged += OnTimeRemainingChanged;

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
        _gameState.TimeRemainingChanged -= OnTimeRemainingChanged;
        _gameState = null;
    }

    private void RefreshLabels()
    {
        WorldLabel.Text = _gameState.CurrentLevelName;
        OnScoreChanged(_gameState.Score);
        OnLivesChanged(_gameState.Lives);
        OnTimeRemainingChanged(_gameState.TimeRemaining);
    }

    private void OnScoreChanged(int score)
    {
        ScoreLabel.Text = score.ToString("D6");
    }

    private void OnLivesChanged(int lives)
    {
        LivesLabel.Text = "x " + lives;
    }

    private void OnLevelChanged(string name)
    {
        WorldLabel.Text = name;
    }

    private void OnTimeRemainingChanged(float seconds)
    {
        TimeLabel.Text = ((int)seconds).ToString();
    }
}
