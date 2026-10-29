"""
Reference check of the Modbus RTU frame logic used in esp32_live_sensor.ino.

This is a Python mirror of the firmware algorithm (CRC-16/Modbus, request
frame, big-endian register decode, CRC rejection). It verifies the maths
and frame layout only. It does NOT run the firmware and does NOT prove the
physical sensor responds.

Run:  python test_npk_modbus_reference.py
"""

import unittest


def crc16(data):
    crc = 0xFFFF
    for b in data:
        crc ^= b
        for _ in range(8):
            crc = (crc >> 1) ^ 0xA001 if crc & 1 else crc >> 1
    return crc


def request(addr=0x01, reg=0x001E, count=3):
    body = bytes([addr, 0x03, reg >> 8, reg & 0xFF, count >> 8, count & 0xFF])
    c = crc16(body)
    return body + bytes([c & 0xFF, c >> 8])


def response(values, addr=0x01):
    body = bytes([addr, 0x03, len(values) * 2])
    for v in values:
        body += bytes([v >> 8, v & 0xFF])
    c = crc16(body)
    return body + bytes([c & 0xFF, c >> 8])


def decode(frame, addr=0x01, count=3, max_value=1999):
    """Mirror of npkTryRead(): returns (values, error)."""
    expected = 5 + count * 2
    if not frame:
        return None, "no_response_timeout"
    start = next((i for i in range(len(frame) - 2)
                  if frame[i] == addr and frame[i + 1] in (0x03, 0x83)), None)
    if start is None:
        return None, "bad_response_header"
    if len(frame) - start < expected:
        return None, "short_response"
    if frame[start + 2] != count * 2:
        return None, "unexpected_byte_count"
    c = crc16(frame[start:start + expected - 2])
    if frame[start + expected - 2] != (c & 0xFF) or \
            frame[start + expected - 1] != (c >> 8):
        return None, "crc_mismatch"
    vals = [(frame[start + 3 + 2 * i] << 8) | frame[start + 4 + 2 * i]
            for i in range(count)]
    if any(v > max_value for v in vals):
        return None, "value_out_of_range"
    return vals, None


class NpkModbusReference(unittest.TestCase):

    def test_request_matches_known_npk_frame(self):
        # Widely published request for N/P/K at 0x1E..0x20.
        self.assertEqual(request().hex(" ").upper(),
                         "01 03 00 1E 00 03 65 CD")

    def test_decode_valid_response(self):
        self.assertEqual(decode(response([30, 15, 40])),
                         ([30, 15, 40], None))

    def test_zero_values_are_valid(self):
        self.assertEqual(decode(response([0, 0, 0])), ([0, 0, 0], None))

    def test_noise_byte_before_frame_is_skipped(self):
        self.assertEqual(decode(b"\x00" + response([1, 2, 3])),
                         ([1, 2, 3], None))

    def test_big_endian_decode(self):
        vals, err = decode(response([0x0102, 0x0001, 0x0100]))
        self.assertIsNone(err)
        self.assertEqual(vals, [258, 1, 256])

    def test_crc_error_rejected(self):
        bad = bytearray(response([30, 15, 40]))
        bad[-1] ^= 0xFF
        self.assertEqual(decode(bytes(bad)), (None, "crc_mismatch"))

    def test_timeout_and_short(self):
        self.assertEqual(decode(b""), (None, "no_response_timeout"))
        self.assertEqual(decode(response([1, 2, 3])[:6]),
                         (None, "short_response"))

    def test_out_of_range(self):
        self.assertEqual(decode(response([2500, 1, 1])),
                         (None, "value_out_of_range"))


if __name__ == "__main__":
    unittest.main()
