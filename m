From: George Moussalem <george.moussalem@outlook.com>
Date: Tue, 08 Sep 2026 13:40:57 +0400
Subject: [PATCH v4 04/13] phy: qualcomm: qcom-uniphy-pcie-usb3-28lp: Drop
 unused phy_to_dw_phy macro
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260908-ipq5018-usb3-v4-4-b789702f0695@outlook.com>
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
 linux-usb@vger.kernel.org, Stanislaw Pal <kuncy7@gmail.com>, 
 George Moussalem <george.moussalem@outlook.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1788860513; l=847;
 i=george.moussalem@outlook.com; s=20250321; h=from:subject:message-id;
 bh=IZ/hjxmEdOnTJTDZazw9P78aJ5AEBePKGFMJqAXOe5s=;
 b=94b2fzvuiH7G5zZammgV57trIIoPK4mwZqfHv2tpEyLyAeIpxfo/xe/+DsS2EFQY4eRxD2v08
 ZWuehp9sx54DjPwk2XmsfBYVjKTaJMsL7x8hSrAFF2Qjl/52zzElgX5
X-Developer-Key: i=george.moussalem@outlook.com; a=ed25519;
 pk=/PuRTSI9iYiHwcc6Nrde8qF4ZDhJBlUgpHdhsIjnqIk=
X-Endpoint-Received: by B4 Relay for george.moussalem@outlook.com/20250321 with auth_id=364
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Remove the unused phy_to_dw_phy() helper macro which is not referenced
anywhere in the driver.

Tested-by: Stanislaw Pal <kuncy7@gmail.com>
Signed-off-by: George Moussalem <george.moussalem@outlook.com>
---
 drivers/phy/qualcomm/phy-qcom-uniphy-pcie-usb3-28lp.c | 2 --
 1 file changed, 2 deletions(-)

diff --git a/drivers/phy/qualcomm/phy-qcom-uniphy-pcie-usb3-28lp.c b/drivers/phy/qualcomm/phy-qcom-uniphy-pcie-usb3-28lp.c
index b9ca6c1c177b..0256183fbcbd 100644
--- a/drivers/phy/qualcomm/phy-qcom-uniphy-pcie-usb3-28lp.c
+++ b/drivers/phy/qualcomm/phy-qcom-uniphy-pcie-usb3-28lp.c
@@ -72,8 +72,6 @@ struct qcom_uniphy {
 	int lanes;
 };
 
-#define phy_to_dw_phy(x)	container_of((x), struct qcom_uniphy, phy)
-
 static const struct qcom_uniphy_regs ipq5018_pcie_regs[] = {
 	{
 		.offset = SSCG_CTRL_REG_4,

-- 
2.53.0

