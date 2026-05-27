using System;

namespace SMB;

public delegate void GameEventHandler<T>(in T evt) where T : struct;

public readonly struct ScoreEarnedEvent
{
    public readonly int Points;

    public ScoreEarnedEvent(int points)
    {
        Points = points;
    }
}

public readonly struct CoinsCollectedEvent
{
    public readonly int Coins;

    public CoinsCollectedEvent(int coins)
    {
        Coins = coins;
    }
}

public class GameEvents
{
    public event GameEventHandler<ScoreEarnedEvent> ScoreEarned;
    public event GameEventHandler<CoinsCollectedEvent> CoinsCollected;

    public void EmitScoreEarned(int points)
    {
        var evt = new ScoreEarnedEvent(points);
        ScoreEarned?.Invoke(in evt);
    }

    public void EmitCoinsCollected(int coins)
    {
        var evt = new CoinsCollectedEvent(coins);
        CoinsCollected?.Invoke(in evt);
    }
}
