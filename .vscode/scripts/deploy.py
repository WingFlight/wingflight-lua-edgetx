"""
Deploy the SCRIPTS/WIDGETS source tree to an EdgeTX radio's SD card (or a local
folder standing in for one, e.g. an EdgeTX simulator's SD image).

This is a trimmed-down, EdgeTX-appropriate counterpart to the deploy tooling used
in rotorflight-lua-ethos-suite. That project's deploy.py talks to Ethos radios over
a vendor HID protocol to switch USB modes and locate the mounted SCRIPTS folder via
*.cpuid marker files written by Ethos firmware - none of that exists for EdgeTX,
which just mounts as a plain USB mass-storage drive. So the transport layer here is
plain removable-drive detection (see drive_detect.py) instead, and the i18n/soundpack/
sensors post-copy steps and Ethos-simulator-version resolution are dropped entirely,
since this project has no equivalent systems.

What's kept from that reference implementation: the incremental MD5/mtime mirror-copy
approach and the cross-platform single-instance lockfile, both of which are generic
and apply here unchanged in spirit.
"""

import argparse
import atexit
import hashlib
import json
import os
import shutil
import signal
import sys
import tempfile
import time
from pathlib import Path

import drive_detect

if os.name == "nt":
    import msvcrt
else:
    import fcntl

REPO_ROOT = Path(__file__).resolve().parents[2]
DEPLOY_JSON = REPO_ROOT / ".vscode" / "deploy.json"

# Trees copied 1:1 onto the SD card root (this repo's src/ layout already mirrors
# the SD card layout, unlike projects that nest everything under one subfolder).
SOURCE_TREES = ["SCRIPTS", "WIDGETS"]


def load_config():
    if not DEPLOY_JSON.is_file():
        print(f"[ERROR] Missing config: {DEPLOY_JSON}")
        sys.exit(1)
    with open(DEPLOY_JSON, "r", encoding="utf-8") as f:
        return json.load(f)


# --- single-instance lock -----------------------------------------------------

def _lock_file(fd):
    if os.name == "nt":
        msvcrt.locking(fd.fileno(), msvcrt.LK_NBLCK, 1)
    else:
        fcntl.flock(fd.fileno(), fcntl.LOCK_EX | fcntl.LOCK_NB)


def _unlock_file(fd):
    try:
        if os.name == "nt":
            fd.seek(0)
            msvcrt.locking(fd.fileno(), msvcrt.LK_UNLCK, 1)
        else:
            fcntl.flock(fd.fileno(), fcntl.LOCK_UN)
    except OSError:
        pass


def _pid_is_running(pid):
    if pid <= 0:
        return False
    try:
        os.kill(pid, 0)
        return True
    except OSError:
        return False


class SingleInstance:
    """OS-level file lock + PID metadata so only one deploy runs at a time."""

    def __init__(self, name, force=False):
        self.lock_path = os.path.join(tempfile.gettempdir(), name)
        self.force = force
        self.fd = None
        self._acquired = False

    def acquire(self):
        self.fd = open(self.lock_path, "a+")
        self.fd.seek(0)
        try:
            _lock_file(self.fd)
            self._acquired = True
        except OSError:
            self.fd.seek(0)
            holder_pid = -1
            try:
                meta = (self.fd.read() or "").strip()
                data = json.loads(meta) if meta else {}
                holder_pid = int(data.get("pid", -1))
            except Exception:
                pass
            if holder_pid > 0 and not _pid_is_running(holder_pid):
                if not self.force:
                    raise RuntimeError(
                        f"Another deploy appears to be running (stale lock from PID {holder_pid}). "
                        f"Re-run with --force, or use the 'Clear locks' task. Lock: {self.lock_path}"
                    )
                _lock_file(self.fd)
                self._acquired = True
            else:
                raise RuntimeError(
                    f"Another deploy is already running (PID {holder_pid if holder_pid > 0 else 'unknown'})."
                )
        try:
            self.fd.seek(0)
            self.fd.truncate(0)
            json.dump({"pid": os.getpid(), "time": time.time()}, self.fd)
            self.fd.flush()
        except Exception:
            pass
        atexit.register(self.release)
        for sig in (signal.SIGINT, signal.SIGTERM):
            try:
                signal.signal(sig, self._signal_and_release)
            except Exception:
                pass

    def _signal_and_release(self, signum, _frame):
        self.release()
        signal.signal(signum, signal.SIG_DFL)
        os.kill(os.getpid(), signum)

    def release(self):
        if self._acquired and self.fd:
            try:
                self.fd.seek(0)
                self.fd.truncate(0)
                self.fd.flush()
                _unlock_file(self.fd)
            finally:
                try:
                    self.fd.close()
                except Exception:
                    pass
                try:
                    os.remove(self.lock_path)
                except Exception:
                    pass
            self._acquired = False


def lock_name_for_repo():
    key = hashlib.md5(str(REPO_ROOT).encode("utf-8")).hexdigest()[:8]
    return f"wf-deploy-{key}.lock"


# --- incremental mirror copy ---------------------------------------------------

def file_md5(path, chunk=1024 * 1024):
    h = hashlib.md5()
    with open(path, "rb") as f:
        while True:
            b = f.read(chunk)
            if not b:
                break
            h.update(b)
    return h.hexdigest()


def _needs_copy(src, dst, ts_slack=2.0):
    try:
        ss = os.stat(src)
    except FileNotFoundError:
        return False
    if not os.path.exists(dst):
        return True
    ds = os.stat(dst)
    if ss.st_size != ds.st_size:
        return True
    if abs(ss.st_mtime - ds.st_mtime) <= ts_slack:
        return False
    try:
        return file_md5(src) != file_md5(dst)
    except Exception:
        return True


def _remove_empty_dirs(root):
    if not os.path.isdir(root):
        return
    for dirpath, dirnames, filenames in os.walk(root, topdown=False):
        if dirnames or filenames:
            continue
        try:
            os.rmdir(dirpath)
        except OSError:
            pass


def mirror_copy(src_dir, dst_dir, force=False):
    """Incremental mirror copy: only touch changed files, delete stale ones."""
    os.makedirs(dst_dir, exist_ok=True)

    src_files = {}
    for r, _, files in os.walk(src_dir):
        for f in files:
            srcf = os.path.join(r, f)
            rel = os.path.relpath(srcf, src_dir)
            src_files[rel] = srcf

    dst_files = {}
    for r, _, files in os.walk(dst_dir):
        for f in files:
            dstf = os.path.join(r, f)
            rel = os.path.relpath(dstf, dst_dir)
            dst_files[rel] = dstf

    copied = 0
    for rel, srcf in src_files.items():
        dstf = os.path.join(dst_dir, rel)
        os.makedirs(os.path.dirname(dstf), exist_ok=True)
        if force or _needs_copy(srcf, dstf):
            shutil.copy2(srcf, dstf)
            print(f"  copy {rel}")
            copied += 1

    removed = 0
    stale = [rel for rel in dst_files if rel not in src_files]
    for rel in stale:
        try:
            os.remove(os.path.join(dst_dir, rel))
            print(f"  delete {rel}")
            removed += 1
        except FileNotFoundError:
            pass

    if stale:
        _remove_empty_dirs(dst_dir)

    if not copied and not removed:
        print(f"  {os.path.basename(src_dir)}: nothing to update")
    else:
        print(f"  {os.path.basename(src_dir)}: {copied} updated, {removed} removed")


def deploy_to(dest_root, force=False):
    for tree in SOURCE_TREES:
        src = REPO_ROOT / "src" / tree
        if not src.is_dir():
            continue
        dst = os.path.join(dest_root, tree)
        print(f"[DEPLOY] {tree} -> {dst}")
        mirror_copy(str(src), dst, force=force)


def main():
    parser = argparse.ArgumentParser(description="Deploy WingFlight EdgeTX Lua scripts")
    parser.add_argument("--radio", action="store_true", help="Deploy to a detected EdgeTX SD card / drive")
    parser.add_argument("--simulator", action="store_true", help="Deploy to the configured simulator SD folder")
    parser.add_argument("--drive", help="Deploy to an explicit drive/folder path (skips auto-detection)")
    parser.add_argument("--force", action="store_true", help="Recopy every file, ignoring incremental mtime/MD5 checks")
    parser.add_argument("--clear-lock", action="store_true", help="Remove this project's deploy lock and exit")
    args = parser.parse_args()

    lock_name = lock_name_for_repo()

    if args.clear_lock:
        path = os.path.join(tempfile.gettempdir(), lock_name)
        try:
            os.remove(path)
            print(f"Removed: {path}")
        except FileNotFoundError:
            print(f"No lock found: {path}")
        return 0

    config = load_config()

    if args.drive:
        dest = args.drive
    elif args.simulator:
        dest = config.get("simulator_sdcard_path")
        if not dest:
            print("[ERROR] No 'simulator_sdcard_path' set in .vscode/deploy.json.")
            return 1
        os.makedirs(dest, exist_ok=True)
    elif args.radio:
        try:
            dest = drive_detect.find_sdcard(config)
        except RuntimeError as e:
            print(f"[ERROR] {e}")
            return 1
    else:
        print("[ERROR] Specify one of --radio, --simulator, or --drive.")
        return 1

    try:
        SingleInstance(lock_name, force=args.force).acquire()
    except RuntimeError as e:
        print(str(e), file=sys.stderr)
        return 1

    print(f"[DEPLOY] Target: {dest}")
    deploy_to(dest, force=args.force)
    print("[DEPLOY] Done.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
