From: Rajan Yadav <rajanyadav0307@gmail.com>
Date: Wed, 04 Nov 2026 22:40:58 -0600
Subject: [PATCH 3/6] cpufreq: sun50i: Add A133 speed grade detection
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261104-a133-series-v1-3-58217cb33a87@gmail.com>
References: <20261104-a133-series-v1-0-58217cb33a87@gmail.com>
In-Reply-To: <20261104-a133-series-v1-0-58217cb33a87@gmail.com>
To: Yangtao Li <tiny.windzz@gmail.com>, Viresh Kumar <vireshk@kernel.org>, 
 Nishanth Menon <nm@ti.com>, Stephen Boyd <sboyd@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Chen-Yu Tsai <wens@kernel.org>, 
 Jernej Skrabec <jernej.skrabec@gmail.com>, 
 Samuel Holland <samuel@sholland.org>, Maxime Ripard <mripard@kernel.org>, 
 "Rafael J. Wysocki" <rafael@kernel.org>, 
 Viresh Kumar <viresh.kumar@linaro.org>, 
 Andre Przywara <andre.przywara@arm.com>
Cc: linux-pm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-sunxi@lists.linux.dev, 
 linux-kernel@vger.kernel.org, Cody Eksal <masterr3c0rd@epochal.quest>, 
 Alexander Sverdlin <alex@sverdlin.org>, 
 Rajan Yadav <rajanyadav0307@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793853656; l=10145;
 i=rajanyadav0307@gmail.com; s=20261103; h=from:subject:message-id;
 bh=7tcNYG4615OVf5uE7/DnP8d9qCp7eIaFzts291Ediz0=;
 b=poQQ54BqWKdiyQCBjiJjAvIRt3F1oPpUP9qi71hjn0JThAG7yr9HSXcdWS2V4yLN7fVpnwu0+
 xtEbfYVpl9kBq2oMAQBgGOg3PJ8Y20QKMnxHU1nFgDYDxIWL9eKEVYX
X-Developer-Key: i=rajanyadav0307@gmail.com; a=ed25519;
 pk=4ZPeiP5qrv2b44q/Obxi2koUS70Q6npbttJnpUoTlgg=
X-Endpoint-Received: by B4 Relay for rajanyadav0307@gmail.com/20261103 with auth_id=1391
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The A133 is handled as an A100 today: only the CPU bin field at SID
offset 0x1c is read, which gives one of three A100 voltage tables.
The vendor BSP for this family (sun50iw10) selects one of 11 grades
from the chip marking ID, the CPU bin, the ICPU current, the PCPU
field, a bin extension bit and the die revision:

- "high speed" marking IDs use the b0-b3 grades, which have 1416 and
  1512 MHz instead of 1464 MHz
- the other parts use a0-a6
- die revisions 0, 3 and 4 ("A-E") use different grades from all other
  revisions ("F and later")
- revision A-E normal parts with ICPU and PCPU within fixed ranges use
  a0

On a KickPi K5C (A133, marking 0x1400, bin 0b010, revision 6), the BSP
selects b2: 408-1512 MHz with 1.10 V at 1512 MHz. Mainline selects the
A100 speed1 table instead. So the chip runs 40 mV below the vendor
voltage at 408-816 MHz and 40 mV above it at 1200 and 1320 MHz, and its
top OPP is 1464 MHz at 1.18 V instead of 1512 MHz at 1.10 V. Grades
with 1416 and 1512 MHz cannot be described at all.

Add the vendor selection for the new A133 OPP compatible. a5 and a6
share their voltages, so the 11 grades map to speed0-9:

  index:  0  1  2  3  4  5      6  7  8  9
  vendor: a0 a1 a2 a3 a4 a5/a6  b0 b1 b2 b3

The die revision comes from SMCCC SOC_ID, as for the H616. On the A133
this needs TF-A with the sun50i_a133 platform, added in commit
a584e8632a7a ("feat(allwinner): add support for allwinner A133 SoC")
and not yet in a release; it reads the same SYSCON register as the
BSP. Neither the A-E nor the F grades always have the lower voltage
(for the same bin, A-E is mostly lower or equal up to 816 MHz and higher
or equal from 1008 MHz). So without SOC_ID the driver keeps the A100
selection, as before, adds the BSP's a0 rule for normal parts, which
never lowers a voltage, and warns. Revision F parts then still run
20-40 mV below the vendor voltage at 408 and 600 MHz, some of them also
at 816 MHz.

The error message for a missing named cell now names the cell.

Testing:
- the function, built on the host from the driver source with stubbed
  cells and revision, matches a transcription of the BSP rules for
  120,960 combinations of boundary and typical field values, and gives
  the A100 selection with the BSP's a0 rule when the revision is
  unknown
- on the K5C it selects b2; the vdd-cpu regulator reads 0.94 V at
  408 MHz, 0.96 V at 1008 MHz, 1.06 V at 1416 MHz and 1.10 V at
  1512 MHz, as in the BSP table
- one hour of full load held 1512 MHz without throttling (max 79 C,
  with the 90 C trip from the A100 thermal trips patch)
- with the revision forced to unknown it warns and selects speed1
- the same kernel with the A100 OPP table gives the same OPPs as
  before
- a missing cell fails the probe with an error naming the cell, and
  the system keeps running without cpufreq

Claude Code (Anthropic) drafted this patch and its message from the
selection rules in the vendor BSP cpufreq driver (no code copied) and
from my test results; I reviewed and tested it.

Suggested-by: Andre Przywara <andre.przywara@arm.com>
Signed-off-by: Rajan Yadav <rajanyadav0307@gmail.com>
---
 drivers/cpufreq/sun50i-cpufreq-nvmem.c | 162 ++++++++++++++++++++++++++++++++-
 1 file changed, 161 insertions(+), 1 deletion(-)

diff --git a/drivers/cpufreq/sun50i-cpufreq-nvmem.c b/drivers/cpufreq/sun50i-cpufreq-nvmem.c
index 34c0897c22c..6bccea2887b 100644
--- a/drivers/cpufreq/sun50i-cpufreq-nvmem.c
+++ b/drivers/cpufreq/sun50i-cpufreq-nvmem.c
@@ -27,8 +27,10 @@
 
 static struct platform_device *cpufreq_dt_pdev, *sun50i_cpufreq_pdev;
 
+/* Exactly one of the two callbacks is set */
 struct sunxi_cpufreq_data {
 	u32 (*efuse_xlate)(u32 speedbin);
+	int (*get_speed)(struct device *cpu_dev, struct device_node *np);
 };
 
 static int sun50i_cpufreq_read_cell(struct device *cpu_dev,
@@ -41,9 +43,14 @@ static int sun50i_cpufreq_read_cell(struct device *cpu_dev,
 	__le32 tmp = 0;
 
 	cell = of_nvmem_cell_get(np, id);
-	if (IS_ERR(cell))
+	if (IS_ERR(cell)) {
+		if (id)
+			return dev_err_probe(cpu_dev, PTR_ERR(cell),
+					     "Could not get nvmem cell %s\n",
+					     id);
 		return dev_err_probe(cpu_dev, PTR_ERR(cell),
 				     "Could not get nvmem cell\n");
+	}
 
 	buf = nvmem_cell_read(cell, &len);
 	nvmem_cell_put(cell);
@@ -152,6 +159,149 @@ static u32 sun50i_h616_efuse_xlate(u32 speedbin)
 	return value;
 }
 
+/*
+ * A133 speed grades, as selected by the vendor BSP (sun50iw10): a0-a6 for
+ * normal parts and b0-b3 for "high speed" parts. a5 and a6 have the same
+ * OPPs and voltages and share an index. The index is the N of
+ * opp-microvolt-speedN and the bit in opp-supported-hw. a0-a2 have the
+ * same voltages as the A100 speed0-speed2.
+ */
+enum sun50i_a133_grade {
+	SUN50I_A133_GRADE_A0,
+	SUN50I_A133_GRADE_A1,
+	SUN50I_A133_GRADE_A2,
+	SUN50I_A133_GRADE_A3,
+	SUN50I_A133_GRADE_A4,
+	SUN50I_A133_GRADE_A5,		/* also a6 */
+	SUN50I_A133_GRADE_B0,
+	SUN50I_A133_GRADE_B1,
+	SUN50I_A133_GRADE_B2,
+	SUN50I_A133_GRADE_B3,
+};
+
+#define SUN50I_A133_MARKING_MASK	0xffff
+#define SUN50I_A133_BIN_SHIFT		12
+#define SUN50I_A133_BIN_MASK		0xf
+#define SUN50I_A133_ICPU_MASK		0xfff
+#define SUN50I_A133_PCPU_MASK		0xfff
+#define SUN50I_A133_BIN_EXT		BIT(31)
+#define SUN50I_A133_REV_MASK		0x7
+
+/*
+ * The BSP runs revision A-E normal parts at a0 when both the ICPU current
+ * (in 0.1 mA) and the PCPU field are in these ranges (upper bounds
+ * exclusive).
+ */
+#define SUN50I_A133_ICPU_A0_MIN		84
+#define SUN50I_A133_ICPU_A0_MAX		160
+#define SUN50I_A133_PCPU_A0_MIN		2900
+#define SUN50I_A133_PCPU_A0_MAX		3100
+
+static bool sun50i_a133_force_a0(u32 icpu, u32 pcpu)
+{
+	return icpu >= SUN50I_A133_ICPU_A0_MIN &&
+	       icpu < SUN50I_A133_ICPU_A0_MAX &&
+	       pcpu >= SUN50I_A133_PCPU_A0_MIN &&
+	       pcpu < SUN50I_A133_PCPU_A0_MAX;
+}
+
+/* Marking IDs that the BSP treats as "high speed" parts */
+static bool sun50i_a133_is_high_speed(u32 marking)
+{
+	switch (marking) {
+	case 0x0200:
+	case 0x0600:
+	case 0x0620:
+	case 0x0640:
+	case 0x0800:
+	case 0x1000:
+	case 0x1400:
+	case 0x2000:
+	case 0x4000:
+		return true;
+	default:
+		return false;
+	}
+}
+
+static int sun50i_a133_get_speed(struct device *cpu_dev,
+				 struct device_node *np)
+{
+	u32 marking, bin_cell, pcpu, bin_ext, bin, icpu;
+	enum sun50i_a133_grade grade;
+	int ver_bits, ver;
+	bool before_f;
+	int ret;
+
+	ret = sun50i_cpufreq_read_cell(cpu_dev, np, "marking", &marking);
+	if (ret)
+		return ret;
+	ret = sun50i_cpufreq_read_cell(cpu_dev, np, "bin", &bin_cell);
+	if (ret)
+		return ret;
+	ret = sun50i_cpufreq_read_cell(cpu_dev, np, "pcpu", &pcpu);
+	if (ret)
+		return ret;
+	ret = sun50i_cpufreq_read_cell(cpu_dev, np, "bin-ext", &bin_ext);
+	if (ret)
+		return ret;
+
+	marking &= SUN50I_A133_MARKING_MASK;
+	bin = (bin_cell >> SUN50I_A133_BIN_SHIFT) & SUN50I_A133_BIN_MASK;
+	icpu = bin_cell & SUN50I_A133_ICPU_MASK;
+	pcpu &= SUN50I_A133_PCPU_MASK;
+
+	/*
+	 * Neither the revision A-E nor the revision F grades always have the
+	 * lower voltage, so there is no safe guess without the revision.
+	 * Keep the A100 selection then (a0-a2), which these SoCs used so far,
+	 * plus the BSP's a0 rule for normal parts, which never lowers a
+	 * voltage. Revision F parts then still run 20-40 mV below the vendor
+	 * voltage at 408 and 600 MHz, some of them also at 816 MHz, and "high
+	 * speed" parts get 1464 MHz instead of 1416 and 1512 MHz.
+	 */
+	ver_bits = get_soc_id_revision();
+	if (ver_bits < 0) {
+		dev_warn(cpu_dev,
+			 "SMCCC SOC_ID not available, using speed grades a0-a2\n");
+		if (!sun50i_a133_is_high_speed(marking) &&
+		    sun50i_a133_force_a0(icpu, pcpu))
+			return SUN50I_A133_GRADE_A0;
+		return sun50i_a100_efuse_xlate(bin_cell);
+	}
+
+	/*
+	 * The BSP treats revisions 0, 3 and 4 as "A-E" and all others as
+	 * "F and later".
+	 */
+	ver = ver_bits & SUN50I_A133_REV_MASK;
+	before_f = ver == 0 || ver == 3 || ver == 4;
+
+	if (sun50i_a133_is_high_speed(marking)) {
+		if (bin == 0b100)
+			grade = before_f ? SUN50I_A133_GRADE_B1 :
+					   SUN50I_A133_GRADE_B3;
+		else
+			grade = before_f ? SUN50I_A133_GRADE_B0 :
+					   SUN50I_A133_GRADE_B2;
+	} else if (!before_f && (bin_ext & SUN50I_A133_BIN_EXT)) {
+		grade = SUN50I_A133_GRADE_A5;		/* a6 */
+	} else if (before_f && sun50i_a133_force_a0(icpu, pcpu)) {
+		grade = SUN50I_A133_GRADE_A0;
+	} else if (bin == 0b100) {
+		grade = before_f ? SUN50I_A133_GRADE_A2 : SUN50I_A133_GRADE_A5;
+	} else if (bin == 0b010) {
+		grade = before_f ? SUN50I_A133_GRADE_A1 : SUN50I_A133_GRADE_A4;
+	} else {
+		grade = before_f ? SUN50I_A133_GRADE_A0 : SUN50I_A133_GRADE_A3;
+	}
+
+	dev_dbg(cpu_dev, "marking 0x%04x, bin %u, revision %d: speed grade %d\n",
+		marking, bin, ver, grade);
+
+	return grade;
+}
+
 static struct sunxi_cpufreq_data sun50i_h6_cpufreq_data = {
 	.efuse_xlate = sun50i_h6_efuse_xlate,
 };
@@ -160,6 +310,10 @@ static struct sunxi_cpufreq_data sun50i_a100_cpufreq_data = {
 	.efuse_xlate = sun50i_a100_efuse_xlate,
 };
 
+static struct sunxi_cpufreq_data sun50i_a133_cpufreq_data = {
+	.get_speed = sun50i_a133_get_speed,
+};
+
 static struct sunxi_cpufreq_data sun50i_h616_cpufreq_data = {
 	.efuse_xlate = sun50i_h616_efuse_xlate,
 };
@@ -171,6 +325,9 @@ static const struct of_device_id cpu_opp_match_list[] = {
 	{ .compatible = "allwinner,sun50i-a100-operating-points",
 	  .data = &sun50i_a100_cpufreq_data,
 	},
+	{ .compatible = "allwinner,sun50i-a133-operating-points",
+	  .data = &sun50i_a133_cpufreq_data,
+	},
 	{ .compatible = "allwinner,sun50i-h616-operating-points",
 	  .data = &sun50i_h616_cpufreq_data,
 	},
@@ -239,6 +396,9 @@ static int sun50i_cpufreq_get_efuse(void)
 
 	opp_data = match->data;
 
+	if (opp_data->get_speed)
+		return opp_data->get_speed(cpu_dev, np);
+
 	ret = sun50i_cpufreq_read_cell(cpu_dev, np, NULL, &speedbin);
 	if (ret)
 		return ret;

-- 
2.34.1

