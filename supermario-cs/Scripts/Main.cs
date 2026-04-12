using Godot;

namespace supermariocs;

public partial class Main : Node
{
	private const string FirstLevelPath = "res://scenes/levels/world_1_1.tscn";

	public override void _Ready()
	{
		GD.Print("[Main] ready");
		CallDeferred(nameof(StartGame));
	}

	private void StartGame()
	{
		GetNode<GameManager>("/root/GameManager").StartNewGame();
		GetNode<SceneManager>("/root/SceneManager").LoadLevel(FirstLevelPath);
	}

	public override void _UnhandledInput(InputEvent @event)
	{
		if (@event is InputEventKey key && key.Pressed && !key.Echo && key.Keycode == Key.R)
		{
			GD.Print("[Main] reload level");
			GetNode<SceneManager>("/root/SceneManager").LoadLevel(FirstLevelPath);
		}
	}
}
