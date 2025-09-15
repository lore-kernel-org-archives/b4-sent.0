From: George Moussalem <george.moussalem@outlook.com>
Date: Mon, 15 Sep 2025 13:24:18 +0400
Subject: [PATCH] arm64: dts: qcom: ipq5018: add QUP3 I2C node
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250915-ipq5018-i2c-v1-1-46bbf27396d6@outlook.com>
X-B4-Tracking: v=1; b=H4sIAEHbx2gC/x3MQQqAIBBA0avIrBNmBMu6SrSQGms2ZQoRiHdPW
 r7F/wUyJ+EMkyqQ+JEs19lAnYL18OfOWrZmMGgsjkRa4m2RnBazavQYPA29ceSgFTFxkPe/zUu
 tH1sLzpNdAAAA
X-Change-ID: 20250911-ipq5018-i2c-0a0fa1762818
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 Vandhiadevan Karunamoorthy <vkarunam@codeaurora.org>, 
 George Moussalem <george.moussalem@outlook.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1757928274; l=1420;
 i=george.moussalem@outlook.com; s=20250321; h=from:subject:message-id;
 bh=5AMg7/oGtHNBWL+11z9Q/HGGQ9F6ll9nuoBPaZhI9aM=;
 b=YRzjCtxRPYCTIZbfjE7Ch/iQgVk2FPQ2D3Z9XheAftOihKy/1/tmjGVVJNjCCP6dXt51fm4rq
 wtSUjXqnECrAN3FPi6I7N+IBTc6A+E6Q/wpYazdNwaMdyxGBj0tyK4f
X-Developer-Key: i=george.moussalem@outlook.com; a=ed25519;
 pk=/PuRTSI9iYiHwcc6Nrde8qF4ZDhJBlUgpHdhsIjnqIk=
X-Endpoint-Received: by B4 Relay for george.moussalem@outlook.com/20250321 with auth_id=364
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Vandhiadevan Karunamoorthy <vkarunam@codeaurora.org>

Add node to support I2C bus inside of IPQ5018.

Signed-off-by: Vandhiadevan Karunamoorthy <vkarunam@codeaurora.org>
Signed-off-by: George Moussalem <george.moussalem@outlook.com>
---
 arch/arm64/boot/dts/qcom/ipq5018.dtsi | 15 +++++++++++++++
 1 file changed, 15 insertions(+)

diff --git a/arch/arm64/boot/dts/qcom/ipq5018.dtsi b/arch/arm64/boot/dts/qcom/ipq5018.dtsi
index e88b52006566fd39c0690e6fb53be743eb56d11b..5ba33255659e0a83562bd42048c7152bef04f1cd 100644
--- a/arch/arm64/boot/dts/qcom/ipq5018.dtsi
+++ b/arch/arm64/boot/dts/qcom/ipq5018.dtsi
@@ -504,6 +504,21 @@ blsp1_spi1: spi@78b5000 {
 			status = "disabled";
 		};
 
+		blsp1_i2c3: i2c@78b7000 {
+			compatible = "qcom,i2c-qup-v2.2.1";
+			reg = <0x078b7000 0x600>;
+			#address-cells = <1>;
+			#size-cells = <0>;
+			interrupts = <GIC_SPI 97 IRQ_TYPE_LEVEL_HIGH>;
+			clocks = <&gcc GCC_BLSP1_QUP3_I2C_APPS_CLK>,
+				 <&gcc GCC_BLSP1_AHB_CLK>;
+			clock-names = "core", "iface";
+			clock-frequency = <400000>;
+			dmas = <&blsp_dma 9>, <&blsp_dma 8>;
+			dma-names = "tx", "rx";
+			status = "disabled";
+		};
+
 		qpic_bam: dma-controller@7984000 {
 			compatible = "qcom,bam-v1.7.4", "qcom,bam-v1.7.0";
 			reg = <0x07984000 0x1c000>;

---
base-commit: b0971d2008c644b9064d968d440fb9f44606d90c
change-id: 20250911-ipq5018-i2c-0a0fa1762818

Best regards,
-- 
George Moussalem <george.moussalem@outlook.com>

