using System;
using Godot;

namespace SMB.EventBus;

public static class Events
{
    public static event Action<AudioStream> SfxPlay;
    public static event Action<int> ScoreEarned;
    public static event Action<int, int, Vector2> CoinPickedUp;
    public static event Action<int, Vector2> MushroomPickedUp;
    public static event Action<int, Vector2> FireFlowerPickedUp;
    public static event Action<int, Vector2> StarmanPickedUp;
    public static event Action OneUpPickedUp;

    public static void EmitSfxPlay(AudioStream stream) => SfxPlay?.Invoke(stream);
    public static void EmitScoreEarned(int value) => ScoreEarned?.Invoke(value);
    public static void EmitGotCoin(int scoreValue, int coinValue, Vector2 position) => CoinPickedUp?.Invoke(scoreValue, coinValue, position);
    public static void EmitGotMushroom(int scoreValue, Vector2 position) => MushroomPickedUp?.Invoke(scoreValue, position);
    public static void EmitGotFireFlower(int scoreValue, Vector2 position) => FireFlowerPickedUp?.Invoke(scoreValue, position);
    public static void EmitGotStarman(int scoreValue, Vector2 position) => StarmanPickedUp?.Invoke(scoreValue, position);
    public static void EmitGotOneUp() => OneUpPickedUp?.Invoke();

    public static void Clear()
    {
        SfxPlay = null;
        ScoreEarned = null;
        CoinPickedUp = null;
        MushroomPickedUp = null;
        FireFlowerPickedUp = null;
        StarmanPickedUp = null;
        OneUpPickedUp = null;
    }
}
