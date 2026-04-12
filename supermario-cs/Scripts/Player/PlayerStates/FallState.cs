using Godot;

namespace supermariocs;

public partial class FallState : PlayerState
{
	public override void ProcessPhysics(double delta)
	{
		Player.ApplyHorizontalAccel(delta);
		Player.ApplyGravity(delta);

		if (Player.IsOnFloor())
		{
			if (Player.JumpBufferCounter > 0)
			{
				Machine.TransitionTo(StateMachine.Jump);
				return;
			}
			bool moving = Input.IsActionPressed("move_left") || Input.IsActionPressed("move_right");
			Machine.TransitionTo(moving ? StateMachine.Run : StateMachine.Idle);
			return;
		}

		if (Player.JumpBufferCounter > 0 && Player.CoyoteCounter > 0)
		{
			Machine.TransitionTo(StateMachine.Jump);
		}
	}
}
