using Godot;

namespace supermariocs;

public partial class RunState : PlayerState
{
	public override void ProcessPhysics(double delta)
	{
		Player.ApplyHorizontalAccel(delta);
		Player.ApplyGravity(delta);

		if (Player.JumpBufferCounter > 0 && (Player.IsOnFloor() || Player.CoyoteCounter > 0))
		{
			Machine.TransitionTo(StateMachine.Jump);
			return;
		}

		if (!Player.IsOnFloor() && Player.CoyoteCounter <= 0)
		{
			Machine.TransitionTo(StateMachine.Fall);
			return;
		}

		bool moving = Input.IsActionPressed("move_left") || Input.IsActionPressed("move_right");
		if (!moving && Mathf.Abs(Player.Velocity.X) < 1.0f)
		{
			Machine.TransitionTo(StateMachine.Idle);
			return;
		}

		if (Input.IsActionPressed("crouch") && Player.CanCrouch())
		{
			Machine.TransitionTo(StateMachine.Crouch);
		}
	}
}
