using Godot;

namespace supermariocs;

public partial class JumpState : PlayerState
{
	public override void Enter()
	{
		Player.Velocity = new Vector2(Player.Velocity.X, PlayerController.JumpVelocity);
		Player.JumpBufferCounter = 0;
		Player.CoyoteCounter = 0;
	}

	public override void ProcessPhysics(double delta)
	{
		Player.ApplyHorizontalAccel(delta);

		if (Input.IsActionJustReleased("jump") && Player.Velocity.Y < 0)
		{
			Player.Velocity = new Vector2(
				Player.Velocity.X,
				Player.Velocity.Y * PlayerController.JumpReleaseMult);
		}

		Player.ApplyGravity(delta);

		if (Player.Velocity.Y >= 0)
		{
			Machine.TransitionTo(StateMachine.Fall);
		}
	}
}
