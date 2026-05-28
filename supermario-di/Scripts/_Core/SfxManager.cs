using Godot;

namespace SMB;

public partial class SfxManager : Node
{
    private const int PoolSize = 10;
    private AudioStreamPlayer[] _players;
    private AudioStream _blockBreak;
    private AudioStream _blockBump;
    private AudioStream _coin;
    private AudioStream _fireball;
    private AudioStream _flagpole;
    private AudioStream _gameOver;
    private AudioStream _kick;
    private AudioStream _oneUp;
    private AudioStream _pipe;
    private AudioStream _playerDeath;
    private AudioStream _playerJump;
    private AudioStream _playerJumpBig;
    private AudioStream _playerPowerDown;
    private AudioStream _playerPowerUp;
    private AudioStream _playerStomp;
    private AudioStream _stageClear;
    private AudioStream _warning;

    public override void _Ready()
    {
        _blockBreak = Load("Block_Break");
        _blockBump = Load("Block_Bump");
        _coin = Load("Coin");
        _fireball = Load("Fireball");
        _flagpole = Load("Flagpole");
        _gameOver = Load("GameOver");
        _kick = Load("Kick");
        _oneUp = Load("OneUp");
        _pipe = Load("Pipe");
        _playerDeath = Load("PlayerDeath");
        _playerJump = Load("PlayerJump");
        _playerJumpBig = Load("PlayerJump_Big");
        _playerPowerDown = Load("PlayerPower_Down");
        _playerPowerUp = Load("PlayerPower_Up");
        _playerStomp = Load("PlayerStomp");
        _stageClear = Load("StageClear");
        _warning = Load("Warning");

        _players = new AudioStreamPlayer[PoolSize];
        for (int i = 0; i < PoolSize; i++)
        {
            var p = new AudioStreamPlayer { Bus = "Master" };
            AddChild(p);
            _players[i] = p;
        }
    }

    public void PlayBlockBreak() => Play(_blockBreak);
    public void PlayBlockBump() => Play(_blockBump);
    public void PlayCoin() => Play(_coin);
    public void PlayFireball() => Play(_fireball);
    public void PlayFlagpole() => Play(_flagpole);
    public void PlayGameOver() => Play(_gameOver);
    public void PlayKick() => Play(_kick);
    public void PlayOneUp() => Play(_oneUp);
    public void PlayPipe() => Play(_pipe);
    public void PlayPlayerDeath() => Play(_playerDeath);
    public void PlayPlayerJump(bool big) => Play(big ? _playerJumpBig : _playerJump);
    public void PlayPlayerPowerDown() => Play(_playerPowerDown);
    public void PlayPlayerPowerUp() => Play(_playerPowerUp);
    public void PlayPlayerStomp() => Play(_playerStomp);
    public void PlayStageClear() => Play(_stageClear);
    public void PlayWarning() => Play(_warning);

    public void Play(AudioStream stream)
    {
        if (stream == null) return;

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

    private static AudioStream Load(string name)
    {
        return GD.Load<AudioStream>($"res://Sfx/{name}.wav");
    }
}
