From: George Moussalem <george.moussalem@outlook.com>
Date: Tue, 25 Aug 2026 16:37:22 +0400
Subject: [PATCH v3 05/12] phy: qualcomm: qcom-uniphy-pcie-usb3-28lp: Use
 bulk reset_control API
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260825-ipq5018-usb3-v3-5-39be0955a6aa@outlook.com>
References: <20260825-ipq5018-usb3-v3-0-39be0955a6aa@outlook.com>
In-Reply-To: <20260825-ipq5018-usb3-v3-0-39be0955a6aa@outlook.com>
To: Vinod Koul <vkoul@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Praveenkumar I <praveenkumar.i@oss.qualcomm.com>, 
 Philipp Zabel <p.zabel@pengutronix.de>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Varadarajan Narayanan <varadarajan.narayanan@oss.qualcomm.com>, 
 Nitheesh Sekar <quic_nsekar@quicinc.com>, 
 Wesley Cheng <quic_wcheng@quicinc.com>, 
 Manivannan Sadhasivam <mani@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, linux-phy@lists.infradead.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-usb@vger.kernel.org, George Moussalem <george.moussalem@outlook.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1787661450; l=3269;
 i=george.moussalem@outlook.com; s=20250321; h=from:subject:message-id;
 bh=anmYpL4XdHm2CePMeEnW1kc8uD6kV9bQvtwXZhei8sQ=;
 b=J/54879naA7qYSLWrsAljr2kFOCd8PXFxuQZhTFXpXZSDCASzOr2ohHCctLia9y5e4PFreiOv
 W9jI3yXpHu2CX48WxUKgACuYEyuA5RRzsUgucw2v2HvG1k11WUEmL+L
X-Developer-Key: i=george.moussalem@outlook.com; a=ed25519;
 pk=/PuRTSI9iYiHwcc6Nrde8qF4ZDhJBlUgpHdhsIjnqIk=
X-Endpoint-Received: by B4 Relay for george.moussalem@outlook.com/20250321 with auth_id=364
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Switch to using bulk reset_control functions to prepare the driver for
managing multiple resets, acquiring reset controls by name, and
uniformly storing resets in the private data structure to enable support
for future combo PHY functionality requiring multiple resets.

Signed-off-by: George Moussalem <george.moussalem@outlook.com>
---
 .../phy/qualcomm/phy-qcom-uniphy-pcie-usb3-28lp.c  | 31 ++++++++++++++++------
 1 file changed, 23 insertions(+), 8 deletions(-)

diff --git a/drivers/phy/qualcomm/phy-qcom-uniphy-pcie-usb3-28lp.c b/drivers/phy/qualcomm/phy-qcom-uniphy-pcie-usb3-28lp.c
index 44ab8f440b8a..671bb805057f 100644
--- a/drivers/phy/qualcomm/phy-qcom-uniphy-pcie-usb3-28lp.c
+++ b/drivers/phy/qualcomm/phy-qcom-uniphy-pcie-usb3-28lp.c
@@ -64,7 +64,8 @@ struct qcom_uniphy {
 	const struct qcom_uniphy_data *data;
 	struct clk_bulk_data *clks;
 	int num_clks;
-	struct reset_control *resets;
+	struct reset_control_bulk_data *resets;
+	int num_resets;
 	void __iomem *base;
 	int lanes;
 };
@@ -133,7 +134,7 @@ static int qcom_uniphy_pcie_usb3_power_off(struct phy *x)
 
 	clk_bulk_disable_unprepare(phy->num_clks, phy->clks);
 
-	return reset_control_assert(phy->resets);
+	return reset_control_bulk_assert(phy->num_resets, phy->resets);
 }
 
 static int qcom_uniphy_pcie_usb3_power_on(struct phy *x)
@@ -141,7 +142,7 @@ static int qcom_uniphy_pcie_usb3_power_on(struct phy *x)
 	struct qcom_uniphy *phy = phy_get_drvdata(x);
 	int ret;
 
-	ret = reset_control_assert(phy->resets);
+	ret = reset_control_bulk_assert(phy->num_resets, phy->resets);
 	if (ret) {
 		dev_err(phy->dev, "reset assert failed (%d)\n", ret);
 		return ret;
@@ -149,7 +150,7 @@ static int qcom_uniphy_pcie_usb3_power_on(struct phy *x)
 
 	usleep_range(RST_ASSERT_DELAY_MIN_US, RST_ASSERT_DELAY_MAX_US);
 
-	ret = reset_control_deassert(phy->resets);
+	ret = reset_control_bulk_deassert(phy->num_resets, phy->resets);
 	if (ret) {
 		dev_err(phy->dev, "reset deassert failed (%d)\n", ret);
 		return ret;
@@ -173,19 +174,33 @@ static int qcom_uniphy_pcie_usb3_power_on(struct phy *x)
 static inline int qcom_uniphy_pcie_usb3_get_resources(struct platform_device *pdev,
 						      struct qcom_uniphy *phy)
 {
+	struct device *dev = phy->dev;
 	struct resource *res;
+	int i, count;
 
 	phy->base = devm_platform_get_and_ioremap_resource(pdev, 0, &res);
 	if (IS_ERR(phy->base))
 		return PTR_ERR(phy->base);
 
-	phy->num_clks = devm_clk_bulk_get_all(phy->dev, &phy->clks);
+	phy->num_clks = devm_clk_bulk_get_all(dev, &phy->clks);
 	if (phy->num_clks < 0)
 		return phy->num_clks;
 
-	phy->resets = devm_reset_control_array_get_exclusive(phy->dev);
-	if (IS_ERR(phy->resets))
-		return PTR_ERR(phy->resets);
+	count = of_count_phandle_with_args(dev->of_node, "resets", "#reset-cells");
+	if (count < 0)
+		return count;
+
+	phy->resets = devm_kcalloc(dev, count, sizeof(*phy->resets), GFP_KERNEL);
+	if (!phy->resets)
+		return -ENOMEM;
+
+	for (i = 0; i < count; i++) {
+		phy->resets[i].rstc = devm_reset_control_get_exclusive_by_index(dev, i);
+		if (IS_ERR(phy->resets[i].rstc))
+			return PTR_ERR(phy->resets[i].rstc);
+	}
+
+	phy->num_resets = count;
 
 	return 0;
 }

-- 
2.53.0

