From: David Heidelberg <david@ixit.cz>
Date: Thu, 02 Apr 2026 11:54:06 +0200
Subject: [PATCH v3 1/3] arm64: dts: qcom: sdm845-shift-axolotl: Enable
 sdcard
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260402-axolotl-misc-p1-v3-1-8934e9db6831@ixit.cz>
References: <20260402-axolotl-misc-p1-v3-0-8934e9db6831@ixit.cz>
In-Reply-To: <20260402-axolotl-misc-p1-v3-0-8934e9db6831@ixit.cz>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Dylan Van Assche <me@dylanvanassche.be>
Cc: linux-arm-msm@vger.kernel.org, Petr Hodina <phodina@protonmail.com>, 
 Casey Connolly <casey.connolly@linaro.org>, 
 Dmitry Baryshkov <dmitry.baryshkov@oss.qualcomm.com>, 
 Alexander Martinz <amartinz@shiftphones.com>, 
 Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, phone-devel@vger.kernel.org, 
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1907; i=david@ixit.cz;
 h=from:subject:message-id; bh=V/gyVRb9byz8QAK00Y2utu0dDrgjEkYddluW8kKLmCI=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpzjy/ODMr9JJWu8/h28lbADOj7k6TlOFsmgBlC
 UTHKz3K7KiJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCac48vwAKCRBgAj/E00kg
 cg3gD/47qV6iwykb7g2169k9tBKeTaX8ux9jAVV5exnXWBlUlnh1iJ5HoaEHvxATqNENLoMtyQR
 gAGlApQ7AWZxwmsQK8rojwv1PONIk4c9rI6McTrO77b5shBOvVKx/D45S03FpSUds/EghW+Cbx7
 Nk+OYYjtwET9G9m4QV+jb7wz/p18KMOQLO9winY1FoKBqT03w16RR3W/7o6IVf2FCmIv0XAGg9r
 tr8vrm2fgBEw5kUMXVHrCGJAqnB8nSPE5GAGS3nVIrUVMEB2KDXCvnIe5cSil2Qf9BgvYDsRAaZ
 fHUvNZIhOJPjLdB/Pqb2HyldrMEADF3MpisS2Vog/aW1dw6ueUc67lbJGHTGml2Q6Fwn5YBj7t/
 OmANWoXdSGJzzhqRoP8mOsHy6xw+9PowYF/PEj8huUfsWZ0zxANeVkkKZ8cMpvXVmcuI7Z4QauQ
 0JiS8nsqJMqH26GfnrmviAulBG+i7IjbGsIAee2Qysir05t+F14yga2uUOp2XszfHCzZg03UQJc
 oyeaFW8HF/KWZc74UiuHMGsaQdDq8J2xLpCmkWhYl0RI9ptXZ2H0wxCCafjnI3YePi7WdTEIcS3
 /3YFeKSOZc8WPnUxybIbTdzdup67uSMhYo34a/ZZ3+pcL6+EwgIcMk1lrUrhi1di8rpcV5VP7tu
 vK46/J5IKbiFMJQ==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Casey Connolly <casey.connolly@linaro.org>

The SHIFT6mq features an sdcard slot, add it.

Signed-off-by: Casey Connolly <casey.connolly@linaro.org>
Reviewed-by: Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>
Co-developed-by: David Heidelberg <david@ixit.cz>
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 arch/arm64/boot/dts/qcom/sdm845-shift-axolotl.dts | 44 +++++++++++++++++++++++
 1 file changed, 44 insertions(+)

diff --git a/arch/arm64/boot/dts/qcom/sdm845-shift-axolotl.dts b/arch/arm64/boot/dts/qcom/sdm845-shift-axolotl.dts
index 740eb22550724..b05f04a621e5b 100644
--- a/arch/arm64/boot/dts/qcom/sdm845-shift-axolotl.dts
+++ b/arch/arm64/boot/dts/qcom/sdm845-shift-axolotl.dts
@@ -600,6 +600,24 @@ &qupv3_id_1 {
 	status = "okay";
 };
 
+&sdhc_2 {
+	pinctrl-0 = <&sdc2_default_state &sdc2_card_det_n>;
+	pinctrl-names = "default";
+
+	vmmc-supply = <&vreg_l21a_2p95>;
+	vqmmc-supply = <&vreg_l13a_2p95>;
+
+	bus-width = <4>;
+	/*
+	 * Card detection is broken, but because the battery must be removed
+	 * to insert the card, we use this rather than the broken-cd property
+	 * which would just waste CPU cycles polling.
+	 */
+	non-removable;
+
+	status = "okay";
+};
+
 &slpi_pas {
 	firmware-name = "qcom/sdm845/SHIFT/axolotl/slpi.mbn";
 
@@ -609,6 +627,32 @@ &slpi_pas {
 &tlmm {
 	gpio-reserved-ranges = <0 4>, <81 4>;
 
+	sdc2_default_state: sdc2-default-state {
+		clk-pins {
+			pins = "sdc2_clk";
+			drive-strength = <16>;
+			bias-disable;
+		};
+
+		cmd-pins {
+			pins = "sdc2_cmd";
+			drive-strength = <10>;
+			bias-pull-up;
+		};
+
+		data-pins {
+			pins = "sdc2_data";
+			drive-strength = <10>;
+			bias-pull-up;
+		};
+	};
+
+	sdc2_card_det_n: sd-card-det-n-state {
+		pins = "gpio126";
+		function = "gpio";
+		bias-disable;
+	};
+
 	sde_dsi_active: sde-dsi-active-state {
 		pins = "gpio6", "gpio11";
 		function = "gpio";

-- 
2.53.0

