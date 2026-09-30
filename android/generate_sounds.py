#!/usr/bin/env python3
import math, struct, wave, os, random

OUT = "assets/sounds"
os.makedirs(OUT, exist_ok=True)

def write_wav(path, samples, rate=22050):
    with wave.open(path, "w") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(rate)
        frames = b"".join(
            struct.pack("<h", max(-32767, min(32767, int(s * 32767))))
            for s in samples
        )
        w.writeframes(frames)

def tone(freq, dur, rate=22050, vol=0.35, decay=True):
    n = int(rate * dur)
    out = []
    for i in range(n):
        t = i / rate
        env = (1 - t / dur) if decay else 0.85
        out.append(vol * env * math.sin(2 * math.pi * freq * t))
    return out

def noise(dur, rate=22050, vol=0.25):
    n = int(rate * dur)
    out = []
    for i in range(n):
        t = i / rate
        env = 1 - t / dur
        out.append(vol * env * (random.random() * 2 - 1))
    return out

write_wav(f"{OUT}/shoot.wav", noise(0.08, vol=0.4) + tone(180, 0.05, vol=0.2))
write_wav(f"{OUT}/melee.wav", tone(420, 0.06, vol=0.3) + tone(280, 0.08, vol=0.25))
write_wav(f"{OUT}/click.wav", tone(660, 0.04, vol=0.2))

bg = []
for _ in range(8):
    bg += tone(55, 0.4, vol=0.12, decay=False)
    bg += tone(73, 0.4, vol=0.10, decay=False)
    bg += tone(82, 0.4, vol=0.11, decay=False)
    bg += tone(55, 0.4, vol=0.12, decay=False)
write_wav(f"{OUT}/bgm.wav", bg)

print("OK:", OUT)
for f in os.listdir(OUT):
    print(" ", f)
