using Godot;

namespace supermariocs;

public partial class ParallaxController : Node2D
{
	[Export] public Node2D CloudsLayer;
	[Export] public Node2D HillsLayer;
	[Export(PropertyHint.Range, "0,1")] public float CloudsRate = 0.3f;
	[Export(PropertyHint.Range, "0,1")] public float HillsRate = 0.6f;

	private Camera2D _camera;

	public override void _Process(double delta)
	{
		if (_camera == null || !IsInstanceValid(_camera))
		{
			_camera = GetViewport().GetCamera2D();
			if (_camera == null) return;
		}

		var center = _camera.GetScreenCenterPosition();
		if (CloudsLayer != null)
		{
			CloudsLayer.Position = new Vector2(center.X * (1.0f - CloudsRate), CloudsLayer.Position.Y);
		}
		if (HillsLayer != null)
		{
			HillsLayer.Position = new Vector2(center.X * (1.0f - HillsRate), HillsLayer.Position.Y);
		}
	}
}
