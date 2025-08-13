import os
from http.server import SimpleHTTPRequestHandler, HTTPServer

CONTENT_DIR = 'content'

# Common index file names to look for
INDEX_NAMES = ["index.html", "index.htm", "default.html", "default.htm"]

def find_index_file():
    for name in INDEX_NAMES:
        index_path = os.path.join(CONTENT_DIR, name)
        if os.path.isfile(index_path):
            return name
    return None

INDEX_FILE = find_index_file()
if not INDEX_FILE:
    raise FileNotFoundError(f"No index file found in {CONTENT_DIR}")

class CustomHandler(SimpleHTTPRequestHandler):
    def translate_path(self, path):
        """Serve files from CONTENT_DIR instead of the current directory."""
        # Strip query string or fragment
        path = path.split('?', 1)[0].split('#', 1)[0]
        path = os.path.normpath(path.lstrip('/'))
        return os.path.join(CONTENT_DIR, path)

    def do_GET(self):
        requested_path = self.translate_path(self.path)
        if not os.path.exists(requested_path) or os.path.isdir(requested_path):
            # Serve index file when path not found or is a directory
            self.path = '/' + INDEX_FILE
        return super().do_GET()

if __name__ == "__main__":
    # If no content directory exists, error out
    if not os.path.exists(CONTENT_DIR):
        raise FileNotFoundError(f"Content directory '{CONTENT_DIR}' does not exist.")

    port = 8080
    print(f"Serving {CONTENT_DIR} on port {port}")
    with HTTPServer(("", port), CustomHandler) as httpd:
        httpd.serve_forever()
