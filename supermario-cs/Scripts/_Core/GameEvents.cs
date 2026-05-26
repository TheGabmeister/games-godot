using System;

namespace SMB;

public class GameEvents
{
    public event Action<int> ScoreEarned;
    public event Action<int> CoinsCollected;

    public void EmitScoreEarned(int points) => ScoreEarned?.Invoke(points);
    public void EmitCoinsCollected(int coins) => CoinsCollected?.Invoke(coins);
}
