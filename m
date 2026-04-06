From: George Moussalem <george.moussalem@outlook.com>
Date: Mon, 06 Apr 2026 22:24:42 +0200
Subject: [PATCH v21 5/6] arm64: dts: qcom: ipq5332: add pwm node
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260406-ipq-pwm-v21-5-6ed1e868e4c2@outlook.com>
References: <20260406-ipq-pwm-v21-0-6ed1e868e4c2@outlook.com>
In-Reply-To: <20260406-ipq-pwm-v21-0-6ed1e868e4c2@outlook.com>
To: =?utf-8?q?Uwe_Kleine-K=C3=B6nig?= <ukleinek@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, linux-pwm@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 George Moussalem <george.moussalem@outlook.com>, 
 Dmitry Baryshkov <dmitry.baryshkov@oss.qualcomm.com>, 
 Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>
X-Mailer: b4 0.15.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1775507135; l=1258;
 i=george.moussalem@outlook.com; s=20260406; h=from:subject:message-id;
 bh=wArkqHV7Q7hOp/b7t2Csz+B/hx/JQeURK4X1hAhc6/s=;
 b=+btGXL0ph+olveYvqptYbxqv2iABShV57vZ6llT43p64+KvU0n4iSNCOPVrsIJ6knSOyLa9Zo
 SjDOIbJVvLYD7lvkfHRrfdzgdg1CObeFdfAF3DtvoE+fMV0t6Frpblw
X-Developer-Key: i=george.moussalem@outlook.com; a=ed25519;
 pk=uqspem3ahtBvPEBuxVbyyXT/0Vp3JNb/mo1EPbmBzWg=
X-Endpoint-Received: by B4 Relay for george.moussalem@outlook.com/20260406 with auth_id=722
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Describe the PWM block on IPQ5332.

Although PWM is in the TCSR area, make pwm its own node as simple-mfd
has been removed from the bindings and as such hardware components
should have its own node.

Reviewed-by: Dmitry Baryshkov <dmitry.baryshkov@oss.qualcomm.com>
Reviewed-by: Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>
Signed-off-by: George Moussalem <george.moussalem@outlook.com>
---
 arch/arm64/boot/dts/qcom/ipq5332.dtsi | 10 ++++++++++
 1 file changed, 10 insertions(+)

diff --git a/arch/arm64/boot/dts/qcom/ipq5332.dtsi b/arch/arm64/boot/dts/qcom/ipq5332.dtsi
index e227730d99a6..27504b7cfe9e 100644
--- a/arch/arm64/boot/dts/qcom/ipq5332.dtsi
+++ b/arch/arm64/boot/dts/qcom/ipq5332.dtsi
@@ -334,6 +334,16 @@ tcsr: syscon@1937000 {
 			reg = <0x01937000 0x21000>;
 		};
 
+		pwm: pwm@1941010 {
+			compatible = "qcom,ipq5332-pwm", "qcom,ipq6018-pwm";
+			reg = <0x01941010 0x20>;
+			clocks = <&gcc GCC_ADSS_PWM_CLK>;
+			assigned-clocks = <&gcc GCC_ADSS_PWM_CLK>;
+			assigned-clock-rates = <100000000>;
+			#pwm-cells = <3>;
+			status = "disabled";
+		};
+
 		sdhc: mmc@7804000 {
 			compatible = "qcom,ipq5332-sdhci", "qcom,sdhci-msm-v5";
 			reg = <0x07804000 0x1000>, <0x07805000 0x1000>;

-- 
2.39.5

