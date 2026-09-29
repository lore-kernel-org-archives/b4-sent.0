From: Carlos Casadiego <cdcp206@gmail.com>
Date: Tue, 29 Sep 2026 12:38:22 -0500
Subject: [PATCH] iio: temperature: ltc2983: avoid string comparison for
 leak detector
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260929-iio-ltc2983-fix-string-compare-v1-1-d67d612d6ddd@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXN0QrCMAyF4VcZuTbQZkOMryJezC6bEW1H08lg7
 N2tevnB4T8bmGQVg3OzQZa3mqZY4Q8NhHsfJ0EdqoEcHR0To2rCZwnEpxZHXdFK1jhhSK+5z4K
 BPVPXjc7zADUyZ6mr38Hl+rctt4eE8q3Cvn8AqxZ174IAAAA=
X-Change-ID: 20260929-iio-ltc2983-fix-string-compare-c919244f019d
To: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, David Lechner <dlechner@baylibre.com>, 
 Andy Shevchenko <andy@kernel.org>, Liviu Stan <liviu.stan@analog.com>
Cc: linux-iio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 kernel test robot <lkp@intel.com>, Carlos Casadiego <cdcp206@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790703503; l=4275;
 i=cdcp206@gmail.com; s=20260921; h=from:subject:message-id;
 bh=G0+7tjtYsflXUSLc/hf+Ph6Z2L4WPo5focGqFfSm1I0=;
 b=u6Vb3uaqDe7bj8N0bag9hXiDjh5foAxNtCjfTcxIQwqe/V6Nca8gutrb1beateQ3aonxX/nTM
 V0h7jrwdVBhCCeBDUQu0Du/z1Es0OO7mub4Iym8imR2UQaFsZidL9Nd
X-Developer-Key: i=cdcp206@gmail.com; a=ed25519;
 pk=Vr3c2AUi1oYbgVkQtRSsWin33frZn0vGGq5g04VWmH8=
X-Endpoint-Received: by B4 Relay for cdcp206@gmail.com/20260921 with auth_id=1041
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

GCC can determine at compile time that propname cannot match
"adi,custom-leak-detector" when __ltc2983_custom_sensor_new() is
inlined for some callers, triggering a -Wstring-compare warning.

Pass an explicit flag for leak detectors instead of deriving the sensor
type from the firmware property name. This preserves the existing
conversion behavior and avoids the constant string comparison.

Fixes: 3dd0c048409e ("iio: temperature: ltc2983: Add support for ADT7604")
Reported-by: kernel test robot <lkp@intel.com>
Closes: https://lore.kernel.org/oe-kbuild-all/202609120045.OxEsKLIn-lkp@intel.com/
Signed-off-by: Carlos Casadiego <cdcp206@gmail.com>
---
 drivers/iio/temperature/ltc2983.c | 18 ++++++++++--------
 1 file changed, 10 insertions(+), 8 deletions(-)

diff --git a/drivers/iio/temperature/ltc2983.c b/drivers/iio/temperature/ltc2983.c
index 6efb5252a773..38c5e81f5f88 100644
--- a/drivers/iio/temperature/ltc2983.c
+++ b/drivers/iio/temperature/ltc2983.c
@@ -472,7 +472,8 @@ static int __ltc2983_chan_custom_sensor_assign(struct ltc2983_data *st,
 static struct ltc2983_custom_sensor *
 __ltc2983_custom_sensor_new(struct ltc2983_data *st, const struct fwnode_handle *fn,
 			    const char *propname, const bool is_steinhart,
-			    const u32 resolution, const bool has_signed)
+			    const u32 resolution, const bool has_signed,
+			    const bool is_leak_detector)
 {
 	struct ltc2983_custom_sensor *new_custom;
 	struct device *dev = &st->spi->dev;
@@ -545,7 +546,7 @@ __ltc2983_custom_sensor_new(struct ltc2983_data *st, const struct fwnode_handle
 			 * to µK so __convert_to_raw() produces the correct hardware
 			 * encoding: P + 273.15 K.
 			 */
-			if ((index % 2) != 0 && !strcmp(propname, "adi,custom-leak-detector"))
+			if ((index % 2) != 0 && is_leak_detector)
 				temp = temp * 1000000 + 273150000;
 
 			if ((index % 2) != 0)
@@ -836,7 +837,7 @@ ltc2983_thermocouple_new(const struct fwnode_handle *child, struct ltc2983_data
 
 		thermo->custom = __ltc2983_custom_sensor_new(st, child,
 							     propname, false,
-							     16384, true);
+							     16384, true, false);
 		if (IS_ERR(thermo->custom))
 			return ERR_CAST(thermo->custom);
 	}
@@ -950,7 +951,8 @@ ltc2983_rtd_new(const struct fwnode_handle *child, struct ltc2983_data *st,
 	if (sensor->type == LTC2983_SENSOR_RTD_CUSTOM) {
 		rtd->custom = __ltc2983_custom_sensor_new(st, child,
 							  "adi,custom-rtd",
-							  false, 2048, false);
+							  false, 2048, false,
+							  false);
 		if (IS_ERR(rtd->custom))
 			return ERR_CAST(rtd->custom);
 	}
@@ -1068,7 +1070,7 @@ ltc2983_thermistor_new(const struct fwnode_handle *child, struct ltc2983_data *s
 		thermistor->custom = __ltc2983_custom_sensor_new(st, child,
 								 propname,
 								 steinhart,
-								 64, false);
+								 64, false, false);
 		if (IS_ERR(thermistor->custom))
 			return ERR_CAST(thermistor->custom);
 	}
@@ -1184,7 +1186,7 @@ ltc2983_copper_trace_new(const struct fwnode_handle *child, struct ltc2983_data
 						 "adi,custom-copper-trace is required for >1 ohm copper trace\n");
 
 		ct->custom = __ltc2983_custom_sensor_new(st, child, "adi,custom-copper-trace",
-							 false, 2048, false);
+							 false, 2048, false, false);
 		if (IS_ERR(ct->custom))
 			return ERR_CAST(ct->custom);
 
@@ -1275,7 +1277,7 @@ ltc2983_leak_detector_new(const struct fwnode_handle *child, struct ltc2983_data
 					 "adi,custom-leak-detector is required for leak detectors\n");
 
 	ld->custom = __ltc2983_custom_sensor_new(st, child, "adi,custom-leak-detector",
-						 false, 16, false);
+						 false, 16, false, true);
 	if (IS_ERR(ld->custom))
 		return ERR_CAST(ld->custom);
 
@@ -1488,7 +1490,7 @@ static struct ltc2983_sensor *ltc2983_temp_new(struct fwnode_handle *child,
 					 sensor->chan);
 
 	temp->custom = __ltc2983_custom_sensor_new(st, child, "adi,custom-temp",
-						   false, 4096, true);
+						   false, 4096, true, false);
 	if (IS_ERR(temp->custom))
 		return ERR_CAST(temp->custom);
 

---
base-commit: d2f2868d2f487b418f68db2ef5bd7cf41722ee68
change-id: 20260929-iio-ltc2983-fix-string-compare-c919244f019d

Best regards,
--  
Carlos Casadiego <cdcp206@gmail.com>

