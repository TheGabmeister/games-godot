"""Generate FF1-style 8-bit music tracks as MIDI files."""
from midiutil import MIDIFile

BPM_PRELUDE = 90
BPM_TOWN = 100
BPM_CASTLE = 80


def create_title_theme():
    """Majestic, hopeful FF prelude-style arpeggio theme."""
    midi = MIDIFile(2)
    # Channel 0: Arpeggio melody (Square wave - Program 80)
    # Channel 1: Bass (Program 81)
    track_melody = 0
    track_bass = 1
    midi.addTempo(track_melody, 0, BPM_PRELUDE)
    midi.addTempo(track_bass, 0, BPM_PRELUDE)
    midi.addProgramChange(track_melody, 0, 0, 80)
    midi.addProgramChange(track_bass, 1, 0, 81)

    # Classic FF prelude: ascending arpeggios in C major / Am
    arp_patterns = [
        # C major arpeggio
        [60, 64, 67, 72, 76, 79, 84, 79, 76, 72, 67, 64],
        # Am arpeggio
        [57, 60, 64, 69, 72, 76, 81, 76, 72, 69, 64, 60],
        # F major arpeggio
        [53, 57, 60, 65, 69, 72, 77, 72, 69, 65, 60, 57],
        # G major arpeggio
        [55, 59, 62, 67, 71, 74, 79, 74, 71, 67, 62, 59],
        # C major high
        [60, 64, 67, 72, 76, 79, 84, 88, 84, 79, 76, 72],
        # Em arpeggio
        [52, 55, 59, 64, 67, 71, 76, 71, 67, 64, 59, 55],
        # F major
        [53, 57, 60, 65, 69, 72, 77, 72, 69, 65, 60, 57],
        # G -> C resolve
        [55, 59, 62, 67, 71, 74, 72, 67, 64, 60, 64, 67],
    ]

    bass_notes = [48, 45, 41, 43, 48, 40, 41, 43]

    t = 0.0
    note_dur = 0.25
    for i, pattern in enumerate(arp_patterns):
        # Bass: whole note per pattern
        midi.addNote(track_bass, 1, bass_notes[i], t, len(pattern) * note_dur, 80)
        midi.addNote(track_bass, 1, bass_notes[i] + 12, t, len(pattern) * note_dur, 60)
        for note in pattern:
            midi.addNote(track_melody, 0, note, t, note_dur * 0.9, 90)
            t += note_dur

    with open("c:/dev/games-godot/final-fantasy/assets/music/title_theme.mid", "wb") as f:
        midi.writeFile(f)
    print("Created title_theme.mid")


def create_town_theme():
    """Peaceful, medieval town atmosphere."""
    midi = MIDIFile(3)
    track_melody = 0
    track_harmony = 1
    track_bass = 2
    for t in range(3):
        midi.addTempo(t, 0, BPM_TOWN)
    midi.addProgramChange(track_melody, 0, 0, 80)   # Square
    midi.addProgramChange(track_harmony, 1, 0, 80)   # Square
    midi.addProgramChange(track_bass, 2, 0, 81)      # Square bass

    # Melody: gentle, pastoral
    melody = [
        (67, 1.0), (69, 0.5), (71, 0.5), (72, 1.0), (71, 0.5), (69, 0.5),
        (67, 1.5), (64, 0.5), (62, 1.0), (64, 1.0),
        (67, 1.0), (69, 0.5), (71, 0.5), (72, 1.0), (74, 0.5), (76, 0.5),
        (74, 1.5), (72, 0.5), (71, 1.0), (69, 1.0),
        # B section
        (72, 1.0), (74, 0.5), (76, 0.5), (77, 1.0), (76, 0.5), (74, 0.5),
        (72, 1.5), (69, 0.5), (67, 1.0), (69, 1.0),
        (67, 1.0), (64, 0.5), (62, 0.5), (64, 1.0), (67, 0.5), (69, 0.5),
        (67, 2.0), (0, 1.0),  # rest
    ]

    t = 0.0
    for note, dur in melody:
        if note > 0:
            midi.addNote(track_melody, 0, note, t, dur * 0.9, 85)
        t += dur

    # Harmony: thirds below melody (simplified)
    harmony = [
        (64, 1.0), (65, 0.5), (67, 0.5), (69, 1.0), (67, 0.5), (65, 0.5),
        (64, 1.5), (60, 0.5), (59, 1.0), (60, 1.0),
        (64, 1.0), (65, 0.5), (67, 0.5), (69, 1.0), (71, 0.5), (72, 0.5),
        (71, 1.5), (69, 0.5), (67, 1.0), (65, 1.0),
        (69, 1.0), (71, 0.5), (72, 0.5), (74, 1.0), (72, 0.5), (71, 0.5),
        (69, 1.5), (65, 0.5), (64, 1.0), (65, 1.0),
        (64, 1.0), (60, 0.5), (59, 0.5), (60, 1.0), (64, 0.5), (65, 0.5),
        (64, 2.0), (0, 1.0),
    ]

    t = 0.0
    for note, dur in harmony:
        if note > 0:
            midi.addNote(track_harmony, 1, note, t, dur * 0.9, 65)
        t += dur

    # Bass: root notes, 2 beats each
    bass = [
        (48, 2.0), (45, 2.0), (43, 2.0), (48, 2.0),
        (48, 2.0), (45, 2.0), (43, 2.0), (41, 2.0),
        (48, 2.0), (50, 2.0), (53, 2.0), (48, 2.0),
        (48, 2.0), (43, 2.0), (48, 2.0), (48, 1.0), (0, 1.0),
    ]

    t = 0.0
    for note, dur in bass:
        if note > 0:
            midi.addNote(track_bass, 2, note, t, dur * 0.9, 75)
        t += dur

    with open("c:/dev/games-godot/final-fantasy/assets/music/town_theme.mid", "wb") as f:
        midi.writeFile(f)
    print("Created town_theme.mid")


def create_castle_theme():
    """Regal, grand castle theme."""
    midi = MIDIFile(3)
    track_melody = 0
    track_harmony = 1
    track_bass = 2
    for t in range(3):
        midi.addTempo(t, 0, BPM_CASTLE)
    midi.addProgramChange(track_melody, 0, 0, 80)
    midi.addProgramChange(track_harmony, 1, 0, 80)
    midi.addProgramChange(track_bass, 2, 0, 81)

    # Regal melody in Bb major
    melody = [
        (70, 1.5), (0, 0.5), (70, 0.5), (72, 0.5), (74, 1.0),
        (77, 1.5), (0, 0.5), (77, 0.5), (74, 0.5), (72, 1.0),
        (70, 1.0), (74, 1.0), (77, 1.0), (79, 1.0),
        (82, 2.0), (79, 1.0), (77, 1.0),
        # B section - descending grandeur
        (79, 1.5), (0, 0.5), (79, 0.5), (77, 0.5), (74, 1.0),
        (72, 1.5), (0, 0.5), (72, 0.5), (74, 0.5), (70, 1.0),
        (70, 1.0), (67, 1.0), (65, 1.0), (67, 1.0),
        (70, 3.0), (0, 1.0),
    ]

    t = 0.0
    for note, dur in melody:
        if note > 0:
            midi.addNote(track_melody, 0, note, t, dur * 0.9, 90)
        t += dur

    # Harmony: fifths and thirds
    harmony = [
        (65, 1.5), (0, 0.5), (65, 0.5), (67, 0.5), (70, 1.0),
        (74, 1.5), (0, 0.5), (74, 0.5), (70, 0.5), (67, 1.0),
        (65, 1.0), (70, 1.0), (74, 1.0), (74, 1.0),
        (77, 2.0), (74, 1.0), (72, 1.0),
        (74, 1.5), (0, 0.5), (74, 0.5), (72, 0.5), (70, 1.0),
        (67, 1.5), (0, 0.5), (67, 0.5), (70, 0.5), (65, 1.0),
        (65, 1.0), (62, 1.0), (60, 1.0), (62, 1.0),
        (65, 3.0), (0, 1.0),
    ]

    t = 0.0
    for note, dur in harmony:
        if note > 0:
            midi.addNote(track_harmony, 1, note, t, dur * 0.9, 70)
        t += dur

    # Bass: stately half notes
    bass = [
        (46, 2.0), (46, 2.0), (53, 2.0), (53, 2.0),
        (46, 2.0), (51, 2.0), (53, 2.0), (53, 2.0),
        (51, 2.0), (51, 2.0), (48, 2.0), (48, 2.0),
        (46, 2.0), (43, 2.0), (46, 2.0), (46, 2.0),
    ]

    t = 0.0
    for note, dur in bass:
        if note > 0:
            midi.addNote(track_bass, 2, note, t, dur * 0.9, 80)
        t += dur

    with open("c:/dev/games-godot/final-fantasy/assets/music/castle_theme.mid", "wb") as f:
        midi.writeFile(f)
    print("Created castle_theme.mid")


if __name__ == "__main__":
    create_title_theme()
    create_town_theme()
    create_castle_theme()
    print("All MIDI files generated.")
