From: Patrick Fischer <admin@tsv-stahl-riesa.de>
Date: Thu, 29 Oct 2026 10:33:01 +0100
Subject: [PATCH 3/3] clk: tegra: dfll: Get the voltage step of range-based
 regulators
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261029-upstream-speedo-t114-v1-3-81457cc9d94c@tsv-stahl-riesa.de>
References: <20261029-upstream-speedo-t114-v1-0-81457cc9d94c@tsv-stahl-riesa.de>
In-Reply-To: <20261029-upstream-speedo-t114-v1-0-81457cc9d94c@tsv-stahl-riesa.de>
To: Thierry Reding <thierry.reding@kernel.org>, 
 Jonathan Hunter <jonathanh@nvidia.com>
Cc: Mikko Perttunen <mperttunen@nvidia.com>, 
 Svyatoslav Ryhel <clamor95@gmail.com>, 
 Prashant Gaikwad <pgaikwad@nvidia.com>, Stephen Boyd <sboyd@kernel.org>, 
 Brian Masney <bmasney+clk@redhat.com>, 
 Jerome Brunet <jbrunet+clk@baylibre.com>, linux-clk@vger.kernel.org, 
 linux-tegra@vger.kernel.org, linux-kernel@vger.kernel.org, 
 stable@vger.kernel.org, Patrick Fischer <admin@tsv-stahl-riesa.de>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793266385; l=3247;
 i=admin@tsv-stahl-riesa.de; s=20261020; h=from:subject:message-id;
 bh=gDuzbARfWGkxqaRftjXwXdKDlFHjKq5qyD4dHr0p9zA=;
 b=UCEkvo1iL+WYXKVi+OSl1d7CVjMUf8WfbDywb4ejuLsyVFLuyGV4tLMHXRHQfNkaschpr9pgm
 pK4anvbJKLdDoDHmbZjnADxSRDPI5Bd1BMeWQYy+ACSr59oV2cGEbOn
X-Developer-Key: i=admin@tsv-stahl-riesa.de; a=ed25519;
 pk=D+v6EloYcEY9PIUHFyTM5sqcGIU/fIXzLUdkR8vjAtk=
X-Endpoint-Received: by B4 Relay for admin@tsv-stahl-riesa.de/20261020 with auth_id=1251
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

get_alignment_from_regulator() takes the voltage step from
regulator_get_linear_step(), which returns desc->uV_step. Regulators
described by linear ranges, such as the SMPS of the TI Palmas PMIC,
leave uV_step at 0.

With a step of 0, round_cvb_voltage() returns 0 for every OPP, which is
then clamped to min_millivolts, so all CPU OPPs get the same voltage.
The I2C LUT is broken as well: find_vdd_map_entry_exact() and
find_vdd_map_entry_min() divide by the step, and on ARMv7 with hardware
division the result is 0, so selector 0 matches every voltage. The LUT
ends up with a single entry and the DFLL never changes vdd_cpu.

This affects boards that run the DFLL in I2C mode with a Palmas SMPS as
vdd_cpu. In mainline these are the Xiaomi Mi Pad (Tegra124, since v6.19)
and the Asus Transformer Pad TF701T (Tegra114, DFLL enabled for v7.4).
The AS3722 and MAX77621 used by the other DFLL boards report a linear
step, and the PWM mode does not use the regulator.

On a Tegra Note 7 (Tegra114, TPS65913) all 16 CPU OPPs are at 1000 mV
and vdd_cpu stays at the 1.10 V left by the bootloader. The CPU runs at
about 1.34 GHz whatever cpufreq requests. With this patch the OPPs range
from 1000 mV to 1270 mV, the LUT holds the 1000 mV to 1270 mV selectors
and the DFLL follows cpufreq up to 1708.5 MHz.

If the regulator reports no linear step, use the smallest step between
the voltages that are usable on the board. Fail the probe if there is
none instead of running with a step of 0.

Fixes: b3cf8d069505 ("clk: tegra: dfll: CVB calculation alignment with the regulator")
Cc: stable@vger.kernel.org
Signed-off-by: Patrick Fischer <admin@tsv-stahl-riesa.de>
---
 drivers/clk/tegra/clk-tegra124-dfll-fcpu.c | 26 ++++++++++++++++++++++++++
 1 file changed, 26 insertions(+)

diff --git a/drivers/clk/tegra/clk-tegra124-dfll-fcpu.c b/drivers/clk/tegra/clk-tegra124-dfll-fcpu.c
index 457a77c5bb62..5bdea4775076 100644
--- a/drivers/clk/tegra/clk-tegra124-dfll-fcpu.c
+++ b/drivers/clk/tegra/clk-tegra124-dfll-fcpu.c
@@ -642,6 +642,7 @@ static int get_alignment_from_regulator(struct device *dev,
 					 struct rail_alignment *align)
 {
 	struct regulator *reg = regulator_get(dev, "vdd-cpu");
+	int i, n_voltages, uv, prev_uv = 0;
 
 	if (IS_ERR(reg))
 		return PTR_ERR(reg);
@@ -649,8 +650,33 @@ static int get_alignment_from_regulator(struct device *dev,
 	align->offset_uv = regulator_list_voltage(reg, 0);
 	align->step_uv = regulator_get_linear_step(reg);
 
+	/*
+	 * Regulators described by linear ranges (e.g. the Palmas SMPS) don't
+	 * report a linear step. Use the smallest step between the voltages
+	 * that are usable on this board instead.
+	 */
+	if (!align->step_uv) {
+		n_voltages = regulator_count_voltages(reg);
+		for (i = 0; i < n_voltages; i++) {
+			uv = regulator_list_voltage(reg, i);
+			if (uv <= 0)
+				continue;
+
+			if (prev_uv && uv > prev_uv &&
+			    (!align->step_uv || uv - prev_uv < align->step_uv))
+				align->step_uv = uv - prev_uv;
+
+			prev_uv = uv;
+		}
+	}
+
 	regulator_put(reg);
 
+	if (!align->step_uv) {
+		dev_err(dev, "failed to get vdd-cpu voltage step\n");
+		return -EINVAL;
+	}
+
 	return 0;
 }
 

-- 
2.56.0

