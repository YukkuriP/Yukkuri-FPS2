import math
import unittest

from main import MAX_ROOM_PLAYERS, MAX_ROOMS, clean_text, finite_number


class ServerValidationTests(unittest.TestCase):
    def test_text_is_printable_trimmed_and_limited(self):
        self.assertEqual(clean_text("  Pilot\x00  ", "Operator", 16), "Pilot")
        self.assertEqual(clean_text("A" * 20, "Operator", 5), "A" * 5)
        self.assertEqual(clean_text(None, "Operator", 16), "Operator")

    def test_numeric_values_must_be_finite_and_not_boolean(self):
        self.assertEqual(finite_number("12.5"), 12.5)
        self.assertIsNone(finite_number("NaN"))
        self.assertIsNone(finite_number(math.inf))
        self.assertIsNone(finite_number(True))
        self.assertIsNone(finite_number("not-a-number"))

    def test_capacity_limits_are_bounded(self):
        self.assertEqual(MAX_ROOM_PLAYERS, 16)
        self.assertEqual(MAX_ROOMS, 128)


if __name__ == "__main__":
    unittest.main()
