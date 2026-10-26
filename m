From: Patrick Fischer <admin@tsv-stahl-riesa.de>
Date: Mon, 26 Oct 2026 07:25:05 +0100
Subject: [PATCH] power: supply: bq24190: Fix NTC status decoding for
 BQ24193
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261026-upstream-bq24190-ntc-v1-1-fdc12d795a99@tsv-stahl-riesa.de>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMwQrCMAyA4VcZORtok06YryIetpppBOtsuiGMv
 bvVHb/D/69gklUMTs0KWRY1faUKf2gg3vt0E9RrNZCjo3fEOE9WsvRPHN4UfOcwlYgjtxKZiUP
 ooKZTllE//+35stvm4SGx/F6wbV/toK4teAAAAA==
X-Change-ID: 20261023-upstream-bq24190-ntc-f35ec3323449
To: Sebastian Reichel <sre@kernel.org>, Aaron Kling <webgeek1234@gmail.com>
Cc: Svyatoslav Ryhel <clamor95@gmail.com>, linux-pm@vger.kernel.org, 
 linux-tegra@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Patrick Fischer <admin@tsv-stahl-riesa.de>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792995907; l=3658;
 i=admin@tsv-stahl-riesa.de; s=20261020; h=from:subject:message-id;
 bh=BUokX18EXdA2wvDNW7+3GVSpgzTFB0r3Izc5EIZbi7Q=;
 b=hzAhsAG/gqezLRrjScN6/AElzUocarO12tX3xX1U/ZKpX3OVKuK2zrVTLUlJN44sehJCsNbIa
 m9e658IV1dLAjA0xNvtuLq6e6ULTNjTHlzfY13AaOc5Xh+9tidgGgBa
X-Developer-Key: i=admin@tsv-stahl-riesa.de; a=ed25519;
 pk=D+v6EloYcEY9PIUHFyTM5sqcGIU/fIXzLUdkR8vjAtk=
X-Endpoint-Received: by B4 Relay for admin@tsv-stahl-riesa.de/20261020 with auth_id=1251
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The BQ24193 has a single thermistor input and applies the JEITA
temperature profile. Its NTC_FAULT field in REG09 is encoded
differently from the BQ24190, which has two TS inputs:

  NTC_FAULT  BQ24190    BQ24193
  000        Normal     Normal
  010        TS1 Hot    Warm
  011        TS2 Cold   Cool
  101        Both Cold  Cold
  110        Both Hot   Hot

(BQ24190/2/2I datasheet SLUSAW5B, table 17; BQ24193 datasheet
SLUSBG7A, table 16.)

Warm (45-60 C at the TS pin) and Cool (0-10 C) are not faults. The
charger keeps charging at a reduced charge voltage or charge current.
The BQ24193 uses bq24190_charger_get_ntc_status() though, so a warm
battery is reported as POWER_SUPPLY_HEALTH_OVERHEAT and a cool one as
POWER_SUPPLY_HEALTH_COLD.

Add a BQ24193 decoder that reports POWER_SUPPLY_HEALTH_WARM and
POWER_SUPPLY_HEALTH_COOL for these states. Cold and Hot are unchanged.

On an NVIDIA Tegra Note 7 (P1640) REG09 reads 0x02 after a few minutes
on USB power. The battery keeps charging, but the charger reports
health "Overheat". With this patch it reports "Warm" in that state and
"Good" while REG09 reads 0x00.

Fixes: afe5301bfbaa ("power: bq24190: Add BQ24193 support")
Signed-off-by: Patrick Fischer <admin@tsv-stahl-riesa.de>
---
I kept this a pure decoding fix. Two things stay as they are and could
be follow-ups if you want them:

- The interrupt handler still logs a change to Warm or Cool as
  "Fault: ... ntc 1", as it does for every change of REG09.
- bq24190_charger_get_health() checks the NTC bits first, so while the
  battery is warm or cool the charger health hides a charge fault or
  battery over-voltage.

Tool use (see Documentation/process/generated-content.rst): this patch,
its changelog and this note were prepared with an LLM coding assistant
(Claude Code). It compared the driver with both datasheets and wrote the
code change and the texts from my register dumps and instructions. I
reviewed the change and ran the test on the device.
---
 drivers/power/supply/bq24190_charger.c | 26 +++++++++++++++++++++++++-
 1 file changed, 25 insertions(+), 1 deletion(-)

diff --git a/drivers/power/supply/bq24190_charger.c b/drivers/power/supply/bq24190_charger.c
index 4bea6fd83c36..350cf79a0744 100644
--- a/drivers/power/supply/bq24190_charger.c
+++ b/drivers/power/supply/bq24190_charger.c
@@ -999,6 +999,30 @@ static int bq24190_charger_get_ntc_status(u8 value)
 	return health;
 }
 
+static int bq24193_charger_get_ntc_status(u8 value)
+{
+	int health;
+
+	switch (value >> BQ24190_REG_F_NTC_FAULT_SHIFT & 0x7) {
+	case 0x2: /* Warm */
+		health = POWER_SUPPLY_HEALTH_WARM;
+		break;
+	case 0x3: /* Cool */
+		health = POWER_SUPPLY_HEALTH_COOL;
+		break;
+	case 0x5: /* Cold */
+		health = POWER_SUPPLY_HEALTH_COLD;
+		break;
+	case 0x6: /* Hot */
+		health = POWER_SUPPLY_HEALTH_OVERHEAT;
+		break;
+	default:
+		health = POWER_SUPPLY_HEALTH_UNKNOWN;
+	}
+
+	return health;
+}
+
 static int bq24296_charger_get_ntc_status(u8 value)
 {
 	int health;
@@ -2013,7 +2037,7 @@ static const struct bq24190_chip_info bq24190_chip_info_tbl[] = {
 		.check_chip = bq24190_check_chip,
 		.set_chg_config = bq24190_battery_set_chg_config,
 		.ntc_fault_mask = BQ24190_REG_F_NTC_FAULT_MASK,
-		.get_ntc_status = bq24190_charger_get_ntc_status,
+		.get_ntc_status = bq24193_charger_get_ntc_status,
 		.set_otg_vbus = bq24190_set_otg_vbus,
 	},
 	[BQ24196] = {

---
base-commit: 734bef548a96e8774d6eef5dfa2026c6edc4e80b
change-id: 20261023-upstream-bq24190-ntc-f35ec3323449

Best regards,
--  
Patrick Fischer <admin@tsv-stahl-riesa.de>

