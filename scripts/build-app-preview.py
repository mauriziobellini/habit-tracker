#!/usr/bin/env python3
"""Cuts and titles the App Store app preview from the raw screen recording.

Reads `build/app-preview/raw.mov` plus the cut points that
`scripts/record-app-preview.sh` wrote, renders the title cards, and assembles
the final video: motivational cards, five feature segments with captions, and
cross-fades throughout.

Everything is composed at the recording's native 1320x2868 and delivered at
886x1920, which is the size App Store Connect accepts for an iPhone app
preview. Note that this is *not* the screenshot size for the same devices —
uploading 1320x2868 is rejected with "the dimensions of one or more app
previews are incorrect".

30fps, H.264 High, under Apple's 30-second ceiling, with the silent audio
track App Store Connect expects.

Environment:
    SYNC_OFFSET   seconds added to every cut point, to correct for screen
                  recording start-up latency without re-recording (default 0).
"""

import os
import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
WORK = ROOT / "build" / "app-preview"
ART = WORK / "art"
CLIPS = WORK / "clips"
RAW = WORK / "raw.mov"
MARKS = WORK / "marks.txt"
MASTER = WORK / "master.mp4"
OUTPUT = ROOT / "marketing" / "app-preview-886x1920.mp4"

WIDTH, HEIGHT, FPS = 1320, 2868, 30
# App Store Connect's iPhone app preview size. Very slightly wider than the
# recording (0.4615 against 0.4602), so the master is scaled to width and the
# five surplus rows are trimmed off — a squash to fit would be invisible too,
# but there is no reason to introduce one.
DELIVERY_WIDTH, DELIVERY_HEIGHT = 886, 1920
XFADE = 0.4

# Each feature segment: the pair of cut points that bracket it, the caption laid
# over it, how much to shave off each end, and when the caption appears. The
# trims are the fine adjustment for pacing — the walkthrough's own `wait` calls
# are the coarse one, and changing those means re-recording.
SEGMENTS = [
    dict(name="dashboard", start="dashboard_in", end="dashboard_out",
         caption="caption_dashboard"),
    dict(name="complete", start="complete_in", end="complete_out",
         caption="caption_complete", tail=0.3),
    dict(name="summary", start="summary_in", end="summary_out",
         caption="caption_summary"),
    dict(name="stats", start="stats_in", end="stats_out",
         caption="caption_stats", tail=0.2),
    # Held back until the form has scrolled: before that the palette sits in the
    # bottom third, exactly where the caption would dim it.
    dict(name="config", start="config_in", end="config_out",
         caption="caption_config", head=0.4, delay=3.0),
]

# The finished running order. Cards break the footage into three acts, so the
# preview reads as an argument rather than as a feature list.
TIMELINE = [
    ("card", "card_open", 3.2),
    ("segment", "dashboard", None),
    ("segment", "complete", None),
    ("card", "card_mid", 3.1),
    ("segment", "summary", None),
    ("segment", "stats", None),
    ("segment", "config", None),
    ("card", "card_close", 3.6),
]

ENCODE = [
    "-c:v", "libx264",
    "-profile:v", "high",
    "-preset", "slow",
    "-crf", "18",
    "-pix_fmt", "yuv420p",
    "-r", str(FPS),
]


def run(command):
    result = subprocess.run(command)
    if result.returncode != 0:
        sys.exit(f"Command failed: {' '.join(str(c) for c in command)}")


def read_marks():
    if not MARKS.exists():
        sys.exit(f"{MARKS} is missing — run scripts/record-app-preview.sh first.")
    offset = float(os.environ.get("SYNC_OFFSET", "0"))
    marks = {}
    for line in MARKS.read_text().splitlines():
        if not line.strip():
            continue
        name, value = line.split()
        marks[name] = float(value) + offset
    return marks


def render_cards():
    print("==> Rendering artwork")
    run(["swift", str(ROOT / "scripts" / "render-preview-cards.swift"), str(ART)])


def cut_segment(name, start, end, caption, delay):
    """Trims one segment out of the raw recording and burns its caption in."""
    duration = end - start
    out = CLIPS / f"{name}.mp4"
    # The caption is held off the first and last moments of the segment so it
    # reads as an annotation appearing over the app, not as part of the UI.
    fade_in, fade_out = 0.35, 0.45
    hold_out = max(duration - fade_out - 0.15, delay + fade_in + 0.2)
    filters = (
        f"[0:v]fps={FPS},scale={WIDTH}:{HEIGHT},setsar=1,setpts=PTS-STARTPTS[v];"
        f"[1:v]format=rgba,setpts=PTS-STARTPTS,"
        f"fade=t=in:st={delay:.3f}:d={fade_in}:alpha=1,"
        f"fade=t=out:st={hold_out:.3f}:d={fade_out}:alpha=1[c];"
        f"[v][c]overlay=0:0:shortest=1,format=yuv420p[out]"
    )
    run([
        "ffmpeg", "-y", "-hide_banner", "-loglevel", "error",
        "-ss", f"{start:.3f}", "-t", f"{duration:.3f}", "-i", str(RAW),
        "-loop", "1", "-t", f"{duration:.3f}", "-i", str(ART / f"{caption}.png"),
        "-filter_complex", filters, "-map", "[out]", *ENCODE, str(out),
    ])
    return out, duration


def cut_card(name, duration):
    """Turns a still card into a clip with a slow push-in.

    Pre-scaled before `zoompan` because zoompan resamples every frame, and at 1x
    its sub-pixel steps show up as a crawl along the edges of the type. `d=1`
    keeps it to one output frame per input frame — the default expands each
    input frame into a whole zoom of its own.
    """
    out = CLIPS / f"{name}.mp4"
    frames = int(round(duration * FPS))
    filters = (
        f"[0:v]scale={WIDTH * 2}:{HEIGHT * 2},"
        f"zoompan=z='1+0.06*on/{frames}':x='iw/2-(iw/zoom/2)':y='ih/2-(ih/zoom/2)':"
        f"d=1:s={WIDTH}x{HEIGHT}:fps={FPS},setsar=1,format=yuv420p[out]"
    )
    run([
        "ffmpeg", "-y", "-hide_banner", "-loglevel", "error",
        "-loop", "1", "-framerate", str(FPS), "-t", f"{duration:.3f}",
        "-i", str(ART / f"{name}.png"),
        "-filter_complex", filters, "-map", "[out]", *ENCODE, str(out),
    ])
    return out, duration


def concatenate(clips):
    """Cross-fades the clips together and muxes a silent audio track."""
    inputs = []
    for path, _ in clips:
        inputs += ["-i", str(path)]
    inputs += ["-f", "lavfi", "-t", "60", "-i", "anullsrc=r=44100:cl=stereo"]

    steps = []
    current = "0:v"
    offset = 0.0
    for index in range(1, len(clips)):
        offset += clips[index - 1][1] - XFADE
        label = f"x{index}"
        steps.append(
            f"[{current}][{index}:v]"
            f"xfade=transition=fade:duration={XFADE}:offset={offset:.3f}[{label}]"
        )
        current = label

    total = sum(duration for _, duration in clips) - XFADE * (len(clips) - 1)
    steps.append(
        f"[{current}]fps={FPS},"
        f"fade=t=in:st=0:d=0.5,fade=t=out:st={total - 0.7:.3f}:d=0.7,"
        f"format=yuv420p[out]"
    )

    run([
        "ffmpeg", "-y", "-hide_banner", "-loglevel", "error",
        *inputs,
        "-filter_complex", ";".join(steps),
        "-map", "[out]", "-map", f"{len(clips)}:a",
        *ENCODE,
        "-c:a", "aac", "-b:a", "128k", "-ar", "44100",
        "-t", f"{total:.3f}",
        "-movflags", "+faststart",
        str(MASTER),
    ])
    return total


def deliver():
    """Scales the master down to the size App Store Connect will accept."""
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    run([
        "ffmpeg", "-y", "-hide_banner", "-loglevel", "error",
        "-i", str(MASTER),
        "-vf", (
            f"scale={DELIVERY_WIDTH}:-2:flags=lanczos,"
            f"crop={DELIVERY_WIDTH}:{DELIVERY_HEIGHT},setsar=1"
        ),
        *ENCODE,
        "-c:a", "copy",
        "-movflags", "+faststart",
        str(OUTPUT),
    ])


def main():
    if not RAW.exists():
        sys.exit(f"{RAW} is missing — run scripts/record-app-preview.sh first.")

    marks = read_marks()
    render_cards()

    if CLIPS.exists():
        shutil.rmtree(CLIPS)
    CLIPS.mkdir(parents=True)

    print("==> Cutting segments")
    segments = {}
    for spec in SEGMENTS:
        missing = [m for m in (spec["start"], spec["end"]) if m not in marks]
        if missing:
            sys.exit(f"Cut points {missing} are missing from {MARKS}")
        name = spec["name"]
        start = marks[spec["start"]] + spec.get("head", 0.0)
        end = marks[spec["end"]] - spec.get("tail", 0.0)
        clip, duration = cut_segment(name, start, end, spec["caption"], spec.get("delay", 0.15))
        segments[name] = (clip, duration)
        print(f"    {name:<10} {start:7.3f}s → {end:7.3f}s  ({duration:.2f}s)")

    print("==> Rendering cards")
    clips = []
    for kind, name, duration in TIMELINE:
        if kind == "card":
            clips.append(cut_card(name, duration))
        else:
            clips.append(segments[name])

    print("==> Assembling")
    total = concatenate(clips)

    print("==> Scaling for delivery")
    deliver()

    print(f"\nApp preview: {OUTPUT}  ({DELIVERY_WIDTH}x{DELIVERY_HEIGHT}, {total:.1f}s)")
    print(f"Master:      {MASTER}  ({WIDTH}x{HEIGHT})")
    if not 15 <= total <= 30:
        print(
            f"!! App Store previews must run 15–30 seconds; this one is {total:.1f}s.",
            file=sys.stderr,
        )


if __name__ == "__main__":
    main()
