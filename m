From: George Moussalem <george.moussalem@outlook.com>
Date: Thu, 09 Jul 2026 13:18:31 +0400
Subject: [PATCH v5 5/6] arm64: dts: qcom: ipq5018: add node required for
 Bluetooth support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260709-ipq5018-bluetooth-v5-5-e476c41f03b8@outlook.com>
References: <20260709-ipq5018-bluetooth-v5-0-e476c41f03b8@outlook.com>
In-Reply-To: <20260709-ipq5018-bluetooth-v5-0-e476c41f03b8@outlook.com>
To: Bartosz Golaszewski <brgl@kernel.org>, 
 Marcel Holtmann <marcel@holtmann.org>, 
 Luiz Augusto von Dentz <luiz.dentz@gmail.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, 
 Philipp Zabel <p.zabel@pengutronix.de>
Cc: linux-arm-msm@vger.kernel.org, linux-bluetooth@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 George Moussalem <george.moussalem@outlook.com>, 
 Bartosz Golaszewski <bartosz.golaszewski@oss.qualcomm.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1783588713; l=1135;
 i=george.moussalem@outlook.com; s=20250321; h=from:subject:message-id;
 bh=ymJvkEJnDShOUP8UxN5TyZg3+NjK0WZUomZnujMqESc=;
 b=RYY8skanotxliOrV7roe0ikM4OLojv53aWcRD6phI/hhClq9Vonk38JCmUCOBpbH0Uwfhe3LT
 liF6nLYmr4xDMXkyIZ5aIbG3FJfkIJLm+qzVdNR8dXc4y4CmyeQtz1X
X-Developer-Key: i=george.moussalem@outlook.com; a=ed25519;
 pk=/PuRTSI9iYiHwcc6Nrde8qF4ZDhJBlUgpHdhsIjnqIk=
X-Endpoint-Received: by B4 Relay for george.moussalem@outlook.com/20250321 with auth_id=364
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add node to enable Bluetooth support on the IPQ5018 platform.

Reviewed-by: Bartosz Golaszewski <bartosz.golaszewski@oss.qualcomm.com>
Signed-off-by: George Moussalem <george.moussalem@outlook.com>
---
 arch/arm64/boot/dts/qcom/ipq5018.dtsi | 16 ++++++++++++++++
 1 file changed, 16 insertions(+)

diff --git a/arch/arm64/boot/dts/qcom/ipq5018.dtsi b/arch/arm64/boot/dts/qcom/ipq5018.dtsi
index 6f8004a22a1f..8c252fa3ff5b 100644
--- a/arch/arm64/boot/dts/qcom/ipq5018.dtsi
+++ b/arch/arm64/boot/dts/qcom/ipq5018.dtsi
@@ -453,6 +453,22 @@ tcsr: syscon@1937000 {
 			reg = <0x01937000 0x21000>;
 		};
 
+		bluetooth: bluetooth@7000000 {
+			compatible = "qcom,ipq5018-bt";
+			reg = <0x07000000 0x58000>;
+
+			firmware-name = "qca/bt_fw_patch.mbn";
+
+			clocks = <&gcc GCC_BTSS_LPO_CLK>;
+			clock-names = "lpo";
+			resets = <&gcc GCC_BTSS_BCR>;
+
+			qcom,ipc = <&apcs_glb 8 23>;
+			interrupts = <GIC_SPI 162 IRQ_TYPE_EDGE_RISING>;
+
+			status = "disabled";
+		};
+
 		sdhc_1: mmc@7804000 {
 			compatible = "qcom,ipq5018-sdhci", "qcom,sdhci-msm-v5";
 			reg = <0x7804000 0x1000>;

-- 
2.53.0

