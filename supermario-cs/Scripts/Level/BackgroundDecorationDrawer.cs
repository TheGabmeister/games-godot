using Godot;

namespace supermariocs;

public partial class BackgroundDecorationDrawer : Node2D
{
	public enum Kind { Clouds, Hills, Bushes }

	[Export] public Kind DecorationKind = Kind.Clouds;
	[Export] public int Count = 12;
	[Export] public float Spacing = 256.0f;
	[Export] public float StartX = 0.0f;
	[Export] public float BaseY = 0.0f;
	[Export] public int RandomSeed = 1337;

	public override void _Draw()
	{
		var rng = new RandomNumberGenerator { Seed = (ulong)RandomSeed };
		for (int i = 0; i < Count; i++)
		{
			float x = StartX + i * Spacing + rng.RandfRange(-32, 32);
			float y = BaseY + rng.RandfRange(-8, 8);
			switch (DecorationKind)
			{
				case Kind.Clouds: DrawCloud(x, y); break;
				case Kind.Hills:  DrawHill(x, y); break;
				case Kind.Bushes: DrawBush(x, y); break;
			}
		}
	}

	private void DrawCloud(float x, float y)
	{
		DrawCircle(new Vector2(x, y), 8, P.CloudWhite);
		DrawCircle(new Vector2(x + 10, y - 4), 10, P.CloudWhite);
		DrawCircle(new Vector2(x + 22, y), 8, P.CloudWhite);
		DrawRect(new Rect2(x - 2, y - 2, 26, 8), P.CloudWhite);
	}

	private void DrawHill(float x, float y)
	{
		var pts = new Vector2[]
		{
			new(x - 64, y),
			new(x - 48, y - 16),
			new(x - 16, y - 32),
			new(x + 16, y - 32),
			new(x + 48, y - 16),
			new(x + 64, y),
		};
		DrawColoredPolygon(pts, P.GroundGreen);
		DrawCircle(new Vector2(x - 16, y - 24), 4, new Color(0.20f, 0.55f, 0.20f));
		DrawCircle(new Vector2(x + 16, y - 24), 4, new Color(0.20f, 0.55f, 0.20f));
	}

	private void DrawBush(float x, float y)
	{
		DrawCircle(new Vector2(x, y - 4), 6, P.GroundGreen);
		DrawCircle(new Vector2(x + 8, y - 6), 7, P.GroundGreen);
		DrawCircle(new Vector2(x + 18, y - 4), 6, P.GroundGreen);
		DrawRect(new Rect2(x - 4, y - 4, 26, 4), P.GroundGreen);
	}
}
