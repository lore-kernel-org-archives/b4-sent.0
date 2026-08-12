From: George Moussalem <george.moussalem@outlook.com>
Date: Wed, 12 Aug 2026 13:34:47 +0400
Subject: [PATCH v2 12/14] arm64: dts: qcom: ipq5332: Enable USB Super-Speed
 PHY
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260812-ipq5018-usb3-v2-12-8f355d7ff0ef@outlook.com>
References: <20260812-ipq5018-usb3-v2-0-8f355d7ff0ef@outlook.com>
In-Reply-To: <20260812-ipq5018-usb3-v2-0-8f355d7ff0ef@outlook.com>
To: Vinod Koul <vkoul@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Praveenkumar I <quic_ipkumar@quicinc.com>, 
 Varadarajan Narayanan <quic_varada@quicinc.com>, 
 Philipp Zabel <p.zabel@pengutronix.de>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Wesley Cheng <quic_wcheng@quicinc.com>
Cc: linux-arm-msm@vger.kernel.org, linux-phy@lists.infradead.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-usb@vger.kernel.org, George Moussalem <george.moussalem@outlook.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1786527282; l=1218;
 i=george.moussalem@outlook.com; s=20250321; h=from:subject:message-id;
 bh=4QodOwLvZBFpQJh/rbVs7oulaifWDwERoBYMxDOywh0=;
 b=Or4wpv3uHdshJMeNMhiS6sXik5KdX92OhBUuazDrm9R/jcwgLPY3HZleHKz8IeA5LRLeojaFu
 VS/ybAQtauRAZF9bPyyZUdF/Ff+wsR4u0faB7W9jM25vJ3Od2w/Z6jO
X-Developer-Key: i=george.moussalem@outlook.com; a=ed25519;
 pk=/PuRTSI9iYiHwcc6Nrde8qF4ZDhJBlUgpHdhsIjnqIk=
X-Endpoint-Received: by B4 Relay for george.moussalem@outlook.com/20250321 with auth_id=364
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Praveenkumar I <quic_ipkumar@quicinc.com>

Enable USB Super-Speed PHY support. The PCIe and USB3 PHYs share the
same MMIO address space, so override the compatible string to use the
USB3 PHY driver instead of the PCIe PHY driver and set the required
properties accordingly.

Signed-off-by: Praveenkumar I <quic_ipkumar@quicinc.com>
Signed-off-by: George Moussalem <george.moussalem@outlook.com>
---
 arch/arm64/boot/dts/qcom/ipq5332-rdp468.dts | 19 +++++++++++++++++++
 1 file changed, 19 insertions(+)

diff --git a/arch/arm64/boot/dts/qcom/ipq5332-rdp468.dts b/arch/arm64/boot/dts/qcom/ipq5332-rdp468.dts
index 25a70cd884c0..164f9a9a6c75 100644
--- a/arch/arm64/boot/dts/qcom/ipq5332-rdp468.dts
+++ b/arch/arm64/boot/dts/qcom/ipq5332-rdp468.dts
@@ -100,3 +100,22 @@ &usbphy0 {
 
 	status = "okay";
 };
+
+/* this combo PHY supports PCIe and USB3 */
+&pcie0_phy {
+	compatible = "qcom,ipq5018-uniphy-usb-ss-phy";
+
+	clocks = <&gcc GCC_PCIE3X1_PHY_AHB_CLK>,
+		 <&gcc GCC_USB0_PHY_CFG_AHB_CLK>,
+		 <&gcc GCC_USB0_PIPE_CLK>;
+
+	resets =  <&gcc GCC_USB0_PHY_BCR>;
+
+	qcom,phy-usb-mux-sel = <&tcsr 0x10540>;
+
+	vdd-supply = <&regulator_fixed_5p0>;
+
+	/delete-property/ num-lanes;
+
+	status = "okay";
+};

-- 
2.53.0

