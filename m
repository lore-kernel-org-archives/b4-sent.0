From: Rodrigo Alencar <rodrigo.alencar@analog.com>
Date: Tue, 03 Mar 2026 13:27:13 +0000
Subject: [PATCH v8 08/10] iio: frequency: adf41513: features on frequency
 change
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260303-adf41513-iio-driver-v8-8-8dd2417cc465@analog.com>
References: <20260303-adf41513-iio-driver-v8-0-8dd2417cc465@analog.com>
In-Reply-To: <20260303-adf41513-iio-driver-v8-0-8dd2417cc465@analog.com>
To: linux-kernel@vger.kernel.org, linux-iio@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-doc@vger.kernel.org
Cc: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, Andy Shevchenko <andy@kernel.org>, 
 Lars-Peter Clausen <lars@metafoo.de>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Jonathan Corbet <corbet@lwn.net>, 
 Andrew Morton <akpm@linux-foundation.org>, 
 Rodrigo Alencar <rodrigo.alencar@analog.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1772544443; l=5625;
 i=rodrigo.alencar@analog.com; s=default; h=from:subject:message-id;
 bh=mrEXi3f4W8srLUTxz0a6PhFOtrsgfGvKqjnyVji55K4=;
 b=ozaiX5k2acrwpv+BUEVVK7/J5WC8HQhbMGoNdM/q7uWy+j0+1/PLymuP/6d9kkxDC1veDN6Kn
 GVf9DuTifbNBUpxUhe9IgG0EYZvV1SEiH6GB3x0Jeu3N79I/9sFKO2H
X-Developer-Key: i=rodrigo.alencar@analog.com; a=ed25519;
 pk=ULeHbgU/OYh/PG/4anHDfLgldFItQHAhOktYRVLMFRo=
X-Endpoint-Received: by B4 Relay for rodrigo.alencar@analog.com/default with auth_id=561
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Set Bleed current when PFD frequency changes (bleed enabled when in
fractional mode). Set lock detector window size, handling bias and
precision. Add phase resync support, setting clock dividers when
PFD frequency changes.

Signed-off-by: Rodrigo Alencar <rodrigo.alencar@analog.com>
---
 drivers/iio/frequency/adf41513.c | 100 +++++++++++++++++++++++++++++++++++++++
 1 file changed, 100 insertions(+)

diff --git a/drivers/iio/frequency/adf41513.c b/drivers/iio/frequency/adf41513.c
index caae9d53c3e2..f6ed42df26d6 100644
--- a/drivers/iio/frequency/adf41513.c
+++ b/drivers/iio/frequency/adf41513.c
@@ -20,6 +20,7 @@
 #include <linux/property.h>
 #include <linux/regulator/consumer.h>
 #include <linux/spi/spi.h>
+#include <linux/time64.h>
 #include <linux/types.h>
 #include <linux/units.h>
 
@@ -213,6 +214,7 @@ struct adf41513_chip_info {
 struct adf41513_data {
 	u64 power_up_frequency_hz;
 	u64 freq_resolution_uhz;
+	u32 phase_resync_period_ns;
 	u32 charge_pump_voltage_mv;
 	u32 lock_detect_count;
 
@@ -271,6 +273,16 @@ struct adf41513_state {
 	struct adf41513_pll_settings settings;
 };
 
+static const u16 adf41513_ld_window_x10_ns[] = {
+	9, 12, 16, 17, 21, 28, 29, 35,			/* 0 - 7 */
+	43, 47, 49, 52, 70, 79, 115,			/* 8 - 14 */
+};
+
+static const u8 adf41513_ldp_bias[] = {
+	0xC, 0xD, 0xE, 0x8, 0x9, 0x4, 0xA, 0x5,		/* 0 - 7 */
+	0x0, 0x6, 0xB, 0x1, 0x2, 0x7, 0x3,		/* 8 - 14 */
+};
+
 static const char * const adf41513_power_supplies[] = {
 	"avdd1", "avdd2", "avdd3", "avdd4", "avdd5", "vp",
 };
@@ -578,9 +590,82 @@ static int adf41513_calc_pll_settings(struct adf41513_state *st,
 	return 0;
 }
 
+static void adf41513_set_bleed_val(struct adf41513_state *st)
+{
+	u32 bleed_value, cp_index;
+
+	if (st->data.phase_detector_polarity)
+		bleed_value = 90;
+	else
+		bleed_value = 144;
+
+	cp_index = 1 + FIELD_GET(ADF41513_REG5_CP_CURRENT_MSK,
+				 st->regs[ADF41513_REG5]);
+	bleed_value = div64_u64(st->settings.pfd_frequency_uhz * cp_index * bleed_value,
+				1600ULL * MEGA * MICROHZ_PER_HZ);
+
+	FIELD_MODIFY(ADF41513_REG6_BLEED_CURRENT_MSK, &st->regs[ADF41513_REG6],
+		     bleed_value);
+}
+
+static void adf41513_set_ld_window(struct adf41513_state *st)
+{
+	/*
+	 * The ideal lock detector window size is halfway between the max
+	 * window, set by the phase comparison period t_PFD = (1 / f_PFD),
+	 * and the minimum is set by (I_BLEED/I_CP) × t_PFD
+	 */
+	u16 ld_window_10x_ns = div64_u64(10ULL * NSEC_PER_SEC * MICROHZ_PER_HZ,
+					 st->settings.pfd_frequency_uhz << 1);
+	u8 ld_idx, ldp, ld_bias;
+
+	if (st->settings.mode != ADF41513_MODE_INTEGER_N) {
+		/* account for bleed current (deduced from eq.6 and eq.7) */
+		if (st->data.phase_detector_polarity)
+			ld_window_10x_ns += 4;
+		else
+			ld_window_10x_ns += 6;
+	}
+
+	ld_idx = find_closest(ld_window_10x_ns, adf41513_ld_window_x10_ns,
+			      ARRAY_SIZE(adf41513_ld_window_x10_ns));
+	ldp = (adf41513_ldp_bias[ld_idx] >> 2) & 0x3;
+	ld_bias = adf41513_ldp_bias[ld_idx] & 0x3;
+
+	FIELD_MODIFY(ADF41513_REG6_LDP_MSK, &st->regs[ADF41513_REG6], ldp);
+	FIELD_MODIFY(ADF41513_REG9_LD_BIAS_MSK, &st->regs[ADF41513_REG9], ld_bias);
+}
+
+static void adf41513_set_phase_resync(struct adf41513_state *st)
+{
+	u32 total_div, clk1_div, clk2_div;
+
+	if (!st->data.phase_resync_period_ns)
+		return;
+
+	/* assuming both clock dividers hold similar values */
+	total_div = mul_u64_u64_div_u64(st->settings.pfd_frequency_uhz,
+					st->data.phase_resync_period_ns,
+					1ULL * MICROHZ_PER_HZ * NSEC_PER_SEC);
+	clk1_div = clamp(int_sqrt(total_div), 1,
+			 ADF41513_MAX_CLK_DIVIDER);
+	clk2_div = clamp(DIV_ROUND_CLOSEST(total_div, clk1_div), 1,
+			 ADF41513_MAX_CLK_DIVIDER);
+
+	FIELD_MODIFY(ADF41513_REG5_CLK1_DIV_MSK, &st->regs[ADF41513_REG5],
+		     clk1_div);
+	FIELD_MODIFY(ADF41513_REG7_CLK2_DIV_MSK, &st->regs[ADF41513_REG7],
+		     clk2_div);
+
+	/* enable phase resync */
+	st->regs[ADF41513_REG7] |= ADF41513_REG7_CLK_DIV_MODE_MSK;
+}
+
 static int adf41513_set_frequency(struct adf41513_state *st, u64 freq_uhz, u16 sync_mask)
 {
 	struct adf41513_pll_settings result;
+	bool pfd_change = false;
+	bool mode_change = false;
 	int ret;
 
 	ret = adf41513_calc_pll_settings(st, &result, freq_uhz);
@@ -588,6 +673,8 @@ static int adf41513_set_frequency(struct adf41513_state *st, u64 freq_uhz, u16 s
 		return ret;
 
 	/* apply computed results to pll settings */
+	pfd_change = st->settings.pfd_frequency_uhz != result.pfd_frequency_uhz;
+	mode_change = st->settings.mode != result.mode;
 	st->settings = result;
 
 	dev_dbg(&st->spi->dev,
@@ -629,6 +716,14 @@ static int adf41513_set_frequency(struct adf41513_state *st, u64 freq_uhz, u16 s
 		st->regs[ADF41513_REG6] |= ADF41513_REG6_BLEED_ENABLE_MSK;
 	}
 
+	if (pfd_change) {
+		adf41513_set_bleed_val(st);
+		adf41513_set_phase_resync(st);
+	}
+
+	if (pfd_change || mode_change)
+		adf41513_set_ld_window(st);
+
 	return adf41513_sync_config(st, sync_mask | ADF41513_SYNC_REG0);
 }
 
@@ -938,6 +1033,11 @@ static int adf41513_parse_fw(struct adf41513_state *st)
 	st->data.phase_detector_polarity =
 		device_property_read_bool(dev, "adi,phase-detector-polarity-positive-enable");
 
+	st->data.phase_resync_period_ns = 0;
+	ret = device_property_read_u32(dev, "adi,phase-resync-period-ns", &tmp);
+	if (!ret)
+		st->data.phase_resync_period_ns = tmp;
+
 	st->data.logic_lvl_1v8_en = device_property_read_bool(dev, "adi,logic-level-1v8-enable");
 
 	tmp = ADF41513_LD_COUNT_MIN;

-- 
2.43.0

