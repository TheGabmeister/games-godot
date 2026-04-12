using Godot;

namespace supermariocs;

public partial class PlayerState : Node
{
	protected PlayerController Player { get; private set; }
	protected StateMachine Machine { get; private set; }

	public void Init(PlayerController player, StateMachine machine)
	{
		Player = player;
		Machine = machine;
	}

	public virtual void Enter() { }
	public virtual void Exit() { }
	public virtual void ProcessInput(InputEvent @event) { }
	public virtual void ProcessFrame(double delta) { }
	public virtual void ProcessPhysics(double delta) { }
}
