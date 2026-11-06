From: Patrick Fischer <admin@tsv-stahl-riesa.de>
Date: Fri, 06 Nov 2026 21:31:56 +0100
Subject: [PATCH 2/2] thermal/drivers/tegra: Avoid SOC_THERM calculation
 overflow on Tegra114
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261106-upstream-soctherm-t114-v1-2-c875d1921084@tsv-stahl-riesa.de>
References: <20261106-upstream-soctherm-t114-v1-0-c875d1921084@tsv-stahl-riesa.de>
In-Reply-To: <20261106-upstream-soctherm-t114-v1-0-c875d1921084@tsv-stahl-riesa.de>
To: "Rafael J. Wysocki" <rafael@kernel.org>, 
 Daniel Lezcano <daniel.lezcano@kernel.org>, Zhang Rui <rui.zhang@intel.com>, 
 Lukasz Luba <lukasz.luba@arm.com>, 
 Thierry Reding <thierry.reding@kernel.org>, 
 Jonathan Hunter <jonathanh@nvidia.com>
Cc: Svyatoslav Ryhel <clamor95@gmail.com>, 
 Mikko Perttunen <mperttunen@nvidia.com>, linux-pm@vger.kernel.org, 
 linux-tegra@vger.kernel.org, linux-kernel@vger.kernel.org, 
 stable@vger.kernel.org, Patrick Fischer <admin@tsv-stahl-riesa.de>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793997117; l=9502;
 i=admin@tsv-stahl-riesa.de; s=20261020; h=from:subject:message-id;
 bh=phtH60/ywrZjJs3x+gxtlamVeIt7WyYa43cPSiih9qM=;
 b=A3u8jhN3RkUy6Ow6SJZSo336q6LKHsu0jdIqDQ3ldSfFBPIFskkKM1adjBOTjRSR7Im3hkQk1
 8nOwDs6+j6GAdHbdALY4LRT5hBxoIvoGgb/kba915bqP6GU3izRiXjl
X-Developer-Key: i=admin@tsv-stahl-riesa.de; a=ed25519;
 pk=D+v6EloYcEY9PIUHFyTM5sqcGIU/fIXzLUdkR8vjAtk=
X-Endpoint-Received: by B4 Relay for admin@tsv-stahl-riesa.de/20261020 with auth_id=1251
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

SOC_THERM calculates each sensor temperature in units of 0.5 C as
THERMA * capture / 2^13 + THERMB. On Tegra114 the intermediate product
THERMA * capture has to stay below 2^24. Above that the hardware sets
TCALC_OVER in SENSOR_CONFIG0, clears TEMP_VALID in SENSOR_STATUS1 and
the sensor drops out of its group. On a Tegra Note 7, 80 out of 80
samples matched this rule: TEMP_VALID was set exactly when
THERMA * capture < 2^24 (largest valid product 16747731, smallest
invalid one 16877718).

The fuse calibration itself is fine. As Mikko pointed out in the review
of the Tegra114 series, the fuse corrections are in 0.5 C units on
Tegra114 just as on Tegra124 and Tegra210, and
2 * NOMINAL_CALIB_XX + shifted_xx is correct. This patch keeps it that
way. The problem is the range: with T in C,
THERMA * capture = (2 * T - THERMB) * 2^13, so a sensor only gives a
valid result for T < (2048 + THERMB) / 2. On Tegra114 THERMB is close
to -2000 (between -2117 and -1812 on the chip tested), which leaves
almost no headroom. On that chip the sensors were valid only up to
45 C (cpu2), 53 C (pllx) and 32 C (gpu), and cpu0, cpu1 and cpu3 not
even at room temperature. The gpu zone therefore always reads 0 C, the
cpu zone stops following the CPU at about 45 C, and neither the
throttle levels nor thermtrip ever see the temperatures they are
programmed for.

NVIDIA's downstream driver runs Tegra114 in "lower precision" mode for
this reason (tegra11_soctherm.c: "We must use lower precision (0) due
to cp_fuse corrections"): the sensors count in 1 C units, the readback
is scaled by two and all thresholds are in 2 C steps.

Do the same with a lower_precision flag in the SoC data:

- keep the fuse calibration in 0.5 C units and halve THERMA and THERMB
  only in the final rounding step, so THERMA * capture stays around
  2^23 and the sensors report the same temperatures at half the
  resolution,
- double the readback in translate_temp(),
- use a threshold grain of 2000 so that thermtrip, the throttle levels
  and the trip interrupts are programmed in 2 C steps.

The use_lower_precision option in v3 of the Tegra114 series and the
downstream driver halve the calibration temperatures before the
calculation instead, which applies fuse_corr_beta at twice its weight.
Here the result is exactly the current calibration divided by two. The
PLLX hotspot offsets are left as they are, as in the downstream driver.
Tegra124, Tegra132 and Tegra210 are unchanged.

Tested on an NVIDIA Tegra Note 7 (P1640) together with the shifted_cp
fix: THERMA * capture now stays between 7.7 and 9.2 million, and all
eight sensors report TEMP_VALID in idle and after 60 s of load on all
four cores at 1.12 GHz. The zones read cpu 43, gpu 39, pllx 43, mem
39 C in idle (board thermistor 34 C) and cpu 63, gpu 55, pllx 62, mem
53 C under load. Before, the gpu zone read 0 C and the cpu zone stopped
at about 45 C. The thermtrip, throttle and trip thresholds are
programmed as 51, 50 and 45, i.e. 102, 100 and 90 C.

Fixes: 9d522a877b6f ("thermal/drivers/tegra: Add Tegra114 specific SOCTHERM driver")
Cc: stable@vger.kernel.org
Link: https://lore.kernel.org/all/22816196.EfDdHjke4D@senjougahara/
Signed-off-by: Patrick Fischer <admin@tsv-stahl-riesa.de>
---
 drivers/thermal/tegra/soctherm-fuse.c     | 15 ++++++++++++---
 drivers/thermal/tegra/soctherm.c          | 21 +++++++++++++--------
 drivers/thermal/tegra/soctherm.h          |  6 ++++++
 drivers/thermal/tegra/tegra114-soctherm.c |  4 +++-
 4 files changed, 34 insertions(+), 12 deletions(-)

diff --git a/drivers/thermal/tegra/soctherm-fuse.c b/drivers/thermal/tegra/soctherm-fuse.c
index 2de1d0cb676e..bba563961da7 100644
--- a/drivers/thermal/tegra/soctherm-fuse.c
+++ b/drivers/thermal/tegra/soctherm-fuse.c
@@ -118,7 +118,7 @@ int tegra_calc_tsensor_calib(const struct tegra_tsensor *sensor,
 	u32 val, calib;
 	s32 actual_tsensor_ft, actual_tsensor_cp;
 	s32 delta_sens, delta_temp;
-	s32 mult, div;
+	s32 mult, div, coeff;
 	s16 therma, thermb;
 	s64 temp;
 	int err;
@@ -147,11 +147,20 @@ int tegra_calc_tsensor_calib(const struct tegra_tsensor *sensor,
 		((s64)actual_tsensor_cp * shared->actual_temp_ft);
 	thermb = div64_s64_precise(temp, delta_sens);
 
+	/*
+	 * With lower precision the sensors count in 1 C units, which keeps
+	 * THERMA * capture within the 24 bits the hardware calculates with.
+	 * Halve both coefficients in the final rounding step.
+	 */
+	coeff = CALIB_COEFFICIENT;
+	if (shared->lower_precision)
+		coeff *= 2;
+
 	temp = (s64)therma * sensor->fuse_corr_alpha;
-	therma = div64_s64_precise(temp, CALIB_COEFFICIENT);
+	therma = div64_s64_precise(temp, coeff);
 
 	temp = (s64)thermb * sensor->fuse_corr_alpha + sensor->fuse_corr_beta;
-	thermb = div64_s64_precise(temp, CALIB_COEFFICIENT);
+	thermb = div64_s64_precise(temp, coeff);
 
 	calib = ((u16)therma << SENSOR_CONFIG2_THERMA_SHIFT) |
 		((u16)thermb << SENSOR_CONFIG2_THERMB_SHIFT);
diff --git a/drivers/thermal/tegra/soctherm.c b/drivers/thermal/tegra/soctherm.c
index f74acf13b24d..0f6e5455ebb4 100644
--- a/drivers/thermal/tegra/soctherm.c
+++ b/drivers/thermal/tegra/soctherm.c
@@ -413,9 +413,10 @@ static void enable_tsensor(struct tegra_soctherm *tegra, unsigned int i)
  *   TTTTTTTT H______N
  * where T's contain the temperature in Celsius,
  * H denotes an addition of 0.5 Celsius and N denotes negation
- * of the final value.
+ * of the final value. With lower precision all of this is in
+ * units of 2 Celsius.
  */
-static int translate_temp(u16 val)
+static int translate_temp(const struct tegra_soctherm *ts, u16 val)
 {
 	int t;
 
@@ -424,6 +425,8 @@ static int translate_temp(u16 val)
 		t += 500;
 	if (val & READBACK_NEGATE)
 		t *= -1;
+	if (ts->soc->lower_precision)
+		t *= 2;
 
 	return t;
 }
@@ -435,7 +438,7 @@ static int tegra_thermctl_get_temp(struct thermal_zone_device *tz, int *out_temp
 
 	val = readl(zone->reg);
 	val = REG_GET_MASK(val, zone->sg->sensor_temp_mask);
-	*out_temp = translate_temp(val);
+	*out_temp = translate_temp(zone->ts, val);
 
 	return 0;
 }
@@ -1287,7 +1290,7 @@ static int regs_show(struct seq_file *s, void *data)
 		state = REG_GET_MASK(r, SENSOR_STATUS1_TEMP_VALID_MASK);
 		seq_printf(s, "Temp(%d/", state);
 		state = REG_GET_MASK(r, SENSOR_STATUS1_TEMP_MASK);
-		seq_printf(s, "%d) ", translate_temp(state));
+		seq_printf(s, "%d) ", translate_temp(ts, state));
 
 		r = readl(ts->regs + tsensors[i].base + SENSOR_STATUS0);
 		state = REG_GET_MASK(r, SENSOR_STATUS0_VALID_MASK);
@@ -1325,14 +1328,14 @@ static int regs_show(struct seq_file *s, void *data)
 
 	r = readl(ts->regs + SENSOR_TEMP1);
 	state = REG_GET_MASK(r, SENSOR_TEMP1_CPU_TEMP_MASK);
-	seq_printf(s, "Temperatures: CPU(%d) ", translate_temp(state));
+	seq_printf(s, "Temperatures: CPU(%d) ", translate_temp(ts, state));
 	state = REG_GET_MASK(r, SENSOR_TEMP1_GPU_TEMP_MASK);
-	seq_printf(s, " GPU(%d) ", translate_temp(state));
+	seq_printf(s, " GPU(%d) ", translate_temp(ts, state));
 	r = readl(ts->regs + SENSOR_TEMP2);
 	state = REG_GET_MASK(r, SENSOR_TEMP2_PLLX_TEMP_MASK);
-	seq_printf(s, " PLLX(%d) ", translate_temp(state));
+	seq_printf(s, " PLLX(%d) ", translate_temp(ts, state));
 	state = REG_GET_MASK(r, SENSOR_TEMP2_MEM_TEMP_MASK);
-	seq_printf(s, " MEM(%d)\n", translate_temp(state));
+	seq_printf(s, " MEM(%d)\n", translate_temp(ts, state));
 
 	for (i = 0; i < ts->soc->num_ttgs; i++) {
 		seq_printf(s, "%s:\n", ttgs[i]->name);
@@ -2159,6 +2162,8 @@ static int tegra_soctherm_probe(struct platform_device *pdev)
 	if (err)
 		return err;
 
+	shared_calib.lower_precision = soc->lower_precision;
+
 	/* calculate tsensor calibration data */
 	for (i = 0; i < soc->num_tsensors; ++i) {
 		err = tegra_calc_tsensor_calib(&soc->tsensors[i],
diff --git a/drivers/thermal/tegra/soctherm.h b/drivers/thermal/tegra/soctherm.h
index aa4af9268b05..67d4ca149e59 100644
--- a/drivers/thermal/tegra/soctherm.h
+++ b/drivers/thermal/tegra/soctherm.h
@@ -122,6 +122,7 @@ struct tegra_soctherm_fuse {
 struct tsensor_shared_calib {
 	u32 base_cp, base_ft;
 	u32 actual_temp_cp, actual_temp_ft;
+	bool lower_precision;
 };
 
 struct tegra_soctherm_soc {
@@ -133,6 +134,11 @@ struct tegra_soctherm_soc {
 	const int thresh_grain;
 	const unsigned int bptt;
 	const bool use_ccroc;
+	/*
+	 * Sensors count in 1 C instead of 0.5 C units: the readback and
+	 * the thresholds are in 2 C steps then.
+	 */
+	const bool lower_precision;
 	struct tsensor_group_thermtrips *thermtrips;
 };
 
diff --git a/drivers/thermal/tegra/tegra114-soctherm.c b/drivers/thermal/tegra/tegra114-soctherm.c
index 688104f28052..0a30103c3f74 100644
--- a/drivers/thermal/tegra/tegra114-soctherm.c
+++ b/drivers/thermal/tegra/tegra114-soctherm.c
@@ -23,7 +23,8 @@
 #define TEGRA114_THERMCTL_LVL0_UP_THRESH_MASK	(0xff << 17)
 #define TEGRA114_THERMCTL_LVL0_DN_THRESH_MASK	(0xff << 9)
 
-#define TEGRA114_THRESH_GRAIN			1000
+/* thresholds are in 2 C steps because of the lower precision */
+#define TEGRA114_THRESH_GRAIN			2000
 #define TEGRA114_BPTT				8
 
 static const struct tegra_tsensor_configuration tegra114_tsensor_config = {
@@ -206,4 +207,5 @@ const struct tegra_soctherm_soc tegra114_soctherm = {
 	.thresh_grain = TEGRA114_THRESH_GRAIN,
 	.bptt = TEGRA114_BPTT,
 	.use_ccroc = false,
+	.lower_precision = true,
 };

-- 
2.56.0

