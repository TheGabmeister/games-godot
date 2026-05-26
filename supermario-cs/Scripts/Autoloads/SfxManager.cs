using Godot;

namespace SMB;

public partial class SfxManager : Node
{
    public static SfxManager Instance { get; private set; }

    private const int PoolSize = 10;
    private AudioStreamPlayer[] _players;

    public override void _Ready()
    {
        Instance = this;
        _players = new AudioStreamPlayer[PoolSize];
        for (int i = 0; i < PoolSize; i++)
        {
            var p = new AudioStreamPlayer { Bus = "Master" };
            AddChild(p);
            _players[i] = p;
        }
    }

    public void Play(AudioStream stream)
    {
        for (int i = 0; i < _players.Length; i++)
        {
            if (!_players[i].Playing)
            {
                _players[i].Stream = stream;
                _players[i].Play();
                return;
            }
        }
        // pool exhausted - drop request
    }
}
