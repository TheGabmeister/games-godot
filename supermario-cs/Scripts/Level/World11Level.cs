using Godot;

namespace supermariocs;

public partial class World11Level : LevelBase
{
	private const int LevelWidthTiles = 212;
	private const int GroundTopRow = 12;
	private const int GroundFillRow = 13;

	private static readonly (int Start, int End)[] GroundRanges =
	{
		(0, 90),
		(93, 111),
		(115, 157),
		(161, 211),
	};

	protected override void BuildTerrain()
	{
		var top = GetNodeOrNull<TileMapLayer>("TileMapLayer_Ground");
		if (top == null)
		{
			GD.PrintErr("[World11Level] TileMapLayer_Ground missing");
			return;
		}

		top.TileSet = TerrainTileSet.Build();

		foreach (var (start, end) in GroundRanges)
		{
			for (int x = start; x <= end; x++)
			{
				top.SetCell(new Vector2I(x, GroundTopRow), TerrainTileSet.GroundTopSourceId, Vector2I.Zero);
				top.SetCell(new Vector2I(x, GroundFillRow), TerrainTileSet.GroundFillSourceId, Vector2I.Zero);
			}
		}
	}
}
