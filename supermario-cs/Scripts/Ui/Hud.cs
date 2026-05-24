using Godot;

namespace SuperMario;

public partial class Hud : CanvasLayer
{
    private Label _scoreLabel;
    private Label _worldLabel;
    private Label _timeLabel;
    private Label _livesLabel;

    private float _timeRemaining;
    private bool _timedOut;
    private GameState _boundState;

    public override void _Ready()
    {
        _scoreLabel = GetNode<Label>("Root/Top/Score/Value");
        _worldLabel = GetNode<Label>("Root/Top/World/Value");
        _timeLabel = GetNode<Label>("Root/Top/Time/Value");
        _livesLabel = GetNode<Label>("Root/Top/Lives/Value");

        RefreshLabels();
    }

    public void Bind(GameState state)
    {
        _boundState = state;
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
        _boundState.ScoreChanged -= OnScoreChanged;
        _boundState.LivesChanged -= OnLivesChanged;
        _boundState.LevelChanged -= OnLevelChanged;
        _boundState = null;
    }

    private void RefreshLabels()
    {
        _worldLabel.Text = _boundState.CurrentLevelName;
        _timeLabel.Text = ((int)_timeRemaining).ToString();
        OnScoreChanged(_boundState.Score);
        OnLivesChanged(_boundState.Lives);
    }

    public override void _Process(double delta)
    {
        if (_timedOut) return;
        _timeRemaining = Mathf.Max(0f, _timeRemaining - (float)delta);
        _timeLabel.Text = ((int)_timeRemaining).ToString();
        if (_timeRemaining <= 0f)
        {
            _timedOut = true;
            var player = GetTree().GetFirstNodeInGroup("player");
            ((PlayerController)player).KillPlayer();
        }
    }

    private void OnScoreChanged(int score)
    {
        _scoreLabel.Text = score.ToString("D6");
    }

    private void OnLivesChanged(int lives)
    {
        _livesLabel.Text = "x " + lives;
    }

    private void OnLevelChanged(string name, float timeLimit)
    {
        _timeRemaining = timeLimit;
        _timedOut = false;
        _worldLabel.Text = name;
        _timeLabel.Text = ((int)_timeRemaining).ToString();
    }
}
