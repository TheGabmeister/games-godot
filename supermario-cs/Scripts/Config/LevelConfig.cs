using Godot;

namespace supermariocs;

[GlobalClass]
public partial class LevelConfig : Resource
{
	[ExportGroup("Identity")]
	[Export] public int World { get; set; } = 1;
	[Export] public int Level { get; set; } = 1;

	[ExportGroup("Timer")]
	[Export] public float TimeLimit { get; set; } = 400.0f;

	[ExportGroup("Music")]
	[Export] public StringName MusicTrack { get; set; } = "overworld";
	[Export] public StringName HurryMusicTrack { get; set; } = "";

	[ExportGroup("Environment")]
	[Export] public bool IsUnderground { get; set; } = false;
	[Export] public bool HasSkyColorOverride { get; set; } = false;
	[Export] public Color SkyColorOverride { get; set; } = new Color(0.42f, 0.62f, 1.0f);
}
