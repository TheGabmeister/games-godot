using Godot;

namespace supermariocs;

public partial class CameraEffects : Node
{
	public override void _Ready()
	{
		GD.Print("[CameraEffects] ready");
	}

	public void Shake(float intensity, float duration)
	{
	}

	public void FreezeFrame(float duration)
	{
	}
}
