from flask import Flask, request, jsonify
from flask_cors import CORS
from google import genai
from dotenv import load_dotenv
import math
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

    client = genai.Client(
        api_key=GEMINI_API_KEY
    )


# Gemini model
MODEL_NAME = "gemini-2.5-flash"


# =========================================================
# LIVE ESP32 SENSOR DATA
# =========================================================

latest_sensor_data = {
    "soil_moisture": 0,
    "temperature": 0,
    "humidity": 0,
    "rain": False,
    # NPK stays None (not 0) until a genuine reading arrives.
    "nitrogen": None,
    "phosphorus": None,
    "potassium": None,
    "npk_valid": False,
    "npk_error": "no_data_received",
    "pump_status": "OFF"
}

# Unix time of the last POST from the ESP32 and the last POST that
# carried a valid NPK reading (None until that happens).
last_sensor_update = None
last_npk_update = None

# Typical RS485 NPK sensors report 0-1999 mg/kg. Anything outside
# this range is a corrupted/misparsed frame, not a soil reading.
NPK_MAX_VALID = 1999


def parse_npk(data):
    """
    Validate the NPK part of an ESP32 payload.

    Returns (values, error) where values is
    {"nitrogen", "phosphorus", "potassium"} as floats, or all None
    when the reading is not valid, and error is None or a short
    reason string. Zero is NOT used as a stand-in for "no reading".
    """

    empty = {"nitrogen": None, "phosphorus": None, "potassium": None}

    # Newer firmware states explicitly whether the NPK read worked.
    if data.get("npk_valid") is False:
        return empty, str(
            data.get("npk_error") or "sensor_reported_invalid"
        )

    raw = {}

    for key in ("nitrogen", "phosphorus", "potassium"):

        value = data.get(key)

        if value is None or isinstance(value, bool):
            return empty, f"missing_{key}"

        try:
            value = float(value)
        except (TypeError, ValueError):
            return empty, f"non_numeric_{key}"

        if math.isnan(value) or math.isinf(value):
            return empty, f"non_numeric_{key}"

        if value < 0 or value > NPK_MAX_VALID:
            return empty, f"out_of_range_{key}"

        raw[key] = value

    # Older firmware always sent 0/0/0 because the RS485 read was
    # never implemented. All three at exactly 0 with no validity
    # flag is that placeholder, not a measurement.
    if "npk_valid" not in data and not any(raw.values()):
        return empty, "no_npk_data_from_esp32"

    return raw, None


# =========================================================
# GET SENSOR DATA
# =========================================================

@app.route("/sensor_data", methods=["GET"])
def get_sensor_data():

    now = time.time()

    return jsonify({
        "success": True,
        **latest_sensor_data,
        # Seconds since the ESP32 last posted anything / a valid NPK
        # reading (None if that has never happened).
        "data_age_seconds": (
            None if last_sensor_update is None
            else round(now - last_sensor_update, 1)
        ),
        "npk_age_seconds": (
            None if last_npk_update is None
            else round(now - last_npk_update, 1)
        )
    })


# =========================================================
# RECEIVE ESP32 SENSOR DATA
# =========================================================

@app.route("/sensor_data", methods=["POST"])
def receive_sensor_data():

    global latest_sensor_data
    global last_sensor_update
    global last_npk_update

    try:

        data = request.get_json(silent=True) or {}

        npk_values, npk_error = parse_npk(data)

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

            "nitrogen": npk_values["nitrogen"],

            "phosphorus": npk_values["phosphorus"],

            "potassium": npk_values["potassium"],

            "npk_valid": npk_error is None,

            "npk_error": npk_error,

            "pump_status": str(
                data.get("pump_status", "OFF")
            ).upper()
        }

        last_sensor_update = time.time()

        if npk_error is None:
            last_npk_update = last_sensor_update

        print("\n========== ESP32 SENSOR DATA ==========")
        print(latest_sensor_data)

        if npk_error is None:
            print(
                "NPK OK -> N:", latest_sensor_data["nitrogen"],
                "P:", latest_sensor_data["phosphorus"],
                "K:", latest_sensor_data["potassium"], "mg/kg"
            )
        else:
            print("NPK NOT AVAILABLE:", npk_error)

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


        print("\n======================================")
        print("SMART IRRIGATION REQUEST")
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
        # RESPONSE
        # -----------------------------------------

        return jsonify({

            "success": True,

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


IMPORTANT:

1. Do NOT use a fixed predefined answer.

2. Do NOT simply map a crop name to one fertilizer.

3. Analyze the combination of crop + soil type + soil pH.

4. Consider the nutritional requirements of the specific crop.

5. Consider how the supplied soil type affects nutrient
   retention, drainage and fertilizer management.

6. Consider how the supplied pH affects nutrient
   availability.

7. Recommend the most appropriate fertilizer or fertilizer
   combination based on the available information.

8. If one fertilizer is not sufficient, recommend a suitable
   combination.

9. If the soil pH indicates a problem, clearly explain it.

10. Do NOT invent soil-test measurements that were not
    supplied by the farmer.

11. Do NOT claim that a fertilizer is definitely required
    if the available information is insufficient.

12. When an exact fertilizer quantity cannot safely be
    determined from the supplied information, say so and
    explain that a soil test is required.

13. Provide practical agricultural advice.

14. The response should be detailed enough for a farmer to
    understand the recommendation.

15. Do not mention that the answer is hardcoded.

16. Do not mention programming, Flask, Flutter, APIs,
    Gemini or backend systems in the answer.

17. Use plain and understandable English.

18. Do not return JSON.

19. Do not use markdown tables.

20. Structure the answer using clear headings.


RETURN THE ANSWER IN THIS STRUCTURE:

Recommended Fertilizer:
[Name of fertilizer or fertilizer combination]

Fertilizer Type / Grade:
[Available grade or composition if appropriate]

Why This Fertilizer:
[Detailed explanation of why it suits this crop,
soil type and pH]

Nutrient Benefits:
[Explain nitrogen, phosphorus, potassium and any important
secondary/micronutrients relevant to the recommendation]

How It Helps the Crop:
[Explain the effect on roots, leaves, flowering,
fruiting, grain formation or overall crop growth as applicable]

How to Apply:
[Explain practical application method]

When to Apply:
[Explain suitable crop growth stages]

Soil pH Consideration:
[Explain how the supplied pH affects this recommendation]

Expected Benefits:
[Explain expected agricultural benefits]

Precautions:
[Explain over-application risks and important precautions]

Alternative:
[Give a reasonable alternative fertilizer or approach
if appropriate]

Important Note:
[Explain that exact dosage should be based on soil testing,
crop variety, growth stage and local agricultural guidance
when required.]
"""


        # -----------------------------------------
        # SEND REQUEST TO GEMINI
        # -----------------------------------------

        print("Sending fertilizer request to Gemini...")


        response = client.models.generate_content(

            model=MODEL_NAME,

            contents=prompt

        )


        print("Gemini fertilizer response received.")


        # -----------------------------------------
        # GET GEMINI ANSWER
        # -----------------------------------------

        answer = ""


        if response and response.text:

            answer = response.text.strip()


        if not answer:

            return jsonify({

                "success": False,

                "error":
                    "Gemini did not return a fertilizer recommendation."

            }), 500


        print("\n========== AI FERTILIZER ANSWER ==========")
        print(answer)
        print("==========================================\n")


        # -----------------------------------------
        # SEND RESPONSE TO FLUTTER
        # -----------------------------------------

        return jsonify({

            "success": True,

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
                "en-IN"
            )
        ).strip()


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

        if lang == "kn-IN":

            language = "Kannada"


        elif lang == "hi-IN":

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

Answer in {language}.

IMPORTANT RULES:

1. Respond ONLY in {language}.
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
        # GEMINI REQUEST
        # -----------------------------------------

        response = client.models.generate_content(

            model=MODEL_NAME,

            contents=prompt

        )


        print("Gemini response received.")


        # -----------------------------------------
        # GET ANSWER
        # -----------------------------------------

        answer = ""


        if response and response.text:

            answer = response.text.strip()


        if not answer:

            answer = (
                "Sorry, I could not generate an answer. "
                "Please try asking your question again."
            )


        print("AI ANSWER:")
        print(answer)

        print("======================================\n")


        # -----------------------------------------
        # SEND RESPONSE TO FLUTTER
        # -----------------------------------------

        return jsonify({

            "success": True,

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