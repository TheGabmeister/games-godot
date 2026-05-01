from __future__ import annotations

import argparse
import subprocess
from pathlib import Path

from midiutil import MIDIFile


ROOT = Path(__file__).resolve().parents[2]
OUT_DIR = ROOT / "music"
MIDI_PATH = OUT_DIR / "battle.mid"
WAV_PATH = OUT_DIR / "battle.wav"
OGG_PATH = OUT_DIR / "battle.ogg"

FLUIDSYNTH = Path("D:/fluidsynth-v2.5.4-win10-x64-cpp11/bin/fluidsynth.exe")
FFMPEG = Path("D:/ffmpeg-8.1-essentials_build/bin/ffmpeg.exe")
SOUNDFONT = Path("D:/GeneralUser-GS/GeneralUser-GS.sf2")

BPM = 172
BEATS_PER_BAR = 4
LOOP_BARS = 16


NOTE_NAMES = {
    "C": 0,
    "C#": 1,
    "Db": 1,
    "D": 2,
    "D#": 3,
    "Eb": 3,
    "E": 4,
    "F": 5,
    "F#": 6,
    "Gb": 6,
    "G": 7,
    "G#": 8,
    "Ab": 8,
    "A": 9,
    "A#": 10,
    "Bb": 10,
    "B": 11,
}


def note(name: str) -> int:
    pitch = name[:-1]
    octave = int(name[-1])
    return 12 * (octave + 1) + NOTE_NAMES[pitch]


def add_note(midi: MIDIFile, track: int, channel: int, name: str, time: float, duration: float, volume: int) -> None:
    midi.addNote(track, channel, note(name), time, duration, volume)


def add_chord(midi: MIDIFile, track: int, channel: int, names: list[str], time: float, duration: float, volume: int) -> None:
    for name in names:
        add_note(midi, track, channel, name, time, duration, volume)


def bar(index: int) -> int:
    return index * BEATS_PER_BAR


def build_midi() -> MIDIFile:
    midi = MIDIFile(7, adjust_origin=False, removeDuplicates=True)
    names = ["Pulse Bass", "Low Strings", "Hero Lead", "Answer Lead", "Brass Hits", "Timpani", "Drums"]

    for track, name in enumerate(names):
        midi.addTrackName(track, 0, name)
        midi.addTempo(track, 0, BPM)

    midi.addProgramChange(0, 0, 0, 38)  # Synth Bass 1
    midi.addProgramChange(1, 1, 0, 48)  # String Ensemble 1
    midi.addProgramChange(2, 2, 0, 80)  # Lead 1 square
    midi.addProgramChange(3, 3, 0, 81)  # Lead 2 saw
    midi.addProgramChange(4, 4, 0, 61)  # Brass Section
    midi.addProgramChange(5, 5, 0, 47)  # Timpani

    add_bass(midi)
    add_strings(midi)
    add_leads(midi)
    add_brass(midi)
    add_timpani(midi)
    add_drums(midi)
    return midi


def add_bass(midi: MIDIFile) -> None:
    roots = ["D2", "D2", "Bb1", "C2", "D2", "D2", "Bb1", "A1", "G1", "Bb1", "F1", "C2", "D2", "Bb1", "C2", "D2"]
    fifths = {"D2": "A2", "Bb1": "F2", "C2": "G2", "A1": "E2", "G1": "D2", "F1": "C2"}
    for i, root in enumerate(roots):
        start = bar(i)
        pattern = [root, root, fifths[root], root, root, fifths[root], root, fifths[root]]
        for step, pitch in enumerate(pattern):
            add_note(midi, 0, 0, pitch, start + step * 0.5, 0.42, 92 if step in (0, 4) else 76)


def add_strings(midi: MIDIFile) -> None:
    chords = [
        ["D3", "A3", "F4"],
        ["D3", "A3", "E4"],
        ["Bb2", "F3", "D4"],
        ["C3", "G3", "E4"],
        ["D3", "A3", "F4"],
        ["F3", "A3", "E4"],
        ["Bb2", "F3", "D4"],
        ["A2", "E3", "C#4"],
        ["G2", "D3", "Bb3"],
        ["Bb2", "F3", "D4"],
        ["F2", "C3", "A3"],
        ["C3", "G3", "E4"],
        ["D3", "A3", "F4"],
        ["Bb2", "F3", "D4"],
        ["C3", "G3", "E4"],
        ["D3", "A3", "F4"],
    ]
    for i, chord in enumerate(chords):
        start = bar(i)
        add_chord(midi, 1, 1, chord, start, 1.85, 58)
        add_chord(midi, 1, 1, chord, start + 2.0, 1.85, 64)


def add_leads(midi: MIDIFile) -> None:
    motif = [
        ("D5", 0.0, 0.5),
        ("F5", 0.5, 0.5),
        ("G5", 1.0, 0.5),
        ("A5", 1.5, 0.5),
        ("C6", 2.0, 0.75),
        ("A5", 2.75, 0.25),
        ("G5", 3.0, 0.5),
        ("F5", 3.5, 0.5),
    ]
    answer = [
        ("A4", 0.0, 0.5),
        ("C5", 0.5, 0.5),
        ("D5", 1.0, 0.5),
        ("F5", 1.5, 0.5),
        ("E5", 2.0, 0.5),
        ("D5", 2.5, 0.5),
        ("C5", 3.0, 0.5),
        ("A4", 3.5, 0.5),
    ]

    for phrase in (0, 4, 8, 12):
        for pitch, offset, duration in motif:
            add_note(midi, 2, 2, pitch, bar(phrase) + offset, duration, 102)
        for pitch, offset, duration in answer:
            add_note(midi, 3, 3, pitch, bar(phrase + 1) + offset, duration, 86)

    climb = ["D5", "E5", "F5", "G5", "A5", "C6", "D6", "E6"]
    for step, pitch in enumerate(climb):
        add_note(midi, 2, 2, pitch, bar(14) + step * 0.5, 0.42, 104 + min(step * 2, 14))
    add_note(midi, 2, 2, "D6", bar(15), 1.5, 118)
    add_note(midi, 2, 2, "A5", bar(15) + 1.5, 0.5, 108)
    add_note(midi, 2, 2, "F5", bar(15) + 2.0, 0.5, 104)
    add_note(midi, 2, 2, "E5", bar(15) + 2.5, 0.5, 104)
    add_note(midi, 2, 2, "D5", bar(15) + 3.0, 1.0, 116)


def add_brass(midi: MIDIFile) -> None:
    hits = [
        (0, ["D4", "A4", "D5"]),
        (2, ["Bb3", "F4", "Bb4"]),
        (3, ["C4", "G4", "C5"]),
        (4, ["D4", "A4", "D5"]),
        (6, ["Bb3", "F4", "Bb4"]),
        (7, ["A3", "E4", "A4"]),
        (8, ["G3", "D4", "G4"]),
        (10, ["F3", "C4", "F4"]),
        (12, ["D4", "A4", "D5"]),
        (13, ["Bb3", "F4", "Bb4"]),
        (14, ["C4", "G4", "C5"]),
        (15, ["D4", "A4", "D5"]),
    ]
    for bar_index, chord in hits:
        add_chord(midi, 4, 4, chord, bar(bar_index), 0.72, 94)
        add_chord(midi, 4, 4, chord, bar(bar_index) + 2.5, 0.38, 86)
        add_chord(midi, 4, 4, chord, bar(bar_index) + 3.0, 0.38, 92)


def add_timpani(midi: MIDIFile) -> None:
    for i in range(LOOP_BARS):
        root = "D2" if i not in (2, 6, 8, 10, 13) else "Bb1"
        if i == 7:
            root = "A1"
        if i == 11 or i == 14:
            root = "C2"
        add_note(midi, 5, 5, root, bar(i), 0.35, 82)
        add_note(midi, 5, 5, root, bar(i) + 2.0, 0.35, 72)
    for offset in [2.5, 2.75, 3.0, 3.25, 3.5, 3.75]:
        add_note(midi, 5, 5, "D2", bar(15) + offset, 0.18, 88)


def add_drums(midi: MIDIFile) -> None:
    drum_track = 6
    drum_channel = 9
    kick = 36
    snare = 38
    closed_hat = 42
    open_hat = 46
    crash = 49
    low_tom = 45
    mid_tom = 47
    high_tom = 50

    for i in range(LOOP_BARS):
        start = bar(i)
        for beat_offset in [0, 1.5, 2.0, 3.5]:
            midi.addNote(drum_track, drum_channel, kick, start + beat_offset, 0.1, 96)
        for beat_offset in [1.0, 3.0]:
            midi.addNote(drum_track, drum_channel, snare, start + beat_offset, 0.1, 92)
        for step in range(8):
            midi.addNote(drum_track, drum_channel, closed_hat, start + step * 0.5, 0.08, 54 if step % 2 else 66)
        if i % 4 == 0:
            midi.addNote(drum_track, drum_channel, crash, start, 0.6, 84)

    fill_start = bar(15) + 2.0
    for index, drum in enumerate([low_tom, low_tom, mid_tom, mid_tom, high_tom, high_tom, snare, crash]):
        midi.addNote(drum_track, drum_channel, drum, fill_start + index * 0.25, 0.12, 94 + index * 3)
    midi.addNote(drum_track, drum_channel, open_hat, bar(15) + 3.5, 0.35, 86)


def run(command: list[str]) -> None:
    subprocess.run(command, cwd=ROOT, check=True)


def render_audio(skip_external: bool = False) -> None:
    OUT_DIR.mkdir(exist_ok=True)
    midi = build_midi()
    with MIDI_PATH.open("wb") as output:
        midi.writeFile(output)

    if skip_external:
        return

    run([
        str(FLUIDSYNTH),
        "-ni",
        "-F",
        str(WAV_PATH),
        "-r",
        "44100",
        str(SOUNDFONT),
        str(MIDI_PATH),
    ])
    run([
        str(FFMPEG),
        "-y",
        "-i",
        str(WAV_PATH),
        "-c:a",
        "libvorbis",
        "-q:a",
        "6",
        str(OGG_PATH),
    ])


def main() -> None:
    parser = argparse.ArgumentParser(description="Generate the Phase 2 battle theme.")
    parser.add_argument("--midi-only", action="store_true", help="Only write music/battle.mid.")
    args = parser.parse_args()
    render_audio(skip_external=args.midi_only)
    print(f"Wrote {MIDI_PATH.relative_to(ROOT)}")
    if not args.midi_only:
        print(f"Wrote {WAV_PATH.relative_to(ROOT)}")
        print(f"Wrote {OGG_PATH.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
