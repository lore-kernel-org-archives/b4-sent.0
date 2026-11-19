From: Umer Uddin <umer.uddin@mentallysanemainliners.org>
Date: Thu, 19 Nov 2026 19:49:19 +0000
Subject: [PATCH 3/6] phy: exynos5-usbdrd: support Exynos7885 USB PHY
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261119-gta3xllte-usb-battery-v1-3-0cf5f763522e@mentallysanemainliners.org>
References: <20261119-gta3xllte-usb-battery-v1-0-0cf5f763522e@mentallysanemainliners.org>
In-Reply-To: <20261119-gta3xllte-usb-battery-v1-0-0cf5f763522e@mentallysanemainliners.org>
To: Vinod Koul <vkoul@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Manivannan Sadhasivam <mani@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Marek Szyprowski <m.szyprowski@samsung.com>, 
 Sylwester Nawrocki <s.nawrocki@samsung.com>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Peter Griffin <peter.griffin@linaro.org>, 
 Alim Akhtar <alim.akhtar@samsung.com>
Cc: Krzysztof Kozlowski <krzk@kernel.org>, linux-phy@lists.infradead.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-usb@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-samsung-soc@vger.kernel.org, 
 Umer Uddin <umer.uddin@mentallysanemainliners.org>, 
 David Virag <virag.david003@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795117759; l=4041;
 i=umer.uddin@mentallysanemainliners.org; s=20261109;
 h=from:subject:message-id; bh=0vg/X3UExBZ1rUkseyLY5OJLxLcF7MB1/Qmq/onbtak=;
 b=9OthLMMVqY+YTTHZvjYUSjxbFnYEGcuT6VI0DHA0eiiVbF8M2VWKX8BSxVVy5tltkkoQ4um1p
 UV6Jtx1R3ceDGmOqOOVak2DLMEoBUo6kT1JaUOt0Q44fnvanfVPSQ3J
X-Developer-Key: i=umer.uddin@mentallysanemainliners.org; a=ed25519;
 pk=Hsgrt4A72CFTe27AI1AAWlnLsiQrlb4+T+cbrfWDhUA=
X-Endpoint-Received: by B4 Relay for umer.uddin@mentallysanemainliners.org/20261109 with auth_id=1466
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: David Virag <virag.david003@gmail.com>

The Exynos7885 SoC has an Exynos USB PHY that theoretically supports
USB3 SuperSpeed, but all known devices using it only have USB2 and the
vendor driver has USB3 function stubbed out, so we'll only support USB2.

Apart from this mysterious USB3 capability, it's the closest to Exynos850
out of those supported. Unlike other SoCs though, this one doesn't set
the reference clock by default, so we have to set it manually.

For this, create a set_ref_clk_rate property in drvdata that can be set
to a predefined value to set the clockrate to.

Signed-off-by: David Virag <virag.david003@gmail.com>
[Umer Uddin: Rebased onto krzk for-next branch]
Signed-off-by: Umer Uddin <umer.uddin@mentallysanemainliners.org>
---
 drivers/phy/samsung/phy-exynos5-usbdrd.c    | 27 +++++++++++++++++++++++++++
 include/linux/soc/samsung/exynos-regs-pmu.h |  3 +++
 2 files changed, 30 insertions(+)

diff --git a/drivers/phy/samsung/phy-exynos5-usbdrd.c b/drivers/phy/samsung/phy-exynos5-usbdrd.c
index 087d552eb511..8f00586f11a6 100644
--- a/drivers/phy/samsung/phy-exynos5-usbdrd.c
+++ b/drivers/phy/samsung/phy-exynos5-usbdrd.c
@@ -23,6 +23,7 @@
 #include <linux/regmap.h>
 #include <linux/regulator/consumer.h>
 #include <linux/soc/samsung/exynos-regs-pmu.h>
+#include <linux/units.h>
 #include <linux/usb/typec.h>
 #include <linux/usb/typec_mux.h>
 
@@ -483,6 +484,7 @@ struct exynos5_usbdrd_phy_drvdata {
 	int n_clks;
 	const char * const *core_clk_names;
 	int n_core_clks;
+	u32 set_ref_clk_rate;
 	const char * const *regulator_names;
 	int n_regulators;
 	u32 pmu_offset_usbdrd0_phy;
@@ -1847,6 +1849,15 @@ static int exynos5_usbdrd_phy_clk_handle(struct exynos5_usbdrd_phy *phy_drd)
 			return dev_err_probe(phy_drd->dev, -ENODEV,
 					     "failed to find phy reference clock\n");
 
+		/* Some SoCs (e.g. Exynos7885) leave the reference clock unset */
+		if (phy_drd->drv_data->set_ref_clk_rate) {
+			ret = clk_set_rate(ref_clk,
+					   phy_drd->drv_data->set_ref_clk_rate);
+			if (ret)
+				return dev_err_probe(phy_drd->dev, ret,
+						     "failed to set ref clock rate\n");
+		}
+
 		ref_rate = clk_get_rate(ref_clk);
 		ret = exynos5_rate_to_clk(ref_rate, &phy_drd->extrefclk);
 		if (ret)
@@ -2107,6 +2118,19 @@ static const struct exynos5_usbdrd_phy_drvdata exynos850_usbdrd_phy = {
 	.n_regulators		= ARRAY_SIZE(exynos5_regulator_names),
 };
 
+static const struct exynos5_usbdrd_phy_drvdata exynos7885_usbdrd_phy = {
+	.phy_cfg		= phy_cfg_exynos850,
+	.phy_ops		= &exynos850_usbdrd_phy_ops,
+	.pmu_offset_usbdrd0_phy	= EXYNOS7885_PHY_CTRL_USB20,
+	.clk_names		= exynos5_clk_names,
+	.n_clks			= ARRAY_SIZE(exynos5_clk_names),
+	.core_clk_names		= exynos5_core_clk_names,
+	.n_core_clks		= ARRAY_SIZE(exynos5_core_clk_names),
+	.regulator_names	= exynos5_regulator_names,
+	.n_regulators		= ARRAY_SIZE(exynos5_regulator_names),
+	.set_ref_clk_rate	= 50 * HZ_PER_MHZ,
+};
+
 static const struct exynos5_usbdrd_phy_tuning exynos990_tunes_utmi_postinit[] = {
 	PHY_TUNING_ENTRY_PHY(EXYNOS850_DRD_HSPPARACON,
 			     (HSPPARACON_TXVREF |
@@ -2929,6 +2953,9 @@ static const struct of_device_id exynos5_usbdrd_phy_of_match[] = {
 	}, {
 		.compatible = "samsung,exynos7870-usbdrd-phy",
 		.data = &exynos7870_usbdrd_phy
+	}, {
+		.compatible = "samsung,exynos7885-usbdrd-phy",
+		.data = &exynos7885_usbdrd_phy
 	}, {
 		.compatible = "samsung,exynos850-usbdrd-phy",
 		.data = &exynos850_usbdrd_phy
diff --git a/include/linux/soc/samsung/exynos-regs-pmu.h b/include/linux/soc/samsung/exynos-regs-pmu.h
index db8a7ca81080..73d9c509dae6 100644
--- a/include/linux/soc/samsung/exynos-regs-pmu.h
+++ b/include/linux/soc/samsung/exynos-regs-pmu.h
@@ -665,6 +665,9 @@
 /* For Exynos990 */
 #define EXYNOS990_PHY_CTRL_USB20				(0x72C)
 
+/* For Exynos7885 */
+#define EXYNOS7885_PHY_CTRL_USB20				(0x674)
+
 /* For Exynos7870 */
 #define EXYNOS7870_MIPI_PHY_CONTROL0				(0x070c)
 #define EXYNOS7870_MIPI_PHY_CONTROL1				(0x0714)

-- 
2.56.1

