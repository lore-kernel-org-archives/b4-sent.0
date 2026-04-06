From: Alexandre Messier <alex@me.ssier.org>
Date: Mon, 06 Apr 2026 01:17:00 -0400
Subject: [PATCH v2 4/4] ARM: dts: qcom: msm8974pro-htc-m8: add touchscreen
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260406-m8-dts-additions-v2-4-c4c4bd50af48@me.ssier.org>
References: <20260406-m8-dts-additions-v2-0-c4c4bd50af48@me.ssier.org>
In-Reply-To: <20260406-m8-dts-additions-v2-0-c4c4bd50af48@me.ssier.org>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: Luca Weiss <luca@lucaweiss.eu>, linux-arm-kernel@lists.infradead.org, 
 linux-arm-msm@vger.kernel.org, ~postmarketos/upstreaming@lists.sr.ht, 
 phone-devel@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Alexandre Messier <alex@me.ssier.org>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1775452618; l=1510;
 i=alex@me.ssier.org; s=20240603; h=from:subject:message-id;
 bh=A5B+vqZ179ZaDPlA3FT17LpryB1RKmK0Cto2Yde+kzY=;
 b=XFv28L9PjBz5gSbfK4yWi2aPoBQ1/kpYHiDEUwKx6u1z4TCJiy+e/YO806jiJrDus5Qvnkm1R
 s4N3BEMGiUtAYb1RCQKiqyBKCrtCw7pDynzRajt3cZUG4kNZgNIpTOe
X-Developer-Key: i=alex@me.ssier.org; a=ed25519;
 pk=JjRqVfLd2XLHX2QTylKoROw346/1LOyZJX0q6cfnrKw=
X-Endpoint-Received: by B4 Relay for alex@me.ssier.org/20240603 with auth_id=168
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the touchscreen device node for the HTC One (M8).

The downstream vendor kernel used an I2C frequency of 384 kHz
for this bus. Use the same value as the vendor.

Signed-off-by: Alexandre Messier <alex@me.ssier.org>
---
 arch/arm/boot/dts/qcom/qcom-msm8974pro-htc-m8.dts | 36 +++++++++++++++++++++++
 1 file changed, 36 insertions(+)

diff --git a/arch/arm/boot/dts/qcom/qcom-msm8974pro-htc-m8.dts b/arch/arm/boot/dts/qcom/qcom-msm8974pro-htc-m8.dts
index 2edf407db567..66ad93e7dd20 100644
--- a/arch/arm/boot/dts/qcom/qcom-msm8974pro-htc-m8.dts
+++ b/arch/arm/boot/dts/qcom/qcom-msm8974pro-htc-m8.dts
@@ -65,6 +65,35 @@ vreg_vph_pwr: vreg-vph-pwr {
 	};
 };
 
+&blsp1_i2c2 {
+	clock-frequency = <384000>;
+
+	status = "okay";
+
+	touch@20 {
+		compatible = "syna,rmi4-i2c";
+		reg = <0x20>;
+
+		interrupts-extended = <&tlmm 18 IRQ_TYPE_LEVEL_LOW>;
+
+		pinctrl-0 = <&ts_int_pin>;
+		pinctrl-names = "default";
+
+		#address-cells = <1>;
+		#size-cells = <0>;
+
+		rmi4-f01@1 {
+			reg = <0x1>;
+			syna,nosleep-mode = <1>;
+		};
+
+		rmi4-f11@11 {
+			reg = <0x11>;
+			syna,sensor-type = <1>;
+		};
+	};
+};
+
 &blsp1_i2c3 {
 	clock-frequency = <384000>;
 
@@ -353,6 +382,13 @@ cmd-data-pins {
 		};
 	};
 
+	ts_int_pin: ts-int-pin-state {
+		pins = "gpio18";
+		function = "gpio";
+		drive-strength = <2>;
+		bias-disable;
+	};
+
 	wcnss_pin_a: wcnss-pin-active-state {
 		bt-pins {
 			pins = "gpio35", "gpio43", "gpio44";

-- 
2.53.0

