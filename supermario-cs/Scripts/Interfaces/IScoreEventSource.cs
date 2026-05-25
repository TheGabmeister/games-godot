using System;

namespace SuperMario;

public interface IScoreEventSource
{
    event Action<int> ScoreEarned;
}
