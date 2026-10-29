"""
Tests for the NPK handling of the /sensor_data endpoints.

Run from this folder:
    python -m unittest test_sensor_npk -v

These tests use Flask's test client with made-up payloads. They check
the backend's parsing/validation only; they do NOT prove the physical
sensor works.
"""

import json
import unittest

import app as backend


def reset_state():
    backend.latest_sensor_data = {
        "soil_moisture": 0,
        "temperature": 0,
        "humidity": 0,
        "rain": False,
        "nitrogen": None,
        "phosphorus": None,
        "potassium": None,
        "npk_valid": False,
        "npk_error": "no_data_received",
        "pump_status": "OFF",
    }
    backend.last_sensor_update = None
    backend.last_npk_update = None


BASE = {
    "soil_moisture": 41.0,
    "temperature": 27.5,
    "humidity": 60.0,
    "rain": False,
    "pump_status": "OFF",
}


class SensorNpkTests(unittest.TestCase):

    def setUp(self):
        reset_state()
        self.client = backend.app.test_client()

    def post(self, payload):
        return self.client.post("/sensor_data", json=payload)

    def get(self):
        return self.client.get("/sensor_data").get_json()

    # ---- before any data ------------------------------------------

    def test_initial_state_is_not_zero(self):
        body = self.get()
        self.assertTrue(body["success"])
        self.assertIsNone(body["nitrogen"])
        self.assertIsNone(body["phosphorus"])
        self.assertIsNone(body["potassium"])
        self.assertFalse(body["npk_valid"])
        self.assertIsNone(body["data_age_seconds"])
        self.assertIsNone(body["npk_age_seconds"])

    # ---- valid readings -------------------------------------------

    def test_valid_reading_with_flag(self):
        r = self.post({**BASE, "nitrogen": 42, "phosphorus": 17,
                       "potassium": 88, "npk_valid": True})
        self.assertEqual(r.status_code, 200)
        body = self.get()
        self.assertTrue(body["npk_valid"])
        self.assertIsNone(body["npk_error"])
        self.assertEqual(
            (body["nitrogen"], body["phosphorus"], body["potassium"]),
            (42.0, 17.0, 88.0),
        )
        self.assertIsNotNone(body["npk_age_seconds"])

    def test_genuine_zero_is_valid_when_firmware_says_so(self):
        self.post({**BASE, "nitrogen": 0, "phosphorus": 0,
                   "potassium": 0, "npk_valid": True})
        body = self.get()
        self.assertTrue(body["npk_valid"])
        self.assertEqual(body["nitrogen"], 0.0)

    def test_legacy_firmware_nonzero_without_flag_is_valid(self):
        self.post({**BASE, "nitrogen": 10, "phosphorus": 5,
                   "potassium": 20})
        self.assertTrue(self.get()["npk_valid"])

    # ---- invalid / unavailable ------------------------------------

    def test_legacy_all_zero_placeholder_is_invalid(self):
        self.post({**BASE, "nitrogen": 0, "phosphorus": 0,
                   "potassium": 0})
        body = self.get()
        self.assertFalse(body["npk_valid"])
        self.assertIsNone(body["nitrogen"])
        self.assertEqual(body["npk_error"], "no_npk_data_from_esp32")

    def test_sensor_reports_failure_with_nulls(self):
        r = self.post({**BASE, "nitrogen": None, "phosphorus": None,
                       "potassium": None, "npk_valid": False,
                       "npk_error": "no_response_timeout"})
        # Must not reject the whole POST: soil data still stored.
        self.assertEqual(r.status_code, 200)
        body = self.get()
        self.assertFalse(body["npk_valid"])
        self.assertEqual(body["npk_error"], "no_response_timeout")
        self.assertIsNone(body["nitrogen"])
        self.assertEqual(body["soil_moisture"], 41.0)
        self.assertIsNone(body["npk_age_seconds"])
        self.assertIsNotNone(body["data_age_seconds"])

    def test_null_values_without_flag_do_not_break_post(self):
        r = self.post({**BASE, "nitrogen": None, "phosphorus": 3,
                       "potassium": 4})
        self.assertEqual(r.status_code, 200)
        body = self.get()
        self.assertFalse(body["npk_valid"])
        self.assertEqual(body["npk_error"], "missing_nitrogen")
        self.assertEqual(body["temperature"], 27.5)

    def test_missing_keys(self):
        self.post(dict(BASE))
        self.assertFalse(self.get()["npk_valid"])

    def test_non_numeric(self):
        r = self.post({**BASE, "nitrogen": "abc", "phosphorus": 1,
                       "potassium": 1})
        self.assertEqual(r.status_code, 200)
        self.assertEqual(self.get()["npk_error"], "non_numeric_nitrogen")

    def test_boolean_is_rejected(self):
        self.post({**BASE, "nitrogen": True, "phosphorus": 1,
                   "potassium": 1})
        self.assertFalse(self.get()["npk_valid"])

    def test_nan_is_rejected(self):
        raw = json.dumps({**BASE, "nitrogen": 1, "phosphorus": 1,
                          "potassium": 1}).replace('"nitrogen": 1',
                                                   '"nitrogen": NaN')
        r = self.client.post("/sensor_data", data=raw,
                             content_type="application/json")
        self.assertEqual(r.status_code, 200)
        self.assertFalse(self.get()["npk_valid"])

    def test_out_of_range(self):
        self.post({**BASE, "nitrogen": 5000, "phosphorus": 1,
                   "potassium": 1, "npk_valid": True})
        self.assertEqual(self.get()["npk_error"],
                         "out_of_range_nitrogen")

    def test_negative(self):
        self.post({**BASE, "nitrogen": 1, "phosphorus": -1,
                   "potassium": 1, "npk_valid": True})
        self.assertEqual(self.get()["npk_error"],
                         "out_of_range_phosphorus")

    def test_recovery_after_failure(self):
        self.post({**BASE, "npk_valid": False,
                   "npk_error": "crc_mismatch"})
        self.assertFalse(self.get()["npk_valid"])
        self.post({**BASE, "nitrogen": 7, "phosphorus": 8,
                   "potassium": 9, "npk_valid": True})
        self.assertTrue(self.get()["npk_valid"])

    # ---- other features untouched ---------------------------------

    def test_irrigation_endpoint_unaffected(self):
        r = self.client.post("/predict_irrigation",
                             json={"soil_moisture": 20,
                                   "temperature": 30, "humidity": 50})
        body = r.get_json()
        self.assertEqual(r.status_code, 200)
        self.assertTrue(body["success"])
        self.assertEqual(body["pump_status"], "ON")

    def test_home(self):
        self.assertTrue(self.client.get("/").get_json()["success"])


if __name__ == "__main__":
    unittest.main()
