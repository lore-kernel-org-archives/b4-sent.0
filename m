From: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>
Date: Mon, 07 Apr 2025 11:28:18 +0100
Subject: [PATCH v3 4/6] clk: clk-axi-clkgen: detect axi_clkgen_limits at
 runtime
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250407-dev-axi-clkgen-limits-v3-4-33c7f27c9d69@analog.com>
References: <20250407-dev-axi-clkgen-limits-v3-0-33c7f27c9d69@analog.com>
In-Reply-To: <20250407-dev-axi-clkgen-limits-v3-0-33c7f27c9d69@analog.com>
To: linux-clk@vger.kernel.org, linux-fpga@vger.kernel.org
Cc: Stephen Boyd <sboyd@kernel.org>, 
 Michael Turquette <mturquette@baylibre.com>, 
 Moritz Fischer <mdf@kernel.org>, Wu Hao <hao.wu@intel.com>, 
 Xu Yilun <yilun.xu@intel.com>, Tom Rix <trix@redhat.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1744021699; l=3698;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=iBmfD8SeeesocRGR7ow2MXwCfnSXtfBsCbwFv9xpXxk=;
 b=K01RSyoiK8pVy3wGTN0J2DCVAYKrP31FAHvA97wxGn2ecEfqv61/tIs2W3V91hKmYouKAFE2X
 xlzdruBuBYmALjm/q+9xW4cZ0zwVl6288k3pgONx3M7wrcdJEOhAjg1
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patch adds support for setting the limits in struct
axi_clkgen_limits  in accordance with fpga speed grade, voltage,
technology and family. This new information is extracted from
two new registers implemented in the ip core that are only available
for core versions higher or equal to 4.

Signed-off-by: Nuno Sá <nuno.sa@analog.com>
---
 drivers/clk/clk-axi-clkgen.c | 62 +++++++++++++++++++++++++++++++++++++++++++-
 1 file changed, 61 insertions(+), 1 deletion(-)

diff --git a/drivers/clk/clk-axi-clkgen.c b/drivers/clk/clk-axi-clkgen.c
index 2a95f9b220234a1245024a821c50e1eb9c104ac9..8c270ba7626bc24c4385615b7aa08ee95e198881 100644
--- a/drivers/clk/clk-axi-clkgen.c
+++ b/drivers/clk/clk-axi-clkgen.c
@@ -16,6 +16,8 @@
 #include <linux/mod_devicetable.h>
 #include <linux/err.h>
 
+#include <linux/fpga/adi-axi-common.h>
+
 #define AXI_CLKGEN_V2_REG_RESET		0x40
 #define AXI_CLKGEN_V2_REG_CLKSEL	0x44
 #define AXI_CLKGEN_V2_REG_DRP_CNTRL	0x70
@@ -497,6 +499,54 @@ static u8 axi_clkgen_get_parent(struct clk_hw *clk_hw)
 	return parent;
 }
 
+static int axi_clkgen_setup_limits(struct axi_clkgen *axi_clkgen,
+				   struct device *dev)
+{
+	unsigned int tech, family, speed_grade, reg_value;
+
+	axi_clkgen_read(axi_clkgen, ADI_AXI_REG_FPGA_INFO, &reg_value);
+	tech = ADI_AXI_INFO_FPGA_TECH(reg_value);
+	family = ADI_AXI_INFO_FPGA_FAMILY(reg_value);
+	speed_grade = ADI_AXI_INFO_FPGA_SPEED_GRADE(reg_value);
+
+	axi_clkgen->limits.fpfd_min = 10000;
+	axi_clkgen->limits.fvco_min = 600000;
+
+	switch (speed_grade) {
+	case ADI_AXI_FPGA_SPEED_1 ... ADI_AXI_FPGA_SPEED_1LV:
+		axi_clkgen->limits.fvco_max = 1200000;
+		axi_clkgen->limits.fpfd_max = 450000;
+		break;
+	case ADI_AXI_FPGA_SPEED_2 ... ADI_AXI_FPGA_SPEED_2LV:
+		axi_clkgen->limits.fvco_max = 1440000;
+		axi_clkgen->limits.fpfd_max = 500000;
+		if (family == ADI_AXI_FPGA_FAMILY_KINTEX || family == ADI_AXI_FPGA_FAMILY_ARTIX) {
+			axi_clkgen_read(axi_clkgen, ADI_AXI_REG_FPGA_VOLTAGE,
+					&reg_value);
+			if (ADI_AXI_INFO_FPGA_VOLTAGE(reg_value) < 950) {
+				axi_clkgen->limits.fvco_max = 1200000;
+				axi_clkgen->limits.fpfd_max = 450000;
+			}
+		}
+		break;
+	case ADI_AXI_FPGA_SPEED_3:
+		axi_clkgen->limits.fvco_max = 1600000;
+		axi_clkgen->limits.fpfd_max = 550000;
+		break;
+	default:
+		return dev_err_probe(dev, -ENODEV, "Unknown speed grade %d\n",
+				     speed_grade);
+	};
+
+	/* Overwrite vco limits for ultrascale+ */
+	if (tech == ADI_AXI_FPGA_TECH_ULTRASCALE_PLUS) {
+		axi_clkgen->limits.fvco_max = 1600000;
+		axi_clkgen->limits.fvco_min = 800000;
+	}
+
+	return 0;
+}
+
 static const struct clk_ops axi_clkgen_ops = {
 	.recalc_rate = axi_clkgen_recalc_rate,
 	.determine_rate = axi_clkgen_determine_rate,
@@ -511,6 +561,7 @@ static int axi_clkgen_probe(struct platform_device *pdev)
 {
 	const struct axi_clkgen_limits *dflt_limits;
 	struct axi_clkgen *axi_clkgen;
+	unsigned int pcore_version;
 	struct clk_init_data init;
 	const char *parent_names[2];
 	const char *clk_name;
@@ -556,7 +607,16 @@ static int axi_clkgen_probe(struct platform_device *pdev)
 			return -EINVAL;
 	}
 
-	memcpy(&axi_clkgen->limits, dflt_limits, sizeof(axi_clkgen->limits));
+	axi_clkgen_read(axi_clkgen, ADI_AXI_REG_VERSION, &pcore_version);
+
+	if (ADI_AXI_PCORE_VER_MAJOR(pcore_version) > 0x04) {
+		ret = axi_clkgen_setup_limits(axi_clkgen, &pdev->dev);
+		if (ret)
+			return ret;
+	} else {
+		memcpy(&axi_clkgen->limits, dflt_limits,
+		       sizeof(axi_clkgen->limits));
+	}
 
 	clk_name = pdev->dev.of_node->name;
 	of_property_read_string(pdev->dev.of_node, "clock-output-names",

-- 
2.49.0

