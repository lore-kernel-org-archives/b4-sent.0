From: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
Date: Wed, 04 Sep 2024 12:42:00 +0530
Subject: [PATCH v6 4/4] PCI: qcom: Add RX margining settings for 16.0 GT/s
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240904-pci-qcom-gen4-stability-v6-4-ec39f7ae3f62@linaro.org>
References: <20240904-pci-qcom-gen4-stability-v6-0-ec39f7ae3f62@linaro.org>
In-Reply-To: <20240904-pci-qcom-gen4-stability-v6-0-ec39f7ae3f62@linaro.org>
To: Richard Zhu <hongxing.zhu@nxp.com>, 
 Lucas Stach <l.stach@pengutronix.de>, 
 Lorenzo Pieralisi <lpieralisi@kernel.org>, 
 =?utf-8?q?Krzysztof_Wilczy=C5=84ski?= <kw@linux.com>, 
 Rob Herring <robh@kernel.org>, Bjorn Helgaas <bhelgaas@google.com>, 
 Shawn Guo <shawnguo@kernel.org>, Sascha Hauer <s.hauer@pengutronix.de>, 
 Pengutronix Kernel Team <kernel@pengutronix.de>, 
 Fabio Estevam <festevam@gmail.com>, Jingoo Han <jingoohan1@gmail.com>, 
 Chuanhua Lei <lchuanhua@maxlinear.com>, 
 Marek Vasut <marek.vasut+renesas@gmail.com>, 
 Yoshihiro Shimoda <yoshihiro.shimoda.uh@renesas.com>
Cc: linux-pci@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 imx@lists.linux.dev, linux-kernel@vger.kernel.org, 
 linux-renesas-soc@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 abel.vesa@linaro.org, johan+linaro@kernel.org, 
 Shashank Babu Chinta Venkata <quic_schintav@quicinc.com>, 
 Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=openpgp-sha256; l=5581;
 i=manivannan.sadhasivam@linaro.org; h=from:subject:message-id;
 bh=+UyPXoBEoMHThbW48iMeb9Epx8yMpHkZz7Vs41Qi22Y=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBm2Ag/CKqFkchoOhfhcoyHVeR3YDPEC2OUGEWKm
 6WLB/Ag6VaJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCZtgIPwAKCRBVnxHm/pHO
 9T9aB/0cOOobTwlsF0wmCW6pgspvSb7L5UPaZJLD9me+c+UTbkKm+gmOC/7F0uhZc0mk91W104B
 7uqxEJOqSw585He5P6MCADmUTIV52H+sBvRQKQ9gEHrUd8GdC4neN+Je/JQMJKrldwkDj59AUvV
 NhiLjHvqT9p/xfskS0QpnO161HeZU3Qa0GcEXwqpL9jGAz1gjzVsUbcGffGGuilzGJtbvxar9YT
 HktzXUuO2QX2etlTpsm6qRmZD4DdzQaVpZ68hW/oxYjiiebbya9VKk+t6nwHIvRhqIznGDKFHrY
 +Vh7w8QtIvvWul1i7Z58hfnF1TeZTuO++OOnhhDw9ApQUHV9
X-Developer-Key: i=manivannan.sadhasivam@linaro.org; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@linaro.org/default with auth_id=185
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Shashank Babu Chinta Venkata <quic_schintav@quicinc.com>

Add RX lane margining settings for 16.0 GT/s (GEN 4) data rate. These
settings improve link stability while operating at high date rates and
helps to improve signal quality.

Signed-off-by: Shashank Babu Chinta Venkata <quic_schintav@quicinc.com>
Reviewed-by: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
[mani: dropped the code refactoring and minor changes]
Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
---
 drivers/pci/controller/dwc/pcie-designware.h  | 18 ++++++++++++++++
 drivers/pci/controller/dwc/pcie-qcom-common.c | 31 +++++++++++++++++++++++++++
 drivers/pci/controller/dwc/pcie-qcom-common.h |  1 +
 drivers/pci/controller/dwc/pcie-qcom-ep.c     |  4 +++-
 drivers/pci/controller/dwc/pcie-qcom.c        |  4 +++-
 5 files changed, 56 insertions(+), 2 deletions(-)

diff --git a/drivers/pci/controller/dwc/pcie-designware.h b/drivers/pci/controller/dwc/pcie-designware.h
index 51744ad25575..f5be99731f7e 100644
--- a/drivers/pci/controller/dwc/pcie-designware.h
+++ b/drivers/pci/controller/dwc/pcie-designware.h
@@ -209,6 +209,24 @@
 
 #define PCIE_PL_CHK_REG_ERR_ADDR			0xB28
 
+/*
+ * 16.0 GT/s (GEN4) lane margining register definitions
+ */
+#define GEN4_LANE_MARGINING_1_OFF		0xb80
+#define MARGINING_MAX_VOLTAGE_OFFSET		GENMASK(29, 24)
+#define MARGINING_NUM_VOLTAGE_STEPS		GENMASK(22, 16)
+#define MARGINING_MAX_TIMING_OFFSET		GENMASK(13, 8)
+#define MARGINING_NUM_TIMING_STEPS		GENMASK(5, 0)
+
+#define GEN4_LANE_MARGINING_2_OFF		0xb84
+#define MARGINING_IND_ERROR_SAMPLER		BIT(28)
+#define MARGINING_SAMPLE_REPORTING_METHOD	BIT(27)
+#define MARGINING_IND_LEFT_RIGHT_TIMING		BIT(26)
+#define MARGINING_IND_UP_DOWN_VOLTAGE		BIT(25)
+#define MARGINING_VOLTAGE_SUPPORTED		BIT(24)
+#define MARGINING_MAXLANES			GENMASK(20, 16)
+#define MARGINING_SAMPLE_RATE_TIMING		GENMASK(13, 8)
+#define MARGINING_SAMPLE_RATE_VOLTAGE		GENMASK(5, 0)
 /*
  * iATU Unroll-specific register definitions
  * From 4.80 core version the address translation will be made by unroll
diff --git a/drivers/pci/controller/dwc/pcie-qcom-common.c b/drivers/pci/controller/dwc/pcie-qcom-common.c
index dc7d93db9dc5..99b75e7f085d 100644
--- a/drivers/pci/controller/dwc/pcie-qcom-common.c
+++ b/drivers/pci/controller/dwc/pcie-qcom-common.c
@@ -43,3 +43,34 @@ void qcom_pcie_common_set_16gt_eq_settings(struct dw_pcie *pci)
 	dw_pcie_writel_dbi(pci, GEN3_EQ_CONTROL_OFF, reg);
 }
 EXPORT_SYMBOL_GPL(qcom_pcie_common_set_16gt_eq_settings);
+
+void qcom_pcie_common_set_16gt_rx_margining_settings(struct dw_pcie *pci)
+{
+	u32 reg;
+
+	reg = dw_pcie_readl_dbi(pci, GEN4_LANE_MARGINING_1_OFF);
+	reg &= ~(MARGINING_MAX_VOLTAGE_OFFSET |
+		MARGINING_NUM_VOLTAGE_STEPS |
+		MARGINING_MAX_TIMING_OFFSET |
+		MARGINING_NUM_TIMING_STEPS);
+	reg |= FIELD_PREP(MARGINING_MAX_VOLTAGE_OFFSET, 0x24) |
+		FIELD_PREP(MARGINING_NUM_VOLTAGE_STEPS, 0x78) |
+		FIELD_PREP(MARGINING_MAX_TIMING_OFFSET, 0x32) |
+		FIELD_PREP(MARGINING_NUM_TIMING_STEPS, 0x10);
+	dw_pcie_writel_dbi(pci, GEN4_LANE_MARGINING_1_OFF, reg);
+
+	reg = dw_pcie_readl_dbi(pci, GEN4_LANE_MARGINING_2_OFF);
+	reg |= MARGINING_IND_ERROR_SAMPLER |
+		MARGINING_SAMPLE_REPORTING_METHOD |
+		MARGINING_IND_LEFT_RIGHT_TIMING |
+		MARGINING_VOLTAGE_SUPPORTED;
+	reg &= ~(MARGINING_IND_UP_DOWN_VOLTAGE |
+		MARGINING_MAXLANES |
+		MARGINING_SAMPLE_RATE_TIMING |
+		MARGINING_SAMPLE_RATE_VOLTAGE);
+	reg |= FIELD_PREP(MARGINING_MAXLANES, pci->num_lanes) |
+		FIELD_PREP(MARGINING_SAMPLE_RATE_TIMING, 0x3f) |
+		FIELD_PREP(MARGINING_SAMPLE_RATE_VOLTAGE, 0x3f);
+	dw_pcie_writel_dbi(pci, GEN4_LANE_MARGINING_2_OFF, reg);
+}
+EXPORT_SYMBOL_GPL(qcom_pcie_common_set_16gt_rx_margining_settings);
diff --git a/drivers/pci/controller/dwc/pcie-qcom-common.h b/drivers/pci/controller/dwc/pcie-qcom-common.h
index 259e04b7bdf9..e9ddc901082e 100644
--- a/drivers/pci/controller/dwc/pcie-qcom-common.h
+++ b/drivers/pci/controller/dwc/pcie-qcom-common.h
@@ -6,3 +6,4 @@
 #include "pcie-designware.h"
 
 void qcom_pcie_common_set_16gt_eq_settings(struct dw_pcie *pci);
+void qcom_pcie_common_set_16gt_rx_margining_settings(struct dw_pcie *pci);
diff --git a/drivers/pci/controller/dwc/pcie-qcom-ep.c b/drivers/pci/controller/dwc/pcie-qcom-ep.c
index af83470216e8..5c220f2ecafe 100644
--- a/drivers/pci/controller/dwc/pcie-qcom-ep.c
+++ b/drivers/pci/controller/dwc/pcie-qcom-ep.c
@@ -487,8 +487,10 @@ static int qcom_pcie_perst_deassert(struct dw_pcie *pci)
 		goto err_disable_resources;
 	}
 
-	if (pcie_link_speed[pci->max_link_speed] == PCIE_SPEED_16_0GT)
+	if (pcie_link_speed[pci->max_link_speed] == PCIE_SPEED_16_0GT) {
 		qcom_pcie_common_set_16gt_eq_settings(pci);
+		qcom_pcie_common_set_16gt_rx_margining_settings(pci);
+	}
 
 	/*
 	 * The physical address of the MMIO region which is exposed as the BAR
diff --git a/drivers/pci/controller/dwc/pcie-qcom.c b/drivers/pci/controller/dwc/pcie-qcom.c
index 2742e82fdcb3..b0b1d8d34279 100644
--- a/drivers/pci/controller/dwc/pcie-qcom.c
+++ b/drivers/pci/controller/dwc/pcie-qcom.c
@@ -284,8 +284,10 @@ static int qcom_pcie_start_link(struct dw_pcie *pci)
 {
 	struct qcom_pcie *pcie = to_qcom_pcie(pci);
 
-	if (pcie_link_speed[pci->max_link_speed] == PCIE_SPEED_16_0GT)
+	if (pcie_link_speed[pci->max_link_speed] == PCIE_SPEED_16_0GT) {
 		qcom_pcie_common_set_16gt_eq_settings(pci);
+		qcom_pcie_common_set_16gt_rx_margining_settings(pci);
+	}
 
 	/* Enable Link Training state machine */
 	if (pcie->cfg->ops->ltssm_enable)

-- 
2.25.1

