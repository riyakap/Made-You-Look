#!/usr/bin/env python3
"""Synthesizes the app's UI sounds (original, royalty-free) into MadeYouLook/Sounds/."""
import math
import struct
import wave
from pathlib import Path

RATE = 44100
OUT = Path(__file__).resolve().parent.parent / "MadeYouLook" / "Sounds"


def bell(freq, start, length, volume=1.0, decay=7.0):
    """A soft bell: fundamental plus a few inharmonic partials with exponential decay."""
    partials = [(1.0, 1.0), (2.0, 0.35), (3.01, 0.12), (4.2, 0.05)]
    samples = {}
    for i in range(int(length * RATE)):
        t = i / RATE
        attack = min(1.0, t / 0.004)  # 4 ms fade-in avoids a click
        env = attack * math.exp(-decay * t)
        value = sum(a * math.sin(2 * math.pi * freq * m * t) for m, a in partials)
        samples[int(start * RATE) + i] = volume * env * value
    return samples


def render(name, notes, total):
    mix = [0.0] * int(total * RATE)
    for note in notes:
        for index, value in bell(*note).items():
            if index < len(mix):
                mix[index] += value
    peak = max(abs(v) for v in mix) or 1
    fade = int(0.02 * RATE)  # fade the tail to silence
    frames = b"".join(
        struct.pack("<h", int(32767 * 0.8 * v / peak * min(1.0, (len(mix) - i) / fade)))
        for i, v in enumerate(mix)
    )
    OUT.mkdir(parents=True, exist_ok=True)
    with wave.open(str(OUT / f"{name}.wav"), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(frames)
    print(f"wrote {name}.wav ({total:.2f}s)")


# Save: a single soft, high "ding" (C6).
render("ding_save", [(1046.5, 0.0, 0.6, 1.0, 7.5)], 0.6)
# Add to bag: a bright rising two-note chime (E6 -> A6).
render("ding_bag", [(1318.5, 0.0, 0.5, 0.8, 8.0), (1760.0, 0.09, 0.6, 1.0, 7.0)], 0.7)
