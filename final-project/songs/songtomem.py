from pathlib import Path

NUM_SONGS = 3
SONG_FILES = [Path(f"songs/song{i}.txt") for i in range(NUM_SONGS)]

# Song format: first line `BPM N`, then events `<type> <arg> <delta_ticks>`
def convert(text):
    lines = [l.strip() for l in text.splitlines() if l.strip()]
    if not lines:
        return ""
    header = lines[0].split()
    assert header[0] == "BPM", f"expected BPM header, got: {lines[0]!r}"
    bpm = int(header[1])
    ticks = 0
    out = []
    for line in lines[1:]:
        ev, arg, delta = line.split()
        ticks += int(delta)
        ms = round(ticks * 15000 / bpm)
        out.append(f"{ev} {arg} {ms}")
    return "\n".join(out) + "\n"

texts = []
for p in SONG_FILES:
    raw = p.read_text() if p.exists() else ""
    texts.append(convert(raw))

header_size = NUM_SONGS
offsets = []
body = []
pos = header_size

for text in texts:
    offsets.append(pos)
    for ch in text:
        body.append(f"{ord(ch):08x}")
        pos += 1
    body.append("00000000")  # per-song terminator (0 triggers done)
    pos += 1

with open("songs/song.mem", "w") as f:
    for off in offsets:
        f.write(f"{off:08x}\n")
    for w in body:
        f.write(f"{w}\n")
