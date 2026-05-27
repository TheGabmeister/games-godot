using Godot;

namespace SMB;

public partial class MusicManager : Node
{
    private AudioStreamPlayer _player;
    private AudioStream _current;

    public override void _Ready()
    {
        _player = new AudioStreamPlayer { Bus = "Master" };
        AddChild(_player);
    }

    public void Play(AudioStream stream)
    {
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
