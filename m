From: Patrick Fischer <admin@tsv-stahl-riesa.de>
Date: Sat, 28 Nov 2026 00:44:39 +0100
Subject: [PATCH v2 2/2] thermal/drivers/tegra: Avoid SOC_THERM calculation
 overflow on Tegra114
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261128-upstream-soctherm-t114-v2-2-abba0b143037@tsv-stahl-riesa.de>
References: <20261128-upstream-soctherm-t114-v2-0-abba0b143037@tsv-stahl-riesa.de>
In-Reply-To: <20261128-upstream-soctherm-t114-v2-0-abba0b143037@tsv-stahl-riesa.de>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795823083; l=7516;
 i=admin@tsv-stahl-riesa.de; s=20261020; h=from:subject:message-id;
 bh=7hewYD1AiCwzAunQGimpWWurZkc1v6MD/KI76dRp3Y4=;
 b=4fjI+aOsZV+GFx4e8E5b4Pyuk5EZm1RHJgcJrvqg6picLX4wInKkFJJorUxswaoDAqsYvoU2R
 ShPGEAM2eFpB0eVauMVpZdZhOOz6JZKH/p6w3zdmsQYDAuQzXEt8GU8
X-Developer-Key: i=admin@tsv-stahl-riesa.de; a=ed25519;
 pk=D+v6EloYcEY9PIUHFyTM5sqcGIU/fIXzLUdkR8vjAtk=
X-Endpoint-Received: by B4 Relay for admin@tsv-stahl-riesa.de/20261020 with auth_id=1251
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The SOC_THERM hardware calculates each sensor temperature in units of
0.5 C as 'THERMA * capture / 2^13 + THERMB'. On Tegra114 the
intermediate product 'THERMA * capture' has to fit into 24 bits; if
not, TEMP_VALID is not set for the sensor.

With the fuse values on the tested devices, this leaves very little
range given the current logic for calculating THERMA and THERMB,
topping out at values below room temperature and 53C depending on
sensor.

Fix the issue by introducing a lower precision mode where THERMA and
THERMB are halved before programming them into the hardware, and
correspondingly doubling the temperature values read from hardware.
TEGRA114_THRESH_GRAIN is also doubled so conversion of temperatures
into hardware threshold values divides by two. This is the same
approach as used by the downstream kernel.

Tested on an NVIDIA Tegra Note 7 (P1640).

Claude Code evaluated the register dumps from the device and wrote this
change from my measurements.

Fixes: 9d522a877b6f ("thermal/drivers/tegra: Add Tegra114 specific SOCTHERM driver")
Cc: stable@vger.kernel.org
Link: https://lore.kernel.org/all/22816196.EfDdHjke4D@senjougahara/
Tested-by: Svyatoslav Ryhel <clamor95@gmail.com> # Tegratab (P1988)
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
2.56.1

