using System;
using System.Collections.Generic;
using Godot;

namespace SuperMario;

public partial class LevelBase : Node2D
{
    public event Action<int> ScoreEarned;
    public event Action<int> CoinsCollected;

    [Export] public Marker2D PlayerStart;
    [Export] public GoalTrigger GoalTrigger;

    private readonly HashSet<Node> _wiredEventSources = new();

    public override void _Ready()
    {
        if (PlayerStart == null)
            throw new InvalidOperationException($"{nameof(LevelBase)} requires {nameof(PlayerStart)} to be assigned in the editor.");

        if (GoalTrigger == null)
            throw new InvalidOperationException($"{nameof(LevelBase)} requires {nameof(GoalTrigger)} to be assigned in the editor.");

        WireEventSources(this);
        SpawnCoinMarkers();
    }

    private void SpawnCoinMarkers()
    {
        var markers = new List<CoinMarker>();
        CollectCoinMarkers(this, markers);

        foreach (var marker in markers)
        {
            var coin = Coin.Create(marker.GlobalPosition);
            AddRuntimeEntity(coin);
        }
    }

    private static void CollectCoinMarkers(Node root, List<CoinMarker> markers)
    {
        foreach (var child in root.GetChildren())
        {
            if (child is CoinMarker marker)
                markers.Add(marker);

            CollectCoinMarkers(child, markers);
        }
    }

    private void AddRuntimeEntity(Node entity)
    {
        AddChild(entity);
        WireEventSources(entity);
    }

    private void OnChildEnteredTree(Node child)
    {
        WireEventSources(child);
    }

    private void WireEventSources(Node root)
    {
        if (!_wiredEventSources.Add(root)) return;
        root.ChildEnteredTree += OnChildEnteredTree;

        if (root is IScoreEventSource scoreSource)
            scoreSource.ScoreEarned += points => ScoreEarned?.Invoke(points);

        if (root is ICoinEventSource coinSource)
            coinSource.CoinCollected += coins => CoinsCollected?.Invoke(coins);

        foreach (var child in root.GetChildren())
            WireEventSources(child);
    }
}
