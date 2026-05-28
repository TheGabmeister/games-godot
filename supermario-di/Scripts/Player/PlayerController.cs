using System;
using Godot;

namespace SMB;

[Meta(typeof(IAutoNode))]
public partial class PlayerController : CharacterBody2D
{
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

    [Dependency] public SfxManager Sfx => this.DependOn<SfxManager>();
    [Dependency] public PlayerTuning Tuning => this.DependOn<PlayerTuning>();

    public override void _Notification(int what) => this.Notify(what);

    public override void _Ready()
    {
        AddToGroup("player");
        CollisionLayer = PhysicsLayers.Player;
        CollisionMask = PhysicsLayers.Environment | PhysicsLayers.PickupTrigger | PhysicsLayers.LevelTrigger;

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

        _velocity.X = axis * Tuning.Speed;
        if (axis != 0f) _facing = axis > 0f ? 1 : -1;

        if (IsOnFloor() && Input.IsActionJustPressed(InputJump))
        {
            _velocity.Y = Tuning.JumpForce;
            Sfx.PlayPlayerJump(_state != PlayerPowerState.Small);
        }

        if (Input.IsActionJustPressed(InputFire) && _state == PlayerPowerState.Fire
            && _activeFireballs < Tuning.MaxFireballs)
        {
            SpawnFireball();
        }

        _velocity.Y += Tuning.Gravity * dt;
        if (_velocity.Y > Tuning.MaxFallSpeed)
            _velocity.Y = Tuning.MaxFallSpeed;

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
        FireballRequested?.Invoke(_muzzle.GlobalPosition, _facing, this);
        _activeFireballs++;
        Sfx.PlayFireball();
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
        _starTimer = Tuning.StarmanInvincibleDuration;
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
        Sfx.PlayPlayerPowerDown();
        _invulnTimer = Tuning.InvulnerabilityDuration;
        _blinker.Start(Tuning.InvulnerabilityDuration);
    }

    public void KillPlayer()
    {
        if (_dead) return;
        _dead = true;
        Sfx.PlayPlayerDeath();
        Died?.Invoke();
        QueueFree();
    }

    public bool TryStomp(IStompable stompable)
    {
        if (_velocity.Y <= 0f) return false;
        _velocity.Y = Tuning.StompBounceForce;
        stompable.OnStomped(this);
        Sfx.PlayPlayerStomp();
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
            case PlayerPowerState.Big:  w = Tuning.BigWidth;   h = Tuning.BigHeight;   color = new Color(0.85f, 0.10f, 0.10f); break;
            case PlayerPowerState.Fire: w = Tuning.BigWidth;   h = Tuning.BigHeight;   color = new Color(1.00f, 0.55f, 0.10f); break;
            default:                    w = Tuning.SmallWidth; h = Tuning.SmallHeight; color = new Color(0.85f, 0.10f, 0.10f); break;
        }

        _visual.Size = new Vector2(w, h);
        _visual.Position = new Vector2(-w / 2f, -h);
        _visual.Color = color;

        var rect = (RectangleShape2D)_shape.Shape;
        rect.Size = new Vector2(w, h);
        _shape.Position = new Vector2(0, -h / 2f);
    }
}
