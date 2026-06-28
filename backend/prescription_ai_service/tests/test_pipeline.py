import unittest

from app.pipeline import parse_prescription_text


SAMPLE_PRESCRIPTION = """Dr. Akshara
M.S.
Reg. No: MMC 2018
SMS hospital
B/503, Business Center, MG Road, Pune
411000.
Ph: 5465647658, Timing: 09:00 AM - 01:00 PM, 06:00 PM - 08:00 PM
Closed: Sunday
Date: 30-Aug-2023
ID: 11 - OPD6 PATIENT (M) / 13 Y Mob. No.: 9423380390
Address: PUNE
Weight (Kg): 80, Height (Cm): 200 (B.M.I. = 20.00), BP: 120/80 mmHg
Chief Complaints
* FEVER WITH CHILLS (4 DAYS)
* HEADACHE (2 DAYS)
Diagnosis:
* MALARIA
Medicine Name Dosage Duration
1) TAB. ABCIXIMAB 1 Morning 8 Days (Tot:8 Tab)
2) TAB. VOMILAST 1 Morning, 1 Night (After Food) 8 Days (Tot:16 Tab)
DOXYLAMINE 10 MG + PYRIDOXINE 10 MG + FOLIC ACID 2.5 MG
3) CAP. ZOCILAR 500 1 Morning 3 Days (Tot:3 Cap)
CLARITHROMYCIN IP 500MG
4) TAB. GESTAKIND 10/SR 1 Night 4 Days (Tot:4 Tab)
ISOXSUPRINE 10 MG
Advice:
* TAKE BED REST
* DO NOT EAT OUTSIDE FOOD
Follow Up: 04-09-2023
"""

COMPOUNDING_PRESCRIPTION = """John M. Brown, M.D.
100 Main Street
Libertyville, Maryland
Phone 123-4567
Name Neil Smith
Date Jan 9, 2014
Address 123 Broad Street
Rx
Metoclopramide HCL 10 g
Methylparaben 50 mg
Propylparaben 20 mg
Sodium Chloride 800 mg
Purified Water, qs ad 100 mL
M. ft. nasal spray
Sig: Nasal spray for chemotherapy-induced emesis. Use as directed.
Discard after 60 days.
Refill 0 times
Label: Yes No
Generic if available: Yes No
JM Brown, M.D.
DEA No. CB1234563
State License No. 65432
"""

HANDWRITTEN_STYLE_PRESCRIPTION = """Date: 20-09-2022
Name: Ashvika
Clinical Description:
URTI RR-22/min
Advice:
syp CAPLOL (250/5) 4 mL Q6H x 3 d
syp DELCON 3 mL TDS x 5d
syp LEVOLIN 3 mL TDS x 5d
syp MEFTAL-P (100/5) 3 mL SOS
Review if fever persists
"""


class ParsePrescriptionTextTests(unittest.TestCase):
    def test_table_layout_ignores_business_details_and_complaints(self) -> None:
        parsed = parse_prescription_text(SAMPLE_PRESCRIPTION)

        self.assertEqual(parsed.date, "30-Aug-2023")
        self.assertEqual(
            [medicine.name for medicine in parsed.medicines],
            [
                "TAB. ABCIXIMAB",
                "TAB. VOMILAST",
                "CAP. ZOCILAR 500",
                "TAB. GESTAKIND 10/SR",
            ],
        )
        self.assertEqual(parsed.medicines[0].frequency, "1 Morning")
        self.assertEqual(
            parsed.medicines[1].frequency,
            "1 Morning, 1 Night (After Food)",
        )
        self.assertTrue(all("Business Center" not in medicine.name for medicine in parsed.medicines))
        self.assertTrue(all("FEVER" not in medicine.name for medicine in parsed.medicines))

    def test_compounding_layout_keeps_only_ingredients(self) -> None:
        parsed = parse_prescription_text(COMPOUNDING_PRESCRIPTION)

        self.assertEqual(
            [medicine.name for medicine in parsed.medicines],
            [
                "Metoclopramide HCL",
                "Methylparaben",
                "Propylparaben",
                "Sodium Chloride",
                "Purified Water, qs ad",
            ],
        )
        self.assertEqual(parsed.medicines[0].dosage, "10 g")
        self.assertTrue(all("Phone" not in medicine.name for medicine in parsed.medicines))
        self.assertTrue(all("DEA" not in medicine.name for medicine in parsed.medicines))

    def test_handwritten_layout_extracts_medicine_lines_without_leaking_into_name(self) -> None:
        parsed = parse_prescription_text(HANDWRITTEN_STYLE_PRESCRIPTION)

        self.assertEqual(
            [medicine.name for medicine in parsed.medicines],
            [
                "syp CAPLOL (250/5)",
                "syp DELCON",
                "syp LEVOLIN",
                "syp MEFTAL-P (100/5)",
            ],
        )
        self.assertEqual(parsed.medicines[0].dosage, "4 mL")
        self.assertEqual(parsed.medicines[0].frequency, "Q6H")
        self.assertEqual(parsed.medicines[0].duration, "3 d")
        self.assertEqual(parsed.medicines[1].duration, "5d")
        self.assertEqual(parsed.medicines[3].frequency, "SOS")
        self.assertTrue(all("Review" not in medicine.name for medicine in parsed.medicines))


if __name__ == "__main__":
    unittest.main()
