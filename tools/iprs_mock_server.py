#!/usr/bin/env python3
"""MOCK IPRS verification backend for the workshop (Python standard library only).

Flow:  phone (on-device OCR) --text fields only--> this backend --> IPRS lookup
       <-- match verdict only -------------------

* The photo never leaves the phone.
* IPRS data never reaches the phone: only a per-field match verdict does.
* In production the backend calls IPRS through whatever authorised access your
  organisation has. Credentials stay on the server, never in the app. This mock
  uses a tiny FICTIONAL registry shaped like an IPRS record; real IPRS response
  fields depend on your access channel.

Run:  python3 tools/iprs_mock_server.py
App:  flutter run --dart-define=VERIFY_SERVER_URL=http://<laptop-ip>:8000/verify
Phone and laptop must be on the same network (or use a hotspot).

Request : {"surname": "...", "givenNames": "...", "idNumber": "...", "dateOfBirth": "..."}
Response: {"verified": bool, "message": "...",
           "fields": {"surname": {"match": bool, "score": 0.97}, ...}}

Matching rules (OCR is noisy, so it is not all exact):
  idNumber     exact, after ignoring case, spaces and punctuation
  dateOfBirth  exact date, any common format (01 JAN 1990, 01.01.1990, 1990-01-01 ...)
  names        fuzzy (score >= 0.80), word order ignored

Demo only: plain http, no auth. Production needs HTTPS, authentication, audit
logging WITHOUT personal data, and a lawful basis (e.g. Kenya Data Protection Act, 2019).
"""
import json
import re
from datetime import datetime
from difflib import SequenceMatcher
from http.server import BaseHTTPRequestHandler, HTTPServer

# Tunable policy choice: lower accepts more OCR slips, higher rejects more near-misses.
NAME_THRESHOLD = 0.80

# FICTIONAL record matching samples/fictional_id_front.png
IPRS_RECORDS = {
    "TL1234567": {
        "surname": "TESTER",
        "firstName": "SAMPLE",
        "otherNames": "PERSON",
        "dateOfBirth": "1990-01-01",
    }
}

DATE_FORMATS = ["%d %b %Y", "%d %B %Y", "%d.%m.%Y", "%d/%m/%Y", "%d-%m-%Y", "%Y-%m-%d"]


def norm(value):
    """Uppercase and strip everything but letters and digits."""
    return re.sub(r"[^A-Z0-9]", "", (value or "").upper())


def name_key(value):
    """Words uppercased, punctuation removed, sorted: word order is ignored."""
    words = re.sub(r"[^A-Z ]", " ", (value or "").upper()).split()
    return " ".join(sorted(words))


def parse_date(value):
    text = re.sub(r"\s+", " ", (value or "").strip().upper())
    for fmt in DATE_FORMATS:
        try:
            return datetime.strptime(text, fmt).date()
        except ValueError:
            continue
    return None


def compare_names(ocr_value, iprs_value):
    score = SequenceMatcher(None, name_key(ocr_value), name_key(iprs_value)).ratio()
    return {"match": score >= NAME_THRESHOLD, "score": round(score, 2)}


def verify(data):
    record = IPRS_RECORDS.get(norm(data.get("idNumber")))
    if record is None:
        return {"verified": False, "fields": {}, "message": "No IPRS record found for this ID number."}

    fields = {"idNumber": {"match": True, "score": 1.0}}
    if data.get("surname") is not None:
        fields["surname"] = compare_names(data["surname"], record["surname"])
    if data.get("givenNames") is not None:
        iprs_given = f"{record['firstName']} {record['otherNames']}"
        fields["givenNames"] = compare_names(data["givenNames"], iprs_given)
    if data.get("dateOfBirth") is not None:
        ocr_date = parse_date(data["dateOfBirth"])
        iprs_date = parse_date(record["dateOfBirth"])
        ok = ocr_date is not None and ocr_date == iprs_date
        fields["dateOfBirth"] = {"match": ok, "score": 1.0 if ok else 0.0}

    verified = all(f["match"] for f in fields.values())
    message = (
        "The card details match the IPRS record."
        if verified
        else "Some details on the card do not match the IPRS record."
    )
    return {"verified": verified, "fields": fields, "message": message}


class Handler(BaseHTTPRequestHandler):
    def do_POST(self):
        length = int(self.headers.get("Content-Length", 0))
        try:
            data = json.loads(self.rfile.read(length) or b"{}")
        except json.JSONDecodeError:
            self.send_error(400)
            return
        body = json.dumps(verify(data)).encode()
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, *args):
        pass  # never log personal data


if __name__ == "__main__":
    print("Mock IPRS verification on http://0.0.0.0:8000/verify")
    HTTPServer(("0.0.0.0", 8000), Handler).serve_forever()