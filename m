From: George Moussalem <george.moussalem@outlook.com>
Date: Wed, 12 Aug 2026 13:34:43 +0400
Subject: [PATCH v2 08/14] arm64: dts: qcom: ipq5332: Add clocks required
 for USB3 support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260812-ipq5018-usb3-v2-8-8f355d7ff0ef@outlook.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1786527282; l=984;
 i=george.moussalem@outlook.com; s=20250321; h=from:subject:message-id;
 bh=ahJs4DPyNLGX7SXzT58shCgWpJw7k4x2FzR8MZ0ny3A=;
 b=82/coOkgY6ouZWe9JkwUpLQLqRtEKxKuPfBSkHsCW6eCDPNKBPWUnE+Mk33E0s3h76cguttEL
 9vSwe7n1lf5C7V/e2dH2O988bbTC4MvaUAwgRcW1dQbgJqau0W4l9V0
X-Developer-Key: i=george.moussalem@outlook.com; a=ed25519;
 pk=/PuRTSI9iYiHwcc6Nrde8qF4ZDhJBlUgpHdhsIjnqIk=
X-Endpoint-Received: by B4 Relay for george.moussalem@outlook.com/20250321 with auth_id=364
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Praveenkumar I <quic_ipkumar@quicinc.com>

Add aux and lfps clocks to USB controller node for Super-Speed support.

Signed-off-by: Praveenkumar I <quic_ipkumar@quicinc.com>
Signed-off-by: George Moussalem <george.moussalem@outlook.com>
---
 arch/arm64/boot/dts/qcom/ipq5332.dtsi | 8 ++++++--
 1 file changed, 6 insertions(+), 2 deletions(-)

diff --git a/arch/arm64/boot/dts/qcom/ipq5332.dtsi b/arch/arm64/boot/dts/qcom/ipq5332.dtsi
index 83d0377455da..664586979ec4 100644
--- a/arch/arm64/boot/dts/qcom/ipq5332.dtsi
+++ b/arch/arm64/boot/dts/qcom/ipq5332.dtsi
@@ -499,10 +499,14 @@ usb: usb@8a00000 {
 
 			clocks = <&gcc GCC_USB0_MASTER_CLK>,
 				 <&gcc GCC_USB0_SLEEP_CLK>,
-				 <&gcc GCC_USB0_MOCK_UTMI_CLK>;
+				 <&gcc GCC_USB0_MOCK_UTMI_CLK>,
+				 <&gcc GCC_USB0_AUX_CLK>,
+				 <&gcc GCC_USB0_LFPS_CLK>;
 			clock-names = "core",
 				      "sleep",
-				      "mock_utmi";
+				      "mock_utmi",
+				      "aux",
+				      "lfps";
 
 			resets = <&gcc GCC_USB_BCR>;
 

-- 
2.53.0

