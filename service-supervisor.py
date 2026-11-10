#!/usr/bin/env python3
"""Manage ttyd and Hermes Gateway with graceful shutdown and restart handling."""
from __future__ import annotations
import asyncio
import os
import signal
from pathlib import Path

def log(message: str) -> None:
    print(f"[service-supervisor] {message}", flush=True)

async def terminate_process_group(proc: asyncio.subprocess.Process, label: str) -> None:
    if proc.returncode is not None: return
    try: os.killpg(proc.pid, signal.SIGTERM)
    except ProcessLookupError: pass
    try: await asyncio.wait_for(proc.wait(), timeout=10)
    except asyncio.TimeoutError:
        log(f"{label} did not stop within 10 seconds; sending SIGKILL.")
        try: os.killpg(proc.pid, signal.SIGKILL)
        except ProcessLookupError: pass
        await proc.wait()

async def gateway_loop(stop_event: asyncio.Event, env: dict[str, str]) -> None:
    retry_seconds = 15
    while not stop_event.is_set():
        proc: asyncio.subprocess.Process | None = None
        try:
            proc = await asyncio.create_subprocess_exec("hermes", "gateway", "run", cwd="/data", env=env, start_new_session=True)
            log(f"Hermes Gateway started (pid {proc.pid}).")
            code = await proc.wait()
            if stop_event.is_set(): return
            log(f"Hermes Gateway exited with code {code}; retrying in {retry_seconds} seconds.")
        except asyncio.CancelledError:
            if proc is not None: await terminate_process_group(proc, "Hermes Gateway")
            raise
        except Exception as exc:
            log(f"Hermes Gateway could not start ({type(exc).__name__}); retrying in {retry_seconds} seconds.")
        try: await asyncio.wait_for(stop_event.wait(), timeout=retry_seconds)
        except asyncio.TimeoutError: continue

async def main() -> int:
    if os.geteuid() == 0:
        log("Refusing to run services as root; expected UID 10001.")
        return 1
    env = os.environ.copy()
    env.update({"HOME":"/home/hermes","USER":"hermes","LOGNAME":"hermes","PATH":"/home/hermes/.local/bin:/home/hermes/.local/share/uv/bin:/usr/local/bin:/usr/bin:/bin"})
    terminal_user, terminal_password = env.get("TERMINAL_USER",""), env.get("TERMINAL_PASSWORD","")
    port = env.get("PORT","8080")
    if not terminal_user or not terminal_password:
        log("TERMINAL_USER and TERMINAL_PASSWORD must be set.")
        return 1
    ttyd_command = [
        "/usr/local/bin/ttyd","--debug","3","--check-origin","--port",port,
        "--credential",f"{terminal_user}:{terminal_password}","--writable","--cwd","/data",
        "/bin/bash","--login",
    ]
    stop_event = asyncio.Event()
    loop = asyncio.get_running_loop()
    for sig in (signal.SIGTERM,signal.SIGINT): loop.add_signal_handler(sig,stop_event.set)
    terminal_proc = await asyncio.create_subprocess_exec(*ttyd_command,cwd="/data",env=env,start_new_session=True)
    log(f"Authenticated browser terminal started (pid {terminal_proc.pid}).")
    enabled = env.get("HERMES_AUTOSTART","true").lower() in {"true","1"}
    config = Path(env.get("HERMES_HOME","/opt/data")) / "config.yaml"
    gateway_task = None
    if enabled and config.is_file(): gateway_task = asyncio.create_task(gateway_loop(stop_event,env))
    elif enabled: log(f"Hermes setup has not created {config}; Gateway auto-start is waiting for a service restart.")
    else: log("Hermes Gateway auto-start is disabled (HERMES_AUTOSTART=false).")
    terminal_wait = asyncio.create_task(terminal_proc.wait())
    shutdown_wait = asyncio.create_task(stop_event.wait())
    try:
        done,_ = await asyncio.wait({terminal_wait,shutdown_wait},return_when=asyncio.FIRST_COMPLETED)
        if terminal_wait in done and not stop_event.is_set():
            code = terminal_wait.result()
            log(f"ttyd exited unexpectedly with code {code}; requesting container restart.")
            stop_event.set()
            return code or 1
        log("Shutdown requested; stopping terminal and Gateway cleanly.")
        return 0
    finally:
        stop_event.set()
        if gateway_task is not None:
            gateway_task.cancel()
            await asyncio.gather(gateway_task,return_exceptions=True)
        if terminal_proc.returncode is None: await terminate_process_group(terminal_proc,"ttyd")
        for task in (terminal_wait,shutdown_wait):
            if not task.done(): task.cancel()
        await asyncio.gather(terminal_wait,shutdown_wait,return_exceptions=True)

if __name__ == "__main__":
    try: raise SystemExit(asyncio.run(main()))
    except KeyboardInterrupt: raise SystemExit(130)
