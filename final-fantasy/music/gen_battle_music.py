"""Generate FF1-style 8-bit battle, victory, and game over music as MIDI files."""
from midiutil import MIDIFile

BPM_BATTLE = 160
BPM_VICTORY = 140
BPM_GAMEOVER = 60


def create_battle_theme():
    """Energetic 8-bit battle theme, uptempo loop."""
    midi = MIDIFile(3)
    track_melody = 0
    track_harmony = 1
    track_bass = 2
    for t in range(3):
        midi.addTempo(t, 0, BPM_BATTLE)
    midi.addProgramChange(track_melody, 0, 0, 80)   # Square lead
    midi.addProgramChange(track_harmony, 1, 0, 80)   # Square harmony
    midi.addProgramChange(track_bass, 2, 0, 81)      # Square bass

    # Aggressive melody in D minor — driving, urgent
    melody = [
        # Intro riff
        (74, 0.25), (74, 0.25), (72, 0.25), (74, 0.25),
        (77, 0.5), (74, 0.5), (72, 0.5), (69, 0.5),
        (74, 0.25), (74, 0.25), (72, 0.25), (74, 0.25),
        (79, 0.5), (77, 0.5), (74, 0.5), (72, 0.5),
        # A section — ascending urgency
        (62, 0.5), (65, 0.5), (69, 0.5), (72, 0.5),
        (74, 0.25), (72, 0.25), (74, 0.5), (77, 1.0),
        (74, 0.5), (72, 0.5), (69, 0.5), (65, 0.5),
        (67, 0.5), (69, 0.5), (72, 1.0),
        # B section — tension
        (77, 0.5), (79, 0.5), (77, 0.5), (74, 0.5),
        (72, 0.25), (74, 0.25), (72, 0.25), (69, 0.25), (67, 1.0),
        (69, 0.5), (72, 0.5), (74, 0.5), (77, 0.5),
        (79, 1.0), (77, 0.5), (74, 0.5),
        # Climax riff
        (74, 0.25), (77, 0.25), (79, 0.25), (82, 0.25),
        (81, 0.5), (79, 0.5), (77, 0.5), (74, 0.5),
        (72, 0.5), (69, 0.5), (74, 1.0),
        (0, 1.0),
    ]

    t = 0.0
    for note, dur in melody:
        if note > 0:
            midi.addNote(track_melody, 0, note, t, dur * 0.85, 100)
        t += dur

    # Driving bass — eighth note pulse
    bass_pattern = [
        (38, 0.5), (38, 0.5), (38, 0.5), (38, 0.5),
        (41, 0.5), (41, 0.5), (41, 0.5), (41, 0.5),
        (36, 0.5), (36, 0.5), (36, 0.5), (36, 0.5),
        (43, 0.5), (43, 0.5), (43, 0.5), (43, 0.5),
    ]

    total_dur = sum(d for _, d in melody)
    t = 0.0
    while t < total_dur:
        for note, dur in bass_pattern:
            if t >= total_dur:
                break
            midi.addNote(track_bass, 2, note, t, dur * 0.8, 90)
            midi.addNote(track_bass, 2, note + 12, t, dur * 0.8, 70)
            t += dur

    # Harmony — power chords on strong beats
    harmony_chords = [
        (62, 65, 2.0), (65, 69, 2.0), (60, 64, 2.0), (67, 72, 2.0),
        (62, 65, 2.0), (65, 69, 2.0), (60, 64, 2.0), (67, 72, 2.0),
        (65, 69, 2.0), (67, 72, 2.0), (62, 65, 2.0), (60, 64, 2.0),
        (65, 69, 1.0), (67, 72, 1.0), (62, 65, 2.0), (62, 65, 1.0),
    ]

    t = 0.0
    for n1, n2, dur in harmony_chords:
        if t >= total_dur:
            break
        midi.addNote(track_harmony, 1, n1, t, dur * 0.9, 75)
        midi.addNote(track_harmony, 1, n2, t, dur * 0.9, 75)
        t += dur

    with open("c:/dev/games-godot/final-fantasy/music/battle_theme.mid", "wb") as f:
        midi.writeFile(f)
    print("Created battle_theme.mid")


def create_victory_fanfare():
    """Triumphant FF-style victory jingle."""
    midi = MIDIFile(2)
    track_melody = 0
    track_bass = 1
    midi.addTempo(track_melody, 0, BPM_VICTORY)
    midi.addTempo(track_bass, 0, BPM_VICTORY)
    midi.addProgramChange(track_melody, 0, 0, 80)
    midi.addProgramChange(track_bass, 1, 0, 81)

    # Classic FF victory fanfare in Bb major
    melody = [
        # Opening triplet fanfare
        (70, 0.33), (70, 0.33), (70, 0.34), (70, 1.0),
        (68, 0.33), (68, 0.33), (68, 0.34), (68, 1.0),
        (69, 0.33), (69, 0.33), (69, 0.34), (69, 1.0),
        (70, 2.0),
        # Triumphant melody
        (70, 0.5), (0, 0.5), (70, 0.25), (72, 0.25), (74, 0.25), (75, 0.25),
        (77, 1.5), (74, 0.5), (77, 2.0),
    ]

    t = 0.0
    for note, dur in melody:
        if note > 0:
            midi.addNote(track_melody, 0, note, t, dur * 0.9, 100)
        t += dur

    # Bass support
    bass = [
        (46, 1.0), (46, 1.0), (44, 1.0), (44, 1.0),
        (45, 1.0), (45, 1.0), (46, 2.0),
        (46, 1.0), (46, 1.0), (53, 1.0), (53, 1.0),
    ]

    t = 0.0
    for note, dur in bass:
        if note > 0:
            midi.addNote(track_bass, 1, note, t, dur * 0.9, 85)
        t += dur

    with open("c:/dev/games-godot/final-fantasy/music/victory_fanfare.mid", "wb") as f:
        midi.writeFile(f)
    print("Created victory_fanfare.mid")


def create_game_over_theme():
    """Somber, melancholic game over theme."""
    midi = MIDIFile(2)
    track_melody = 0
    track_bass = 1
    midi.addTempo(track_melody, 0, BPM_GAMEOVER)
    midi.addTempo(track_bass, 0, BPM_GAMEOVER)
    midi.addProgramChange(track_melody, 0, 0, 80)
    midi.addProgramChange(track_bass, 1, 0, 81)

    # Slow, descending melody in C minor
    melody = [
        (72, 2.0), (71, 1.0), (69, 1.0),
        (67, 2.0), (65, 1.0), (63, 1.0),
        (60, 2.0), (63, 1.0), (60, 1.0),
        (58, 3.0), (0, 1.0),
        (60, 2.0), (58, 1.0), (55, 1.0),
        (48, 4.0),
    ]

    t = 0.0
    for note, dur in melody:
        if note > 0:
            midi.addNote(track_melody, 0, note, t, dur * 0.95, 70)
        t += dur

    # Slow bass — sustained notes
    bass = [
        (48, 4.0), (43, 4.0),
        (36, 4.0), (34, 4.0),
        (36, 4.0), (36, 4.0),
    ]

    t = 0.0
    for note, dur in bass:
        if note > 0:
            midi.addNote(track_bass, 1, note, t, dur * 0.95, 60)
            midi.addNote(track_bass, 1, note + 12, t, dur * 0.95, 45)
        t += dur

    with open("c:/dev/games-godot/final-fantasy/music/game_over.mid", "wb") as f:
        midi.writeFile(f)
    print("Created game_over.mid")


if __name__ == "__main__":
    create_battle_theme()
    create_victory_fanfare()
    create_game_over_theme()
    print("All battle music MIDI files generated.")
