using Godot;

namespace supermariocs;

public partial class CrouchState : PlayerState
{
	public override void Enter()
	{
		Player.SetCrouchShape(true);
	}

	public override void Exit()
	{
		Player.SetCrouchShape(false);
	}

	public override void ProcessPhysics(double delta)
	{
		Player.Velocity = new Vector2(
			Mathf.MoveToward(Player.Velocity.X, 0, PlayerController.Deceleration * (float)delta),
			Player.Velocity.Y);
		Player.ApplyGravity(delta);

		if (!Player.IsOnFloor() && Player.CoyoteCounter <= 0)
		{
			Machine.TransitionTo(StateMachine.Fall);
			return;
		}

		if (!Input.IsActionPressed("crouch"))
		{
			if (Player.CanStand())
			{
				Machine.TransitionTo(StateMachine.Idle);
			}
		}
	}
}
