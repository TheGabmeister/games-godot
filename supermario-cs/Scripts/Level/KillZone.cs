using Godot;

namespace supermariocs;

public partial class KillZone : Area2D
{
	public override void _Ready()
	{
		CollisionLayer = 1u << 8;  // layer 9
		CollisionMask = (1u << 1) | (1u << 2);  // mask Player (2) + Enemies (3)
		BodyEntered += OnBodyEntered;
	}

	private void OnBodyEntered(Node2D body)
	{
		if (body is PlayerController)
		{
			GetNode<GameManager>("/root/GameManager").LoseLife();
			GetNode<SceneManager>("/root/SceneManager").LoadLevel("res://scenes/levels/world_1_1.tscn");
		}
		else
		{
			body.QueueFree();
		}
	}
}
