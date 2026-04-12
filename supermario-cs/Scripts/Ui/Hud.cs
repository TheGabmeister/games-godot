using Godot;

namespace supermariocs;

public partial class Hud : CanvasLayer
{
	private Label _scoreLabel;
	private Label _coinLabel;
	private Label _worldLabel;
	private Label _timeLabel;
	private LabelSettings _labelSettings;
	private EventBus _bus;
	private GameManager _gm;

	public override void _Ready()
	{
		Layer = 100;
		BuildLayout();
		_bus = GetNode<EventBus>("/root/EventBus");
		_gm = GetNode<GameManager>("/root/GameManager");
		_bus.ScoreChanged += OnScoreChanged;
		_bus.CoinsChanged += OnCoinsChanged;
		_bus.LivesChanged += OnLivesChanged;
		_bus.TimeTick += OnTimeTick;
		_bus.LevelStarted += OnLevelStarted;
		Refresh();
	}

	public override void _ExitTree()
	{
		if (_bus == null) return;
		_bus.ScoreChanged -= OnScoreChanged;
		_bus.CoinsChanged -= OnCoinsChanged;
		_bus.LivesChanged -= OnLivesChanged;
		_bus.TimeTick -= OnTimeTick;
		_bus.LevelStarted -= OnLevelStarted;
	}

	private void BuildLayout()
	{
		_labelSettings = new LabelSettings
		{
			FontColor = P.White,
			FontSize = 12,
			ShadowColor = P.Black,
			ShadowSize = 1,
			ShadowOffset = new Vector2(1, 1),
		};

		var margin = new MarginContainer { MouseFilter = Control.MouseFilterEnum.Ignore };
		margin.SetAnchorsAndOffsetsPreset(Control.LayoutPreset.TopWide);
		margin.AddThemeConstantOverride("margin_left", 16);
		margin.AddThemeConstantOverride("margin_right", 16);
		margin.AddThemeConstantOverride("margin_top", 8);
		AddChild(margin);

		var hbox = new HBoxContainer { Alignment = BoxContainer.AlignmentMode.Center };
		hbox.AddThemeConstantOverride("separation", 32);
		margin.AddChild(hbox);

		_scoreLabel = MakeLabel("MARIO\n000000");
		_coinLabel = MakeLabel("$x00");
		_worldLabel = MakeLabel("WORLD\n1-1");
		_timeLabel = MakeLabel("TIME\n400");
		hbox.AddChild(_scoreLabel);
		hbox.AddChild(_coinLabel);
		hbox.AddChild(_worldLabel);
		hbox.AddChild(_timeLabel);
	}

	private Label MakeLabel(string text)
	{
		return new Label
		{
			Text = text,
			LabelSettings = _labelSettings,
			HorizontalAlignment = HorizontalAlignment.Center,
			MouseFilter = Control.MouseFilterEnum.Ignore,
		};
	}

	private void Refresh()
	{
		OnScoreChanged(_gm.Score);
		OnCoinsChanged(_gm.Coins);
		OnTimeTick(_gm.TimeRemaining);
		OnLevelStarted(_gm.CurrentWorld, _gm.CurrentLevel);
	}

	private void OnScoreChanged(int newScore) =>
		_scoreLabel.Text = $"MARIO\n{newScore:D6}";

	private void OnCoinsChanged(int newCount) =>
		_coinLabel.Text = $"$x{newCount:D2}";

	private void OnLivesChanged(int newLives) { /* future: lives indicator */ }

	private void OnTimeTick(int timeRemaining)
	{
		_timeLabel.Text = $"TIME\n{timeRemaining:D3}";
		_timeLabel.LabelSettings.FontColor = timeRemaining < 100 ? P.MarioRed : P.White;
	}

	private void OnLevelStarted(int world, int level) =>
		_worldLabel.Text = $"WORLD\n{world}-{level}";
}
