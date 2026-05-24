using Godot;
using supermariocs.Autoloads;
using supermariocs.Resources;

namespace supermariocs.Ui;

public partial class Hud : CanvasLayer
{
    [Export] private Label _scoreLabel;
    [Export] private Label _worldLabel;
    [Export] private Label _timeLabel;
    [Export] private Label _livesLabel;

    private LevelDefinition _config;
    private float _timeRemaining;
    private bool _timedOut;

    public void Bind(LevelDefinition config)
    {
        _config = config;
        _timeRemaining = config?.TimeLimit ?? 0f;
        if (_worldLabel != null) _worldLabel.Text = config?.Name ?? "";

        var state = GameManager.Instance?.State;
        if (state != null)
        {
            OnScoreChanged(state.Score);
            OnLivesChanged(state.Lives);
            state.ScoreChanged += OnScoreChanged;
            state.LivesChanged += OnLivesChanged;
        }
    }

    public override void _ExitTree()
    {
        var state = GameManager.Instance?.State;
        if (state != null)
        {
            state.ScoreChanged -= OnScoreChanged;
            state.LivesChanged -= OnLivesChanged;
        }
    }

    public override void _Process(double delta)
    {
        if (_timedOut) return;
        _timeRemaining = Mathf.Max(0f, _timeRemaining - (float)delta);
        if (_timeLabel != null)
            _timeLabel.Text = ((int)_timeRemaining).ToString();
        if (_timeRemaining <= 0f)
        {
            _timedOut = true;
            var player = GetTree().GetFirstNodeInGroup("player");
            if (player is Player.PlayerController pc)
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
}
