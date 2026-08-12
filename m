From: George Moussalem <george.moussalem@outlook.com>
Date: Wed, 12 Aug 2026 13:34:46 +0400
Subject: [PATCH v2 11/14] arm64: dts: qcom: ipq5018: Add Super-Speed UNIPHY
 to USB node
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260812-ipq5018-usb3-v2-11-8f355d7ff0ef@outlook.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1786527282; l=865;
 i=george.moussalem@outlook.com; s=20250321; h=from:subject:message-id;
 bh=8bhPK8flz4g64F9hoc1dqcAmebxhDioRZihPcA2zzas=;
 b=iOasZLYsfLMSMhH9mM8vLaYok33PTvlCo51GrOdO8jsqdez68kqQWKaAJxpHPR/pO1sskcx58
 mnRboKr4eYSBm4XSpjZIl4xKcxLDwhOeFn4znV2GDxVVVaISZOc2vT1
X-Developer-Key: i=george.moussalem@outlook.com; a=ed25519;
 pk=/PuRTSI9iYiHwcc6Nrde8qF4ZDhJBlUgpHdhsIjnqIk=
X-Endpoint-Received: by B4 Relay for george.moussalem@outlook.com/20250321 with auth_id=364
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the USB3 UNIPHY node to the USB controller node.
In addition, switch to the pipe clock supplied by the USB3 UNIPHY
instead of the UTMI clock.

Signed-off-by: George Moussalem <george.moussalem@outlook.com>
---
 arch/arm64/boot/dts/qcom/ipq5018.dtsi | 6 ++----
 1 file changed, 2 insertions(+), 4 deletions(-)

diff --git a/arch/arm64/boot/dts/qcom/ipq5018.dtsi b/arch/arm64/boot/dts/qcom/ipq5018.dtsi
index c98889a7c26c..01b8181ffa40 100644
--- a/arch/arm64/boot/dts/qcom/ipq5018.dtsi
+++ b/arch/arm64/boot/dts/qcom/ipq5018.dtsi
@@ -631,10 +631,8 @@ usb: usb@8a00000 {
 
 			resets = <&gcc GCC_USB0_BCR>;
 
-			phys = <&usbphy0>;
-			phy-names = "usb2-phy";
-
-			qcom,select-utmi-as-pipe-clk;
+			phys = <&usbphy0>, <&usbphy1>;
+			phy-names = "usb2-phy", "usb3-phy";
 
 			tx-fifo-resize;
 			snps,is-utmi-l1-suspend;

-- 
2.53.0

