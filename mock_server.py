#!/usr/bin/env python3
import argparse
import json
import os
import sys
from http.server import BaseHTTPRequestHandler, HTTPServer
from datetime import datetime


class SimpleHandler(BaseHTTPRequestHandler):
    def _send(self, code=200, body=None):
        self.send_response(code)
        self.send_header("Content-Type", "application/json")
        self.end_headers()
        if body is None:
            body = {}
        self.wfile.write(json.dumps(body).encode("utf-8"))

    def do_GET(self):  # noqa: N802
        body = {
            "ok": True,
            "method": "GET",
            "path": self.path,
            "ts": datetime.utcnow().isoformat() + "Z",
        }
        self._send(200, body)

    def do_POST(self):  # noqa: N802
        length = int(self.headers.get("Content-Length", 0))
        data = self.rfile.read(length) if length > 0 else b""
        # Store payloads in tmp directory for debugging
        tmp_dir = os.path.join(os.path.dirname(__file__), "tmp")
        os.makedirs(tmp_dir, exist_ok=True)
        fname = os.path.join(
            tmp_dir, f"payload_{datetime.utcnow().strftime('%Y%m%dT%H%M%SZ')}.bin"
        )
        try:
            with open(fname, "wb") as f:
                f.write(data)
        except Exception:
            pass

        body = {
            "ok": True,
            "method": "POST",
            "path": self.path,
            "bytes": len(data),
            "ts": datetime.utcnow().isoformat() + "Z",
        }
        self._send(200, body)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--port", type=int, default=8080)
    args = parser.parse_args()

    server = HTTPServer(("0.0.0.0", args.port), SimpleHandler)
    print(f"Mock server listening on :{args.port}")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        server.server_close()


if __name__ == "__main__":
    sys.exit(main())


