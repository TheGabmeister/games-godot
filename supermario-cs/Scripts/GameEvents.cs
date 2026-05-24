using System;
using Godot;

namespace SuperMario;

public class GameEvents
{
    public event Action<int> ScoreEarned;
    public event Action<string, Vector2> TextPopupRequested;
    public event Action OneUpAwarded;
    public event Action<PlayerPowerState> PlayerPowerStateChanged;

    public void EmitScoreEarned(int points) => ScoreEarned?.Invoke(points);
    public void EmitTextPopupRequested(string text, Vector2 worldPosition) => TextPopupRequested?.Invoke(text, worldPosition);
    public void EmitOneUpAwarded() => OneUpAwarded?.Invoke();
    public void EmitPlayerPowerStateChanged(PlayerPowerState state) => PlayerPowerStateChanged?.Invoke(state);
}
