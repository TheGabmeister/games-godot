using Godot;

namespace supermariocs;

public partial class AudioManager : Node
{
	public override void _Ready()
	{
		GD.Print("[AudioManager] ready");
	}

	public void PlaySfx(StringName soundName, Vector2 position = default)
	{
	}

	public void PlayMusic(StringName musicName)
	{
	}

	public void StopMusic()
	{
	}

	public void SetMusicDucked(bool enabled)
	{
	}
}
