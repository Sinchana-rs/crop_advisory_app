"""
End-to-end language + TTS checks against a RUNNING Flask server.

    python app.py                      # terminal 1
    python test_language_endpoints.py  # terminal 2

Checks that every AI endpoint answers in the requested language (by
script), that /tts returns real MP3 audio for en / kn / hi (including a
long Kannada text), and that switching languages repeatedly never mixes
languages.
"""
import io
import sys

import requests

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")

BASE = "http://127.0.0.1:5000"


def counts(text):
    kn = sum(1 for c in text if "\u0c80" <= c <= "\u0cff")
    hi = sum(1 for c in text if "\u0900" <= c <= "\u097f")
    la = sum(1 for c in text if c.isascii() and c.isalpha())
    return kn, hi, la


def lang_ok(text, code):
    kn, hi, la = counts(text)
    tot = max(kn + hi + la, 1)
    if code == "kn":
        return kn / tot >= 0.6 and hi == 0
    if code == "hi":
        return hi / tot >= 0.6 and kn == 0
    return kn == 0 and hi == 0


results = []


def record(name, ok, detail=""):
    results.append((name, ok))
    print(("PASS" if ok else "FAIL"), "-", name, detail)


def post(path, payload, timeout=120):
    return requests.post(BASE + path, json=payload, timeout=timeout)


for code in ("en", "kn", "hi"):
    r = post("/predict_irrigation", {
        "soil_moisture": 22, "temperature": 31, "humidity": 55, "lang": code})
    j = r.json()
    text = j.get("recommendation", "") + " " + j.get("message", "")
    record(f"irrigation[{code}]", r.status_code == 200 and lang_ok(text, code),
           f"decision={j.get('decision')} ai_localized={j.get('ai_localized')} :: {text[:90]!r}")

for code in ("en", "kn", "hi"):
    r = post("/predict_fertilizer", {
        "crop": "Tomato", "soil_type": "Loamy", "ph": 6.5, "lang": code})
    j = r.json()
    text = j.get("recommendation", "")
    record(f"fertilizer[{code}]", r.status_code == 200 and lang_ok(text, code),
           f"chars={len(text)} language_ok={j.get('language_ok')} :: {text[:70]!r}")

for code, loc in (("en", "en-IN"), ("kn", "kn-IN"), ("hi", "hi-IN")):
    r = post("/ai_voice_advisor", {
        "question": "How much water does a tomato crop need?", "lang": loc})
    j = r.json()
    text = j.get("answer", "")
    record(f"voice-ai[{loc}]", r.status_code == 200 and lang_ok(text, code),
           f"chars={len(text)} :: {text[:70]!r}")

samples = {
    "en": "Water the tomato crop early in the morning and avoid wet leaves. " * 3,
    "hi": "टमाटर की फसल को सुबह जल्दी पानी दें और पत्तियों को गीला न करें। " * 3,
    "kn": "ಟೊಮೆಟೊ ಬೆಳೆಗೆ ಬೆಳಿಗ್ಗೆ ಬೇಗ ನೀರು ಹಾಕಿ ಮತ್ತು ಎಲೆಗಳನ್ನು ಒದ್ದೆ ಮಾಡಬೇಡಿ. " * 3,
}
samples["kn_long"] = ("ಟೊಮೆಟೊ ಬೆಳೆಗೆ ಸಾರಜನಕ, ರಂಜಕ ಮತ್ತು ಪೊಟ್ಯಾಸಿಯಂ ಸಮತೋಲನದಲ್ಲಿ ಬೇಕು. "
                      "ಮಣ್ಣಿನ pH ಅನ್ನು ಪರೀಕ್ಷಿಸಿ ನಂತರ ಗೊಬ್ಬರ ಹಾಕಿ. ") * 25

for name, text in samples.items():
    code = name.split("_")[0]
    r = post("/tts", {"text": text, "lang": code}, timeout=180)
    ct = r.headers.get("Content-Type", "")
    is_mp3 = r.content[:3] == b"ID3" or (len(r.content) > 2 and r.content[0] == 0xFF)
    record(f"tts[{name}] chars={len(text)}",
           r.status_code == 200 and "audio" in ct and is_mp3 and len(r.content) > 5000,
           f"bytes={len(r.content)} type={ct}")
    if name in ("kn", "kn_long"):
        open(rf"C:\Users\Admin\AppData\Local\Temp\tts_{name}.mp3", "wb").write(r.content)

seq = ["kn", "hi", "en", "kn", "en", "hi", "kn"]
mixed = 0
for code in seq:
    r = post("/ai_voice_advisor", {"question": "When should I apply urea?", "lang": code})
    if not lang_ok(r.json().get("answer", ""), code):
        mixed += 1
record("rapid language switching has no mixed/wrong language", mixed == 0, f"sequence={seq} bad={mixed}")

failed = [n for n, ok in results if not ok]
print("\nSUMMARY:", len(results) - len(failed), "passed,", len(failed), "failed")
sys.exit(1 if failed else 0)
