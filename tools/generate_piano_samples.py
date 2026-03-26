#!/usr/bin/env python3

"""Generate piano note assets for the ear-training app.

This script downloads a small subset of Salamander Grand Piano v3 samples,
converts them to mono WAV files, pitch-shifts them to C4-B4, trims them to a
short ear-training-friendly length, and writes them into assets/audio/notes.
"""

from __future__ import annotations

import math
import shutil
import struct
import subprocess
import tempfile
import urllib.parse
import urllib.request
import wave
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
OUTPUT_DIR = ROOT / "assets" / "audio" / "notes"

SAMPLE_RATE = 44_100
OUTPUT_DURATION_SECONDS = 1.8
SOURCE_WINDOW_SECONDS = 2.4
PRE_ROLL_SECONDS = 0.008
FADE_IN_SECONDS = 0.003
FADE_OUT_SECONDS = 0.12
TARGET_PEAK = 25_000

SOURCE_VERSION = "v8"
SOURCE_BASE_URL = (
    "https://raw.githubusercontent.com/sfzinstruments/SalamanderGrandPiano/"
    "master/Samples"
)

SOURCE_NOTES = {
    "C4": 60,
    "D#4": 63,
    "F#4": 66,
    "A4": 69,
}

TARGET_NOTES = {
    "c4": 60,
    "cs4": 61,
    "d4": 62,
    "ds4": 63,
    "e4": 64,
    "f4": 65,
    "fs4": 66,
    "g4": 67,
    "gs4": 68,
    "a4": 69,
    "as4": 70,
    "b4": 71,
}


def download(url: str, destination: Path) -> None:
    destination.parent.mkdir(parents=True, exist_ok=True)
    with urllib.request.urlopen(url) as response, destination.open("wb") as out:
        out.write(response.read())


def convert_flac_to_mono_wav(source: Path, destination: Path) -> None:
    subprocess.run(
        [
            "afconvert",
            "-f",
            "WAVE",
            "-d",
            f"LEI16@{SAMPLE_RATE}",
            "-c",
            "1",
            str(source),
            str(destination),
        ],
        check=True,
    )


def read_wav_samples(path: Path) -> list[int]:
    with wave.open(str(path), "rb") as wav_file:
        if wav_file.getnchannels() != 1:
            raise ValueError(f"{path} is not mono")
        if wav_file.getsampwidth() != 2:
            raise ValueError(f"{path} is not 16-bit PCM")
        if wav_file.getframerate() != SAMPLE_RATE:
            raise ValueError(f"{path} is not {SAMPLE_RATE} Hz")

        frame_count = wav_file.getnframes()
        raw_frames = wav_file.readframes(frame_count)

    return list(struct.unpack(f"<{frame_count}h", raw_frames))


def detect_onset(samples: list[int]) -> int:
    peak = max(abs(sample) for sample in samples)
    threshold = max(160, int(peak * 0.03))
    for index, sample in enumerate(samples):
        if abs(sample) >= threshold:
            return index
    return 0


def choose_source_note(target_midi: int) -> tuple[str, int]:
    return min(
        SOURCE_NOTES.items(),
        key=lambda item: (abs(item[1] - target_midi), item[1]),
    )


def resample_linear(samples: list[int], ratio: float) -> list[float]:
    output_length = max(1, int(len(samples) / ratio))
    output: list[float] = []
    last_index = len(samples) - 1

    for index in range(output_length):
        source_position = index * ratio
        left_index = int(source_position)
        if left_index >= last_index:
            output.append(float(samples[last_index]))
            continue

        fraction = source_position - left_index
        left = samples[left_index]
        right = samples[left_index + 1]
        output.append((left * (1.0 - fraction)) + (right * fraction))

    return output


def trim_and_shape(samples: list[float]) -> list[int]:
    target_length = int(OUTPUT_DURATION_SECONDS * SAMPLE_RATE)
    if len(samples) < target_length:
        samples = samples + [0.0] * (target_length - len(samples))
    else:
        samples = samples[:target_length]

    average = sum(samples) / len(samples)
    centered = [sample - average for sample in samples]

    fade_in_length = max(1, int(FADE_IN_SECONDS * SAMPLE_RATE))
    fade_out_length = max(1, int(FADE_OUT_SECONDS * SAMPLE_RATE))

    for index in range(fade_in_length):
        multiplier = index / max(1, fade_in_length - 1)
        centered[index] *= multiplier

    for index in range(fade_out_length):
        position = len(centered) - fade_out_length + index
        multiplier = 0.5 * (
            1.0 + math.cos(math.pi * index / max(1, fade_out_length - 1))
        )
        centered[position] *= multiplier

    peak = max(abs(sample) for sample in centered) or 1.0
    gain = TARGET_PEAK / peak

    pcm_samples: list[int] = []
    for sample in centered:
        value = int(round(sample * gain))
        pcm_samples.append(max(-32_767, min(32_767, value)))

    return pcm_samples


def write_wav(path: Path, samples: list[int]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(path), "wb") as wav_file:
        wav_file.setnchannels(1)
        wav_file.setsampwidth(2)
        wav_file.setframerate(SAMPLE_RATE)
        wav_file.writeframes(struct.pack(f"<{len(samples)}h", *samples))


def source_url(note_name: str) -> str:
    file_name = f"{note_name}{SOURCE_VERSION}.flac"
    encoded_name = urllib.parse.quote(file_name)
    return f"{SOURCE_BASE_URL}/{encoded_name}"


def generate_note(target_name: str, target_midi: int, source_cache: dict[str, list[int]]) -> None:
    source_name, source_midi = choose_source_note(target_midi)
    source_samples = source_cache[source_name]

    onset = detect_onset(source_samples)
    start = max(0, onset - int(PRE_ROLL_SECONDS * SAMPLE_RATE))
    window_length = int(SOURCE_WINDOW_SECONDS * SAMPLE_RATE)
    window = source_samples[start : start + window_length]

    ratio = 2 ** ((target_midi - source_midi) / 12)
    pitched = resample_linear(window, ratio)
    shaped = trim_and_shape(pitched)
    write_wav(OUTPUT_DIR / f"{target_name}.wav", shaped)

    semitone_shift = target_midi - source_midi
    print(f"{target_name}.wav <- {source_name}{SOURCE_VERSION}.flac ({semitone_shift:+} st)")


def main() -> None:
    if not shutil.which("afconvert"):
        raise SystemExit("afconvert is required but was not found on PATH")

    with tempfile.TemporaryDirectory(prefix="yunxu_piano_") as temp_dir_name:
        temp_dir = Path(temp_dir_name)
        source_cache: dict[str, list[int]] = {}

        for source_name in SOURCE_NOTES:
            flac_path = temp_dir / f"{source_name}{SOURCE_VERSION}.flac"
            wav_path = temp_dir / f"{source_name}{SOURCE_VERSION}.wav"

            download(source_url(source_name), flac_path)
            convert_flac_to_mono_wav(flac_path, wav_path)
            source_cache[source_name] = read_wav_samples(wav_path)

        for target_name, target_midi in TARGET_NOTES.items():
            generate_note(target_name, target_midi, source_cache)


if __name__ == "__main__":
    main()
