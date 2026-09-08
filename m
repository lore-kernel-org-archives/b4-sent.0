From: George Moussalem <george.moussalem@outlook.com>
Date: Tue, 08 Sep 2026 13:40:58 +0400
Subject: [PATCH v4 05/13] phy: qualcomm: qcom-uniphy-pcie-usb3-28lp:
 Refactor init regs table definitions
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260908-ipq5018-usb3-v4-5-b789702f0695@outlook.com>
References: <20260908-ipq5018-usb3-v4-0-b789702f0695@outlook.com>
In-Reply-To: <20260908-ipq5018-usb3-v4-0-b789702f0695@outlook.com>
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
 Manivannan Sadhasivam <mani@kernel.org>, 
 Varadarajan Narayanan <quic_varada@quicinc.com>
Cc: linux-arm-msm@vger.kernel.org, linux-phy@lists.infradead.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-usb@vger.kernel.org, Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>, 
 Stanislaw Pal <kuncy7@gmail.com>, 
 George Moussalem <george.moussalem@outlook.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1788860513; l=2508;
 i=george.moussalem@outlook.com; s=20250321; h=from:subject:message-id;
 bh=j5eDBU1/M/VWuaZnnm/rYsHj5E3f2ArUUkz0LzF/aZY=;
 b=EsNjOdFWxRh2tznRzAS6gw4JLaSQrKdA36/aIXLc4K5DTg5/I8/PQbYw+TZY4zp84nmNiE1sl
 xzsDXRNyIw8AZ+dls5TglpJU8c+Ge4pwXmush/Jznv/uNBAMCNWSuDJ
X-Developer-Key: i=george.moussalem@outlook.com; a=ed25519;
 pk=/PuRTSI9iYiHwcc6Nrde8qF4ZDhJBlUgpHdhsIjnqIk=
X-Endpoint-Received: by B4 Relay for george.moussalem@outlook.com/20250321 with auth_id=364
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Refactor the IPQ5018/IPQ5332 UNIPHY PCIe init data by introducing a
helper macro for register/value entries and converting open-coded struct
initializers to the compact form.

No functional change intended.

Reviewed-by: Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>
Tested-by: Stanislaw Pal <kuncy7@gmail.com>
Signed-off-by: George Moussalem <george.moussalem@outlook.com>
---
 .../phy/qualcomm/phy-qcom-uniphy-pcie-usb3-28lp.c  | 60 +++++++---------------
 1 file changed, 19 insertions(+), 41 deletions(-)

diff --git a/drivers/phy/qualcomm/phy-qcom-uniphy-pcie-usb3-28lp.c b/drivers/phy/qualcomm/phy-qcom-uniphy-pcie-usb3-28lp.c
index 0256183fbcbd..c12de5549652 100644
--- a/drivers/phy/qualcomm/phy-qcom-uniphy-pcie-usb3-28lp.c
+++ b/drivers/phy/qualcomm/phy-qcom-uniphy-pcie-usb3-28lp.c
@@ -72,51 +72,29 @@ struct qcom_uniphy {
 	int lanes;
 };
 
+#define PHY_INIT_CFG(o, v)		\
+	{				\
+		.offset = o,		\
+		.val = v,		\
+	}
+
 static const struct qcom_uniphy_regs ipq5018_pcie_regs[] = {
-	{
-		.offset = SSCG_CTRL_REG_4,
-		.val = 0x1cb9,
-	}, {
-		.offset = SSCG_CTRL_REG_5,
-		.val = 0x023a,
-	}, {
-		.offset = SSCG_CTRL_REG_3,
-		.val = 0xd360,
-	}, {
-		.offset = SSCG_CTRL_REG_1,
-		.val = 0x1,
-	}, {
-		.offset = SSCG_CTRL_REG_2,
-		.val = 0xeb,
-	}, {
-		.offset = CDR_CTRL_REG_4,
-		.val = 0x3f9,
-	}, {
-		.offset = CDR_CTRL_REG_5,
-		.val = 0x1c9,
-	}, {
-		.offset = CDR_CTRL_REG_2,
-		.val = 0x419,
-	}, {
-		.offset = CDR_CTRL_REG_1,
-		.val = 0x200,
-	}, {
-		.offset = PCS_INTERNAL_CONTROL_2,
-		.val = 0xf101,
-	},
+	PHY_INIT_CFG(SSCG_CTRL_REG_4, 0x1cb9),
+	PHY_INIT_CFG(SSCG_CTRL_REG_5, 0x023a),
+	PHY_INIT_CFG(SSCG_CTRL_REG_3, 0xd360),
+	PHY_INIT_CFG(SSCG_CTRL_REG_1, 0x1),
+	PHY_INIT_CFG(SSCG_CTRL_REG_2, 0xeb),
+	PHY_INIT_CFG(CDR_CTRL_REG_4, 0x3f9),
+	PHY_INIT_CFG(CDR_CTRL_REG_5, 0x1c9),
+	PHY_INIT_CFG(CDR_CTRL_REG_2, 0x419),
+	PHY_INIT_CFG(CDR_CTRL_REG_1, 0x200),
+	PHY_INIT_CFG(PCS_INTERNAL_CONTROL_2, 0xf101),
 };
 
 static const struct qcom_uniphy_regs ipq5332_pcie_regs[] = {
-	{
-		.offset = PHY_CFG_PLLCFG,
-		.val = 0x30,
-	}, {
-		.offset = PHY_CFG_EIOS_DTCT_REG,
-		.val = 0x53ef,
-	}, {
-		.offset = PHY_CFG_GEN3_ALIGN_HOLDOFF_TIME,
-		.val = 0xcf,
-	},
+	PHY_INIT_CFG(PHY_CFG_PLLCFG, 0x30),
+	PHY_INIT_CFG(PHY_CFG_EIOS_DTCT_REG, 0x53ef),
+	PHY_INIT_CFG(PHY_CFG_GEN3_ALIGN_HOLDOFF_TIME, 0xcf),
 };
 
 static const struct qcom_uniphy_data ipq5018_pcie_data = {

-- 
2.53.0

