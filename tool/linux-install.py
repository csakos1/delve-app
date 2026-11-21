#!/usr/bin/env python3
"""Installs the Linux release build for this user (no root), or takes it out again:

    flutter build linux --release && python3 tool/linux-install.py
    python3 tool/linux-install.py --uninstall

- the bundle (build/linux/<arch>/release/bundle) goes to ~/.local/opt/delve;
- the launcher entry is ~/.local/share/applications/hu.csakos.delve.desktop - its name
  is the window's app id, so the compositor, the task bar and the notification daemon
  find the icon;
- the icon is ~/.local/share/icons/hicolor/scalable/apps/hu.csakos.delve.svg.

A second run is an update. The new bundle is copied next to the old one and the two
are swapped, so a running Delve is not broken: it stays the old version until it is
restarted. Nothing starts with the session and nothing sits in a tray. There is no
`delve` in ~/.local/bin on purpose: that name is the backend's CLI (/usr/local/bin/delve).
What the app wrote itself (its settings and databases, the token in the keyring) is
never touched, by --uninstall either.

`--bundle DIR` installs another bundle, for example the unpacked `delve-linux-x64`
artifact of the CI.
"""
import argparse
import os
import platform
import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
APP_ID = "hu.csakos.delve"  # APPLICATION_ID in linux/CMakeLists.txt: the window's app id
BINARY = "delve"  # BINARY_NAME in linux/CMakeLists.txt
ICON = ROOT / "linux" / "packaging" / f"{APP_ID}.svg"
ARCH = {"x86_64": "x64", "aarch64": "arm64"}

# what a release bundle has: without lib/libapp.so it is a debug build
BUNDLE_PARTS = (
    BINARY,
    "lib/libapp.so",
    "lib/libflutter_linux_gtk.so",
    "data/icudtl.dat",
    "data/flutter_assets",
)


def data_home() -> Path:
    xdg = os.environ.get("XDG_DATA_HOME", "")
    return Path(xdg) if os.path.isabs(xdg) else Path.home() / ".local" / "share"


def app_dir() -> Path:
    return Path.home() / ".local" / "opt" / "delve"


def desktop_file() -> Path:
    return data_home() / "applications" / f"{APP_ID}.desktop"


def icon_theme() -> Path:
    return data_home() / "icons" / "hicolor"


def icon_file() -> Path:
    return icon_theme() / "scalable" / "apps" / f"{APP_ID}.svg"


def default_bundle() -> Path:
    arch = ARCH.get(platform.machine(), "x64")
    return ROOT / "build" / "linux" / arch / "release" / "bundle"


def short(path: Path) -> str:
    """The path as it is said to the reader: ~ for the home directory."""
    try:
        return "~/" + str(path.relative_to(Path.home()))
    except ValueError:
        return str(path)


def exec_arg(arg: str) -> str:
    """One argument of an Exec line (Desktop Entry Specification, "The Exec key")."""
    arg = arg.replace("%", "%%")
    if not any(c in arg for c in " \t\n\"'\\><~|&;$*?#()`"):
        return arg
    for c in '\\"`$':
        arg = arg.replace(c, "\\" + c)
    # a string value's own escape on top: every backslash doubled
    return '"' + arg.replace("\\", "\\\\") + '"'


def desktop_entry(exe: Path) -> str:
    return "\n".join(
        (
            "[Desktop Entry]",
            "Type=Application",
            "Name=Delve",
            "GenericName=Personal agent",
            "Comment=Client for the Delve personal agent",
            f"TryExec={exe}",
            f"Exec={exec_arg(str(exe))}",
            f"Icon={APP_ID}",
            "Terminal=false",
            "Categories=Utility;",
            f"StartupWMClass={APP_ID}",
            "",
        )
    )


def running(dest: Path) -> list[int]:
    """The processes started from the installed bundle - also from one that an update
    has replaced since (its link reads `…/.delve.old-N/delve (deleted)`)."""
    pids = []
    parents = {str(dest.parent), os.path.realpath(dest.parent)}
    for entry in Path("/proc").iterdir():
        if not entry.name.isdigit():
            continue
        try:
            exe = Path(os.readlink(entry / "exe").removesuffix(" (deleted)"))
        except OSError:
            continue  # another user's process, or one that just ended
        home = exe.parent
        ours = home.name == dest.name or home.name.startswith(".delve.old-")
        if exe.name == BINARY and ours and str(home.parent) in parents:
            pids.append(int(entry.name))
    return sorted(pids)


def leftovers(parent: Path) -> list[Path]:
    """Copies an interrupted run left next to the bundle."""
    if not parent.is_dir():
        return []
    return [p for p in parent.iterdir() if p.name.startswith((".delve.new-", ".delve.old-"))]


def remove(path: Path) -> None:
    if path.is_dir() and not path.is_symlink():
        shutil.rmtree(path)
    else:
        path.unlink()


def write_if_changed(path: Path, text: str) -> bool:
    if path.is_file() and path.read_text() == text:
        return False
    path.parent.mkdir(parents=True, exist_ok=True)
    tmp = path.with_name(f".{path.name}.new-{os.getpid()}")
    tmp.write_text(text)
    os.replace(tmp, path)
    return True


def quiet(*cmd: str) -> None:
    """A cache refresh that may be missing and may fail: neither stops the install."""
    if shutil.which(cmd[0]) is None:
        return
    try:
        subprocess.run(
            cmd,
            check=False,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            timeout=60,
        )
    except (OSError, subprocess.TimeoutExpired):
        pass


def refresh_caches() -> None:
    theme = icon_theme()
    if theme.is_dir():
        # a cache is only trusted while it is newer than the theme directory
        os.utime(theme)
        if (theme / "icon-theme.cache").exists():
            quiet("gtk-update-icon-cache", "-q", "-t", "-f", str(theme))
    apps = desktop_file().parent
    if apps.is_dir():
        quiet("update-desktop-database", "-q", str(apps))


def notes() -> list[str]:
    """What the app wants at run time and this machine seems not to have."""
    out = []
    if shutil.which("wl-paste") is None:
        out.append("wl-paste is missing (wl-clipboard): Ctrl+V will not paste an image into a chat")
    if shutil.which("busctl") is not None:
        try:
            names = subprocess.run(
                ("busctl", "--user", "--no-pager", "--no-legend", "list"),
                check=False,
                capture_output=True,
                text=True,
                timeout=10,
            )
            if names.returncode == 0 and "org.freedesktop.secrets" not in names.stdout:
                out.append(
                    "no Secret Service on the session bus (gnome-keyring): "
                    "the pairing cannot be kept"
                )
        except (OSError, subprocess.TimeoutExpired):
            pass
    return out


def install(bundle: Path) -> int:
    missing = [part for part in BUNDLE_PARTS if not (bundle / part).exists()]
    if missing:
        print(f"{bundle} is not a release bundle (missing: {', '.join(missing)})")
        print("build it first: flutter build linux --release")
        return 1
    if not ICON.is_file():
        print(f"{ICON} is missing")
        return 1

    dest = app_dir()
    exe = dest / BINARY
    alive = running(dest)
    update = dest.exists() or dest.is_symlink()

    dest.parent.mkdir(parents=True, exist_ok=True)
    for stale in leftovers(dest.parent):
        remove(stale)
    fresh = dest.parent / f".delve.new-{os.getpid()}"
    shutil.copytree(bundle, fresh, symlinks=True)
    os.chmod(fresh / BINARY, 0o755)
    if update:
        old = dest.parent / f".delve.old-{os.getpid()}"
        os.rename(dest, old)
        os.rename(fresh, dest)
        remove(old)
    else:
        os.rename(fresh, dest)
    print(f"{short(dest)}: {'updated' if update else 'installed'}")

    icon = icon_file()
    changed = write_if_changed(icon, ICON.read_text())
    print(f"{short(icon)}: {'written' if changed else 'already there'}")
    entry = desktop_file()
    changed = write_if_changed(entry, desktop_entry(exe))
    print(f"{short(entry)}: {'written' if changed else 'already there'}")
    refresh_caches()

    for note in notes():
        print(f"note: {note}")
    if alive:
        print("note: Delve is running - it stays the old version until it is restarted")
    return 0


def uninstall() -> int:
    dest = app_dir()
    alive = running(dest)
    targets = [dest, desktop_file(), icon_file(), *leftovers(dest.parent)]
    for path in targets:
        if path.exists() or path.is_symlink():
            remove(path)
            print(f"{short(path)}: removed")
        else:
            print(f"{short(path)}: not there")
    try:
        dest.parent.rmdir()  # ~/.local/opt, when Delve was all it held
    except OSError:
        pass
    refresh_caches()
    print("the app's own data and its keyring entry were left alone")
    if alive:
        print("note: Delve is still running - it goes on until it is closed")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Install the Linux release build for this user: the bundle to "
        "~/.local/opt/delve, a launcher entry and the icon. A second run updates it."
    )
    parser.add_argument(
        "--bundle",
        type=Path,
        metavar="DIR",
        help="the bundle to install (default: this checkout's release build)",
    )
    parser.add_argument(
        "--uninstall",
        action="store_true",
        help="remove the bundle, the launcher entry and the icon",
    )
    args = parser.parse_args()
    if args.uninstall and args.bundle:
        parser.error("--uninstall takes no bundle")
    if os.geteuid() == 0:
        print("run it as yourself, not as root: it installs into your home directory")
        return 1
    if args.uninstall:
        return uninstall()
    return install((args.bundle or default_bundle()).resolve())


if __name__ == "__main__":
    sys.exit(main())
