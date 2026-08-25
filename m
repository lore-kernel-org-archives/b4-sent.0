From: George Moussalem <george.moussalem@outlook.com>
Date: Tue, 25 Aug 2026 16:37:28 +0400
Subject: [PATCH v3 11/12] arm64: dts: qcom: ipq5018: Add Super-Speed UNIPHY
 to USB node
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260825-ipq5018-usb3-v3-11-39be0955a6aa@outlook.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1787661450; l=880;
 i=george.moussalem@outlook.com; s=20250321; h=from:subject:message-id;
 bh=nVztOgvUA+UCMXgiAA8vKe6nVwfiycloNnuAVugC3Ac=;
 b=A85eEy0Q45TkeWiv8ekcGDPCXTButmyt7zaT2ZC2ASmwKckXMF16vG15NA5Lzn5L0Jbw/TfDs
 J0jBuxfN5JeDlJV9e5Bn2LeEzR8Mvrg4QbSrXL50YMl/r4119B7sv3K
X-Developer-Key: i=george.moussalem@outlook.com; a=ed25519;
 pk=/PuRTSI9iYiHwcc6Nrde8qF4ZDhJBlUgpHdhsIjnqIk=
X-Endpoint-Received: by B4 Relay for george.moussalem@outlook.com/20250321 with auth_id=364
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the USB3 UNIPHY to the USB controller node for USB3 support.
In addition, switch to the pipe clock supplied by the USB3 UNIPHY
instead of the UTMI clock.

Signed-off-by: George Moussalem <george.moussalem@outlook.com>
---
 arch/arm64/boot/dts/qcom/ipq5018.dtsi | 5 ++---
 1 file changed, 2 insertions(+), 3 deletions(-)

diff --git a/arch/arm64/boot/dts/qcom/ipq5018.dtsi b/arch/arm64/boot/dts/qcom/ipq5018.dtsi
index 7f730c2ab763..1f55b0ba5c9d 100644
--- a/arch/arm64/boot/dts/qcom/ipq5018.dtsi
+++ b/arch/arm64/boot/dts/qcom/ipq5018.dtsi
@@ -627,10 +627,9 @@ usb: usb@8a00000 {
 
 			resets = <&gcc GCC_USB0_BCR>;
 
-			phys = <&usbphy0>;
-			phy-names = "usb2-phy";
+			phys = <&usbphy0>, <&usbphy1>;
+			phy-names = "usb2-phy", "usb3-phy";
 
-			qcom,select-utmi-as-pipe-clk;
 			qcom,select-utmi-as-ref-clk;
 
 			tx-fifo-resize;

-- 
2.53.0

