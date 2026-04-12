using Godot;

namespace supermariocs;

public static class TerrainTileSet
{
	public const int GroundTopSourceId = 0;
	public const int GroundFillSourceId = 1;
	private const int TileSize = 16;

	public static TileSet Build()
	{
		var tileSet = new TileSet { TileSize = new Vector2I(TileSize, TileSize) };
		tileSet.AddPhysicsLayer();
		tileSet.SetPhysicsLayerCollisionLayer(0, 1);  // Terrain layer 1
		tileSet.SetPhysicsLayerCollisionMask(0, 0);

		AddTileSource(tileSet, GroundTopSourceId, BuildGroundTopTexture());
		AddTileSource(tileSet, GroundFillSourceId, BuildGroundFillTexture());

		return tileSet;
	}

	private static void AddTileSource(TileSet tileSet, int sourceId, Texture2D texture)
	{
		var atlas = new TileSetAtlasSource
		{
			Texture = texture,
			TextureRegionSize = new Vector2I(TileSize, TileSize),
		};
		tileSet.AddSource(atlas, sourceId);
		atlas.CreateTile(Vector2I.Zero);
		var data = atlas.GetTileData(Vector2I.Zero, 0);
		data.AddCollisionPolygon(0);
		data.SetCollisionPolygonPoints(0, 0, new Vector2[]
		{
			new(-TileSize / 2f, -TileSize / 2f),
			new( TileSize / 2f, -TileSize / 2f),
			new( TileSize / 2f,  TileSize / 2f),
			new(-TileSize / 2f,  TileSize / 2f),
		});
	}

	private static Texture2D BuildGroundTopTexture()
	{
		var image = Image.CreateEmpty(TileSize, TileSize, false, Image.Format.Rgba8);
		for (int y = 0; y < TileSize; y++)
		{
			for (int x = 0; x < TileSize; x++)
			{
				Color c = y < 4 ? P.GroundGreen : P.GroundBrown;
				if (y == 4) c = new Color(0.18f, 0.50f, 0.18f);
				if (y > 5 && (x + y) % 4 == 0) c = P.BrickDark;
				image.SetPixel(x, y, c);
			}
		}
		return ImageTexture.CreateFromImage(image);
	}

	private static Texture2D BuildGroundFillTexture()
	{
		var image = Image.CreateEmpty(TileSize, TileSize, false, Image.Format.Rgba8);
		for (int y = 0; y < TileSize; y++)
		{
			for (int x = 0; x < TileSize; x++)
			{
				Color c = P.GroundBrown;
				if ((x + y) % 4 == 0) c = P.BrickDark;
				image.SetPixel(x, y, c);
			}
		}
		return ImageTexture.CreateFromImage(image);
	}
}
