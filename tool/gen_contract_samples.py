"""Regenerate test/fixtures/contract/samples.json with the backend serializers.

Run from a delve-backend checkout with its venv active:
    python ../delve-app/tool/gen_contract_samples.py > ../delve-app/test/fixtures/contract/samples.json
"""
import json, sys, uuid
from datetime import datetime, timedelta, timezone
from delve import API_REVISION, protocol
from delve.db.models import Approval, Card, Conversation, Message, Run, Schedule, ToolStep
from delve.serialize import approval_out, card_out, conversation_out, message_out, run_out, step_out
from delve.llama import Props
from delve.system import Parts, system_out
from delve.brief import brief_payload
from delve.schedules import schedule_out
from delve.stats import RANGES, GpuBucket, RunRow, bucket_edges, edges_between, stats_out
import math

t0 = datetime(2026, 10, 19, 21, 39, 0, 123456, tzinfo=timezone.utc)
conv = Conversation(id="c_5f2a9e1b7c3d4e6f", title="Kernel and CPU count", created_at=t0,
    updated_at=t0 + timedelta(minutes=3), archived=False, last_run_id="run_8e4b1c2d3a4f5e6b",
    thinking=True, context_tokens=8728, context_max=65536, context_measured_at=t0 + timedelta(minutes=3),
    tokens_in=25887, tokens_out=67, tokens_cache_read=17152, origin="app",
    preview="Kernel 7.2.11, 24 CPUs.")
msg = Message(id=412, conversation_id=conv.id, run_id="run_8e4b1c2d3a4f5e6b", role="assistant",
    content="Kernel 7.2.11, 24 CPUs.", interim="I'll check uname and nproc.", reasoning=None,
    client_msg_id=None, status="final", created_at=t0 + timedelta(seconds=2))
umsg = Message(id=411, conversation_id=conv.id, run_id="run_8e4b1c2d3a4f5e6b", role="user",
    content="uname -r && nproc", interim=None, reasoning=None,
    client_msg_id=uuid.UUID("0b8f3c52-7a1e-4d2b-9c61-2f5e8a7d3b10"), status="final", created_at=t0)
run = Run(run_id="run_8e4b1c2d3a4f5e6b", conversation_id=conv.id, status="completed", thinking=False,
    origin="app", queued_at=t0, started_at=t0 + timedelta(seconds=1), ended_at=t0 + timedelta(seconds=3),
    usage={"input_tokens": 17315, "output_tokens": 63, "cache_read_tokens": 17152},
    perf={"sse_reconnects": 0, "first_delta_s": 2.96, "context_source": "final_read", "llama_calls_seen": 2,
          "prompt_tokens": 122, "predicted_tokens": 63, "prefill_tps": 210.4, "gen_tps": 20.6}, error=None)
appr = Approval(request_id="apr_3c9d1e2f", run_id="run_8e4b1c2d3a4f5e6b", conversation_id=conv.id,
    command="rm -r /tmp/delve-12-4-smoke-dir", description="recursive delete", pattern_keys=["rm -r"],
    action_class="delete_kill", status="pending", choice=None, decided_by=None, created_at=t0,
    hermes_deadline=t0 + timedelta(seconds=300), expires_at=t0 + timedelta(minutes=30), responded_at=None)
step = ToolStep(id=97, run_id=run.run_id, tool="terminal", status="ok", preview_start="uname -r && nproc",
    result={"exit_code": 0, "output": "7.2.11-arch1-1\n24"}, result_raw='{"exit_code": 0}',
    user_summary=None, duration_s=0.41, seq_started=5, seq_completed=7, approval_request_id="apr_3c9d1e2f")

card = Card(id="643692effbf845d9b4a0594509b03157", v=1, type="water", severity="info",
    ts=t0 - timedelta(hours=1), origin="script", session_id=None,
    payload={"station": "Siófok", "level_cm": 98.0, "measured_at": "2026-10-19T18:52:00Z",
             "trend_cm_24h": -2.0, "lake_avg_cm": 101.0, "lake_avg_trend_cm_24h": -1.0,
             "data_source": "vizugy.hu"},
    received_at=t0 - timedelta(hours=1) + timedelta(seconds=1))

# B3: the system view (values from delve-infra tests/fixtures/system)
gpus = [
    {"index": 0, "name": "NVIDIA GeForce RTX 4070 SUPER", "temp_c": 51.0, "mem_used_mib": 11381,
     "mem_total_mib": 12282, "util_pct": 6.0, "power_w": 40.39, "power_limit_w": 220.0},
    {"index": 1, "name": "NVIDIA GeForce RTX 3050", "temp_c": 49.0, "mem_used_mib": 6693,
     "mem_total_mib": 8192, "util_pct": 0.0, "power_w": 14.52, "power_limit_w": 130.0},
]
detail = {"status": "degraded", "readiness": {"checks": {
    "disk": {"status": "degraded", "used_percent": 96.4, "free_bytes": 15779127296},
    "gateway": {"status": "ok"}}}}
system_running = system_out(Parts(checked_at=t0, hermes_ok=True, hermes_version="0.22.2",
    hermes_detail=detail, hermes_unit={"active_state": "active", "active_since": 1792535518},
    llama_unit={"active_state": "active", "active_since": 1792537434, "inactive_since": 1792535668},
    llama_healthy=True, props=Props("Qwen3.8-27B", "IQ4_XS", 65536, 1), slot_busy=True,
    gen_tps=21.4, active_runs=1, queued_runs=1, gpus=gpus))
system_stopped = system_out(Parts(checked_at=t0, hermes_ok=True, hermes_version="0.22.2",
    hermes_detail=detail, hermes_unit={"active_state": "active", "active_since": 1792535518},
    llama_unit={"active_state": "inactive", "active_since": 1792535325, "inactive_since": 1792535668},
    known_slots=1, intent="stopped", queued_runs=2,
    gpus=[{**gpus[0], "mem_used_mib": 1266}, {**gpus[1], "mem_used_mib": 15}]))

# B4: schedules and the morning brief
brief_sched = Schedule(id=uuid.UUID("7c1e9d2a-4b3f-4e5a-9c8d-1f2e3a4b5c6d"), kind="brief",
    name="Morning brief", cron="30 7 * * *", prompt=None, conversation_mode="new",
    conversation_id=None, thinking=False, enabled=True, next_run_at=t0 + timedelta(hours=8),
    last_run_at=t0 - timedelta(hours=16), last_status="ok", last_error=None,
    created_at=t0 - timedelta(days=2), updated_at=t0 - timedelta(hours=16))
prompt_sched = Schedule(id=uuid.UUID("2b4d6f8a-1c3e-4a5b-8d7f-9e0a1b2c3d4e"), kind="prompt",
    name="Arch news digest", cron="52 8,12,20 * * *", prompt="Summarize today's Arch news in three lines.",
    conversation_mode="fixed", conversation_id=conv.id, thinking=False, enabled=True,
    next_run_at=t0 + timedelta(hours=11), last_run_at=t0 - timedelta(minutes=47), last_status=None,
    last_error=None, created_at=t0 - timedelta(days=1), updated_at=t0 - timedelta(minutes=47))
updates_card = Card(id="5d0c9b8a7f6e4d3c2b1a0f9e8d7c6b5a", v=1, type="updates", severity="info",
    ts=t0 - timedelta(hours=2), origin="script", payload={"count": 44, "packages": ["clang"],
    "checked_at": "2026-10-19T19:39:00Z"}, received_at=t0 - timedelta(hours=2))
brief = brief_payload(now=t0, host={"uptime_s": 275400, "booted_at": 1792443359},
    incidents=[{"id": "98de85_009110dce5cf", "state": "detected", "job": "98de85fe6a1f",
                "error": "Script exited with code 2 stderr: cron_failtest: simulated parse_failed",
                "last_seen": "2026-10-19T21:35:16.146881+02:00"}],
    updates=updates_card, water=card, system=system_running)
brief_card = Card(id="3e69fb78e25c4d45bfdbe18b3e3da170", v=1, type="brief", severity="warn",
    ts=t0, origin="backend", session_id=None, payload=brief, received_at=t0)

# B5: GET /api/v1/stats?range=24h, a day in the shape of design 15 (deterministic)
spec = RANGES["24h"]
hours = bucket_edges(t0, spec.bucket, spec.count)
stat_runs = []
for h in range(24):
    if h % 4 == 3:
        continue  # an idle hour: gaps in the speed lines
    end = hours[h] + timedelta(minutes=40)
    if end > t0:
        end = t0 - timedelta(minutes=5)
    wait = 2 if h in (9, 12, 23) else 0
    stat_runs.append(RunRow(status="completed", queued_at=end - timedelta(minutes=2 + wait),
        started_at=end - timedelta(minutes=2), ended_at=end,
        usage={"input_tokens": 12000 + 400 * h, "output_tokens": 300, "total_tokens": 12300 + 400 * h,
               "cache_read_tokens": int((12000 + 400 * h) * (0.72 + 0.005 * h))},
        perf={"gen_tps": round(21.4 + 0.6 * math.sin(h / 2), 1),
              "prefill_tps": round(640 + 30 * math.sin(h / 3), 1), "prompt_tokens": 900}))
stat_lat = [(hours[h] + timedelta(minutes=30), s) for h, s in ((8, 30.0), (11, 12.0), (12, 95.0), (17, 25.0), (22, 118.0))]
fine = edges_between(hours[0], hours[-1], spec.gpu_bucket)
stat_gpus = [
    GpuBucket(index=0, name="NVIDIA GeForce RTX 4070 SUPER",
              temp=[round(45 + 26 * max(0.0, math.sin(i / 14)), 1) for i in range(len(fine) - 1)],
              power=[round(20 + 167 * max(0.0, math.sin(i / 14)), 1) for i in range(len(fine) - 1)],
              last_temp=71.0, last_power=187.0),
    GpuBucket(index=1, name="NVIDIA GeForce RTX 3050",
              temp=[None] * 6 + [round(40 + 18 * max(0.0, math.sin(i / 14)), 1) for i in range(6, len(fine) - 1)],
              power=[None] * 6 + [round(8 + 54 * max(0.0, math.sin(i / 14)), 1) for i in range(6, len(fine) - 1)],
              last_temp=58.0, last_power=62.0),
]
stats_day = stats_out(range_key="24h", now=t0, runs=stat_runs, latencies=stat_lat, queued_now=2,
    gpus=stat_gpus, gpu_edges=fine,
    sampling={"interval_s": 60, "ok": True, "error": None, "last_at": (t0 - timedelta(seconds=20)).isoformat()})

shapes = {
    "conversation": conversation_out(conv),
    "message": message_out(msg),
    "message_user": message_out(umsg),
    "run": run_out(run),
    "open_run": {**run_out(Run(**{**{c: getattr(run, c) for c in ("run_id","conversation_id","thinking","origin","queued_at")},
                                    "status": "running", "started_at": t0, "ended_at": None,
                                    "usage": None, "perf": None, "error": None})), "position": 0},
    "approval": approval_out(appr),
    "tool_step": step_out(step, appr),
    "card": card_out(card),
    "system": system_running,
    "gpu": system_running["gpus"][0],
    "hermes_issue": system_running["hermes"]["issues"][0],
    "schedule": schedule_out(brief_sched),
    "schedule_prompt": schedule_out(prompt_sched),
    "brief_payload": brief,
    "brief_incident": brief["incidents"][0],
    "card_brief": card_out(brief_card),
    "stats": stats_day,
    "stats_series": stats_day["generation"],
    "stats_point": stats_day["generation"]["points"][-1],
    "stats_day": stats_day["tokens_per_day"]["days"][-1],
    "stats_gpu": stats_day["gpus"][0],
    "tool_step_plain": step_out(ToolStep(id=98, run_id=run.run_id, tool="terminal", status="running",
        preview_start="nproc", result=None, result_raw=None, user_summary=None, duration_s=None,
        seq_started=9, seq_completed=None, approval_request_id=None)),
}
c, m, a = shapes["conversation"], shapes["message"], shapes["approval"]
base = {"conversation_id": conv.id, "run_id": run.run_id}
events = {
    "conversation.created": c,
    "conversation.updated": {**c, "title": None, "context": {**c["context"], "tokens": None, "pct": None, "warn": False, "measured_at": None}},
    "message.created": {"conversation_id": conv.id, "message": m},
    "message.updated": {"conversation_id": conv.id, "message": {**m, "status": "streaming"}},
    "message.delta": {**base, "message_id": 412, "delta": "Kernel "},
    "message.interim": {**base, "message_id": 412, "text": "I'll check uname and nproc."},
    "run.queued": {"conversation_id": conv.id, "run_id": "q_7d1f0c2b9a8e4f6d", "position": 1, "thinking": True, "origin": "app"},
    "run.started": {**base, "queued_id": "q_7d1f0c2b9a8e4f6d", "thinking": True},
    "run.updated": {**base, "status": "waiting_for_approval"},
    "run.finished": {**base, "status": "completed", "usage": run.usage, "error": None},
    "tool.started": {**base, "step": shapes["tool_step_plain"]},
    "tool.completed": {**base, "step": shapes["tool_step"]},
    "approval.request": {**a, "step_id": 97},
    "approval.updated": {**a, "status": "denied", "choice": "deny", "decided_by": "pixel", "responded_at": (t0 + timedelta(seconds=4)).isoformat()},
    "reasoning.final": {**base, "message_id": 412, "text": "17 times 23 is 391."},
    "context.updated": {**base, "tokens": 8728, "max": 65536, "pct": 13.3, "warn": False, "source": "final_read", "measured_at": t0.isoformat(), "final": True},
    "health.status": {"hermes": "ok", "hermes_version": "0.22.2"},
    "card.new": card_out(card),
    "system.updated": system_stopped,
    "schedule.updated": schedule_out(prompt_sched),
    "schedule.deleted": {"id": str(prompt_sched.id)},
    "error": {"code": "thinking_route_not_applied", "ref_id": run.run_id, "message": "The thinking run did not use the thinking provider."},
}
for k, v in events.items():
    p = protocol.check_event(k, v)
    assert p is None, (k, p)
assert set(events) == set(protocol.SERVER_EVENTS)
connection = {
    "hello.ok": {"server_version": "0.1.0", "api_revision": API_REVISION, "revision": "eb4045ed6a94", "hermes": "ok",
                 "hermes_version": "0.22.2", "thinking_route": {"ok": True, "run_id": run.run_id, "at": t0.isoformat()},
                 "epoch": "9f8e7d6c5b4a3921", "seq": 1042, "resync_required": False},
    "meta": {"server_version": "0.1.0", "api_revision": API_REVISION, "revision": "eb4045ed6a94", "python": "3.14.8",
             "hermes_expected_version": "0.22.2", "approval_timeout_s": 300},
    "status": {"server_version": "0.1.0", "api_revision": API_REVISION, "revision": None, "hermes": None,
               "hermes_version": None, "thinking_route": None},
    "history_message": {**m, "tool_steps": [shapes["tool_step"]]},
    # GET/PATCH /api/v1/devices/me (api/devices.py _device_out; no shared serializer)
    "device_me": {"id": "4f1c2b3a-9d8e-4f7a-8b6c-5d4e3f2a1b0c", "name": "pixel", "created_at": t0.isoformat(),
                  "last_seen_at": (t0 + timedelta(minutes=1)).isoformat(), "fcm": True, "push": True,
                  "notify": {"approvals": True, "run_done": False, "water": False, "brief": False}},
}
out = {"_note": "Generated from delve-backend serializers (decision 176); keys must equal contract.json.",
       "shapes": shapes, "events": events, "connection": connection}
json.dump(out, sys.stdout, indent=2, ensure_ascii=False, default=str); print()
