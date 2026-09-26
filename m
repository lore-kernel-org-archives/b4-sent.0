From: David Heidelberg <david@ixit.cz>
Date: Sat, 26 Sep 2026 14:40:31 +0200
Subject: [PATCH RFC 12/12] arm64: dts: qcom: sdm845-shift-axolotl: Enable
 USB Type-C port controller
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260926-typec-v1-12-31adc19f32c6@ixit.cz>
References: <20260926-typec-v1-0-31adc19f32c6@ixit.cz>
In-Reply-To: <20260926-typec-v1-0-31adc19f32c6@ixit.cz>
To: Alexey Minnekhanov <alexeymin@minlexx.ru>, 
 Bryan O'Donoghue <bryan.odonoghue@linaro.org>, 
 Heikki Krogerus <heikki.krogerus@linux.intel.com>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Liam Girdwood <lgirdwood@gmail.com>, Mark Brown <broonie@kernel.org>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>, 
 Dmitry Baryshkov <dmitry.baryshkov@oss.qualcomm.com>, 
 Lee Jones <lee@kernel.org>, Stephen Boyd <sboyd@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, linux-usb@vger.kernel.org, 
 linux-kernel@vger.kernel.org, devicetree@vger.kernel.org, 
 phone-devel@vger.kernel.org, mfd@lists.linux.dev, 
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=4218; i=david@ixit.cz;
 h=from:subject:message-id; bh=x32COcG8Butqrlw/fff8Lfo8b61ySUHbjR8/5yIgBUw=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBqt70+D9ld9Gu1iU4YWKZL3BfGDTzOC2I5j0XtG
 MZVW8YLmNSJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCare9PgAKCRBgAj/E00kg
 ctTpEACDKiK7HntwbRh9oZMsTQl2VLJx030TyTKvQKkMLV8xfAZzVCr5NtbggSwgcW0cuAvvmOf
 a/eC3re114t2mQqz5sFmPuwQMndQPdUwdyB83yUpq/FG8jOD6b6H/qSFdeI3AmmAi2I5LPlbnXD
 q3sYf74UJo0aHBXbWzgluM5ucCqIOqFILfIVKCRF0spodPSY5IJO4GgJ3WTb4wDJWfjCdHWXRnd
 veQXKjLYzes/VLbdZbAPCx+SDuBG52lLqgFJjvu1aTLNK+24x29Xv9fnqFIjTyy+lMS1TB1fhVO
 hE+rbWoQQ3mkFIgo1XjLO0x3hKmV5GdNKbQeSSPJ/xXUZUcAdTmrXUnslz/Cq692xxWAW47QW3M
 OxKKwsda304QmybzA0WNQWQ2D4B28rcbirGgirSEzqkL1H3izI8hEzz1X6IN+D8FDxeqACkHg49
 66PoG3U5OwiONfiXCGgqq09ZYEqxTPxTISJmArCt9Ic8XvTBceLpuWADxTooDzcqh03j/tHDNW5
 xaGN43A/RRotu2VPLYwRtTM0Yq4xqx5WT2RbEo8o7QqtvG29uVbaWS8XPVnFFk5ZJVft4YefF3H
 X3xrniO/S5/tjmegs/I3vFYYM59GcJcalPPBN1kFmO7nI3pQ9Q3EywU8Qcbm1d63FhhHVzdiETq
 K5u4gTq0aPACfNg==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Enable the PMI8998 Type-C port controller with a USB-C connector
description for the SHIFT6mq:

  - Sink-only power role with a 5V/3A sink PDO
  - Dual-role data with USB role switching

The VBUS output of the charger is not supported yet, so the port can't
act as a power source. Describe it as sink-only until VBUS support lands,
USB host mode is still reachable through a PD data role swap. Higher
voltage PDOs are left out until the charger driver programs the allowed
USBIN adapter voltage.

Wire the USB-C connector port graph:
  - port@0: DWC3 HS endpoint for USB role switching
  - port@1: QMP combo PHY for SS lane orientation

Switch the DWC3 controller from peripheral-only to OTG mode with
usb-role-switch to allow the TCPM framework to control USB host/device
role based on CC pin detection.

DisplayPort Alt Mode is not advertised yet, it will be added together
with enabling the DP controller (mdss_dp).

Assisted-by: LLM
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 arch/arm64/boot/dts/qcom/sdm845-shift-axolotl.dts | 62 ++++++++++++++++++++++-
 1 file changed, 61 insertions(+), 1 deletion(-)

diff --git a/arch/arm64/boot/dts/qcom/sdm845-shift-axolotl.dts b/arch/arm64/boot/dts/qcom/sdm845-shift-axolotl.dts
index 1b0eaeafbd517..2ddbe732961a2 100644
--- a/arch/arm64/boot/dts/qcom/sdm845-shift-axolotl.dts
+++ b/arch/arm64/boot/dts/qcom/sdm845-shift-axolotl.dts
@@ -6,16 +6,17 @@
  */
 
 /dts-v1/;
 
 #include <dt-bindings/arm/qcom,ids.h>
 #include <dt-bindings/gpio/gpio.h>
 #include <dt-bindings/leds/common.h>
 #include <dt-bindings/regulator/qcom,rpmh-regulator.h>
+#include <dt-bindings/usb/pd.h>
 #include "sdm845.dtsi"
 #include "pm8998.dtsi"
 #include "pmi8998.dtsi"
 
 / {
 	model = "SHIFT SHIFT6mq";
 	compatible = "shift,axolotl", "qcom,sdm845";
 	chassis-type = "handset";
@@ -654,16 +655,66 @@ led-1 {
 		color = <LED_COLOR_ID_YELLOW>;
 		led-sources = <2>;
 		led-max-microamp = <100000>;
 		flash-max-microamp = <1100000>;
 		flash-max-timeout-us = <1280000>;
 	};
 };
 
+&pmi8998_typec {
+	status = "okay";
+
+	vdd-pdphy-supply = <&vreg_l24a_3p075>;
+
+	connector {
+		compatible = "usb-c-connector";
+
+		/*
+		 * Sink only for now, as the PMI8998 charger doesn't provide
+		 * the VBUS output yet. Switch to the dual power role with
+		 * source PDOs, try-power-role and vbus-supply once it is
+		 * supported.
+		 *
+		 * Higher voltage sink PDOs will be added once the charger
+		 * driver programs the allowed USBIN adapter voltage.
+		 *
+		 * DisplayPort Alt Mode will be added together with enabling
+		 * the DP controller (mdss_dp).
+		 */
+		power-role = "sink";
+		data-role = "dual";
+		self-powered;
+
+		sink-pdos = <PDO_FIXED(5000, 3000,
+				       PDO_FIXED_USB_COMM |
+				       PDO_FIXED_DATA_SWAP)>;
+		op-sink-microwatt = <15000000>;
+
+		ports {
+			#address-cells = <1>;
+			#size-cells = <0>;
+
+			port@0 {
+				reg = <0>;
+				pmi8998_hs_in: endpoint {
+					remote-endpoint = <&usb_1_dwc3_hs>;
+				};
+			};
+
+			port@1 {
+				reg = <1>;
+				pmi8998_typec_mux_in: endpoint {
+					remote-endpoint = <&usb_1_qmpphy_out>;
+				};
+			};
+		};
+	};
+};
+
 &qup_uart9_rx {
 	drive-strength = <2>;
 	bias-pull-up;
 };
 
 &qup_uart9_tx {
 	drive-strength = <2>;
 	bias-disable;
@@ -855,17 +906,22 @@ &ufs_mem_phy {
 	vdda-pll-supply = <&vdda_ufs1_1p2>;
 };
 
 &usb_1 {
 	status = "okay";
 };
 
 &usb_1_dwc3 {
-	dr_mode = "peripheral";
+	dr_mode = "otg";
+	usb-role-switch;
+};
+
+&usb_1_dwc3_hs {
+	remote-endpoint = <&pmi8998_hs_in>;
 };
 
 &usb_1_hsphy {
 	status = "okay";
 
 	vdd-supply = <&vreg_l1a_0p875>;
 	vdda-phy-dpdm-supply = <&vreg_l24a_3p075>;
 	vdda-pll-supply = <&vreg_l12a_1p8>;
@@ -873,16 +929,20 @@ &usb_1_hsphy {
 
 &usb_1_qmpphy {
 	status = "okay";
 
 	vdda-phy-supply = <&vreg_l1a_0p875>;
 	vdda-pll-supply = <&vreg_l26a_1p2>;
 };
 
+&usb_1_qmpphy_out {
+	remote-endpoint = <&pmi8998_typec_mux_in>;
+};
+
 &venus {
 	firmware-name = "qcom/sdm845/SHIFT/axolotl/venus.mbn";
 
 	status = "okay";
 };
 
 &wifi {
 	vdd-0.8-cx-mx-supply = <&vreg_l5a_0p8>;

-- 
2.55.0

