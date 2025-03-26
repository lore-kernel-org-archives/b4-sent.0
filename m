From: George Moussalem <george.moussalem@outlook.com>
Date: Wed, 26 Mar 2025 12:10:56 +0400
Subject: [PATCH v7 2/6] phy: qualcomm: qcom-uniphy-pcie 28LP add support
 for IPQ5018
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250326-ipq5018-pcie-v7-2-e1828fef06c9@outlook.com>
References: <20250326-ipq5018-pcie-v7-0-e1828fef06c9@outlook.com>
In-Reply-To: <20250326-ipq5018-pcie-v7-0-e1828fef06c9@outlook.com>
To: Vinod Koul <vkoul@kernel.org>, 
 Kishon Vijay Abraham I <kishon@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Nitheesh Sekar <quic_nsekar@quicinc.com>, 
 Varadarajan Narayanan <quic_varada@quicinc.com>, 
 Bjorn Helgaas <bhelgaas@google.com>, 
 Lorenzo Pieralisi <lpieralisi@kernel.org>, 
 =?utf-8?q?Krzysztof_Wilczy=C5=84ski?= <kw@linux.com>, 
 Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, 
 Praveenkumar I <quic_ipkumar@quicinc.com>
Cc: linux-arm-msm@vger.kernel.org, linux-phy@lists.infradead.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-pci@vger.kernel.org, George Moussalem <george.moussalem@outlook.com>, 
 20250317100029.881286-1-quic_varada@quicinc.com, 
 20250317100029.881286-2-quic_varada@quicinc.com, 
 Sricharan Ramabadhran <quic_srichara@quicinc.com>, 
 Dmitry Baryshkov <dmitry.baryshkov@oss.qualcomm.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1742976660; l=2535;
 i=george.moussalem@outlook.com; s=20250321; h=from:subject:message-id;
 bh=kYH6vXN/WlVTNUTrZPgBDmJJfb+EoAkdo/0WziGGijo=;
 b=Ma/+ghqQ1vbu85eRfMhm40tdOdvQ/+8Gmo/1EOCdGV6tE0sBXPzZjL17x7NHV+9e7JNQrsgmc
 IovVQfcOn6iAfGAOk7O8jjYSFXn5Dms/U43reXLfSvivjtgABeJ/mZj
X-Developer-Key: i=george.moussalem@outlook.com; a=ed25519;
 pk=/PuRTSI9iYiHwcc6Nrde8qF4ZDhJBlUgpHdhsIjnqIk=
X-Endpoint-Received: by B4 Relay for george.moussalem@outlook.com/20250321 with auth_id=364
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Nitheesh Sekar <quic_nsekar@quicinc.com>

The Qualcomm UNIPHY PCIe PHY 28LP is found on both IPQ5332 and IPQ5018.
Adding the PHY init sequence, pipe clock rate, and compatible for IPQ5018.

Signed-off-by: Nitheesh Sekar <quic_nsekar@quicinc.com>
Signed-off-by: Sricharan Ramabadhran <quic_srichara@quicinc.com>
Reviewed-by: Dmitry Baryshkov <dmitry.baryshkov@oss.qualcomm.com>
Signed-off-by: George Moussalem <george.moussalem@outlook.com>
---
 drivers/phy/qualcomm/phy-qcom-uniphy-pcie-28lp.c | 45 ++++++++++++++++++++++++
 1 file changed, 45 insertions(+)

diff --git a/drivers/phy/qualcomm/phy-qcom-uniphy-pcie-28lp.c b/drivers/phy/qualcomm/phy-qcom-uniphy-pcie-28lp.c
index c8b2a3818880ea3bf7bee67f5c1c075c1ac650e4..324c0a5d658e43e03597b285e761d3604761508e 100644
--- a/drivers/phy/qualcomm/phy-qcom-uniphy-pcie-28lp.c
+++ b/drivers/phy/qualcomm/phy-qcom-uniphy-pcie-28lp.c
@@ -75,6 +75,40 @@ struct qcom_uniphy_pcie {
 
 #define phy_to_dw_phy(x)	container_of((x), struct qca_uni_pcie_phy, phy)
 
+static const struct qcom_uniphy_pcie_regs ipq5018_regs[] = {
+	{
+		.offset = SSCG_CTRL_REG_4,
+		.val = 0x1cb9,
+	}, {
+		.offset = SSCG_CTRL_REG_5,
+		.val = 0x023a,
+	}, {
+		.offset = SSCG_CTRL_REG_3,
+		.val = 0xd360,
+	}, {
+		.offset = SSCG_CTRL_REG_1,
+		.val = 0x1,
+	}, {
+		.offset = SSCG_CTRL_REG_2,
+		.val = 0xeb,
+	}, {
+		.offset = CDR_CTRL_REG_4,
+		.val = 0x3f9,
+	}, {
+		.offset = CDR_CTRL_REG_5,
+		.val = 0x1c9,
+	}, {
+		.offset = CDR_CTRL_REG_2,
+		.val = 0x419,
+	}, {
+		.offset = CDR_CTRL_REG_1,
+		.val = 0x200,
+	}, {
+		.offset = PCS_INTERNAL_CONTROL_2,
+		.val = 0xf101,
+	},
+};
+
 static const struct qcom_uniphy_pcie_regs ipq5332_regs[] = {
 	{
 		.offset = PHY_CFG_PLLCFG,
@@ -88,6 +122,14 @@ static const struct qcom_uniphy_pcie_regs ipq5332_regs[] = {
 	},
 };
 
+static const struct qcom_uniphy_pcie_data ipq5018_data = {
+	.lane_offset	= 0x800,
+	.phy_type	= PHY_TYPE_PCIE_GEN2,
+	.init_seq	= ipq5018_regs,
+	.init_seq_num	= ARRAY_SIZE(ipq5018_regs),
+	.pipe_clk_rate	= 125 * MEGA,
+};
+
 static const struct qcom_uniphy_pcie_data ipq5332_data = {
 	.lane_offset	= 0x800,
 	.phy_type	= PHY_TYPE_PCIE_GEN3,
@@ -212,6 +254,9 @@ static inline int phy_pipe_clk_register(struct qcom_uniphy_pcie *phy, int id)
 
 static const struct of_device_id qcom_uniphy_pcie_id_table[] = {
 	{
+		.compatible = "qcom,ipq5018-uniphy-pcie-phy",
+		.data = &ipq5018_data,
+	}, {
 		.compatible = "qcom,ipq5332-uniphy-pcie-phy",
 		.data = &ipq5332_data,
 	}, {

-- 
2.49.0

