using System;
using Godot;

namespace SMB;

public partial class PlayerController : CharacterBody2D
{
    [Export] public float Speed = 280f;
    [Export] public float JumpForce = -680f;
    [Export] public float Gravity = 1200f;
    [Export] public float MaxFallSpeed = 600f;
    [Export] public float StompBounceForce = -420f;
    [Export] public float InvulnerableDuration = 2f;
    [Export] public float StarmanInvincibleDuration = 10f;
    [Export] public int MaxFireballs = 2;
    [Export] public int SmallWidth = 32;
    [Export] public int SmallHeight = 48;
    [Export] public int BigWidth = 32;
    [Export] public int BigHeight = 64;
    [Export] private AudioStream _jumpClip;
    [Export] private AudioStream _jumpBigClip;
    [Export] private AudioStream _fireballClip;
    [Export] private AudioStream _stompClip;
    [Export] private AudioStream _powerDownClip;
    [Export] private AudioStream _deathClip;

    public event Action Died;
    public event Action<PlayerPowerState> PowerStateChanged;
    public event Action<Vector2, int, PlayerController> FireballRequested;

    private static readonly StringName InputLeft = "move_left";
    private static readonly StringName InputRight = "move_right";
    private static readonly StringName InputJump = "jump";
    private static readonly StringName InputFire = "run"; // X / J -> fire when Fire power

    private ColorRect _visual;
    private CollisionShape2D _shape;
    private Blinker _blinker;
    private Marker2D _muzzle;
    private Vector2 _velocity;
    private int _facing = 1;
    private int _activeFireballs;
    private float _invulnTimer;
    private float _starTimer;
    private bool _dead;
    private PlayerPowerState _state = PlayerPowerState.Small;

    public PlayerPowerState State => _state;
    public bool IsStarInvincible => _starTimer > 0f;
    public bool IsInvulnerable => _invulnTimer > 0f;
    public bool CanBreakBricks => _state != PlayerPowerState.Small;

    public override void _Ready()
    {
        AddToGroup("player");

        _visual = GetNode<ColorRect>("Visual");
        _shape = GetNode<CollisionShape2D>("CollisionShape2D");
        _blinker = GetNode<Blinker>("Blinker");
        _blinker.Target = _visual;
        _muzzle = GetNode<Marker2D>("Muzzle");

        ApplyStateVisuals();
    }

    public void Initialize(PlayerPowerState initialState)
    {
        _state = initialState;
    }

    public override void _PhysicsProcess(double delta)
    {
        if (_dead) return;

        float dt = (float)delta;
        if (_invulnTimer > 0f) _invulnTimer -= dt;
        if (_starTimer > 0f) _starTimer -= dt;

        float axis = 0f;
        if (Input.IsActionPressed(InputLeft)) axis -= 1f;
        if (Input.IsActionPressed(InputRight)) axis += 1f;

        _velocity.X = axis * Speed;
        if (axis != 0f) _facing = axis > 0f ? 1 : -1;

        if (IsOnFloor() && Input.IsActionJustPressed(InputJump))
        {
            _velocity.Y = JumpForce;
            PlaySfx(_state == PlayerPowerState.Small ? _jumpClip : _jumpBigClip);
        }

        if (Input.IsActionJustPressed(InputFire) && _state == PlayerPowerState.Fire
            && _activeFireballs < MaxFireballs)
        {
            SpawnFireball();
        }

        _velocity.Y += Gravity * dt;
        if (_velocity.Y > MaxFallSpeed)
            _velocity.Y = MaxFallSpeed;

        Velocity = _velocity;
        MoveAndSlide();
        _velocity = Velocity;

        for (int i = 0; i < GetSlideCollisionCount(); i++)
        {
            var col = GetSlideCollision(i);
            var normal = col.GetNormal();
            if (normal.Y > 0.9f)
            {
                if (col.GetCollider() is IBumpable bumpable)
                    bumpable.OnBumped(this);
                _velocity.Y = 0f;
            }
        }
    }

    private void SpawnFireball()
    {
        PlaySfx(_fireballClip);
        FireballRequested?.Invoke(_muzzle.GlobalPosition, _facing, this);
        _activeFireballs++;
    }

    public void NotifyFireballDestroyed()
    {
        if (_activeFireballs > 0) _activeFireballs--;
    }

    public void ApplyMushroom()
    {
        if (_state != PlayerPowerState.Small) return;
        SetState(PlayerPowerState.Big);
    }

    public void ApplyFireFlower()
    {
        if (_state == PlayerPowerState.Fire) return;
        SetState(_state == PlayerPowerState.Small ? PlayerPowerState.Big : PlayerPowerState.Fire);
    }

    public void ApplyStarman()
    {
        _starTimer = StarmanInvincibleDuration;
    }

    public void TakeDamage()
    {
        if (_invulnTimer > 0f || _starTimer > 0f || _dead) return;

        if (_state == PlayerPowerState.Small)
        {
            KillPlayer();
            return;
        }

        SetState(PlayerPowerState.Small);
        PlaySfx(_powerDownClip);
        _invulnTimer = InvulnerableDuration;
        _blinker.Start(InvulnerableDuration);
    }

    public void KillPlayer()
    {
        if (_dead) return;
        _dead = true;
        PlaySfx(_deathClip);
        Died?.Invoke();
        QueueFree();
    }

    public bool TryStomp(IStompable stompable)
    {
        if (_velocity.Y <= 0f) return false;
        _velocity.Y = StompBounceForce;
        PlaySfx(_stompClip);
        stompable.OnStomped(this);
        return true;
    }

    private void SetState(PlayerPowerState newState)
    {
        _state = newState;
        PowerStateChanged?.Invoke(newState);
        ApplyStateVisuals();
    }

    private void ApplyStateVisuals()
    {
        int w, h;
        Color color;
        switch (_state)
        {
            case PlayerPowerState.Big:  w = BigWidth;   h = BigHeight;   color = new Color(0.85f, 0.10f, 0.10f); break;
            case PlayerPowerState.Fire: w = BigWidth;   h = BigHeight;   color = new Color(1.00f, 0.55f, 0.10f); break;
            default:                    w = SmallWidth; h = SmallHeight; color = new Color(0.85f, 0.10f, 0.10f); break;
        }

        _visual.Size = new Vector2(w, h);
        _visual.Position = new Vector2(-w / 2f, -h);
        _visual.Color = color;

        var rect = (RectangleShape2D)_shape.Shape;
        rect.Size = new Vector2(w, h);
        _shape.Position = new Vector2(0, -h / 2f);
    }
}
