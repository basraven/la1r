import json, logging, os, ssl, sys, urllib.request, urllib.error
from http.server import HTTPServer, BaseHTTPRequestHandler

NTFY_URL = os.environ.get("NTFY_URL", "http://ntfy.monitoring.svc.cluster.local/k8s-status")
API_HOST = "https://kubernetes.default.svc"
TOKEN_PATH = "/var/run/secrets/kubernetes.io/serviceaccount/token"
CA_PATH = "/var/run/secrets/kubernetes.io/serviceaccount/ca.crt"

with open(TOKEN_PATH) as f:
    TOKEN = f.read().strip()

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(message)s", stream=sys.stderr)
logger = logging.getLogger("kubewatch-filter")

def fetch_event(namespace, name):
    url = f"{API_HOST}/api/v1/namespaces/{namespace}/events/{name}"
    req = urllib.request.Request(url, headers={"Authorization": f"Bearer {TOKEN}"})
    ctx = ssl.create_default_context(cafile=CA_PATH)
    try:
        with urllib.request.urlopen(req, context=ctx, timeout=10) as resp:
            return json.loads(resp.read())
    except urllib.error.HTTPError as e:
        if e.code == 404:
            return None
        logger.error(f"K8s API {e.code} fetching event {namespace}/{name}")
        return None
    except urllib.error.URLError as e:
        logger.error(f"K8s API error fetching event {namespace}/{name}: {e}")
        return None

class Handler(BaseHTTPRequestHandler):
    def do_POST(self):
        body = self.rfile.read(int(self.headers.get("Content-Length", 0)))
        try:
            payload = json.loads(body)
        except json.JSONDecodeError:
            return self._respond(400, "invalid json")

        meta = payload.get("eventmeta", {})
        if meta.get("kind") != "Event":
            return self._respond(200, "ignored")

        namespace = meta.get("namespace", "")
        name = meta.get("name", "")

        event = fetch_event(namespace, name)
        if event is None:
            return self._respond(200, "gone")

        event_type = event.get("type", "")
        if event_type != "Warning":
            return self._respond(200, "dropped")

        reason = event.get("reason", "")
        involved = event.get("involvedObject", {})
        msg = event.get("message", "")
        obj_name = f"{involved.get('namespace', namespace)}/{involved.get('name', name)}"
        logger.info(f"Forwarding Warning: {reason} - {obj_name}")

        try:
            ntfy_body = json.dumps({
                "topic": "k8s-status",
                "title": f"⚠️ {reason}",
                "message": f"[{reason}] {obj_name}: {msg}",
                "tags": ["warning", "kubernetes"]
            }).encode()
            req = urllib.request.Request(
                NTFY_URL, data=ntfy_body,
                headers={"Content-Type": "application/json"},
                method="POST"
            )
            urllib.request.urlopen(req, timeout=10)
            self._respond(200, "forwarded")
        except urllib.error.URLError as e:
            logger.error(f"ntfy error: {e}")
            self._respond(502, "upstream error")

    def _respond(self, code, msg):
        self.send_response(code)
        self.end_headers()
        self.wfile.write(msg.encode())

    def log_message(self, fmt, *args):
        pass

HTTPServer(("0.0.0.0", 8080), Handler).serve_forever()
