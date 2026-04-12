using Godot;

namespace supermariocs;

public partial class IdleState : PlayerState
{
	public override void ProcessPhysics(double delta)
	{
		Player.ApplyHorizontalAccel(delta);
		Player.ApplyGravity(delta);

		if (TryJump()) return;

		if (!Player.IsOnFloor() && Player.CoyoteCounter <= 0)
		{
			Machine.TransitionTo(StateMachine.Fall);
			return;
		}

		bool moving = Input.IsActionPressed("move_left") || Input.IsActionPressed("move_right");
		if (moving)
		{
			Machine.TransitionTo(StateMachine.Run);
			return;
		}

		if (Input.IsActionPressed("crouch") && Player.CanCrouch())
		{
			Machine.TransitionTo(StateMachine.Crouch);
		}
	}

	private bool TryJump()
	{
		if (Player.JumpBufferCounter > 0 && (Player.IsOnFloor() || Player.CoyoteCounter > 0))
		{
			Machine.TransitionTo(StateMachine.Jump);
			return true;
		}
		return false;
	}
}
