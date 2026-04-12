using Godot;

namespace supermariocs;

public partial class PlayerDrawer : Node2D
{
	public GameManager.PowerState PowerState { get; set; } = GameManager.PowerState.Small;
	public int AnimFrame { get; set; } = 0;
	public bool IsCrouching { get; set; } = false;
	public bool IsAirborne { get; set; } = false;

	public override void _Draw()
	{
		if (PowerState == GameManager.PowerState.Small)
		{
			DrawSmallMario();
		}
		else
		{
			if (IsCrouching) DrawBigCrouched();
			else DrawBigMario();
		}
	}

	private (int leftX, int rightX) FeetOffsets()
	{
		if (IsAirborne) return (-7, 1);
		return AnimFrame switch
		{
			1 => (-6, 0),
			2 => (-8, 2),
			_ => (-7, 1),
		};
	}

	private void DrawSmallMario()
	{
		// 16x16 footprint, drawn from y=-16 (head top) to y=0 (feet)
		DrawRect(new Rect2(-8, -16, 16, 4), P.MarioRed);          // hat
		DrawRect(new Rect2(-7, -13, 14, 1), P.MarioRed);          // hat brim
		DrawRect(new Rect2(-6, -12, 12, 4), P.MarioSkin);         // face
		DrawRect(new Rect2(2, -11, 2, 2), P.Black);               // eye
		DrawRect(new Rect2(-2, -10, 4, 1), P.BrickDark);       // mustache
		DrawRect(new Rect2(-7, -8, 14, 4), PowerState == GameManager.PowerState.Fire ? P.MarioFireWhite : P.MarioRed);
		var (lx, rx) = FeetOffsets();
		DrawRect(new Rect2(lx, -4, 6, 4), P.MarioBlue);
		DrawRect(new Rect2(rx, -4, 6, 4), P.MarioBlue);
	}

	private void DrawBigMario()
	{
		// 16x32 footprint
		Color shirt = PowerState == GameManager.PowerState.Fire ? P.MarioFireWhite : P.MarioRed;
		DrawRect(new Rect2(-8, -32, 16, 6), P.MarioRed);          // hat
		DrawRect(new Rect2(-7, -27, 14, 1), P.MarioRed);          // hat brim
		DrawRect(new Rect2(-6, -26, 12, 6), P.MarioSkin);         // face
		DrawRect(new Rect2(3, -25, 2, 2), P.Black);               // eye
		DrawRect(new Rect2(-2, -22, 4, 1), P.BrickDark);       // mustache
		DrawRect(new Rect2(-8, -20, 16, 8), shirt);               // shirt
		DrawRect(new Rect2(-5, -20, 2, 8), P.MarioBlue);          // overall strap L
		DrawRect(new Rect2(3, -20, 2, 8), P.MarioBlue);           // overall strap R
		DrawRect(new Rect2(-8, -12, 16, 8), P.MarioBlue);         // overalls
		DrawRect(new Rect2(-4, -8, 1, 1), P.QuestionYellow);      // overall button L
		DrawRect(new Rect2(3, -8, 1, 1), P.QuestionYellow);       // overall button R
		var (lx, rx) = FeetOffsets();
		DrawRect(new Rect2(lx, -4, 6, 4), P.BrickDark);        // shoe L
		DrawRect(new Rect2(rx, -4, 6, 4), P.BrickDark);        // shoe R
	}

	private void DrawBigCrouched()
	{
		// Big Mario but compressed to 16 tall — shoulders and hat only
		Color shirt = PowerState == GameManager.PowerState.Fire ? P.MarioFireWhite : P.MarioRed;
		DrawRect(new Rect2(-8, -16, 16, 4), P.MarioRed);          // hat
		DrawRect(new Rect2(-6, -12, 12, 3), P.MarioSkin);         // face squashed
		DrawRect(new Rect2(2, -11, 2, 2), P.Black);
		DrawRect(new Rect2(-8, -9, 16, 5), shirt);                // body
		DrawRect(new Rect2(-8, -4, 16, 4), P.MarioBlue);          // overalls/feet
	}
}
