using System;
using System.Collections.Generic;

namespace SMB.EventBus;

public static class Bus<T> where T : struct, IEvent
{
    private static readonly HashSet<Action> BindingsWithoutArgs = new();
    private static readonly HashSet<Action<T>> BindingsWithArgs = new();

    public static void Sub(Action<T> binding)
    {
        BindingsWithArgs.Add(binding);
    }

    public static void Sub(Action binding)
    {
        BindingsWithoutArgs.Add(binding);
    }

    public static void Unsub(Action<T> binding)
    {
        BindingsWithArgs.Remove(binding);
    }

    public static void Unsub(Action binding)
    {
        BindingsWithoutArgs.Remove(binding);
    }

    public static void Emit()
    {
        Emit(default);
    }

    public static void Emit(T @event)
    {
        foreach (var binding in BindingsWithArgs)
            binding?.Invoke(@event);

        foreach (var binding in BindingsWithoutArgs)
            binding?.Invoke();
    }

    public static void Clear()
    {
        BindingsWithArgs.Clear();
        BindingsWithoutArgs.Clear();
    }
}
