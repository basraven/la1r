import json
import logging
import os
import time
import threading
from pathlib import Path

from fastapi import FastAPI, HTTPException, Body, Request, Depends
from fastapi.responses import HTMLResponse
from kubernetes import client, config
from kubernetes.client.rest import ApiException

app = FastAPI()

# Parse deployment configs
_raw = os.getenv("TOGGLE_DEPLOYMENTS", '[{"name":"enshrouded","namespace":"gaming"}]')
DEPLOYMENT_CONFIGS = []
for dep in json.loads(_raw):
    DEPLOYMENT_CONFIGS.append({
        "name": dep["name"],
        "namespace": dep["namespace"],
        "mode": dep.get("mode", "simple"),
        "options": dep.get("options", [1, 2, 4]),
    })

HTML = Path("/app/index.html").read_text()
TOKEN = os.getenv("TOKEN") or ""

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")
logger = logging.getLogger(__name__)

# --- Timer & uptime tracking ---
_timers = {}       # "ns/name" -> expiry timestamp
_start_times = {}  # "ns/name" -> start timestamp
_timers_lock = threading.Lock()


def _get_api():
    config.load_incluster_config()
    return client.AppsV1Api()


def _get_dep_config(name: str, namespace: str):
    for dep in DEPLOYMENT_CONFIGS:
        if dep["name"] == name and dep["namespace"] == namespace:
            return dep
    return None


def _remaining_seconds(key: str) -> int:
    with _timers_lock:
        expiry = _timers.get(key)
        if expiry is None:
            return 0
        remaining = int(expiry - time.time())
        if remaining <= 0:
            return 0
        return remaining


def _uptime_seconds(key: str) -> int:
    with _timers_lock:
        start = _start_times.get(key)
        if start is None:
            return 0
        return int(time.time() - start)


def _timer_worker():
    while True:
        time.sleep(15)
        now = time.time()
        to_expire = []
        with _timers_lock:
            for key, expiry in list(_timers.items()):
                if expiry <= now:
                    to_expire.append(key)
        for key in to_expire:
            namespace, name = key.split("/", 1)
            try:
                api = _get_api()
                body = {"spec": {"replicas": 0}}
                api.patch_namespaced_deployment_scale(
                    name=name, namespace=namespace, body=body
                )
                with _timers_lock:
                    del _timers[key]
                    _start_times.pop(key, None)
            except Exception as e:
                logger.warning(
                    "Failed to scale down %s/%s to 0: %s", namespace, name, e
                )


threading.Thread(target=_timer_worker, daemon=True).start()

# Initialize start times from actual deployment conditions
try:
    _api = _get_api()
    for dep in DEPLOYMENT_CONFIGS:
        key = f"{dep['namespace']}/{dep['name']}"
        deploy = _api.read_namespaced_deployment(
            name=dep["name"], namespace=dep["namespace"]
        )
        if (deploy.status and deploy.status.conditions and
                deploy.spec.replicas and deploy.spec.replicas > 0):
            for c in deploy.status.conditions:
                if c.type == "Available" and c.status == "True":
                    _start_times[key] = c.last_transition_time.timestamp()
                    break
except Exception as e:
    logger.warning("Failed to initialize start times: %s", e)


# --- Token auth ---

def verify_token(request: Request):
    """Dependency: validates token from Authorization header or ?token= query param."""
    if not TOKEN:
        return
    auth = request.headers.get("Authorization", "")
    token_from_header = auth[7:] if auth.startswith("Bearer ") else ""
    token_from_query = request.query_params.get("token", "")
    if token_from_header != TOKEN and token_from_query != TOKEN:
        raise HTTPException(status_code=401, detail="Invalid or missing token")


@app.get("/api/verify-token")
def verify_token_endpoint(request: Request):
    """Auth endpoint used by Traefik forwardAuth middleware."""
    verify_token(request)
    return {"status": "ok"}


# --- API ---

@app.get("/api/status", dependencies=[Depends(verify_token)])
def get_status():
    results = []
    api = _get_api()
    for dep in DEPLOYMENT_CONFIGS:
        key = f"{dep['namespace']}/{dep['name']}"
        try:
            scale = api.read_namespaced_deployment_scale(
                name=dep["name"], namespace=dep["namespace"]
            )
            replicas = scale.spec.replicas or 0
            remaining = _remaining_seconds(key)
            uptime = _uptime_seconds(key) if replicas > 0 else 0
            results.append({
                "name": dep["name"],
                "namespace": dep["namespace"],
                "replicas": replicas,
                "status": "online" if replicas > 0 else ("timed" if remaining > 0 else "offline"),
                "mode": dep["mode"],
                "options": dep["options"],
                "remaining_seconds": remaining,
                "uptime_seconds": uptime,
            })
        except ApiException as e:
            results.append({
                "name": dep["name"],
                "namespace": dep["namespace"],
                "replicas": 0,
                "status": "error",
                "mode": dep["mode"],
                "options": dep["options"],
                "remaining_seconds": 0,
                "uptime_seconds": 0,
                "error": str(e),
            })
    return results


@app.post("/api/toggle/{namespace}/{name}", dependencies=[Depends(verify_token)])
def toggle(name: str, namespace: str, body: dict = Body({})):
    key = f"{namespace}/{name}"
    try:
        api = _get_api()
        scale = api.read_namespaced_deployment_scale(
            name=name, namespace=namespace
        )
        current = scale.spec.replicas or 0
        hours = body.get("hours")

        if hours is not None and hours != 0:
            # Add/subtract hours from timer
            with _timers_lock:
                existing = _timers.get(key)
                if existing is not None:
                    existing += hours * 3600
                    if existing <= time.time():
                        _timers.pop(key, None)
                        _start_times.pop(key, None)
                        new_replicas = 0
                    else:
                        _timers[key] = existing
                        new_replicas = 1
                elif hours > 0:
                    _timers[key] = time.time() + hours * 3600
                    if current == 0:
                        _start_times[key] = time.time()
                    new_replicas = 1
                else:
                    new_replicas = current  # negative hours with no timer = no-op
        elif current > 0:
            # Turn off
            new_replicas = 0
            with _timers_lock:
                _timers.pop(key, None)
                _start_times.pop(key, None)
        else:
            # Turn on (no timer — simple mode)
            new_replicas = 1
            with _timers_lock:
                _timers.pop(key, None)
                _start_times[key] = time.time()

        body = {"spec": {"replicas": new_replicas}}
        api.patch_namespaced_deployment_scale(
            name=name, namespace=namespace, body=body
        )
        remaining = _remaining_seconds(key) if new_replicas > 0 else 0
        uptime = _uptime_seconds(key) if new_replicas > 0 else 0
        return {
            "name": name,
            "namespace": namespace,
            "replicas": new_replicas,
            "status": "online" if new_replicas > 0 else "offline",
            "remaining_seconds": remaining,
            "uptime_seconds": uptime,
        }
    except ApiException as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/", response_class=HTMLResponse, dependencies=[Depends(verify_token)])
def index():
    return HTMLResponse(HTML)
