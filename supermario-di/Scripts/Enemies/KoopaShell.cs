using Godot;

namespace SMB;

[Meta(typeof(IAutoNode))]
public partial class KoopaShell : CharacterBody2D, IStompable, IStarHittable
{
    [Export] public Walker Walker;
    [Export] public float KickSpeed = 280f;

    private bool _moving;

    [Dependency] public SfxManager Sfx => this.DependOn<SfxManager>();

    public override void _Notification(int what) => this.Notify(what);

    public override void _Ready()
    {
        Walker.Speed = 0f;
    }

    public void OnStomped(PlayerController player)
    {
        if (_moving)
        {
            Walker.Speed = 0f;
            _moving = false;
        }
        else
        {
            Walker.Speed = KickSpeed;
            Walker.Direction = player.GlobalPosition.X < GlobalPosition.X ? 1 : -1;
            _moving = true;
            Sfx.PlayKick();
        }
    }

    public void OnHitByStar(PlayerController _) => QueueFree();
}
