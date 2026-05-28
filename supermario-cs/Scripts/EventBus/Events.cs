using System;
using Godot;

namespace SMB.EventBus;

public static class Events
{
    public static event Action<AudioStream> SfxPlayRequested;
    public static event Action<string, Vector2> TextSpawnRequested;
    public static event Action<int> ScoreEarned;
    public static event Action<int, int, Vector2> CoinPickedUp;
    public static event Action<int, Vector2> MushroomPickedUp;
    public static event Action<int, Vector2> FireFlowerPickedUp;
    public static event Action<int, Vector2> StarmanPickedUp;
    public static event Action OneUpPickedUp;

    public static void EmitSfxPlayRequested(AudioStream stream) => SfxPlayRequested?.Invoke(stream);
    public static void EmitTextSpawnRequested(string text, Vector2 position) => TextSpawnRequested?.Invoke(text, position);
    public static void EmitScoreEarned(int value) => ScoreEarned?.Invoke(value);
    public static void EmitCoinPickedUp(int scoreValue, int coinValue, Vector2 position) => CoinPickedUp?.Invoke(scoreValue, coinValue, position);
    public static void EmitMushroomPickedUp(int scoreValue, Vector2 position) => MushroomPickedUp?.Invoke(scoreValue, position);
    public static void EmitFireFlowerPickedUp(int scoreValue, Vector2 position) => FireFlowerPickedUp?.Invoke(scoreValue, position);
    public static void EmitStarmanPickedUp(int scoreValue, Vector2 position) => StarmanPickedUp?.Invoke(scoreValue, position);
    public static void EmitOneUpPickedUp() => OneUpPickedUp?.Invoke();

    public static void Clear()
    {
        SfxPlayRequested = null;
        TextSpawnRequested = null;
        ScoreEarned = null;
        CoinPickedUp = null;
        MushroomPickedUp = null;
        FireFlowerPickedUp = null;
        StarmanPickedUp = null;
        OneUpPickedUp = null;
    }
}
