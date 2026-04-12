using Godot;

namespace supermariocs;

public partial class StateMachine : Node
{
	public static readonly StringName Idle = "IdleState";
	public static readonly StringName Run = "RunState";
	public static readonly StringName Jump = "JumpState";
	public static readonly StringName Fall = "FallState";
	public static readonly StringName Crouch = "CrouchState";

	public PlayerState CurrentState { get; private set; }

	public void Initialize(PlayerController player, StringName initialState)
	{
		foreach (var child in GetChildren())
		{
			if (child is PlayerState state)
			{
				state.Init(player, this);
			}
		}
		TransitionTo(initialState);
	}

	public void TransitionTo(StringName stateName)
	{
		var next = GetNodeOrNull<PlayerState>((string)stateName);
		if (next == null)
		{
			GD.PrintErr($"[StateMachine] missing state: {stateName}");
			return;
		}
		if (CurrentState == next) return;
		CurrentState?.Exit();
		CurrentState = next;
		CurrentState.Enter();
	}
}
