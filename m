From: David Heidelberg <david@ixit.cz>
Date: Sat, 26 Sep 2026 14:40:28 +0200
Subject: [PATCH RFC 09/12] arm64: dts: qcom: sdm670-google-common: Enable
 USB Type-C port controller
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260926-typec-v1-9-31adc19f32c6@ixit.cz>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=3664; i=david@ixit.cz;
 h=from:subject:message-id; bh=CjS4hw3kr0t8vOchmksh9hh2KTW9zTk6YzJTOsPRVhk=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBqt70+gGgkptBxM92aPKjE+5O95WN0shFAlu1nR
 v+Fpo3bXr6JAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCare9PgAKCRBgAj/E00kg
 cqkqEADPo2oLUvuGwwEQukf+Tf1e58KayaODxbTvtiWcIGeujCSmRGCBqskRF4wxyOWldimWLGz
 B+u4qEie7FN6OyGhkQkhcL8tRVIsvoP4vSvG7xoe911nglRao2HOSkix4g55OxBee+Bogxczd3K
 RqOq30o/DrvkVFoojYAV/xHrwa/xWKww9dfdMOtfozkn2QK1hCgzztB+2T5meV/uCN32SB2bN0f
 +DO6A74g1oWJSi2FGZMSM/KBx/qU6qQ7jrUiOZgENwiWgY96SAEXq9uAC3iEnaKriiRJTw1m4eH
 h32s+PfTmcdHxU9Sez71jiQpu5P/OZWzScPbkbkAh7MmFyKDRbmwpo5vy1QPk+9k9d04S4yYjuy
 87xLQY6C6tXwFTDkLto4X2VM18CDtN4NpyRGUXcBvkO6A1gQF3GZT2PJ+qQNro2dm/vL/QgMejZ
 uPIhEc1hXPPhHinz338vu07fzQe54JRoUJNncN3Df6MfZvn1EZu1kSJYpIOrgSFNejqRi7FLAaX
 qqyZemCAT9iro+5JSErr+cr0aag5QHS6hhRpYoSU5KVT14pyOUbsf4e8OgmS9S1+zgb/SyWbgGY
 zM/9INYpOIl89mPueOmBlYXP3TylaJiHbyVbhiwp9ks202uLrx19W75Mrvk4qJcQNBiGDAz0sqW
 kK+RhsbszxWqCMw==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Enable the PM660 Type-C port controller with a USB-C connector
description for the Google Pixel 3a (sargo) and Pixel 3a XL (bonito),
which share the same USB-C hardware via this common dtsi.

The connector is configured as:
  - Sink-only power role with a 5V/3A sink PDO
  - Dual-role data with USB role switching

The VBUS output of the charger is not supported yet, so the port can't
act as a power source. Describe it as sink-only until VBUS support lands,
USB host mode is still reachable through a PD data role swap. Higher
voltage PDOs are left out until the charger driver programs the allowed
USBIN adapter voltage.

The Pixel 3a USB-C port is USB 2.0 only, so only the HS endpoint is
wired to the DWC3 controller.

Switch the DWC3 controller from peripheral-only to OTG mode with
usb-role-switch to allow the TCPM framework to control USB host/device
role based on CC pin detection.

Assisted-by: LLM
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 arch/arm64/boot/dts/qcom/sdm670-google-common.dtsi | 51 +++++++++++++++++++++-
 1 file changed, 49 insertions(+), 2 deletions(-)

diff --git a/arch/arm64/boot/dts/qcom/sdm670-google-common.dtsi b/arch/arm64/boot/dts/qcom/sdm670-google-common.dtsi
index b4854801a5f5e..afecbef2e5bc2 100644
--- a/arch/arm64/boot/dts/qcom/sdm670-google-common.dtsi
+++ b/arch/arm64/boot/dts/qcom/sdm670-google-common.dtsi
@@ -6,16 +6,17 @@
  * Copyright (c) 2022, Richard Acayan. All rights reserved.
  */
 
 #include <dt-bindings/gpio/gpio.h>
 #include <dt-bindings/input/input.h>
 #include <dt-bindings/leds/common.h>
 #include <dt-bindings/pinctrl/qcom,pmic-gpio.h>
 #include <dt-bindings/power/qcom-rpmpd.h>
+#include <dt-bindings/usb/pd.h>
 #include "sdm670.dtsi"
 #include "pm660.dtsi"
 #include "pm660l.dtsi"
 
 /delete-node/ &mpss_region;
 /delete-node/ &venus_mem;
 /delete-node/ &wlan_msa_mem;
 /delete-node/ &cdsp_mem;
@@ -580,16 +581,56 @@ cam_vio_pin: cam-vio-state {
 		power-source = <0>;
 	};
 };
 
 &pm660_rradc {
 	status = "okay";
 };
 
+&pm660_typec {
+	vdd-pdphy-supply = <&vreg_l7b_3p125>;
+
+	status = "okay";
+
+	connector {
+		compatible = "usb-c-connector";
+
+		/*
+		 * Sink only for now, as the PM660 charger doesn't provide
+		 * the VBUS output yet. Switch to the dual power role with
+		 * source PDOs, try-power-role and vbus-supply once it is
+		 * supported.
+		 *
+		 * Higher voltage sink PDOs will be added once the charger
+		 * driver programs the allowed USBIN adapter voltage.
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
+				pm660_hs_in: endpoint {
+					remote-endpoint = <&usb_1_dwc3_hs>;
+				};
+			};
+		};
+	};
+};
+
 &pm660l_flash {
 	status = "okay";
 
 	led-0 {
 		function = LED_FUNCTION_FLASH;
 		color = <LED_COLOR_ID_WHITE>;
 		led-sources = <1>, <2>;
 		led-max-microamp = <500000>;
@@ -702,16 +743,22 @@ &usb_1_hsphy {
 };
 
 &usb_1 {
 	qcom,select-utmi-as-pipe-clk;
 	status = "okay";
 };
 
 &usb_1_dwc3 {
-	/* Only peripheral works for now */
-	dr_mode = "peripheral";
+	dr_mode = "otg";
+	usb-role-switch;
 
 	/* Do not assume that sdm670.dtsi will never support USB 3.0 */
 	phys = <&usb_1_hsphy>;
 	phy-names = "usb2-phy";
 	maximum-speed = "high-speed";
+
+	port {
+		usb_1_dwc3_hs: endpoint {
+			remote-endpoint = <&pm660_hs_in>;
+		};
+	};
 };

-- 
2.55.0

