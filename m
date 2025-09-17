From: George Moussalem <george.moussalem@outlook.com>
Date: Wed, 17 Sep 2025 15:49:00 +0400
Subject: [PATCH] arm64: dts: qcom: ipq5018: add QUP1 UART2 node
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250917-ipq5018-uart2-v1-1-f8680bbf947f@outlook.com>
X-B4-Tracking: v=1; b=H4sIACugymgC/x3MQQqAIBBA0avErBNGKdSuEi3EppqNmVYE0t2Tl
 m/xf4FMiSnD0BRIdHPmPVTItgG/ubCS4LkaFKoerdSC49GjNOJy6VTCWtsZRYhee6hNTLTw8//
 G6X0/WLnqal8AAAA=
X-Change-ID: 20250917-ipq5018-uart2-999482e00c7c
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 Manikanta Mylavarapu <quic_mmanikan@quicinc.com>, 
 George Moussalem <george.moussalem@outlook.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1758109754; l=1271;
 i=george.moussalem@outlook.com; s=20250321; h=from:subject:message-id;
 bh=HM/nI43DAlY/zjakfQ1WPfyIyi8Yd5G24Lox3W+bASA=;
 b=tSA+wVVKSl7EQVIcar1wFpLWcYt4BMzrg8snAh1odR53zMJiIUMHLsb+W8lUSw7iKwSczqR2y
 BNZTG48ItJxDzNo5VATpWWHiuOBBvnjpKsG3jmVzkgh+zt+wQhmOEmM
X-Developer-Key: i=george.moussalem@outlook.com; a=ed25519;
 pk=/PuRTSI9iYiHwcc6Nrde8qF4ZDhJBlUgpHdhsIjnqIk=
X-Endpoint-Received: by B4 Relay for george.moussalem@outlook.com/20250321 with auth_id=364
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Manikanta Mylavarapu <quic_mmanikan@quicinc.com>

Add node to support the second UART node controller in IPQ5018.

Signed-off-by: Manikanta Mylavarapu <quic_mmanikan@quicinc.com>
Signed-off-by: George Moussalem <george.moussalem@outlook.com>
---
 arch/arm64/boot/dts/qcom/ipq5018.dtsi | 10 ++++++++++
 1 file changed, 10 insertions(+)

diff --git a/arch/arm64/boot/dts/qcom/ipq5018.dtsi b/arch/arm64/boot/dts/qcom/ipq5018.dtsi
index e88b52006566fd39c0690e6fb53be743eb56d11b..52840eb00a262a05fe2e7cbe5b77c47ff5937222 100644
--- a/arch/arm64/boot/dts/qcom/ipq5018.dtsi
+++ b/arch/arm64/boot/dts/qcom/ipq5018.dtsi
@@ -490,6 +490,16 @@ blsp1_uart1: serial@78af000 {
 			status = "disabled";
 		};
 
+		blsp1_uart2: serial@78b0000 {
+			compatible = "qcom,msm-uartdm-v1.4", "qcom,msm-uartdm";
+			reg = <0x078b0000 0x200>;
+			interrupts = <GIC_SPI 108 IRQ_TYPE_LEVEL_HIGH>;
+			clocks = <&gcc GCC_BLSP1_UART2_APPS_CLK>,
+				 <&gcc GCC_BLSP1_AHB_CLK>;
+			clock-names = "core", "iface";
+			status = "disabled";
+		};
+
 		blsp1_spi1: spi@78b5000 {
 			compatible = "qcom,spi-qup-v2.2.1";
 			#address-cells = <1>;

---
base-commit: 05af764719214d6568adb55c8749dec295228da8
change-id: 20250917-ipq5018-uart2-999482e00c7c

Best regards,
-- 
George Moussalem <george.moussalem@outlook.com>

