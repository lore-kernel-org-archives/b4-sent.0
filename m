From: Joel Selvaraj <foss@joelselvaraj.com>
Date: Fri, 19 Sep 2025 04:02:29 -0500
Subject: [PATCH] arm64: dts: qcom: sdm845-shift-axolotl: fix touchscreen
 properties
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250919-shift-axolotl-fix-touchscreen-dts-v1-1-60e26ad4e038@joelselvaraj.com>
X-B4-Tracking: v=1; b=H4sIACUczWgC/x2NQQqAIBAAvxJ7bqGsiPpKdBBdcyE0XIsg+nvSc
 WCYeUAoMQnM1QOJLhaOoUBbV2C8Dhsh28KgGjU0UzuheHYZ9R33mHd0fGOOp/FiElFAmwW102r
 sjeo6S1A6R6Ki/Y9lfd8P3kSGknMAAAA=
X-Change-ID: 20250919-shift-axolotl-fix-touchscreen-dts-afa274c233de
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Joel Selvaraj <foss@joelselvaraj.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1758272571; l=1992;
 i=foss@joelselvaraj.com; s=20250919; h=from:subject:message-id;
 bh=6LBH+r1kb4SLbj+q2QfBWT2d9IJvx4qETyl2gI3HG/E=;
 b=A//B6TSPiw9hGoryvpzwQBGolYnGD8pHdgBCJFbRqADxMePhaVm8ZvlzGqjNC64tW080SNCPE
 x1J7WRb5LM7ASwcLijqa2/VDMrzeeBrDN6RViRYR/cErbb3YzNvwWyX
X-Developer-Key: i=foss@joelselvaraj.com; a=ed25519;
 pk=BBMos4ph15apUFh2AkG9rLZIrBWl5LD4egPOhEv63X0=
X-Endpoint-Received: by B4 Relay for foss@joelselvaraj.com/20250919 with auth_id=529
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The touchscreen properties previously upstreamed was based on downstream
touchscreen driver. We ended up adapting upstream edt_ft5x06 driver to
support the FocalTech FT5452 touchscreen controller used in this device.
Update the touchscreen properties to match with the upstream edt_ft5x06
driver. Also, as mentioned, the touchscreen controller used in this
device is ft5452 and not fts8719. Fix it.

Signed-off-by: Joel Selvaraj <foss@joelselvaraj.com>
---
 arch/arm64/boot/dts/qcom/sdm845-shift-axolotl.dts | 17 ++++++++---------
 1 file changed, 8 insertions(+), 9 deletions(-)

diff --git a/arch/arm64/boot/dts/qcom/sdm845-shift-axolotl.dts b/arch/arm64/boot/dts/qcom/sdm845-shift-axolotl.dts
index 89260fce6513937224f76a94e1833a5a8d59faa4..d4062844234e33b0d501bcb7d0b6d5386c822937 100644
--- a/arch/arm64/boot/dts/qcom/sdm845-shift-axolotl.dts
+++ b/arch/arm64/boot/dts/qcom/sdm845-shift-axolotl.dts
@@ -434,20 +434,19 @@ &i2c5 {
 	status = "okay";
 
 	touchscreen@38 {
-		compatible = "focaltech,fts8719";
+		compatible = "focaltech,ft5452";
 		reg = <0x38>;
-		wakeup-source;
-		interrupt-parent = <&tlmm>;
-		interrupts = <125 IRQ_TYPE_EDGE_FALLING>;
-		vdd-supply = <&vreg_l28a_3p0>;
-		vcc-i2c-supply = <&vreg_l14a_1p88>;
 
-		pinctrl-names = "default", "suspend";
+		interrupts-extended = <&tlmm 125 IRQ_TYPE_EDGE_FALLING>;
+		reset-gpios = <&tlmm 99 GPIO_ACTIVE_LOW>;
+
+		vcc-supply = <&vreg_l28a_3p0>;
+		iovcc-supply = <&vreg_l14a_1p88>;
+
 		pinctrl-0 = <&ts_int_active &ts_reset_active>;
 		pinctrl-1 = <&ts_int_suspend &ts_reset_suspend>;
+		pinctrl-names = "default", "suspend";
 
-		reset-gpio = <&tlmm 99 GPIO_ACTIVE_HIGH>;
-		irq-gpio = <&tlmm 125 GPIO_TRANSITORY>;
 		touchscreen-size-x = <1080>;
 		touchscreen-size-y = <2160>;
 	};

---
base-commit: 8f7f8b1b3f4c613dd886f53f768f82816b41eaa3
change-id: 20250919-shift-axolotl-fix-touchscreen-dts-afa274c233de

Best regards,
-- 
Joel Selvaraj <foss@joelselvaraj.com>

