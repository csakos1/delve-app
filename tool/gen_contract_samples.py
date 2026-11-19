"""Regenerate test/fixtures/contract/samples.json with the backend serializers.

Run from a delve-backend checkout with its venv active:
    python ../delve-app/tool/gen_contract_samples.py > ../delve-app/test/fixtures/contract/samples.json
"""
import json, sys, uuid
from datetime import datetime, timedelta, timezone
from delve import API_REVISION, protocol
from delve.attachments import attachment_out
from delve.db.models import Approval, Attachment, Card, Conversation, Message, Run, Schedule, ToolStep, Watch, WatchItem
from delve.serialize import approval_out, card_out, conversation_out, message_out, run_out, step_out
from delve.llama import Props
from delve.system import Parts, switch_out, system_out
from delve.brief import brief_payload
from delve.schedules import schedule_out, schedule_run_out
from delve.stats import RANGES, GpuBucket, RunRow, bucket_edges, edges_between, stats_out
from delve.mirror import mirror_out
from delve.persona import Persona, Section, Topic, persona_out, section_out, topic_out
from pathlib import Path
from delve.watches import item_out, watch_out
from delve.db.models import NewsItem, NewsSource, NewsTopic
from delve import news as nw
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
att = Attachment(id=uuid.UUID("5d0c7e2a-41b9-4c8e-9f3a-6b2d1e0f9a87"), kind="image", mime="image/jpeg",
    filename="screen.jpg", size_bytes=64895, sha256="0" * 64, conversation_id=conv.id, message_id=411,
    created_at=t0 - timedelta(seconds=20))
run = Run(run_id="run_8e4b1c2d3a4f5e6b", conversation_id=conv.id, status="completed", thinking=False,
    origin="app", queued_at=t0, started_at=t0 + timedelta(seconds=1), ended_at=t0 + timedelta(seconds=3),
    usage={"input_tokens": 17315, "output_tokens": 63, "cache_read_tokens": 17152},
    perf={"sse_reconnects": 0, "first_delta_s": 2.96, "context_source": "final_read", "llama_calls_seen": 2,
          "prompt_tokens": 122, "predicted_tokens": 63, "prefill_tps": 210.4, "gen_tps": 20.6}, error=None,
    model="Qwen3.8-27B · IQ4_XS")
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
# M: the model presets as the helper lists them (`llama.models`)
GB = 1000 ** 3
def preset(name, file, ctx=65536, size=None, label=None, note=None, vision=True, thinking="toggle", reason=None):
    return {"name": name, "file": file, "label": label, "note": note, "ctx": ctx, "vision": vision,
            "thinking": thinking, "size_bytes": size, "usable": reason is None, "reason": reason}
presets = {"active": "qwen38-27b-iq4xs", "models": [
    preset("qwen38-27b-iq4xs", "Qwen3.8-27B-UD-IQ4_XS.gguf", size=14252845984),
    preset("qwen38-27b-q6k", "Qwen3.8-27B-UD-Q6_K.gguf", size=int(22.1 * GB), note="Q6 since the RTX 3060"),
    preset("qwen38-27b-abl", "Qwen3.8-27B-abliterated-Q4_K_M.gguf", size=int(16.5 * GB),
           label="Qwen3.8-27B abliterated", vision=False),
    preset("reasoner-32b", "Reasoner-32B-Q4_K_M.gguf", size=int(19.8 * GB), thinking="always"),
    preset("qwen38-9b", "Qwen3.8-9B-Q8_0.gguf", ctx=32768, size=int(9.7 * GB), reason="context_below_64k"),
    preset("test-broken", "does-not-exist.gguf", vision=False, reason="model_missing"),
]}
system_running = system_out(Parts(checked_at=t0, hermes_ok=True, hermes_version="0.22.2",
    hermes_detail=detail, hermes_unit={"active_state": "active", "active_since": 1792535518},
    llama_unit={"active_state": "active", "active_since": 1792537434, "inactive_since": 1792535668},
    llama_healthy=True, props=Props("Qwen3.8-27B", "IQ4_XS", 65536, 1, file="Qwen3.8-27B-UD-IQ4_XS.gguf", vision=True),
    slot_busy=True, gen_tps=21.4, active_runs=1, queued_runs=1, gpus=gpus, presets=presets))
system_stopped = system_out(Parts(checked_at=t0, hermes_ok=True, hermes_version="0.22.2",
    hermes_detail=detail, hermes_unit={"active_state": "active", "active_since": 1792535518},
    llama_unit={"active_state": "inactive", "active_since": 1792535325, "inactive_since": 1792535668},
    known_slots=1, intent="stopped", queued_runs=2, presets=presets,
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

# W2/W3: a watch with its counters, a judged hit and a reserved one
watch = Watch(slug="rtx-4070-super-180k", name="RTX 4070 Super ≤180k", source="hardverapro",
    url="https://hardverapro.hu/aprok/hardver/videokartya/keres.php?stext=rtx+4070+super",
    criteria="Semmi nem utal rá, hogy a videokártyát bányászásra használták.",
    filters={"include": ["4070 super"], "any": [], "exclude": ["bánya"], "min_price": None,
             "max_price": 180000, "fetch_details": True, "notify_existing": False},
    stop_after_hit=False, schedule="15 8,13,19 * * *", def_hash="0" * 16, defined_at=t0 - timedelta(days=1),
    job_id="12abb4a038c0", job_state="scheduled", next_run_at=t0 + timedelta(hours=1),
    last_check_at=t0 - timedelta(minutes=20), last_status="ok", last_error_code=None, last_error=None,
    last_items=27, last_matched=1, errors_in_row=0, stopped_at=None,
    created_at=t0 - timedelta(days=1), updated_at=t0 - timedelta(minutes=20), deleted_at=None)
watch_counts = {"hits": 3, "hits_24h": 2, "pending": 1, "rejected": 2, "last_hit_at": t0 - timedelta(minutes=20)}
hit = WatchItem(id=17, slug=watch.slug, item_id="ha:8231467", card_id="a" * 32,
    title="Gigabyte RTX 4070 Super Gaming OC 12G – garanciális",
    url="https://hardverapro.hu/apro/gigabyte_rtx_4070_super_gaming_oc/friss.html", price="165 000 Ft",
    price_value=165000, location="Budapest XI.", posted="ma 13:02", excerpt="Garanciális, számlával.",
    reserved=False, verdict="match", reason="Nem említ bányászást; garanciális, számlával.", notify=True,
    attempts=1, seen_at=t0 - timedelta(minutes=20), judged_at=t0 - timedelta(minutes=19),
    notified_at=t0 - timedelta(minutes=19), available_at=None)

persona = Persona(
    sections=(
        Section("Basics", "- Name: Minta Bence. Lives in Győr.\n- Dog: Zsömle, a vizsla."),
        Section("Answering", "- Writes Hungarian, often without accents. Answer briefly.", True),
        Section("His own words", '- "a torony" = the desktop; "a kicsi" = the laptop.'),
    ),
    topics=(
        Topic("books", "Books", "what he reads", "- Scandinavian crime.", True),
        Topic("gepek", "Machines", "parts, disks and the home network", "- The desktop: 48 GB RAM."),
    ),
    available=True,
)
# N2: News (an invented reader; a merged sailing story with its text, a day of releases)
n_topic = NewsTopic(id="sailing", name="Sailing", description="America's Cup, SailGP, the Balaton.",
    position=0, enabled=True)
n_source = NewsSource(id="sail-world.com", topic_id="sailing", url="https://www.sail-world.com/rss",
    kind="feed", window_h=48, every_min=60, enabled=True, origin="import", last_at=t0,
    last_ok_at=t0, last_status="error", last_http=503, last_error_code="http_503",
    last_error="Service Unavailable", last_items=0, last_new=0, errors_in_row=3)
n_story = NewsItem(id=8121, key="0" * 32, source_id="sail-world.com", topic_id="sailing", kind="feed",
    title="Team USA launches its new AC75 ahead of the Naples regatta",
    url="https://www.sail-world.com/news/290112", publisher="Sail-World",
    excerpt="The American challenger rolled out its second boat in Naples.",
    published_at=t0 - timedelta(hours=2), seen_at=t0 - timedelta(hours=1, minutes=40), gn=False,
    releases=None, score=9, why="Vízre tette új AC75-ösét a Team USA Nápoly előtt.", setup=False,
    summary_hu="A Team USA vízre tette második AC75-ösét Nápolyban. A hajó két hét tesztelés után indul az előregattán.",
    text="The American challenger rolled out its second boat on Tuesday.\n\nTesting starts next week.",
    text_state="ok", text_error=None, text_url="https://www.sail-world.com/news/290112",
    text_at=t0 - timedelta(hours=1), read_at=None, saved_at=t0 - timedelta(minutes=30), feedback="more")
n_other = NewsItem(id=8133, publisher="Scuttlebutt", title="Team USA splashes AC75 number two",
    url="https://www.sailingscuttlebutt.com/2026/10/19/team-usa", published_at=t0 - timedelta(hours=1))
n_release = NewsItem(id=8140, key="1" * 32, source_id="llama-cpp", topic_id="local_ai", kind="release",
    title="llama.cpp - 2 releases (b11690 ... b11712)", url="https://github.com/ggml-org/llama.cpp/releases",
    publisher="llama.cpp", excerpt=None, published_at=t0, seen_at=t0, gn=False,
    releases=[{"tag": "b11712", "url": "https://github.com/ggml-org/llama.cpp/releases/tag/b11712",
               "published_at": t0.isoformat()},
              {"tag": "b11690", "url": "https://github.com/ggml-org/llama.cpp/releases/tag/b11690",
               "published_at": (t0 - timedelta(hours=5)).isoformat()}],
    score=6, why="Új llama.cpp kiadások a géped inference-szerveréhez.", setup=True, summary_hu=None,
    text_state=None, text_url=None, read_at=None, saved_at=None, feedback=None)
n_item = nw.item_out(n_story, 2)
n_rel = nw.item_out(n_release)
n_story_out = {**n_item, "others": [nw.other_out(n_other)], "text": n_story.text,
    "text_at": n_story.text_at.isoformat(), "text_now": False, "text_error": None}
shapes = {
    "news_item": n_item,
    "news_item_release": n_rel,
    "news_release": n_release.releases[0],
    "news_story": n_story_out,
    "news_story_failed": {**n_rel, **nw.item_out(NewsItem(**{c: getattr(n_story, c) for c in (
        "id", "source_id", "topic_id", "kind", "title", "url", "publisher", "excerpt", "published_at",
        "seen_at", "gn", "releases", "score", "why", "setup", "read_at", "saved_at", "feedback")},
        summary_hu=None, text_state="failed", text_url=None)), "others": [], "text": None, "text_at": None,
        "text_now": False,
        "text_error": "robots"},
    "news_other": nw.other_out(n_other),
    "news_section": {"topic": "sailing", "name": "Sailing", "count": 4, "week": 14, "new": 2,
                     "top": [n_item]},
    "news_digest": {"top": [n_item, n_rel], "new": 12, "updated_at": t0.isoformat(), "state": "ok",
                    "sources": 41, "failing": 3, "weekly": {"count": 8}},
    "news_topic": nw.topic_out(n_topic, {"sources": 7, "items_24h": 5}),
    "news_source": nw.source_out(n_source, t0 - timedelta(hours=5)),
    "news_settings": nw.settings_out({"setup": "An invented reader's desktop.", "digest_at": "07:00",
                                      "push": True, "push_max": 2}),
    "watch": watch_out(watch, watch_counts),
    "watch_item": item_out(hit),
    "conversation": conversation_out(conv),
    "message": message_out(msg),
    "message_user": message_out(umsg, [attachment_out(att)]),
    "attachment": attachment_out(att),
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
    "llama_model": system_running["llama"]["models"][1],
    "llama_switch": switch_out("failed", src="qwen38-27b-iq4xs", to="reasoner-32b", by="Pixel 9 Pro XL",
        at=(t0 - timedelta(minutes=2)).isoformat(), error="exited", elapsed_s=34),
    "schedule": schedule_out(brief_sched),
    "schedule_prompt": schedule_out(prompt_sched),
    # API 22: GET /api/v1/schedules/{id}/runs
    "schedule_run": schedule_run_out(Run(**{**{c: getattr(run, c) for c in (
        "conversation_id", "thinking", "usage", "perf", "model")},
        "run_id": "run_4a7c2e9b1d3f5a6c", "status": "completed", "origin": "schedule",
        "queued_at": t0 - timedelta(minutes=47), "started_at": t0 - timedelta(minutes=47),
        "ended_at": t0 - timedelta(minutes=46), "error": None}), conv.title),
    "schedule_run_failed": schedule_run_out(Run(**{**{c: getattr(run, c) for c in (
        "conversation_id", "thinking", "model")},
        "run_id": "run_0d2f4b6a8c1e3a5b", "status": "failed", "origin": "schedule",
        "queued_at": t0 - timedelta(hours=12), "started_at": t0 - timedelta(hours=12),
        "ended_at": t0 - timedelta(hours=12) + timedelta(seconds=9), "usage": None, "perf": None,
        "error": "llama-server is not running"}), None),
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
    # DA2: GET /api/v1/mirror (the desktop agent asked three seconds ago)
    "mirror": mirror_out(connected=True, seen_s=3.2),
    # P1: GET /api/v1/persona (an invented person; one section and one topic for General)
    "persona": persona_out(persona, Path("/var/lib/delve-persona")),
    "persona_section": section_out(persona.sections[1]),
    "persona_topic": topic_out(persona.topics[1]),
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
    "watch.updated": watch_out(watch, watch_counts),
    "watch.item": item_out(hit),
    "news.updated": {"new": 3, "texts": 1, "updated_at": t0.isoformat()},
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
                  "notify": {"approvals": True, "run_done": False, "water": False, "brief": False, "watches": True, "system": True, "news": False}},
}
out = {"_note": "Generated from delve-backend serializers (decision 176); keys must equal contract.json.",
       "shapes": shapes, "events": events, "connection": connection}
json.dump(out, sys.stdout, indent=2, ensure_ascii=False, default=str); print()
