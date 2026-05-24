using Godot;

namespace supermariocs.Autoloads;

public partial class MusicManager : Node
{
    public static MusicManager Instance { get; private set; }

    private AudioStreamPlayer _player;
    private AudioStream _current;

    public override void _Ready()
    {
        Instance = this;
        _player = new AudioStreamPlayer { Bus = "Master" };
        AddChild(_player);
    }

    public void Play(AudioStream stream)
    {
        if (stream == null) return;
        if (stream == _current && _player.Playing) return;
        _current = stream;
        _player.Stream = stream;
        _player.Play();
    }

    public void Stop()
    {
        _player.Stop();
        _current = null;
    }
}
