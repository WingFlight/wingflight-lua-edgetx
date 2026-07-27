"""
Cross-platform removable-drive detection for deploying to an EdgeTX radio's SD card.

Unlike Ethos, EdgeTX radios mount as a plain USB mass-storage drive - there is no
vendor HID protocol to switch modes or a *.cpuid marker file to identify the drive.
Detection here just looks for a removable/mounted volume that contains a plausible
subset of the well-known EdgeTX SD card root folders (SCRIPTS, MODELS, RADIO, THEMES,
SOUNDS), scored by how many of those are present, so a random USB stick or SD card
used for something else doesn't get mistaken for the radio.
"""

import os
import platform


def _list_removable_windows():
    import ctypes

    DRIVE_REMOVABLE = 2
    drives = []
    bitmask = ctypes.windll.kernel32.GetLogicalDrives()
    for i in range(26):
        if not (bitmask >> i) & 1:
            continue
        letter = chr(ord("A") + i)
        root = f"{letter}:\\"
        try:
            drive_type = ctypes.windll.kernel32.GetDriveTypeW(root)
        except Exception:
            continue
        if drive_type == DRIVE_REMOVABLE:
            drives.append(root)
    return drives


def _list_removable_macos():
    base = "/Volumes"
    if not os.path.isdir(base):
        return []
    return [os.path.join(base, entry) for entry in os.listdir(base)]


def _list_removable_linux():
    drives = []
    user = os.environ.get("USER") or os.environ.get("LOGNAME") or ""
    for base in (f"/media/{user}", f"/run/media/{user}", "/media"):
        if not os.path.isdir(base):
            continue
        for entry in os.listdir(base):
            path = os.path.join(base, entry)
            if os.path.isdir(path):
                drives.append(path)
    return drives


def list_removable_drives():
    system = platform.system()
    if system == "Windows":
        return _list_removable_windows()
    if system == "Darwin":
        return _list_removable_macos()
    return _list_removable_linux()


def score_drive(root, marker_folders):
    """Count how many of the known EdgeTX SD card root folders exist on this drive."""
    score = 0
    for folder in marker_folders:
        if os.path.isdir(os.path.join(root, folder)):
            score += 1
    return score


def find_candidates(marker_folders, min_matches):
    candidates = []
    for root in list_removable_drives():
        try:
            score = score_drive(root, marker_folders)
        except OSError:
            continue
        if score >= min_matches:
            candidates.append((root, score))
    candidates.sort(key=lambda item: item[1], reverse=True)
    return candidates


def find_sdcard(config, interactive=True):
    """
    Resolve the EdgeTX SD card root using deploy.json's config.

    Returns the drive root path, or raises RuntimeError with guidance if none
    could be confidently identified.
    """
    manual = config.get("manual_drive_path")
    if manual:
        if os.path.isdir(manual):
            return os.path.normpath(manual)
        raise RuntimeError(
            f"'manual_drive_path' is set to {manual!r} in deploy.json but that path does not exist."
        )

    marker_folders = config.get(
        "sdcard_marker_folders", ["SCRIPTS", "MODELS", "RADIO", "THEMES", "SOUNDS"]
    )
    min_matches = int(config.get("sdcard_marker_min_matches", 2))

    candidates = find_candidates(marker_folders, min_matches)

    if not candidates:
        raise RuntimeError(
            "No removable drive matching an EdgeTX SD card layout was found.\n"
            "  - Make sure the radio is connected and in USB mass-storage mode.\n"
            f"  - Looking for at least {min_matches} of: {', '.join(marker_folders)}\n"
            "  - Or set 'manual_drive_path' in .vscode/deploy.json to a fixed path."
        )

    if len(candidates) == 1:
        return os.path.normpath(candidates[0][0])

    print("[DRIVE] Multiple matching removable drives found:")
    for i, (root, score) in enumerate(candidates, 1):
        print(f"  {i}. {root}  (matched {score}/{len(marker_folders)} folders)")

    if not interactive:
        return os.path.normpath(candidates[0][0])

    while True:
        choice = input(f"Select drive [1-{len(candidates)}]: ").strip()
        if choice.isdigit() and 1 <= int(choice) <= len(candidates):
            return os.path.normpath(candidates[int(choice) - 1][0])
        print("Invalid choice, try again.")


if __name__ == "__main__":
    import json
    import sys

    cfg = {}
    cfg_path = os.path.join(os.path.dirname(__file__), "..", "deploy.json")
    if os.path.isfile(cfg_path):
        with open(cfg_path, "r", encoding="utf-8") as f:
            cfg = json.load(f)

    print("Detected removable drives:")
    for root in list_removable_drives():
        marker_folders = cfg.get(
            "sdcard_marker_folders", ["SCRIPTS", "MODELS", "RADIO", "THEMES", "SOUNDS"]
        )
        score = score_drive(root, marker_folders)
        print(f"  {root}  (matched {score}/{len(marker_folders)} folders)")

    try:
        picked = find_sdcard(cfg, interactive=True)
        print(f"\nWould deploy to: {picked}")
    except RuntimeError as e:
        print(f"\n{e}")
        sys.exit(1)
