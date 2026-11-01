from flask import Flask, request, jsonify
from flask_cors import CORS
from google import genai
from dotenv import load_dotenv
import os
import time


# =========================================================
# LOAD ENVIRONMENT VARIABLES
# =========================================================

load_dotenv()


# =========================================================
# FLASK APP
# =========================================================

app = Flask(__name__)

CORS(app)


# =========================================================
# GEMINI CONFIGURATION
# =========================================================

GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")

if not GEMINI_API_KEY:

    print("======================================")
    print("WARNING: GEMINI_API_KEY NOT FOUND")
    print("Please check your .env file.")
    print("======================================")

    client = None

else:

    print("======================================")
    print("Gemini API key loaded successfully.")
    print("======================================")

    from google.genai import types as genai_types

    # 45 second limit per Gemini request, so a slow model can never
    # freeze the app; the next fallback model is tried instead.
    client = genai.Client(
        api_key=GEMINI_API_KEY,
        http_options=genai_types.HttpOptions(timeout=45000),
    )


# Gemini model
MODEL_NAME = "gemini-2.5-flash"

# Gemini keeps a separate quota for every model. When the main model
# has used up its quota (429) or no longer exists (404), the next
# model in this list is tried automatically. The model that worked
# last is tried first on the next request.
FALLBACK_MODELS = [
    "gemini-flash-lite-latest",
    "gemini-flash-latest",
]

_active_model = MODEL_NAME


def _gemini_generate(contents):
    global _active_model

    order = [_active_model] + [
        m for m in [MODEL_NAME] + FALLBACK_MODELS if m != _active_model
    ]

    first_error = None

    for model in order:
        try:
            response = client.models.generate_content(
                model=model,
                contents=contents,
            )

            if model != _active_model:
                print(f"Gemini model switched to: {model}")
                _active_model = model

            return response

        except Exception as e:
            text = str(e)

            retryable = any(
                s in text
                for s in (
                    "429",
                    "RESOURCE_EXHAUSTED",
                    "404",
                    "NOT_FOUND",
                    "503",
                    "UNAVAILABLE",
                    "504",
                    "DEADLINE_EXCEEDED",
                    "timed out",
                    "Timeout",
                )
            )

            if first_error is None:
                first_error = e

            print(f"Gemini model '{model}' failed: {text[:120]}")

            if not retryable:
                raise

    raise first_error


# =========================================================
# LANGUAGE SUPPORT (English / Kannada / Hindi)
# =========================================================
#
# The Flutter app sends either the short app code
# ("en", "kn", "hi") or a locale code ("kn-IN").
# Every AI endpoint normalises it with normalize_lang()
# and builds its prompt from the same LANGUAGES table,
# so the AI answer, the on-screen text and the speech
# always use the same language.
#

LANGUAGES = {
    "en": {
        "name": "English",
        "script": "English (Latin script)",
    },
    "kn": {
        "name": "Kannada",
        "script": "Kannada script (ಕನ್ನಡ ಲಿಪಿ)",
    },
    "hi": {
        "name": "Hindi",
        "script": "Hindi in Devanagari script (देवनागरी)",
    },
}


def normalize_lang(value):
    """'kn', 'kn-IN', 'KN_in' -> 'kn'. Unknown -> 'en'."""
    code = (
        str(value or "en")
        .strip()
        .lower()
        .replace("_", "-")
        .split("-")[0]
    )
    return code if code in LANGUAGES else "en"


def language_rules(code):
    """Prompt block forcing the whole answer into one language."""
    info = LANGUAGES[code]

    if code == "en":
        return (
            "LANGUAGE RULE: Write the COMPLETE answer in plain, "
            "simple English only. Do not use any Kannada or Hindi "
            "words or script."
        )

    return (
        f"LANGUAGE RULE (VERY IMPORTANT): Write the COMPLETE answer, "
        f"including every heading, label, sentence and list item, "
        f"in {info['name']} using {info['script']}. "
        f"Do NOT write any sentence or heading in English. "
        f"Do not add an English translation. "
        f"Only unavoidable technical tokens such as NPK, pH, DAP, "
        f"MOP, kg or acre may stay in Latin letters, and numbers "
        f"may use normal digits. Use simple words a farmer "
        f"understands and avoid markdown symbols such as ** or #."
    )


def _count_scripts(text):
    kannada = sum(1 for c in text if "\u0c80" <= c <= "\u0cff")
    devanagari = sum(1 for c in text if "\u0900" <= c <= "\u097f")
    latin = sum(1 for c in text if c.isascii() and c.isalpha())
    return kannada, devanagari, latin


def is_in_language(text, code):
    """
    Cheap script check used to catch wrong-language or mixed-language
    answers. Kannada/Hindi answers must be mostly in their own script;
    English answers must not contain Kannada/Devanagari.
    """
    kannada, devanagari, latin = _count_scripts(text)

    if code == "kn":
        total = kannada + devanagari + latin
        return total > 0 and kannada / total >= 0.6 and devanagari == 0

    if code == "hi":
        total = kannada + devanagari + latin
        return total > 0 and devanagari / total >= 0.6 and kannada == 0

    return kannada == 0 and devanagari == 0


def generate_in_language(prompt, code):
    """
    Calls Gemini with a language-aware prompt. If the answer is not
    in the requested language (or is mixed), asks Gemini once to
    rewrite it completely in that language. Returns the final text
    (may be empty) and whether it passed the language check.
    """
    response = _gemini_generate(prompt)

    text = (response.text or "").strip() if response else ""

    if not text or is_in_language(text, code):
        return text, bool(text)

    print(f"Answer was not fully in '{code}'. Rewriting once...")

    retry_prompt = f"""
Rewrite the text below so that it is written ENTIRELY in
{LANGUAGES[code]['name']} ({LANGUAGES[code]['script']}).
Keep the same meaning, structure and headings, but translate the
headings too. Return only the rewritten text.

{language_rules(code)}

TEXT:
{text}
"""

    retry = _gemini_generate(retry_prompt)

    fixed = (retry.text or "").strip() if retry else ""

    if fixed and is_in_language(fixed, code):
        return fixed, True

    return (fixed or text), False


def strip_markdown(text):
    """Removes markdown symbols so they are not read aloud."""
    import re

    cleaned = re.sub(r"\*\*(.*?)\*\*", r"\1", text)
    cleaned = re.sub(r"__(.*?)__", r"\1", cleaned)
    cleaned = re.sub(r"#{1,6}\s*", "", cleaned)
    cleaned = cleaned.replace("`", "").replace("*", "")
    cleaned = re.sub(r"^\s*[-•]\s*", "", cleaned, flags=re.M)
    cleaned = re.sub(r"\n\s*\n", "\n", cleaned)
    return cleaned.strip()


# =========================================================
# LIVE ESP32 SENSOR DATA
# =========================================================

latest_sensor_data = {
    "soil_moisture": 0,
    "temperature": 0,
    "humidity": 0,
    "rain": False,
    "pump_status": "OFF"
}

# Unix time of the last POST from the ESP32 (None until that happens).
last_sensor_update = None

# =========================================================
# GET SENSOR DATA
# =========================================================

@app.route("/sensor_data", methods=["GET"])
def get_sensor_data():

    now = time.time()

    return jsonify({
        "success": True,
        **latest_sensor_data,
        # Seconds since the ESP32 last posted (None if never).
        "data_age_seconds": (
            None if last_sensor_update is None
            else round(now - last_sensor_update, 1)
        )
    })


# =========================================================
# RECEIVE ESP32 SENSOR DATA
# =========================================================

@app.route("/sensor_data", methods=["POST"])
def receive_sensor_data():

    global latest_sensor_data
    global last_sensor_update

    try:

        data = request.get_json(silent=True) or {}

        latest_sensor_data = {

            "soil_moisture": float(
                data.get("soil_moisture", 0)
            ),

            "temperature": float(
                data.get("temperature", 0)
            ),

            "humidity": float(
                data.get("humidity", 0)
            ),

            "rain": bool(
                data.get("rain", False)
            ),

            "pump_status": str(
                data.get("pump_status", "OFF")
            ).upper()
        }

        last_sensor_update = time.time()

        print("\n========== ESP32 SENSOR DATA ==========")
        print(latest_sensor_data)

        print("=======================================\n")

        return jsonify({

            "success": True,

            "message": "Sensor data received",

            **latest_sensor_data

        })

    except Exception as e:

        return jsonify({

            "success": False,

            "error": str(e)

        }), 400


# =========================================================
# HOME / SERVER TEST
# =========================================================

@app.route("/", methods=["GET"])
def home():

    return jsonify({

        "success": True,

        "message": "AgriSense AI Flask Server is running"

    })


# =========================================================
# SMART IRRIGATION
# =========================================================

IRRIGATION_TEXT = {
    "kn": {
        "critical": {
            "recommendation": "ನೀರಾವರಿ ತುರ್ತಾಗಿ ಅಗತ್ಯವಿದೆ.",
            "message": "ಮಣ್ಣಿನ ತೇವಾಂಶ {m}% ಇದ್ದು, ಮಣ್ಣು ತುಂಬಾ ಒಣಗಿದೆ. ತಕ್ಷಣ ನೀರಾವರಿ ಪ್ರಾರಂಭಿಸಿ.",
        },
        "low": {
            "recommendation": "ನೀರಾವರಿ ಮಾಡುವುದು ಸೂಕ್ತ.",
            "message": "ಮಣ್ಣಿನ ತೇವಾಂಶ {m}% ಇದ್ದು, ಕಡಿಮೆ ಇದೆ. ಬೆಳೆಗೆ ನೀರು ಹಾಯಿಸಿ.",
        },
        "moderate": {
            "recommendation": "ಮಧ್ಯಮ ಪ್ರಮಾಣದ ನೀರಾವರಿ ಬೇಕಾಗಬಹುದು.",
            "message": "ಮಣ್ಣಿನ ತೇವಾಂಶ {m}% ಇದ್ದು, ಮಧ್ಯಮ ಮಟ್ಟದಲ್ಲಿದೆ. ಮಣ್ಣನ್ನು ಗಮನಿಸುತ್ತಿರಿ ಮತ್ತು ಅಗತ್ಯವಿದ್ದರೆ ನೀರು ಹಾಯಿಸಿ.",
        },
        "sufficient": {
            "recommendation": "ನೀರಾವರಿ ಅಗತ್ಯವಿಲ್ಲ.",
            "message": "ಮಣ್ಣಿನ ತೇವಾಂಶ {m}% ಇದ್ದು, ಸಾಕಷ್ಟು ಇದೆ. ನೀರಾವರಿಯನ್ನು ಆಫ್ ಆಗಿಯೇ ಇಡಬಹುದು.",
        },
    },
    "hi": {
        "critical": {
            "recommendation": "सिंचाई की तत्काल आवश्यकता है।",
            "message": "मिट्टी में नमी {m}% है और मिट्टी बहुत सूखी है। तुरंत सिंचाई शुरू करें।",
        },
        "low": {
            "recommendation": "सिंचाई करने की सलाह दी जाती है।",
            "message": "मिट्टी में नमी {m}% है, जो कम है। फसल को पानी दें।",
        },
        "moderate": {
            "recommendation": "मध्यम सिंचाई की आवश्यकता हो सकती है।",
            "message": "मिट्टी में नमी {m}% है, जो मध्यम स्तर पर है। मिट्टी पर नज़र रखें और जरूरत होने पर सिंचाई करें।",
        },
        "sufficient": {
            "recommendation": "सिंचाई की आवश्यकता नहीं है।",
            "message": "मिट्टी में नमी {m}% है, जो पर्याप्त है। सिंचाई बंद रखी जा सकती है।",
        },
    },
}


@app.route("/predict_irrigation", methods=["POST"])
def predict_irrigation():

    try:

        data = request.get_json(silent=True)

        if not data:

            return jsonify({

                "success": False,

                "error": "No data received"

            }), 400


        # -----------------------------------------
        # GET VALUES
        # -----------------------------------------

        soil_moisture = float(
            data.get("soil_moisture", 0)
        )

        temperature = float(
            data.get("temperature", 0)
        )

        humidity = float(
            data.get("humidity", 0)
        )

        lang_code = normalize_lang(data.get("lang"))


        print("\n======================================")
        print("SMART IRRIGATION REQUEST")
        print("Language:", lang_code)
        print("Soil Moisture:", soil_moisture)
        print("Temperature:", temperature)
        print("Humidity:", humidity)


        # -----------------------------------------
        # IRRIGATION LOGIC
        # -----------------------------------------

        if soil_moisture < 30:

            recommendation = (
                "Irrigation is highly required."
            )

            pump_status = "ON"

            message = (
                "The soil is very dry. "
                "Start irrigation immediately."
            )


        elif soil_moisture < 50:

            recommendation = (
                "Irrigation is recommended."
            )

            pump_status = "ON"

            message = (
                "The soil moisture is low. "
                "Provide irrigation to the crop."
            )


        elif soil_moisture < 70:

            recommendation = (
                "Moderate irrigation may be required."
            )

            pump_status = "OPTIONAL"

            message = (
                "The soil has moderate moisture. "
                "Monitor the soil and irrigate if required."
            )


        else:

            recommendation = (
                "Irrigation is not required."
            )

            pump_status = "OFF"

            message = (
                "The soil has sufficient moisture. "
                "Irrigation can remain OFF."
            )


        print("Recommendation:", recommendation)
        print("Pump:", pump_status)
        print("======================================\n")


        # -----------------------------------------
        # DECISION CODE (language independent)
        # -----------------------------------------

        if soil_moisture < 30:
            decision = "critical"
        elif soil_moisture < 50:
            decision = "low"
        elif soil_moisture < 70:
            decision = "moderate"
        else:
            decision = "sufficient"


        # -----------------------------------------
        # TRANSLATE THE RECOMMENDATION (no AI needed)
        # -----------------------------------------
        #
        # The decision is rule based, so the Kannada and Hindi text is
        # built in (IRRIGATION_TEXT). It always matches the selected
        # language, uses no AI quota and still works when Gemini is
        # unavailable. ai_localized=True means "the text is in the
        # selected language".
        #

        ai_localized = lang_code == "en"

        translated = IRRIGATION_TEXT.get(lang_code, {}).get(decision)

        if translated:
            moisture_text = f"{round(soil_moisture, 1):g}"
            recommendation = translated["recommendation"]
            message = translated["message"].format(m=moisture_text)
            ai_localized = True


        # -----------------------------------------
        # RESPONSE
        # -----------------------------------------

        return jsonify({

            "success": True,

            "lang": lang_code,

            "decision": decision,

            "ai_localized": ai_localized,

            "soil_moisture": soil_moisture,

            "temperature": temperature,

            "humidity": humidity,

            "recommendation": recommendation,

            "pump_status": pump_status,

            "message": message

        })


    except Exception as e:

        print("IRRIGATION ERROR:")
        print(str(e))


        return jsonify({

            "success": False,

            "error": str(e)

        }), 500


# =========================================================
# AI FERTILIZER RECOMMENDATION
# =========================================================

@app.route("/predict_fertilizer", methods=["POST"])
def predict_fertilizer():

    try:

        data = request.get_json(silent=True)

        if not data:

            return jsonify({

                "success": False,

                "error": "No data received"

            }), 400


        # -----------------------------------------
        # GET USER INPUT
        # -----------------------------------------

        crop = str(
            data.get("crop", "")
        ).strip()

        soil_type = str(
            data.get("soil_type", "")
        ).strip()

        ph_value = data.get("ph", None)

        lang_code = normalize_lang(data.get("lang"))
        language_name = LANGUAGES[lang_code]["name"]


        if not crop:

            return jsonify({

                "success": False,

                "error": "Crop name is required."

            }), 400


        if not soil_type:

            return jsonify({

                "success": False,

                "error": "Soil type is required."

            }), 400


        if ph_value is None:

            return jsonify({

                "success": False,

                "error": "Soil pH is required."

            }), 400


        try:

            ph = float(ph_value)

        except:

            return jsonify({

                "success": False,

                "error": "Soil pH must be a valid number."

            }), 400


        if ph < 0 or ph > 14:

            return jsonify({

                "success": False,

                "error": "Soil pH must be between 0 and 14."

            }), 400


        # -----------------------------------------
        # OPTIONAL NPK VALUES
        # -----------------------------------------
        #
        # These are optional.
        #
        # If your ESP32 currently gives 0 for NPK,
        # Gemini will NOT treat those zeros as actual
        # measured nutrient levels.
        #

        nitrogen = data.get("nitrogen", None)
        phosphorus = data.get("phosphorus", None)
        potassium = data.get("potassium", None)


        try:

            nitrogen = (
                float(nitrogen)
                if nitrogen is not None
                else None
            )

        except:

            nitrogen = None


        try:

            phosphorus = (
                float(phosphorus)
                if phosphorus is not None
                else None
            )

        except:

            phosphorus = None


        try:

            potassium = (
                float(potassium)
                if potassium is not None
                else None
            )

        except:

            potassium = None


        print("\n======================================")
        print("AI FERTILIZER REQUEST")
        print("Crop:", crop)
        print("Soil Type:", soil_type)
        print("pH:", ph)
        print("Nitrogen:", nitrogen)
        print("Phosphorus:", phosphorus)
        print("Potassium:", potassium)
        print("======================================")


        # -----------------------------------------
        # CHECK GEMINI
        # -----------------------------------------

        if client is None:

            return jsonify({

                "success": False,

                "error":
                    "Gemini API key is not configured. "
                    "Please check your .env file.",

                "error_type": "api_key"

            }), 500


        # -----------------------------------------
        # BUILD NPK INFORMATION
        # -----------------------------------------

        npk_information = ""

        valid_npk = (
            nitrogen is not None
            or phosphorus is not None
            or potassium is not None
        )


        if valid_npk:

            npk_information = f"""
Optional soil nutrient sensor readings:

Nitrogen (N): {nitrogen}
Phosphorus (P): {phosphorus}
Potassium (K): {potassium}

IMPORTANT:
If any of these values is 0, null, missing, or clearly
unavailable, DO NOT assume that the soil actually contains
zero of that nutrient.

Use the crop, soil type and pH as the primary inputs.
Only use NPK readings when they appear to be genuine
measured values.
"""

        else:

            npk_information = """
No reliable NPK sensor readings were provided.

Do NOT invent NPK values.

Base the recommendation primarily on:
- crop
- soil type
- soil pH
"""


        # -----------------------------------------
        # GEMINI PROMPT
        # -----------------------------------------

        prompt = f"""
You are AgriSense AI, an intelligent agricultural
fertilizer recommendation system.

Your task is to provide a DYNAMIC fertilizer recommendation
for the farmer.

The recommendation must be generated specifically from
the information supplied by the farmer.

FARMER INPUT:

Crop:
{crop}

Soil Type:
{soil_type}

Soil pH:
{ph}

{npk_information}


IMPORTANT RULES:

1. Analyse the combination of crop + soil type + soil pH and the
   real nutrient needs of THAT crop. Do not give a fixed answer.

2. Recommend 2 to 4 SPECIFIC fertilizers. Each one must be given
   by its exact commercial name, the way it is sold in an Indian
   fertilizer shop and printed on the bag. Examples of exact
   names: Urea (46% N), DAP (18-46-0), MOP / Muriate of Potash
   (60% K2O), SSP / Single Super Phosphate, Ammonium Sulphate,
   Zinc Sulphate (21%), Gypsum, 19:19:19, 10:26:26, 20:20:0:13,
   Vermicompost, FYM (farmyard manure), Neem Cake, and for acidic
   soil Agricultural Lime or Dolomite. Choose the ones that really
   suit this crop, soil type and pH.

3. NEVER use a generic phrase such as "balanced NPK fertilizer",
   "NPK fertilizer" or "compound fertilizer" as a fertilizer name.
   The farmer must be able to walk into a shop and ask for each
   fertilizer by its exact name.

4. For EACH fertilizer explain: what it is (nutrients it
   contains), why this crop needs it, WHEN to use it (crop growth
   stage or days after sowing / planting) and HOW to use it
   (method of application and a typical quantity per acre, split
   into doses where needed).

5. Give typical quantities as normal agronomic guidance per acre
   (for example "about 40 to 50 kg per acre") and say clearly that
   the exact quantity should be adjusted after a soil test. Do NOT
   invent soil-test results that were not supplied.

6. Soil type and pH must change the advice (for example leaching
   in sandy soil, lime for acidic soil, gypsum for alkaline soil).
   If the pH is a problem, name the soil amendment and explain how
   to use it.

7. Use plain, simple words a farmer understands. Do not use
   markdown symbols such as ** or #, no tables and no JSON.

8. Do not mention programming, Flask, Flutter, APIs, Gemini or
   backend systems in the answer.

9. {language_rules(lang_code)}

10. FERTILIZER NAMES (exception to the language rule): when the
    language is Kannada or Hindi, write each fertilizer name in the
    script of that language and, in brackets directly after it, the
    standard English name used on the bag, for example
    "ಯೂರಿಯಾ (Urea)" or "डीएपी (DAP)". That bracket is the only
    English allowed. For English, ignore this rule.


ANSWER STRUCTURE (the headings below are in English only as a
guide; write every heading in {language_name}):

Recommended Fertilizers:
[List the exact fertilizer names, one per line, numbered]

Then repeat this block for EACH fertilizer:

Fertilizer Name:
[Exact name]

What It Is:
[Short description: the nutrients it contains and its form]

Why This Crop Needs It:
[Reason for this crop, soil type and soil pH]

When to Use:
[Crop growth stage / days after sowing or planting]

How to Use:
[Application method, typical quantity per acre and how to split it]

Precautions:
[One or two short, practical points]

After all the fertilizers, add:

Soil pH Consideration:
[How the supplied soil pH affects this recommendation and what to
correct, if anything]

Application Schedule (Summary):
[A short timeline: basal dose, first top dressing, second top
dressing and so on]

Important Note:
[Quantities are general guidance only; confirm with a soil test
and the local agriculture officer.]
"""


        # -----------------------------------------
        # SEND REQUEST TO GEMINI
        # -----------------------------------------

        print("Sending fertilizer request to Gemini...")


        answer, language_ok = generate_in_language(
            prompt,
            lang_code,
        )


        print("Gemini fertilizer response received.")


        # -----------------------------------------
        # CHECK GEMINI ANSWER
        # -----------------------------------------

        if not answer:

            return jsonify({

                "success": False,

                "error":
                    "Gemini did not return a fertilizer recommendation."

            }), 500


        print("Language OK:", language_ok)
        print("\n========== AI FERTILIZER ANSWER ==========")
        print(answer)
        print("==========================================\n")


        # -----------------------------------------
        # SEND RESPONSE TO FLUTTER
        # -----------------------------------------

        return jsonify({

            "success": True,

            "lang": lang_code,

            "language_ok": language_ok,

            "crop": crop,

            "soil_type": soil_type,

            "ph": ph,

            "nitrogen": nitrogen,

            "phosphorus": phosphorus,

            "potassium": potassium,

            # Main AI response
            "recommendation": answer,

            # Same answer separately for easier Flutter use
            "answer": answer

        })


    except Exception as e:

        error_message = str(e)

        print("\n======================================")
        print("!!! FERTILIZER AI ERROR !!!")
        print(error_message)
        print("======================================\n")


        # -----------------------------------------
        # QUOTA ERROR
        # -----------------------------------------

        if (
            "429" in error_message
            or
            "quota" in error_message.lower()
        ):

            return jsonify({

                "success": False,

                "error":
                    "The AI service has reached "
                    "its current API quota. "
                    "Please check your Gemini API quota.",

                "error_type": "quota"

            }), 429


        # -----------------------------------------
        # API KEY ERROR
        # -----------------------------------------

        if (
            "API key" in error_message
            or
            "api_key" in error_message
            or
            "authentication" in error_message.lower()
        ):

            return jsonify({

                "success": False,

                "error":
                    "There is a problem with the "
                    "Gemini API key. Please check "
                    "your .env file.",

                "error_type": "api_key"

            }), 401


        # -----------------------------------------
        # OTHER ERROR
        # -----------------------------------------

        return jsonify({

            "success": False,

            "error":
                "Sorry, I could not generate the "
                "fertilizer recommendation right now.",

            "error_type": "server_error",

            "details": error_message

        }), 500


# =========================================================
# AI VOICE ASSISTANT
# =========================================================

@app.route("/ai_voice_advisor", methods=["POST"])
def ai_voice_advisor():

    try:

        # -----------------------------------------
        # GET REQUEST DATA
        # -----------------------------------------

        data = request.get_json(silent=True)


        print("\n======================================")
        print("VOICE ASSISTANT REQUEST")
        print("Received data:", data)


        if not data:

            return jsonify({

                "success": False,

                "answer": "No data was received."

            }), 400


        question = str(
            data.get(
                "question",
                ""
            )
        ).strip()


        lang = str(
            data.get(
                "lang",
                "en"
            )
        ).strip()

        lang_code = normalize_lang(lang)


        print("Question:", question)
        print("Language:", lang)


        # -----------------------------------------
        # CHECK QUESTION
        # -----------------------------------------

        if not question:

            return jsonify({

                "success": False,

                "answer":
                    "Please ask a farming related question."

            }), 400


        # -----------------------------------------
        # SELECT LANGUAGE
        # -----------------------------------------

        if lang_code == "kn":

            language = "Kannada"


        elif lang_code == "hi":

            language = "Hindi"


        else:

            language = "English"


        print("Selected language:", language)


        # -----------------------------------------
        # CHECK GEMINI CLIENT
        # -----------------------------------------

        if client is None:

            return jsonify({

                "success": False,

                "answer":
                    "Gemini API key is not configured. "
                    "Please check your .env file.",

                "error_type": "api_key"

            }), 500


        # -----------------------------------------
        # PROMPT
        # -----------------------------------------

        prompt = f"""
You are AgriSense AI, an intelligent agricultural
voice assistant for farmers.

The farmer asked:

{question}

{language_rules(lang_code)}

IMPORTANT RULES:

1. Respond ONLY in {language}, even if the farmer's question
   was typed or spoken in another language.
2. Give a complete natural answer.
3. Do not answer using only numbers.
4. Do not return JSON.
5. Do not return programming code.
6. Use simple language.
7. Give practical agricultural information.
8. Keep the answer short enough to be spoken.
9. If the question is about crops, explain crop-related advice.
10. If the question is about irrigation, explain irrigation clearly.
11. If the question is about fertilizer, explain fertilizer usage.
12. If the question is about soil, explain soil requirements.
13. If the question is about pests, explain general prevention.
14. Do not use unnecessary technical terminology.

Farmer's question:

{question}
"""


        print("Sending request to Gemini...")


        # -----------------------------------------
        # GEMINI REQUEST (language checked)
        # -----------------------------------------

        answer, language_ok = generate_in_language(
            prompt,
            lang_code,
        )


        print("Gemini response received.")
        print("Language OK:", language_ok)


        if not answer:

            answer = (
                "Sorry, I could not generate an answer. "
                "Please try asking your question again."
            )

            language_ok = False


        print("AI ANSWER:")
        print(answer)

        print("======================================\n")


        # -----------------------------------------
        # SEND RESPONSE TO FLUTTER
        # -----------------------------------------

        return jsonify({

            "success": True,

            "lang": lang_code,

            "language_ok": language_ok,

            "answer": answer

        })


    # =================================================
    # ERROR HANDLING
    # =================================================

    except Exception as e:

        error_message = str(e)


        print("\n======================================")
        print("!!! VOICE ASSISTANT ERROR !!!")
        print(error_message)
        print("======================================\n")


        # -----------------------------------------
        # QUOTA ERROR
        # -----------------------------------------

        if (
            "429" in error_message
            or
            "quota" in error_message.lower()
        ):

            return jsonify({

                "success": False,

                "answer":
                    "The AI service has reached "
                    "its current API quota. "
                    "Please check your Gemini API quota.",

                "error_type": "quota"

            }), 429


        # -----------------------------------------
        # API KEY ERROR
        # -----------------------------------------

        if (
            "API key" in error_message
            or
            "api_key" in error_message
            or
            "authentication" in error_message.lower()
        ):

            return jsonify({

                "success": False,

                "answer":
                    "There is a problem with the "
                    "Gemini API key. Please check "
                    "your API key configuration.",

                "error_type": "api_key"

            }), 401


        # -----------------------------------------
        # OTHER ERROR
        # -----------------------------------------

        return jsonify({

            "success": False,

            "answer":
                "Sorry, I could not process "
                "your question right now. "
                "Please try again.",

            "error_type": "server_error",

            "error": error_message

        }), 500


# =========================================================
# TEXT TO SPEECH (server side, used for Kannada)
# =========================================================
#
# WHY THIS EXISTS
# The Flutter app speaks with the device's own TTS engine
# (flutter_tts). Windows, Chrome and many Android phones ship
# NO Kannada voice, so setLanguage("kn-IN") / speak() produces
# silence without an error. This endpoint turns the exact
# on-screen text into an MP3 with Google's online TTS (gTTS,
# no API key needed, supports Kannada, Hindi and English) so
# the app can play it with audioplayers.
#

TTS_MAX_CHARS = 4500

TTS_CACHE = {}


@app.route("/tts_audio/<audio_id>.mp3", methods=["GET"])
def tts_audio(audio_id):

    audio = TTS_CACHE.get(audio_id)

    if audio is None:

        return jsonify({"success": False, "error": "Audio expired."}), 404

    return app.response_class(
        audio,
        mimetype="audio/mpeg",
        headers={"Cache-Control": "no-store"},
    )


@app.route("/tts", methods=["POST"])
def text_to_speech():

    try:

        from gtts import gTTS

    except ImportError:

        return jsonify({

            "success": False,

            "error": "gTTS is not installed. Run: pip install gTTS",

            "error_type": "tts_unavailable"

        }), 500


    try:

        data = request.get_json(silent=True) or {}

        text = strip_markdown(
            str(data.get("text", ""))
        )

        lang_code = normalize_lang(data.get("lang"))


        if not text:

            return jsonify({

                "success": False,

                "error": "No text to speak.",

                "error_type": "empty_text"

            }), 400


        if len(text) > TTS_MAX_CHARS:

            # Cut at a sentence end where possible.
            cut = text[:TTS_MAX_CHARS]

            for stop in ("।", ". ", "\n"):

                position = cut.rfind(stop)

                if position > TTS_MAX_CHARS * 0.6:

                    cut = cut[: position + 1]

                    break

            text = cut


        print("\n======================================")
        print("TTS REQUEST")
        print("Language:", lang_code)
        print("Characters:", len(text))


        import io

        buffer = io.BytesIO()

        gTTS(
            text=text,
            lang=lang_code,
        ).write_to_fp(buffer)

        audio = buffer.getvalue()

        print("Audio bytes:", len(audio))
        print("======================================\n")


        if not audio:

            return jsonify({

                "success": False,

                "error": "TTS returned no audio.",

                "error_type": "tts_failed"

            }), 502


        if data.get("as_url"):

            # Small in-memory cache so the app can stream the audio
            # from a URL (works the same on Windows, web and Android).
            import uuid

            audio_id = uuid.uuid4().hex

            TTS_CACHE[audio_id] = audio

            while len(TTS_CACHE) > 20:

                TTS_CACHE.pop(next(iter(TTS_CACHE)))

            return jsonify({

                "success": True,

                "lang": lang_code,

                "bytes": len(audio),

                "path": f"/tts_audio/{audio_id}.mp3",

            })


        return app.response_class(

            audio,

            mimetype="audio/mpeg",

            headers={

                "Cache-Control": "no-store",

                "X-TTS-Lang": lang_code,

            }

        )


    except Exception as e:

        print("TTS ERROR:", str(e))

        return jsonify({

            "success": False,

            "error": str(e),

            "error_type": "tts_failed"

        }), 502


# =========================================================
# LIVE CROP / MANDI PRICES (Agmarknet via data.gov.in)
# =========================================================
#
# Prices come from the Government of India "Current daily price
# of various commodities from various markets (Mandi)" dataset.
# A free API key is needed: register at https://data.gov.in and
# add   DATA_GOV_API_KEY=your_key   to the .env file.
#
# The government data is in Rs per QUINTAL (100 kg). The app shows
# Rs per KG, so the values are divided by 100 here.
#

DATA_GOV_API_KEY = os.getenv("DATA_GOV_API_KEY")

MANDI_RESOURCE_URL = (
    "https://api.data.gov.in/resource/"
    "9ef84268-d588-465a-a308-a864a43d0070"
)

PRICE_CACHE = {}

# data.gov.in answers plain Python requests with a 502 error, but
# works normally when the request looks like a browser request.
MANDI_HEADERS = {
    "User-Agent": (
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
        "Chrome/120 Safari/537.36"
    ),
    "Accept": "application/json",
}
PRICE_CACHE_SECONDS = 600

# Last successful prices are also saved on disk so that a government
# server outage does not leave the screen empty. Old prices are always
# shown with their original date and a note; nothing is invented.
PRICE_DISK_FILE = os.path.join(
    os.path.dirname(os.path.abspath(__file__)),
    "price_cache.json",
)


def _disk_cache_load():
    import json

    try:
        with open(PRICE_DISK_FILE, "r", encoding="utf-8") as f:
            return json.load(f)
    except Exception:
        return {}


def _disk_cache_save(crop, state, result):
    import json

    try:
        store = _disk_cache_load()
        store[f"{crop}|{state}"] = {
            "saved_at": time.strftime("%d/%m/%Y %H:%M"),
            "result": result,
        }
        with open(PRICE_DISK_FILE, "w", encoding="utf-8") as f:
            json.dump(store, f, ensure_ascii=False)
    except Exception as e:
        print("Price cache save failed:", str(e))


def _parse_arrival_date(value):
    from datetime import datetime

    try:
        return datetime.strptime(str(value), "%d/%m/%Y")
    except Exception:
        return datetime.min


def _per_kg(value):
    try:
        return f"{float(value) / 100:.1f}".rstrip("0").rstrip(".")
    except Exception:
        return "-"


@app.route("/crop_prices", methods=["POST"])
def crop_prices():

    import requests

    try:

        data = request.get_json(silent=True) or {}

        crop = str(data.get("crop", "")).strip().title()

        state = str(data.get("state", "")).strip().title()

        if not DATA_GOV_API_KEY:

            return jsonify({

                "success": False,

                "records": [],

                "error":
                    "DATA_GOV_API_KEY is not set in the .env file.",

                "error_type": "api_key"

            }), 500


        cache_key = (crop, state)

        cached = PRICE_CACHE.get(cache_key)

        if cached and time.time() - cached[0] < PRICE_CACHE_SECONDS:

            return jsonify(cached[1])


        params = {

            "api-key": DATA_GOV_API_KEY,

            "format": "json",

            "limit": 200,

        }

        if crop:

            params["filters[commodity]"] = crop

        if state:

            params["filters[state.keyword]"] = state


        print("\n======================================")
        print("CROP PRICE REQUEST")
        print("Crop:", crop or "(all)")
        print("State:", state or "(all)")

        response = requests.get(
            MANDI_RESOURCE_URL,
            params=params,
            headers=MANDI_HEADERS,
            timeout=60,
        )

        response.raise_for_status()

        raw = response.json().get("records", [])

        raw.sort(
            key=lambda r: _parse_arrival_date(r.get("arrival_date")),
            reverse=True,
        )

        records = []

        for r in raw[:50]:

            records.append({

                "commodity": r.get("commodity", ""),
                "variety": r.get("variety", ""),
                "market": r.get("market", ""),
                "district": r.get("district", ""),
                "state": r.get("state", ""),
                "arrival_date": r.get("arrival_date", ""),
                "min_price": _per_kg(r.get("min_price")),
                "max_price": _per_kg(r.get("max_price")),
                "modal_price": _per_kg(r.get("modal_price")),

            })

        print("Records found:", len(records))
        print("======================================\n")

        result = {

            "success": True,

            "unit": "Rs per kg",

            "records": records,

        }

        if records:

            PRICE_CACHE[cache_key] = (time.time(), result)

            _disk_cache_save(crop, state, result)

        return jsonify(result)


    except Exception as e:

        print("CROP PRICE ERROR:", str(e))

        # Government server down: show the last saved prices (with
        # their original dates) instead of an empty screen.
        saved = _disk_cache_load().get(f"{crop}|{state}")

        if saved and saved.get("result", {}).get("records"):

            stale = dict(saved["result"])

            stale["stale"] = True

            stale["stale_note"] = (
                "Live prices are unavailable right now. "
                f"Showing the last prices saved on {saved.get('saved_at')}."
            )

            return jsonify(stale)

        return jsonify({

            "success": False,

            "records": [],

            "error": str(e),

            "error_type": "price_unavailable"

        }), 502


# =========================================================
# RUN FLASK SERVER
# =========================================================

if __name__ == "__main__":

    print("")

    print("======================================")
    print("       AGRISENSE AI BACKEND")
    print("======================================")

    print("Flask server starting...")

    print("URL: http://127.0.0.1:5000")

    print("======================================")

    print("")


    app.run(

        host="0.0.0.0",

        port=5000,

        debug=True

    )