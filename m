From: Chuan Liu <chuan.liu@amlogic.com>
Date: Tue, 22 Jul 2025 14:06:58 +0800
Subject: [PATCH v2] soc: amlogic: clk-measure: Optimize measurement
 accuracy
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250722-optimize_clk-measure_accuracy-v2-1-cb121fd57e6d@amlogic.com>
X-B4-Tracking: v=1; b=H4sIAIEqf2gC/4XNQQ6CMBCF4auQrq2hLVB15T0MIXU6wkRKSQtEJ
 NxdxAO4/N/iewuLGAgjuyQLCzhRJN9tIQ8Jg8Z0NXKyWzOZyjzNpeK+H8jRGyton9yhiWPAygC
 MwcDMzygKRJUV1kq2GX3AB712/1Zu3VAcfJj3u0l815+shf4jT4ILru4naTWA1Zm6Gtf6muAI3
 rFyXdcPHuTCBMwAAAA=
To: Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>
Cc: linux-arm-kernel@lists.infradead.org, linux-amlogic@lists.infradead.org, 
 linux-kernel@vger.kernel.org, Chuan Liu <chuan.liu@amlogic.com>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1753164591; l=5869;
 i=chuan.liu@amlogic.com; s=20240902; h=from:subject:message-id;
 bh=oQhUGoSZxIi1keYigrFF8wPRjrcx7Jaid/BmEwKEBDI=;
 b=bpOdsOdMACbofeQdme94D/tMNvgjUoxblptycdgowPS4uvd+6e1Q/u5IQ9xiLpOl2r7MsinL4
 trf8cV7rEWnDBlVa18F4KqZXXj0gV+MqS9yJu1AYIUQzZI8RERXJcDz
X-Developer-Key: i=chuan.liu@amlogic.com; a=ed25519;
 pk=fnKDB+81SoWGKW2GJNFkKy/ULvsDmJZRGBE7pR5Xcpo=
X-Endpoint-Received: by B4 Relay for chuan.liu@amlogic.com/20240902 with auth_id=203
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The cycle count register has a 20-bit effective width, but the driver
only utilizes 16 bits. This reduces the sampling window when measuring
high-frequency clocks, resulting in (slightly) degraded measurement
accuracy.

The input clock signal path from gate (Controlled by MSR_RUN) to internal
sampling circuit in clk-measure has a propagation delay requirement: 24
clock cycles must elapse after mux selection before sampling.

The measurement circuit employs single-edge sampling for clock frequency
detection, resulting in a ±1 cycle count error within the measurement window.

+1 cycle: 3 rising edges captured in 2-cycle measurement window.
    __    __    __
 __↑  |__↑  |__↑  |__
  ^             ^

-1 cycle: 2 rising edges captured in 3-cycle measurement window.
    __    __    __
 __↑  |__↑  |__↑  |__↑
    ^               ^

Change-Id: If367c013fe2a8d0c8f5f06888bb8f30a1e46b927
Signed-off-by: Chuan Liu <chuan.liu@amlogic.com>
---
Improve measurement accuracy by increasing the bit width of the cycle
counter register and adding delay during measurement.

The 800μs delay between enabling the input clock gate and activating
sampling is determined by the minimum sampling frequency of 30kHz (the
lowest commonly used frequency in applications is 32.768kHz).

Here are the test comparisons based on C3:

Pre-optimization:
cat /sys/kernel/debug/meson-clk-msr/measure_summary 
  clock                     rate    precision
---------------------------------------------
 sys_clk               166664063    +/-5208Hz
 axi_clk               499968750    +/-15625Hz
 rtc_clk                23982813    +/-3125Hz
 p20_usb2_ckout        479968750    +/-15625Hz
 eth_mpll_test         499992188    +/-15625Hz
 sys_pll              1919875000    +/-62500Hz
 cpu_clk_div16         119998162    +/-3676Hz
 ts_pll                        0    +/-3125Hz
 fclk_div2             999843750    +/-31250Hz
 fclk_div2p5           799953125    +/-31250Hz
 fclk_div3             666625000    +/-20833Hz
 fclk_div4             499914063    +/-15625Hz
 fclk_div5             399987500    +/-12500Hz
 fclk_div7             285709821    +/-8928Hz
 fclk_50m               49982813    +/-3125Hz
 sys_oscin32k_i            26563    +/-3125Hz

Post-optimization:
cat /sys/kernel/debug/meson-clk-msr/measure_summary 
  clock                     rate    precision
---------------------------------------------
 sys_clk               166665625    +/-1562Hz
 axi_clk               499996875    +/-1562Hz
 rtc_clk                24000000    +/-1562Hz
 p20_usb2_ckout        479996875    +/-1562Hz
 eth_mpll_test         499996875    +/-1562Hz
 sys_pll              1919987132    +/-1838Hz
 cpu_clk_div16         119998438    +/-1562Hz
 ts_pll                        0    +/-1562Hz
 fclk_div2             999993750    +/-1562Hz
 fclk_div2p5           799995313    +/-1562Hz
 fclk_div3             666656250    +/-1562Hz
 fclk_div4             499996875    +/-1562Hz
 fclk_div5             399993750    +/-1562Hz
 fclk_div7             285712500    +/-1562Hz
 fclk_50m               49998438    +/-1562Hz
 sys_oscin32k_i            32813    +/-1562Hz
---
Changes in v2:
- Change "HACK" in comments to "NOTE" according to Martin's suggestion.
- Link to v1: https://lore.kernel.org/r/20250717-optimize_clk-measure_accuracy-v1-1-3b82d7ccd743@amlogic.com
---
 drivers/soc/amlogic/meson-clk-measure.c | 27 ++++++++++++++++++---------
 1 file changed, 18 insertions(+), 9 deletions(-)

diff --git a/drivers/soc/amlogic/meson-clk-measure.c b/drivers/soc/amlogic/meson-clk-measure.c
index d862e30a244e..df395e015f26 100644
--- a/drivers/soc/amlogic/meson-clk-measure.c
+++ b/drivers/soc/amlogic/meson-clk-measure.c
@@ -22,7 +22,7 @@ static DEFINE_MUTEX(measure_lock);
 #define MSR_CLK_SRC		GENMASK(26, 20)
 #define MSR_BUSY		BIT(31)
 
-#define MSR_VAL_MASK		GENMASK(15, 0)
+#define MSR_VAL_MASK		GENMASK(19, 0)
 
 #define DIV_MIN			32
 #define DIV_STEP		32
@@ -805,14 +805,23 @@ static int meson_measure_id(struct meson_msr_id *clk_msr_id,
 	regmap_update_bits(priv->regmap, reg->freq_ctrl, MSR_DURATION,
 			   FIELD_PREP(MSR_DURATION, duration - 1));
 
-	/* Set ID */
-	regmap_update_bits(priv->regmap, reg->freq_ctrl, MSR_CLK_SRC,
-			   FIELD_PREP(MSR_CLK_SRC, clk_msr_id->id));
+	/* Set the clock channel ID and enable the input clock gate. */
+	regmap_update_bits(priv->regmap, reg->freq_ctrl, MSR_CLK_SRC | MSR_RUN,
+			   FIELD_PREP(MSR_CLK_SRC, clk_msr_id->id) | MSR_RUN);
 
-	/* Enable & Start */
-	regmap_update_bits(priv->regmap, reg->freq_ctrl,
-			   MSR_RUN | MSR_ENABLE,
-			   MSR_RUN | MSR_ENABLE);
+	/*
+	 * NOTE: The input clock signal path from gate (Controlled by MSR_RUN)
+	 * to internal sampling circuit in clk-measure has a propagation delay
+	 * requirement: 24 clock cycles must elapse after mux selection before
+	 * sampling.
+	 *
+	 * For a 30kHz measurement clock, this translates to an 800μs delay:
+	 * 800us = 24 / 30000Hz.
+	 */
+	fsleep(800);
+
+	/* Enable the internal sampling circuit and start clock measurement. */
+	regmap_update_bits(priv->regmap, reg->freq_ctrl, MSR_ENABLE, MSR_ENABLE);
 
 	ret = regmap_read_poll_timeout(priv->regmap, reg->freq_ctrl,
 				       val, !(val & MSR_BUSY), 10, 10000);
@@ -846,7 +855,7 @@ static int meson_measure_best_id(struct meson_msr_id *clk_msr_id,
 	do {
 		ret = meson_measure_id(clk_msr_id, duration);
 		if (ret >= 0)
-			*precision = (2 * 1000000) / duration;
+			*precision = 1000000 / duration;
 		else
 			duration -= DIV_STEP;
 	} while (duration >= DIV_MIN && ret == -EINVAL);

---
base-commit: 58abdca0eb653c1a2e755ba9ba406ee475d87636
change-id: 20250523-optimize_clk-measure_accuracy-9e16ee346dd2

Best regards,
-- 
Chuan Liu <chuan.liu@amlogic.com>

