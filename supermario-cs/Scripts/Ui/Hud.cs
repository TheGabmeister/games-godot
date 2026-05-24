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
        _scoreLabel = GetNodeOrNull<Label>("Root/Top/Score/Value");
        _worldLabel = GetNodeOrNull<Label>("Root/Top/World/Value");
        _timeLabel = GetNodeOrNull<Label>("Root/Top/Time/Value");
        _livesLabel = GetNodeOrNull<Label>("Root/Top/Lives/Value");

        RefreshLabels();
    }

    public void Bind(GameState state)
    {
        if (state != null && state != _boundState)
        {
            UnbindState();
            _boundState = state;
            state.ScoreChanged += OnScoreChanged;
            state.LivesChanged += OnLivesChanged;
            state.LevelChanged += OnLevelChanged;
            _timeRemaining = state.CurrentLevelTimeLimit;
        }

        RefreshLabels();
    }

    public override void _ExitTree()
    {
        UnbindState();
    }

    private void UnbindState()
    {
        if (_boundState != null)
        {
            _boundState.ScoreChanged -= OnScoreChanged;
            _boundState.LivesChanged -= OnLivesChanged;
            _boundState.LevelChanged -= OnLevelChanged;
            _boundState = null;
        }
    }

    private void RefreshLabels()
    {
        if (_worldLabel != null)
            _worldLabel.Text = _boundState?.CurrentLevelName ?? "";
        if (_timeLabel != null)
            _timeLabel.Text = ((int)_timeRemaining).ToString();
        if (_boundState != null)
        {
            OnScoreChanged(_boundState.Score);
            OnLivesChanged(_boundState.Lives);
        }
    }

    public override void _Process(double delta)
    {
        if (_boundState == null) return;
        if (_timedOut) return;
        _timeRemaining = Mathf.Max(0f, _timeRemaining - (float)delta);
        if (_timeLabel != null)
            _timeLabel.Text = ((int)_timeRemaining).ToString();
        if (_timeRemaining <= 0f)
        {
            _timedOut = true;
            var player = GetTree().GetFirstNodeInGroup("player");
            if (player is PlayerController pc)
                pc.KillPlayer();
        }
    }

    private void OnScoreChanged(int score)
    {
        if (_scoreLabel != null) _scoreLabel.Text = score.ToString("D6");
    }

    private void OnLivesChanged(int lives)
    {
        if (_livesLabel != null) _livesLabel.Text = "x " + lives;
    }

    private void OnLevelChanged(string name, float timeLimit)
    {
        _timeRemaining = timeLimit;
        _timedOut = false;
        if (_worldLabel != null) _worldLabel.Text = name;
        if (_timeLabel != null) _timeLabel.Text = ((int)_timeRemaining).ToString();
    }
}
