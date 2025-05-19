From: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>
Date: Mon, 19 May 2025 16:41:10 +0100
Subject: [PATCH v6 5/7] clk: clk-axi-clkgen: detect axi_clkgen_limits at
 runtime
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250519-dev-axi-clkgen-limits-v6-5-bc4b3b61d1d4@analog.com>
References: <20250519-dev-axi-clkgen-limits-v6-0-bc4b3b61d1d4@analog.com>
In-Reply-To: <20250519-dev-axi-clkgen-limits-v6-0-bc4b3b61d1d4@analog.com>
To: linux-clk@vger.kernel.org, linux-fpga@vger.kernel.org, 
 dmaengine@vger.kernel.org, linux-hwmon@vger.kernel.org, 
 linux-iio@vger.kernel.org, linux-pwm@vger.kernel.org, 
 linux-spi@vger.kernel.org
Cc: Stephen Boyd <sboyd@kernel.org>, 
 Michael Turquette <mturquette@baylibre.com>, 
 Moritz Fischer <mdf@kernel.org>, Wu Hao <hao.wu@intel.com>, 
 Xu Yilun <yilun.xu@intel.com>, Tom Rix <trix@redhat.com>, 
 Vinod Koul <vkoul@kernel.org>, Jean Delvare <jdelvare@suse.com>, 
 Guenter Roeck <linux@roeck-us.net>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, Trevor Gamblin <tgamblin@baylibre.com>, 
 =?utf-8?q?Uwe_Kleine-K=C3=B6nig?= <ukleinek@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, Mark Brown <broonie@kernel.org>, 
 Mike Turquette <mturquette@linaro.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1747669828; l=3981;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=nuqSxH2DcFb0n5Cp5hJrZPhnAul6ayJrJavTFUfm6W8=;
 b=EP72A+xNs6i9+2wLrCQGiIpOvsX6aWdoj+MYtyGoxio5Ru2sYulayB6MJJdLSXy0TxcM37Oyf
 QpmRecRdZ82AshSfJiWGNzP3hAwy9LTVbc3BNjswZeYAyoKJUWe6Av9
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
 drivers/clk/clk-axi-clkgen.c | 65 +++++++++++++++++++++++++++++++++++++++++++-
 1 file changed, 64 insertions(+), 1 deletion(-)

diff --git a/drivers/clk/clk-axi-clkgen.c b/drivers/clk/clk-axi-clkgen.c
index 2a95f9b220234a1245024a821c50e1eb9c104ac9..f4e96394e9c25c817b09ee0c08751147083f19b7 100644
--- a/drivers/clk/clk-axi-clkgen.c
+++ b/drivers/clk/clk-axi-clkgen.c
@@ -6,6 +6,8 @@
  *  Author: Lars-Peter Clausen <lars@metafoo.de>
  */
 
+#include <linux/adi-axi-common.h>
+#include <linux/bits.h>
 #include <linux/platform_device.h>
 #include <linux/clk.h>
 #include <linux/clk-provider.h>
@@ -29,6 +31,9 @@
 
 #define AXI_CLKGEN_V2_DRP_STATUS_BUSY	BIT(16)
 
+#define ADI_CLKGEN_REG_FPGA_VOLTAGE		0x0140
+#define ADI_CLKGEN_INFO_FPGA_VOLTAGE(val)	((val) & GENMASK(15, 0))
+
 #define MMCM_REG_CLKOUT5_2	0x07
 #define MMCM_REG_CLKOUT0_1	0x08
 #define MMCM_REG_CLKOUT0_2	0x09
@@ -497,6 +502,54 @@ static u8 axi_clkgen_get_parent(struct clk_hw *clk_hw)
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
+			axi_clkgen_read(axi_clkgen, ADI_CLKGEN_REG_FPGA_VOLTAGE,
+					&reg_value);
+			if (ADI_CLKGEN_INFO_FPGA_VOLTAGE(reg_value) < 950) {
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
@@ -511,6 +564,7 @@ static int axi_clkgen_probe(struct platform_device *pdev)
 {
 	const struct axi_clkgen_limits *dflt_limits;
 	struct axi_clkgen *axi_clkgen;
+	unsigned int pcore_version;
 	struct clk_init_data init;
 	const char *parent_names[2];
 	const char *clk_name;
@@ -556,7 +610,16 @@ static int axi_clkgen_probe(struct platform_device *pdev)
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

