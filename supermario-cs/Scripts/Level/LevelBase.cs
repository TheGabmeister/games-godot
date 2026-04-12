using Godot;

namespace supermariocs;

public partial class LevelBase : Node2D
{
	[Export] public LevelConfig Config;

	[ExportGroup("Camera Bounds")]
	[Export] public int CameraLimitLeft = 0;
	[Export] public int CameraLimitRight = 3392;
	[Export] public int CameraLimitTop = 0;
	[Export] public int CameraLimitBottom = 448;

	public override void _Ready()
	{
		if (Config == null)
		{
			GD.PrintErr($"[LevelBase] {Name}: Config not assigned");
		}
		BuildTerrain();
		BuildBackground();
	}

	protected virtual void BuildTerrain() { }
	protected virtual void BuildBackground() { }
}
