From: George Moussalem <george.moussalem@outlook.com>
Date: Tue, 25 Aug 2026 16:37:23 +0400
Subject: [PATCH v3 06/12] phy: qualcomm: qcom-uniphy-pcie-usb3-28lp:
 Improve error handling in power_on
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260825-ipq5018-usb3-v3-6-39be0955a6aa@outlook.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1787661450; l=2016;
 i=george.moussalem@outlook.com; s=20250321; h=from:subject:message-id;
 bh=7wBK4ADEhWBDqDww6gxmOEnN2/BlTdDKW1nGKMr0m+o=;
 b=C/MYQL7TG7DA7JcFLXibus27QkTlcnmxhzu7Vca3khVoAlzNRyJCTtlSZizM71/jTyiIZbUpo
 j5fKhLDbh4cDHNCctklnY94gRgK3ukpF3JbMkogPcOlKt+EED1pT4yo
X-Developer-Key: i=george.moussalem@outlook.com; a=ed25519;
 pk=/PuRTSI9iYiHwcc6Nrde8qF4ZDhJBlUgpHdhsIjnqIk=
X-Endpoint-Received: by B4 Relay for george.moussalem@outlook.com/20250321 with auth_id=364
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When the PHY fails the enable clocks, it leaves the PHY out of reset.
Fix this by asserting the reset before returning the error.

In addition, language correct the error messages.

Signed-off-by: George Moussalem <george.moussalem@outlook.com>
---
 drivers/phy/qualcomm/phy-qcom-uniphy-pcie-usb3-28lp.c | 13 +++++++++----
 1 file changed, 9 insertions(+), 4 deletions(-)

diff --git a/drivers/phy/qualcomm/phy-qcom-uniphy-pcie-usb3-28lp.c b/drivers/phy/qualcomm/phy-qcom-uniphy-pcie-usb3-28lp.c
index 671bb805057f..d25ae9d8b9e7 100644
--- a/drivers/phy/qualcomm/phy-qcom-uniphy-pcie-usb3-28lp.c
+++ b/drivers/phy/qualcomm/phy-qcom-uniphy-pcie-usb3-28lp.c
@@ -144,7 +144,7 @@ static int qcom_uniphy_pcie_usb3_power_on(struct phy *x)
 
 	ret = reset_control_bulk_assert(phy->num_resets, phy->resets);
 	if (ret) {
-		dev_err(phy->dev, "reset assert failed (%d)\n", ret);
+		dev_err(phy->dev, "failed to assert reset: %d\n", ret);
 		return ret;
 	}
 
@@ -152,7 +152,7 @@ static int qcom_uniphy_pcie_usb3_power_on(struct phy *x)
 
 	ret = reset_control_bulk_deassert(phy->num_resets, phy->resets);
 	if (ret) {
-		dev_err(phy->dev, "reset deassert failed (%d)\n", ret);
+		dev_err(phy->dev, "failed to deassert reset: %d\n", ret);
 		return ret;
 	}
 
@@ -160,8 +160,8 @@ static int qcom_uniphy_pcie_usb3_power_on(struct phy *x)
 
 	ret = clk_bulk_prepare_enable(phy->num_clks, phy->clks);
 	if (ret) {
-		dev_err(phy->dev, "clk prepare and enable failed %d\n", ret);
-		return ret;
+		dev_err(phy->dev, "failed to enable clocks: %d\n", ret);
+		goto err_assert_resets;
 	}
 
 	usleep_range(CLK_EN_DELAY_MIN_US, CLK_EN_DELAY_MAX_US);
@@ -169,6 +169,11 @@ static int qcom_uniphy_pcie_usb3_power_on(struct phy *x)
 	qcom_uniphy_pcie_usb3_init(phy);
 
 	return 0;
+
+err_assert_resets:
+	reset_control_bulk_assert(phy->num_resets, phy->resets);
+
+	return ret;
 }
 
 static inline int qcom_uniphy_pcie_usb3_get_resources(struct platform_device *pdev,

-- 
2.53.0

