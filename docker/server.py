import os
from http.server import SimpleHTTPRequestHandler, HTTPServer
from urllib.parse import urlsplit

CONTENT_DIR = 'content'
PORT = 8080


def _is_health(path: str) -> bool:
    # Accept /healthz, /healthz/, and /healthz?...
    parts = urlsplit(path)  # strips query/fragment cleanly
    p = parts.path.rstrip('/')
    return p == "/healthz"

class CustomHandler(SimpleHTTPRequestHandler):
    # Ensure we always serve from CONTENT_DIR
    def translate_path(self, path):
        parts = urlsplit(path)
        # normalize path without leading slash
        clean = os.path.normpath(parts.path.lstrip('/'))
        return os.path.join(CONTENT_DIR, clean)

    # Health response writer used by GET/HEAD
    def _write_health(self, head_only: bool):
        self.send_response(200)
        self.send_header("Content-Type", "text/plain; charset=utf-8")
        body = b"ok\n"
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        if not head_only:
            self.wfile.write(body)

    def do_HEAD(self):
        if _is_health(self.path):
            return self._write_health(head_only=True)
        # For HEAD on static files, fall back to parent
        return super().do_HEAD()

    def do_GET(self):
        # Health check first, accept variants
        if _is_health(self.path):
            return self._write_health(head_only=False)

        # Resolve requested file
        requested_path = self.translate_path(self.path)

        if os.path.isdir(requested_path):
            # Serve index.html from a directory if present
            for name in ("index.html", "index.htm", "default.html", "default.htm"):
                index_path = os.path.join(requested_path, name)
                if os.path.exists(index_path):
                    self.path = os.path.join(self.path.rstrip('/'), name)
                    return super().do_GET()

        if os.path.exists(requested_path):
            return super().do_GET()

        # SPA fallback: serve root index.html when route isn't a real file
        spa_index = os.path.join(CONTENT_DIR, "index.html")
        if os.path.exists(spa_index):
            self.path = "/index.html"
            return super().do_GET()

        # If no SPA index, return 404
        self.send_error(404, "File not found")

if __name__ == "__main__":
    if not os.path.exists(CONTENT_DIR):
        raise FileNotFoundError(f"Content directory '{CONTENT_DIR}' does not exist.")
    print(f"Serving {CONTENT_DIR} on port {PORT}")
    with HTTPServer(("", PORT), CustomHandler) as httpd:
        httpd.serve_forever()
