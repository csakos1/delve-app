#!/usr/bin/env python3
"""Records WebSocket conversations with a running delve-backend for the app's
reducer tests (test/fixtures/ws/<scenario>.jsonl).

Every frame in both directions is written as one JSON line:
    {"t": 1.234, "conn": 1, "dir": "in" | "out", "frame": {...}}
after a first line {"scenario", "recorded_at", "url", "prompts"}. The device
token is never written; the home directory, the user name and tailnet names
are replaced before anything reaches the file.

Use the development backend (its own database), never production:

    cd ~/delve-backend && . .venv/bin/activate
    set -a; . ~/.config/delve/dev.env; set +a
    DELVE_TOKEN=$(cat ~/.config/delve/dev.token) \\
      python ../delve-app/tool/ws-record.py --url http://127.0.0.1:8700

Scenarios (default: all but `late`): basic, tool, interim, deny, thinking,
stop, queued, reconnect, late (~6 minutes: waits out the Hermes approval
timeout, then approves late). Any approval a scenario does not expect is
denied at once. Needs `websockets` (in the backend venv).
"""

from __future__ import annotations

import argparse
import asyncio
import getpass
import json
import os
import re
import sys
import time
import uuid
from collections.abc import Callable
from datetime import UTC, datetime
from pathlib import Path
from typing import Any

import websockets

HERE = Path(__file__).resolve().parent
DEFAULT_OUT = HERE.parent / "test" / "fixtures" / "ws"

PROMPTS: dict[str, list[str]] = {
    "basic": ["Reply with just the word: pong"],
    "tool": ["Run `uptime` with the terminal tool, then tell me the load average in one sentence."],
    "interim": [
        "First tell me in one short sentence what you are going to do, then run `uname -r` "
        "with the terminal tool and report the kernel version."
    ],
    "deny": ["Run exactly this command with the terminal tool: rm -r /tmp/delve-ws-record-dir"],
    "thinking": ["Without using any tool: what is 17*23? Answer with the number only."],
    "stop": ["Run `sleep 60` with the terminal tool and tell me when it is done."],
    "queued": ["Count from 1 to 30, one number per line.", "Now just say: done."],
    "reconnect": ["Write 15 short lines about Lake Balaton, one fact per line."],
    "late": ["Run exactly this command with the terminal tool: rm -r /tmp/delve-ws-late-dir"],
}
ALL = list(PROMPTS)
DEFAULT = [s for s in ALL if s != "late"]


class Redactor:
    def __init__(self, token: str) -> None:
        home = os.path.expanduser("~")
        user = getpass.getuser()
        self.rules: list[tuple[re.Pattern[str], str]] = [
            (re.compile(re.escape(token)), "dlv_redacted"),
            (re.compile(re.escape(home)), "/home/operator"),
            (re.compile(r"\b" + re.escape(user) + r"\b"), "operator"),
            (re.compile(r"tail[0-9a-f]{5,}", re.I), "tailnet"),
            (re.compile(r"\b100\.(6[4-9]|[7-9]\d|1[01]\d|12[0-7])\.\d{1,3}\.\d{1,3}\b"), "100.64.0.1"),
        ]

    def __call__(self, text: str) -> str:
        for pattern, repl in self.rules:
            text = pattern.sub(repl, text)
        return text


class Recorder:
    """One scenario: frames of all its connections go to one file."""

    def __init__(self, url: str, token: str, redact: Redactor) -> None:
        self.ws_url = re.sub(r"^http", "ws", url.rstrip("/")) + "/api/v1/ws"
        self.token = token
        self.redact = redact
        self.lines: list[str] = []
        self.t0 = time.monotonic()
        self.conn = 0
        self.ws: Any = None
        self.epoch: str | None = None
        self.last_seq: int | None = None
        self.frames: list[dict[str, Any]] = []  # incoming, current scenario
        self.expected_approvals = 0  # approvals the scenario answers itself
        self.renamed: dict[str, str] = {}  # q_… → run_…
        self.done: set[str | None] = set()  # run ids with run.finished
        self._ids = 0

    def _write(self, direction: str, frame: dict[str, Any]) -> None:
        line = json.dumps(
            {"t": round(time.monotonic() - self.t0, 3), "conn": self.conn, "dir": direction,
             "frame": frame},
            ensure_ascii=False,
        )  # fmt: skip
        self.lines.append(self.redact(line))

    async def connect(self, resume: bool = False) -> dict[str, Any]:
        self.conn += 1
        self.ws = await websockets.connect(self.ws_url, max_size=2**22, ping_interval=None)
        hello: dict[str, Any] = {"device_token": self.token}
        if resume and self.last_seq is not None:
            hello |= {"last_seq": self.last_seq, "epoch": self.epoch}
        await self.send("hello", hello, frame_id="hello")
        ok = await self.recv()
        if ok.get("type") != "hello.ok":
            raise SystemExit(f"no hello.ok: {ok}")
        self.epoch = ok["data"]["epoch"]
        if self.last_seq is None:
            self.last_seq = ok["data"]["seq"]
        return ok

    async def close(self) -> None:
        if self.ws is not None:
            await self.ws.close()
            self.ws = None

    async def send(self, type_: str, data: dict[str, Any], frame_id: str | None = None) -> str:
        self._ids += 1
        fid = frame_id or f"r{self._ids}"
        frame = {"type": type_, "id": fid, "data": data}
        await self.ws.send(json.dumps(frame))
        self._write("out", frame)
        return fid

    async def recv(self, timeout: float = 600.0) -> dict[str, Any]:
        raw = await asyncio.wait_for(self.ws.recv(), timeout)
        frame = json.loads(raw)
        self._write("in", frame)
        if isinstance(frame.get("seq"), int):
            self.last_seq = frame["seq"]
        data = frame.get("data") or {}
        if frame.get("type") == "run.started" and data.get("queued_id"):
            self.renamed[data["queued_id"]] = data["run_id"]
        if frame.get("type") == "run.finished":
            self.done.add(data.get("run_id"))
        self.frames.append(frame)
        return frame

    async def wait_finished(self, *run_ids: str, timeout: float = 180.0) -> None:
        pred = self.finished(*run_ids)
        if not pred({}):
            await self.until(pred, timeout)

    def finished(self, *run_ids: str) -> Callable[[dict[str, Any]], bool]:
        """True once every run (queue or Hermes id) has had its run.finished."""
        return lambda _f: all(
            r in self.done or self.renamed.get(r) in self.done for r in run_ids
        )

    async def until(self, pred: Callable[[dict[str, Any]], bool], timeout: float = 180.0) -> dict[str, Any]:
        deadline = time.monotonic() + timeout
        while True:
            left = deadline - time.monotonic()
            if left <= 0:
                raise TimeoutError("scenario timed out")
            f = await self.recv(left)
            await self.auto_deny(f)
            if pred(f):
                return f

    async def linger(self, seconds: float) -> None:
        """Late events: title, reasoning, context, conversation totals."""
        end = time.monotonic() + seconds
        while (left := end - time.monotonic()) > 0:
            try:
                f = await self.recv(left)
            except TimeoutError:
                return
            await self.auto_deny(f)

    async def auto_deny(self, f: dict[str, Any]) -> None:
        if f.get("type") != "approval.request":
            return
        if self.expected_approvals > 0:
            return
        await self.send("approval.respond", {"request_id": f["data"]["request_id"], "choice": "deny"})

    async def chat(self, text: str, conversation_id: str | None = None, thinking: bool | None = None) -> dict[str, Any]:
        data: dict[str, Any] = {"text": text, "client_msg_id": str(uuid.uuid4())}
        if conversation_id:
            data["conversation_id"] = conversation_id
        if thinking is not None:
            data["thinking"] = thinking
        fid = await self.send("chat.send", data)
        ack = await self.until(lambda f: f.get("id") == fid)
        if ack["type"] != "ack":
            raise SystemExit(f"chat.send refused: {ack}")
        return ack["data"]


async def scenario(name: str, r: Recorder, linger: float) -> None:
    p = PROMPTS[name]
    await r.connect()
    if name in ("basic", "tool", "interim"):
        ack = await r.chat(p[0])
        await r.wait_finished(ack["run_id"])
    elif name == "deny":
        r.expected_approvals = 1
        ack = await r.chat(p[0])
        req = await r.until(lambda f: f["type"] == "approval.request")
        await r.send("approval.respond", {"request_id": req["data"]["request_id"], "choice": "deny"})
        r.expected_approvals = 0
        await r.wait_finished(ack["run_id"])
    elif name == "thinking":
        ack = await r.chat(p[0], thinking=True)
        await r.wait_finished(ack["run_id"])
    elif name == "stop":
        ack = await r.chat(p[0])
        started = await r.until(lambda f: f["type"] in ("tool.started", "message.delta"))
        await r.send("run.stop", {"run_id": started["data"]["run_id"]})
        await r.wait_finished(ack["run_id"])
    elif name == "queued":
        first = await r.chat(p[0])
        second = await r.chat(p[1], conversation_id=first["conversation_id"])
        await r.wait_finished(first["run_id"], second["run_id"])
    elif name == "reconnect":
        ack = await r.chat(p[0])
        deltas = 0

        def enough(f: dict[str, Any]) -> bool:
            nonlocal deltas
            deltas += f["type"] == "message.delta"
            return deltas >= 10 or f["type"] == "run.finished"

        f = await r.until(enough)
        if f["type"] != "run.finished":
            await r.close()
            await asyncio.sleep(1.0)
            await r.connect(resume=True)
        await r.wait_finished(ack["run_id"])
    elif name == "late":
        r.expected_approvals = 1
        ack = await r.chat(p[0])
        req = await r.until(lambda f: f["type"] == "approval.request")
        rid = req["data"]["request_id"]
        print("  waiting for the Hermes approval timeout (~5 min)…", file=sys.stderr)
        await r.until(
            lambda f: f["type"] == "approval.updated"
            and f["data"]["request_id"] == rid
            and f["data"]["status"] == "expired_in_hermes",
            timeout=600.0,
        )
        await r.wait_finished(ack["run_id"])
        await r.send("approval.respond", {"request_id": rid, "choice": "once"})
        follow = await r.until(lambda f: f["type"] == "run.queued" and f["data"]["origin"] == "late_approval")
        r.expected_approvals = 1  # the follow-up asks again; the backend answers it
        await r.wait_finished(follow["data"]["run_id"])
        r.expected_approvals = 0
    await r.linger(linger)
    await r.close()


async def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--url", default="http://127.0.0.1:8700", help="backend origin")
    ap.add_argument("--out", type=Path, default=DEFAULT_OUT)
    ap.add_argument("--linger", type=float, default=7.0, help="seconds to keep listening after a scenario")
    ap.add_argument("--note", default=None, help="free text for the metadata line")
    ap.add_argument("scenarios", nargs="*", metavar="SCENARIO",
                    help=f"subset of {', '.join(ALL)} (default: all but late)")  # fmt: skip
    args = ap.parse_args()
    token = os.environ.get("DELVE_TOKEN", "").strip()
    if not token:
        print("set DELVE_TOKEN (a device token of the development backend)", file=sys.stderr)
        return 2
    unknown = [s for s in args.scenarios if s not in PROMPTS]
    if unknown:
        print(f"unknown scenario(s): {', '.join(unknown)}", file=sys.stderr)
        return 2
    args.out.mkdir(parents=True, exist_ok=True)
    redact = Redactor(token)
    for name in args.scenarios or DEFAULT:
        r = Recorder(args.url, token, redact)
        print(f"{name} …", file=sys.stderr, flush=True)
        try:
            await scenario(name, r, args.linger)
        except (TimeoutError, OSError, websockets.ConnectionClosed) as exc:
            print(f"  failed: {exc!r}; last frames:", file=sys.stderr)
            for line in r.lines[-8:]:
                print("   ", line[:200], file=sys.stderr)
            return 1
        finally:
            await r.close()
        meta = {
            "scenario": name,
            "recorded_at": datetime.now(UTC).isoformat(timespec="seconds"),
            "url": redact(args.url),
            "prompts": PROMPTS[name],
        }
        if args.note:
            meta["note"] = args.note
        path = args.out / f"{name}.jsonl"
        path.write_text("\n".join([json.dumps(meta, ensure_ascii=False), *r.lines]) + "\n", "utf-8")
        events = sum(1 for f in r.frames if isinstance(f.get("seq"), int))
        print(f"  {path.name}: {len(r.lines)} frames, {events} events", file=sys.stderr)
    return 0


if __name__ == "__main__":
    sys.exit(asyncio.run(main()))
