namespace SuperMario;

public enum FireballReaction
{
    Defeated,
    Blocked
}

public interface IFireballHittable
{
    FireballReaction OnHitByFireball();
}
