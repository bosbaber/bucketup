import os
from http.server import SimpleHTTPRequestHandler, HTTPServer

CONTENT_DIR = 'content'


class CustomHandler(SimpleHTTPRequestHandler):
    def translate_path(self, path):
        # Strip query string/fragment and normalize
        path = path.split('?', 1)[0].split('#', 1)[0]
        path = os.path.normpath(path.lstrip('/'))
        return os.path.join(CONTENT_DIR, path)

    def do_GET(self):
        # Health check endpoint
        if self.path == "/healthz":
            self.send_response(200)
            self.send_header("Content-type", "text/plain")
            self.end_headers()
            self.wfile.write(b"ok\n")
            return

        requested_path = self.translate_path(self.path)
        if not os.path.exists(requested_path):
            # Redirect to root for unknown paths
            self.send_response(302)
            self.send_header('Location', '/')
            self.end_headers()
            return

        return super().do_GET()


if __name__ == "__main__":
    if not os.path.exists(CONTENT_DIR):
        raise FileNotFoundError(f"Content directory '{CONTENT_DIR}' does not exist.")

    port = 8080
    print(f"Serving {CONTENT_DIR} on port {port}")
    with HTTPServer(("", port), CustomHandler) as httpd:
        httpd.serve_forever()
