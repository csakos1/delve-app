#!/usr/bin/env python3
"""One-off Linux runner settings, after `flutter create --platforms linux .`:

- the window title "Delve" (the template writes the project name, "delve");
- no GTK header bar under Hyprland (a tiling compositor: the bar is only a
  wasted strip with a close button; GNOME keeps it);
- a default size closer to the app's layout than 1280 × 720.

Idempotent: a second run changes nothing.
"""
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
APP = ROOT / "linux" / "runner" / "my_application.cc"
MARK = "HYPRLAND_INSTANCE_SIGNATURE"


def main() -> int:
    if not APP.exists():
        print(f"{APP} is missing: run `flutter create --platforms linux .` first")
        return 1
    s = APP.read_text()
    before = s

    s = s.replace('set_title(header_bar, "delve")', 'set_title(header_bar, "Delve")')
    s = s.replace('set_title(window, "delve")', 'set_title(window, "Delve")')

    if MARK not in s:
        anchor = re.search(r"gboolean use_header_bar = TRUE;\n(?:.*\n)*?#endif\n", s)
        if anchor:
            s = (
                s[: anchor.end()]
                + "  // Hyprland tiles: no client-side title bar (Delve)\n"
                + f'  if (g_getenv("{MARK}") != nullptr) {{\n'
                + "    use_header_bar = FALSE;\n"
                + "  }\n"
                + s[anchor.end() :]
            )
        else:
            print("warning: the header-bar block was not found – title bar left as it is")

    s = re.sub(
        r"gtk_window_set_default_size\(window, \d+, \d+\);",
        "gtk_window_set_default_size(window, 1100, 860);",
        s,
    )

    if s == before:
        print(f"{APP.relative_to(ROOT)}: already set")
    else:
        APP.write_text(s)
        print(f"{APP.relative_to(ROOT)}: updated")
    for line in s.splitlines():
        if "set_title" in line or MARK in line or "default_size" in line:
            print("  " + line.strip())
    return 0


if __name__ == "__main__":
    sys.exit(main())
