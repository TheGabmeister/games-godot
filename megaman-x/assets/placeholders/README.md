# Placeholder Conventions

Phase 1 placeholders are intentionally flat and readable so scene wiring can stabilize before final art arrives.

- Keep placeholder files in SVG where possible for easy resizing during early iteration.
- Use lowercase snake case names with a role and footprint, such as `test_floor_256x32.svg`.
- Build stage backdrops and UI mockups against the current `1280x720` presentation target unless a fixture is intentionally narrower.
- Reserve cool blues for UI and neutral steel tones for shared stage geometry.
- Spawn points, anchor markers, and debug affordances should stay visually distinct from gameplay solids.
- Keep collision authored in scenes and scripts, not baked into placeholder artwork.
