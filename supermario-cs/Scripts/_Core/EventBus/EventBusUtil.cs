using System;
using System.Collections.Generic;
using System.Reflection;

namespace SMB.EventBus;

public static class EventBusUtil
{
    private const string ClearMethodName = "Clear";

    public static IReadOnlyList<Type> EventTypes { get; private set; } = Array.Empty<Type>();
    public static IReadOnlyList<Type> EventBusTypes { get; private set; } = Array.Empty<Type>();

    public static void Initialize()
    {
        EventTypes = EventTypeScanner.GetTypes(typeof(IEvent));
        EventBusTypes = InitializeAllBuses(EventTypes);
    }

    public static void ClearAllBuses()
    {
        EnsureInitialized();

        foreach (var busType in EventBusTypes)
        {
            var clearMethod = busType.GetMethod(
                ClearMethodName,
                BindingFlags.Static | BindingFlags.Public | BindingFlags.NonPublic);

            clearMethod?.Invoke(null, null);
        }
    }

    private static IReadOnlyList<Type> InitializeAllBuses(IReadOnlyList<Type> eventTypes)
    {
        var eventBusTypes = new List<Type>(eventTypes.Count);
        var genericBusType = typeof(Bus<>);

        foreach (var eventType in eventTypes)
            eventBusTypes.Add(genericBusType.MakeGenericType(eventType));

        return eventBusTypes;
    }

    private static void EnsureInitialized()
    {
        if (EventTypes.Count == 0 && EventBusTypes.Count == 0)
            Initialize();
    }
}
