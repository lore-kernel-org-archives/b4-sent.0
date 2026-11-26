From: Ilia Snezhkov <iasnezhkov@gmail.com>
To: daniel.lezcano@linaro.org, rafael@kernel.org, rui.zhang@intel.com, 
 lukasz.luba@arm.com
Cc: matthias.bgg@gmail.com, angelogioacchino.delregno@collabora.com, 
 linux-pm@vger.kernel.org, linux-mediatek@lists.infradead.org, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org
Subject: [PATCH 2/4] thermal/drivers/mediatek/lvts_thermal: avoid 32-bit
 overflow in lvts_temp_to_raw_mt7988() and INT_MAX trips
Date: Thu, 26 Nov 2026 00:53:23 +0000
Message-Id: <20261126005321.71799-3-iasnezhkov@gmail.com>
In-Reply-To: <20261126005321.71799-1-iasnezhkov@gmail.com>
References: <20261126005321.71799-1-iasnezhkov@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795654401; l=3303;
 i=iasnezhkov@gmail.com; s=mindone2026; h=from:subject:message-id;
 bh=psSr6KJdwfmb1wfsBNafw8vECeQMBdTkcT5VL1q598A=;
 b=AYmY1cNYhCNMV/zdOV2u3nU5P6SKNRf55XL2K3+T/JDXQRWC0haRg/IFRwRaNwZVRRyD59tf/
 F0l9FwfIjHABLyOW8s1+3hnNHD8yHAPRJd+fXU4gXm55p8Spys1p6dT
X-Developer-Key: i=iasnezhkov@gmail.com; a=ed25519;
 pk=hQgXfiWi4ukk2jh4BHu1vRVhg9BUivo//AFp50AKMag=
X-Endpoint-Received: by B4 Relay for iasnezhkov@gmail.com/mindone2026 with auth_id=1643
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

lvts_temp_to_raw_mt7988() subtracts two 32-bit ints before casting to
s64, shifts left by 14 bits, and immediately truncates the result to a
u32 before passing it to div_s64().

When golden_temp_offset - temperature >= 262144 (for example,
golden_temp = 60, temp_offset = 250460, temperature < 18316 mC, or even
LVTS_MINIMUM_THRESHOLD = 20000 mC when golden_temp >= 64), the shifted
value exceeds U32_MAX and silently wraps modulo 2^32, programming a
bogus low raw value (high temperature) into LVTS_OFFSETL/LVTS_OFFSETH.

In addition, lvts_set_trips() passes high == INT_MAX (used by the
thermal core when no upper trip exists) directly to lvts_temp_to_raw(),
which produces a negative quotient cast to u32 while leaving the sensor's
high-offset interrupt enabled.

Promote golden_temp_offset to s64 before subtracting, keep the shifted
numerator in s64, clamp negative results to 0, avoid converting
high == INT_MAX in lvts_set_trips(), and mask high_offset_inten when
high_thresh == INT_MAX.

Found and drafted with an AI coding assistant.

Fixes: f5f633b18234 ("thermal/drivers/mediatek: Add the Low Voltage Thermal Sensor driver")
Fixes: 2bba1acf7a4c ("thermal/drivers/mediatek/lvts_thermal: Manage threshold between sensors")
Signed-off-by: Ilia Snezhkov <iasnezhkov@gmail.com>
---
 drivers/thermal/mediatek/lvts_thermal.c | 17 ++++++++++-------
 1 file changed, 10 insertions(+), 7 deletions(-)

diff --git a/drivers/thermal/mediatek/lvts_thermal.c b/drivers/thermal/mediatek/lvts_thermal.c
index e034c6c..9b8b653 100644
--- a/drivers/thermal/mediatek/lvts_thermal.c
+++ b/drivers/thermal/mediatek/lvts_thermal.c
@@ -322,11 +322,11 @@ static int lvts_raw_to_temp_mt7988(u32 raw_temp, int temp_factor)
 
 static u32 lvts_temp_to_raw_mt7988(int temperature, int temp_factor)
 {
-	u32 raw_temp = ((s64)(golden_temp_offset - temperature)) << 14;
+	s64 raw_temp = ((s64)golden_temp_offset - temperature) << 14;
 
 	raw_temp = div_s64(raw_temp, -temp_factor);
 
-	return raw_temp;
+	return raw_temp < 0 ? 0 : (u32)raw_temp;
 }
 
 static u32 lvts_temp_to_raw_mt8196(int temperature, int temp_factor)
@@ -409,12 +409,15 @@ static void lvts_update_irq_mask(struct lvts_ctrl *lvts_ctrl)
 			 * don't actually want to generate interrupts when
 			 * crossing it.
 			 */
-			if (lvts_ctrl->low_thresh == -INT_MAX) {
+			if (lvts_ctrl->low_thresh == -INT_MAX)
 				value &= ~low_offset_inten_masks[i];
+			else
+				value |= low_offset_inten_masks[i];
+
+			if (lvts_ctrl->high_thresh == INT_MAX)
+				value &= ~high_offset_inten_masks[i];
+			else
 				value |= high_offset_inten_masks[i];
-			} else {
-				value |= low_offset_inten_masks[i] | high_offset_inten_masks[i];
-			}
 		} else {
 			value &= ~(low_offset_inten_masks[i] | high_offset_inten_masks[i]);
 		}
@@ -447,7 +450,7 @@ static int lvts_set_trips(struct thermal_zone_device *tz, int low, int high)
 	void __iomem *base = lvts_sensor->base;
 	u32 raw_low = lvts_temp_to_raw(low != -INT_MAX ? low : LVTS_MINIMUM_THRESHOLD,
 				       lvts_data);
-	u32 raw_high = lvts_temp_to_raw(high, lvts_data);
+	u32 raw_high = high != INT_MAX ? lvts_temp_to_raw(high, lvts_data) : 0;
 	bool should_update_thresh;
 
 	lvts_sensor->low_thresh = low;
-- 
2.54.0 (Apple Git-157)


