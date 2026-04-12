using Godot;

namespace supermariocs;

public partial class SceneManager : Node
{
	private const float FadeDuration = 0.5f;

	private CanvasLayer _overlay;
	private ColorRect _fadeRect;
	private Label _introLabel;
	private bool _isTransitioning;

	public override void _Ready()
	{
		BuildOverlay();
		GD.Print("[SceneManager] ready");
	}

	private void BuildOverlay()
	{
		_overlay = new CanvasLayer { Name = "Overlay", Layer = 100 };
		AddChild(_overlay);

		_fadeRect = new ColorRect
		{
			Name = "FadeRect",
			Color = new Color(0, 0, 0, 1),
			Modulate = new Color(1, 1, 1, 0),
			MouseFilter = Control.MouseFilterEnum.Ignore,
		};
		_fadeRect.SetAnchorsAndOffsetsPreset(Control.LayoutPreset.FullRect);
		_overlay.AddChild(_fadeRect);

		_introLabel = new Label
		{
			Name = "IntroLabel",
			Text = "",
			Visible = false,
			HorizontalAlignment = HorizontalAlignment.Center,
			VerticalAlignment = VerticalAlignment.Center,
			MouseFilter = Control.MouseFilterEnum.Ignore,
		};
		_introLabel.SetAnchorsAndOffsetsPreset(Control.LayoutPreset.FullRect);
		_overlay.AddChild(_introLabel);
	}

	public async void ChangeScene(string path)
	{
		if (_isTransitioning) return;
		_isTransitioning = true;

		await FadeTo(1.0f);

		if (!string.IsNullOrEmpty(path) && ResourceLoader.Exists(path))
		{
			GD.Print($"[SceneManager] loading scene: {path}");
			GetTree().ChangeSceneToFile(path);
		}
		else if (!string.IsNullOrEmpty(path))
		{
			GD.PrintErr($"[SceneManager] missing scene: {path}");
		}

		await FadeTo(0.0f);
		_isTransitioning = false;
	}

	public void ReloadCurrentScene()
	{
		if (_isTransitioning) return;
		GetTree().ReloadCurrentScene();
	}

	public void ShowLevelIntro(int world, int level, int lives)
	{
		_introLabel.Text = $"WORLD {world}-{level}\nLIVES x {lives}";
		_introLabel.Visible = true;
	}

	public void HideLevelIntro()
	{
		_introLabel.Visible = false;
	}

	private SignalAwaiter FadeTo(float targetAlpha)
	{
		var tween = CreateTween();
		tween.TweenProperty(_fadeRect, "modulate:a", targetAlpha, FadeDuration);
		return ToSignal(tween, Tween.SignalName.Finished);
	}
}
