using Godot;

namespace supermariocs;

public partial class Main : Node
{
	public override void _Ready()
	{
		GD.Print("[Main] ready");
	}

	public override void _UnhandledInput(InputEvent @event)
	{
		if (@event is InputEventKey key && key.Pressed && !key.Echo && key.Keycode == Key.F)
		{
			GD.Print("[Main] debug fade triggered");
			GetNode<SceneManager>("/root/SceneManager").ChangeScene("");
		}
	}
}
