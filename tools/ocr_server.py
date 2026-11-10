#!/usr/bin/env python3
"""Reference server-side OCR for the on-device vs server demo.

Setup:   pip install pillow pytesseract    (and install the Tesseract binary)
Run:     python3 tools/ocr_server.py
App:     flutter run --dart-define=OCR_SERVER_URL=http://<laptop-ip>:8000/ocr
Phone and laptop must be on the same network (or use a hotspot).
Android blocks plain http by default: see the manifest notes in the README.

Contract: POST the JPEG bytes, get back
  {"width": W, "height": H,
   "lines": [{"text": "...", "left": 0, "top": 0, "right": 0, "bottom": 0}]}
"""
import io
import json
from http.server import BaseHTTPRequestHandler, HTTPServer

import pytesseract
from PIL import Image, ImageOps


def read_lines(image):
    data = pytesseract.image_to_data(image, output_type=pytesseract.Output.DICT)
    grouped = {}
    for i, text in enumerate(data["text"]):
        if not text.strip():
            continue
        key = (data["block_num"][i], data["par_num"][i], data["line_num"][i])
        left, top = data["left"][i], data["top"][i]
        right, bottom = left + data["width"][i], top + data["height"][i]
        entry = grouped.setdefault(
            key, {"words": [], "left": left, "top": top, "right": right, "bottom": bottom}
        )
        entry["words"].append(text)
        entry["left"] = min(entry["left"], left)
        entry["top"] = min(entry["top"], top)
        entry["right"] = max(entry["right"], right)
        entry["bottom"] = max(entry["bottom"], bottom)
    return [
        {
            "text": " ".join(e["words"]),
            "left": e["left"],
            "top": e["top"],
            "right": e["right"],
            "bottom": e["bottom"],
        }
        for e in grouped.values()
    ]


class Handler(BaseHTTPRequestHandler):
    def do_POST(self):
        length = int(self.headers.get("Content-Length", 0))
        image = Image.open(io.BytesIO(self.rfile.read(length)))
        image = ImageOps.exif_transpose(image).convert("RGB")  # match what the user sees
        body = json.dumps(
            {"width": image.width, "height": image.height, "lines": read_lines(image)}
        ).encode()
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)


if __name__ == "__main__":
    print("OCR server on http://0.0.0.0:8000/ocr")
    HTTPServer(("0.0.0.0", 8000), Handler).serve_forever()