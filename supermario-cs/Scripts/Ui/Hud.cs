using Godot;

namespace SuperMario;

public partial class Hud : CanvasLayer
{
    [Export] public Label ScoreLabel;
    [Export] public Label CoinLabel;
    [Export] public Label WorldLabel;
    [Export] public Label TimeLabel;
    [Export] public Label LivesLabel;

    private GameSession _session;

    public void Bind(GameSession session)
    {
        _session = session;
        session.ScoreChanged += OnScoreChanged;
        session.CoinsChanged += OnCoinsChanged;
        session.LivesChanged += OnLivesChanged;
        session.LevelChanged += OnLevelChanged;
        session.TimeRemainingChanged += OnTimeRemainingChanged;

        RefreshLabels();
    }

    public override void _ExitTree()
    {
        UnbindState();
    }

    private void UnbindState()
    {
        if (_session == null) return;

        _session.ScoreChanged -= OnScoreChanged;
        _session.CoinsChanged -= OnCoinsChanged;
        _session.LivesChanged -= OnLivesChanged;
        _session.LevelChanged -= OnLevelChanged;
        _session.TimeRemainingChanged -= OnTimeRemainingChanged;
        _session = null;
    }

    private void RefreshLabels()
    {
        var saveData = _session.SaveData;
        WorldLabel.Text = saveData.CurrentLevelName;
        OnScoreChanged(saveData.Score);
        OnCoinsChanged(saveData.Coins);
        OnLivesChanged(saveData.Lives);
        OnTimeRemainingChanged(saveData.TimeRemaining);
    }

    private void OnScoreChanged(int score)
    {
        ScoreLabel.Text = score.ToString("D6");
    }

    private void OnCoinsChanged(int coins)
    {
        CoinLabel.Text = "x" + coins.ToString("D2");
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
