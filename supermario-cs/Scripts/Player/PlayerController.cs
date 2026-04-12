using Godot;

namespace supermariocs;

public partial class PlayerController : CharacterBody2D
{
	public const float WalkSpeed       = 130.0f;
	public const float RunSpeed        = 210.0f;
	public const float Acceleration    = 800.0f;
	public const float Deceleration    = 1200.0f;
	public const float AirAcceleration = 600.0f;
	public const float TurnAcceleration = 1600.0f;
	public const float JumpVelocity    = -330.0f;
	public const float JumpReleaseMult = 0.5f;
	public const float Gravity         = 900.0f;
	public const float FastFallGravity = 1400.0f;
	public const float MaxFallSpeed    = 500.0f;
	public const float CoyoteTime      = 0.08f;
	public const float JumpBufferTime  = 0.10f;

	private const float ShapeWidth   = 12.0f;
	private const float SmallHeight  = 16.0f;
	private const float BigHeight    = 30.0f;
	private const float CrouchHeight = 16.0f;
	private const float WalkFrameInterval = 0.12f;
	private const float CameraLookAhead = 48.0f;
	private const float ViewportHalfWidth = 256.0f;

	public int FacingDirection { get; set; } = 1;
	public float CoyoteCounter { get; set; }
	public float JumpBufferCounter { get; set; }
	public bool IsCrouching { get; private set; }

	private CollisionShape2D _shape;
	private Node2D _visuals;
	private PlayerDrawer _drawer;
	private StateMachine _machine;
	private Camera2D _camera;
	private GameManager _gameManager;
	private EventBus _eventBus;
	private float _walkAnimTime;
	private float _currentLookAhead;

	public override void _Ready()
	{
		_shape = GetNode<CollisionShape2D>("CollisionShape2D");
		_visuals = GetNode<Node2D>("Visuals");
		_drawer = GetNode<PlayerDrawer>("Visuals/PlayerDrawer");
		_machine = GetNode<StateMachine>("StateMachine");
		_camera = GetNodeOrNull<Camera2D>("Camera2D");
		_gameManager = GetNode<GameManager>("/root/GameManager");
		_eventBus = GetNode<EventBus>("/root/EventBus");

		ApplyPowerStateShape(_gameManager.CurrentPowerState);
		_eventBus.PlayerPowerStateChanged += OnPowerStateChanged;

		_machine.Initialize(this, StateMachine.Idle);
	}

	public override void _ExitTree()
	{
		if (_eventBus != null)
		{
			_eventBus.PlayerPowerStateChanged -= OnPowerStateChanged;
		}
	}

	private void OnPowerStateChanged(int oldState, int newState)
	{
		ApplyPowerStateShape((GameManager.PowerState)newState);
	}

	public bool CanCrouch()
	{
		return _gameManager.CurrentPowerState != GameManager.PowerState.Small;
	}

	private void ApplyPowerStateShape(GameManager.PowerState state)
	{
		var rect = _shape.Shape as RectangleShape2D;
		if (rect == null) return;
		float h = state == GameManager.PowerState.Small ? SmallHeight : BigHeight;
		rect.Size = new Vector2(ShapeWidth, h);
		_shape.Position = new Vector2(0, -h / 2.0f);
		IsCrouching = false;
		_drawer.PowerState = state;
		_drawer.IsCrouching = false;
		_drawer.QueueRedraw();
	}

	public void SetCrouchShape(bool crouching)
	{
		if (_gameManager.CurrentPowerState == GameManager.PowerState.Small) return;
		IsCrouching = crouching;
		var rect = (RectangleShape2D)_shape.Shape;
		float h = crouching ? CrouchHeight : BigHeight;
		rect.Size = new Vector2(ShapeWidth, h);
		_shape.Position = new Vector2(0, -h / 2.0f);
		_drawer.IsCrouching = crouching;
		_drawer.QueueRedraw();
	}

	public bool CanStand()
	{
		var standingShape = new RectangleShape2D { Size = new Vector2(ShapeWidth - 1, BigHeight) };
		var transform = new Transform2D(0, GlobalPosition + new Vector2(0, -BigHeight / 2.0f));
		var query = new PhysicsShapeQueryParameters2D
		{
			Shape = standingShape,
			Transform = transform,
			CollisionMask = 1,
			Exclude = new Godot.Collections.Array<Rid> { GetRid() },
		};
		var result = GetWorld2D().DirectSpaceState.IntersectShape(query, 1);
		return result.Count == 0;
	}

	public override void _PhysicsProcess(double delta)
	{
		UpdateTimers(delta);

		_machine.CurrentState?.ProcessPhysics(delta);

		MoveAndSlide();

		ClampToCameraLeft();
		UpdateFacing();
		UpdateAnimation((float)delta);
	}

	public override void _Process(double delta)
	{
		_machine.CurrentState?.ProcessFrame(delta);
		UpdateCamera(delta);
	}

	private void UpdateCamera(double delta)
	{
		if (_camera == null) return;
		float target = FacingDirection * CameraLookAhead;
		_currentLookAhead = Mathf.Lerp(_currentLookAhead, target, (float)delta * 3.0f);
		_camera.Offset = new Vector2(_currentLookAhead, _camera.Offset.Y);

		int currentLeftEdge = (int)(_camera.GetScreenCenterPosition().X - ViewportHalfWidth);
		if (currentLeftEdge > _camera.LimitLeft)
		{
			_camera.LimitLeft = currentLeftEdge;
		}
	}

	private void ClampToCameraLeft()
	{
		if (_camera == null) return;
		float minX = _camera.LimitLeft + 8.0f;
		if (GlobalPosition.X < minX)
		{
			GlobalPosition = new Vector2(minX, GlobalPosition.Y);
			if (Velocity.X < 0)
			{
				Velocity = new Vector2(0, Velocity.Y);
			}
		}
	}

	private void UpdateTimers(double delta)
	{
		if (IsOnFloor())
		{
			CoyoteCounter = CoyoteTime;
		}
		else
		{
			CoyoteCounter = Mathf.Max(0, CoyoteCounter - (float)delta);
		}

		if (Input.IsActionJustPressed("jump"))
		{
			JumpBufferCounter = JumpBufferTime;
		}
		else
		{
			JumpBufferCounter = Mathf.Max(0, JumpBufferCounter - (float)delta);
		}
	}

	private void UpdateFacing()
	{
		if (Velocity.X > 1.0f) FacingDirection = 1;
		else if (Velocity.X < -1.0f) FacingDirection = -1;
		_visuals.Scale = new Vector2(FacingDirection, _visuals.Scale.Y);
	}

	private void UpdateAnimation(float delta)
	{
		_drawer.IsAirborne = !IsOnFloor();

		if (IsCrouching)
		{
			_walkAnimTime = 0;
			_drawer.AnimFrame = 0;
		}
		else if (!IsOnFloor())
		{
			_walkAnimTime = 0;
			_drawer.AnimFrame = 1;
		}
		else if (Mathf.Abs(Velocity.X) > 5.0f)
		{
			float speedScale = Mathf.Abs(Velocity.X) / WalkSpeed;
			_walkAnimTime += delta * Mathf.Max(1.0f, speedScale);
			int frame = (int)(_walkAnimTime / WalkFrameInterval) % 3;
			_drawer.AnimFrame = frame;
		}
		else
		{
			_walkAnimTime = 0;
			_drawer.AnimFrame = 0;
		}
		_drawer.QueueRedraw();
	}

	public void ApplyHorizontalAccel(double delta)
	{
		float input = 0;
		if (Input.IsActionPressed("move_right")) input += 1;
		if (Input.IsActionPressed("move_left")) input -= 1;

		bool airborne = !IsOnFloor();
		float maxSpeed = Input.IsActionPressed("run") ? RunSpeed : WalkSpeed;

		if (input != 0)
		{
			float target = input * maxSpeed;
			float accel;
			if (airborne)
			{
				accel = AirAcceleration;
			}
			else if (Velocity.X != 0 && Mathf.Sign(Velocity.X) != input)
			{
				accel = TurnAcceleration;
			}
			else
			{
				accel = Acceleration;
			}
			Velocity = new Vector2(
				Mathf.MoveToward(Velocity.X, target, accel * (float)delta),
				Velocity.Y);
		}
		else if (!airborne)
		{
			Velocity = new Vector2(
				Mathf.MoveToward(Velocity.X, 0, Deceleration * (float)delta),
				Velocity.Y);
		}
	}

	public void ApplyGravity(double delta)
	{
		float g = Velocity.Y < 0 ? Gravity : FastFallGravity;
		Velocity = new Vector2(
			Velocity.X,
			Mathf.MoveToward(Velocity.Y, MaxFallSpeed, g * (float)delta));
	}
}
