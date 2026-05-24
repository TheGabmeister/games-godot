using System;
using Godot;

namespace SuperMario;

public class GameEvents
{
    public event Action<int> ScoreEarned;
    public event Action<int, Vector2> ScoreEarnedAt;
    public event Action OneUpAwarded;
    public event Action<PlayerPowerState> PlayerPowerStateChanged;

    public void EmitScoreEarned(int points) => ScoreEarned?.Invoke(points);
    public void EmitScoreEarnedAt(int points, Vector2 worldPosition) => ScoreEarnedAt?.Invoke(points, worldPosition);
    public void EmitOneUpAwarded() => OneUpAwarded?.Invoke();
    public void EmitPlayerPowerStateChanged(PlayerPowerState state) => PlayerPowerStateChanged?.Invoke(state);
}
