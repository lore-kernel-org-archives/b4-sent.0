From: George Moussalem <george.moussalem@outlook.com>
Date: Tue, 08 Sep 2026 13:41:00 +0400
Subject: [PATCH v4 07/13] phy: qualcomm: qcom-uniphy-pcie-usb3-28lp: Assert
 reset on clock enable failure
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260908-ipq5018-usb3-v4-7-b789702f0695@outlook.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1788860513; l=945;
 i=george.moussalem@outlook.com; s=20250321; h=from:subject:message-id;
 bh=Xt9077phHCqVPqMVNZVzBLq0pYjZ3VnSS927ST8gSWc=;
 b=AIvUePJfwwQReYU60ZhpE5aFQZ4csdMBGKGnxFwBKh1Lt4PYR1ueo4LZpPFkx4/d3/w64mEWA
 Oza4apZiP0TA+sqkwp7OeyVBpJW+NfuQMyYtbemzANyG+LTdKMQ9qR3
X-Developer-Key: i=george.moussalem@outlook.com; a=ed25519;
 pk=/PuRTSI9iYiHwcc6Nrde8qF4ZDhJBlUgpHdhsIjnqIk=
X-Endpoint-Received: by B4 Relay for george.moussalem@outlook.com/20250321 with auth_id=364
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When the PHY fails the enable clocks, it leaves the PHY out of reset.
Fix this by asserting the reset before returning the error.

Tested-by: Stanislaw Pal <kuncy7@gmail.com>
Signed-off-by: George Moussalem <george.moussalem@outlook.com>
---
 drivers/phy/qualcomm/phy-qcom-uniphy-pcie-usb3-28lp.c | 1 +
 1 file changed, 1 insertion(+)

diff --git a/drivers/phy/qualcomm/phy-qcom-uniphy-pcie-usb3-28lp.c b/drivers/phy/qualcomm/phy-qcom-uniphy-pcie-usb3-28lp.c
index 0a50eb44c0ce..15b17044fde3 100644
--- a/drivers/phy/qualcomm/phy-qcom-uniphy-pcie-usb3-28lp.c
+++ b/drivers/phy/qualcomm/phy-qcom-uniphy-pcie-usb3-28lp.c
@@ -164,6 +164,7 @@ static int qcom_uniphy_pcie_power_on(struct phy *x)
 	ret = clk_bulk_prepare_enable(phy->num_clks, phy->clks);
 	if (ret) {
 		dev_err(phy->dev, "clk prepare and enable failed %d\n", ret);
+		reset_control_bulk_assert(phy->num_resets, phy->resets);
 		return ret;
 	}
 

-- 
2.53.0

