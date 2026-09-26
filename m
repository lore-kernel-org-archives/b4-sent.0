From: David Heidelberg <david@ixit.cz>
Date: Sat, 26 Sep 2026 14:40:29 +0200
Subject: [PATCH RFC 10/12] arm64: dts: qcom: sdm845-google-common: Enable
 USB Type-C port controller
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260926-typec-v1-10-31adc19f32c6@ixit.cz>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=4327; i=david@ixit.cz;
 h=from:subject:message-id; bh=r5IQw5ef3NgqdpkqzvYRqDdpmBPKAHmtONrEfZAVnQU=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBqt70+aIeCNkK1YRBq0hkMzBSfTWJFNLHe+EZpq
 iLkAL06sCWJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCare9PgAKCRBgAj/E00kg
 crwKEACh2VG72WBEQaWlm3ElTE/xURhQ7dFGJfr9JYN8dzdcagAcTPi6+ZdQ6RdLT6pIT8r6f2Y
 th1vxhNgAt0s66X4HUgPV2vI8/3gYoLLklygGI+yxZXgkvIgfkgYh7PSZ3M7jewWpOnafvEx9dz
 UIoKcHJxfP06RykWB5BT0DJxmVULNpW4RRNBs/S9oOzDVYcLz9j2dy1qyya+Nqspw+Q6VAfKnyE
 iytMEIZIMOLj0Gncl6twyZsxuRKTvDu8SfS4udsCuIy+scSO7taWVPShxTTWFHFbK1d0puhBUbK
 rUSpYEvBtnFmjCU4+qv0gxhlDQdGJzhg8WN3XV8O1Hev9vdDb9OEJl4yLcoMjMGuR228b25DEIV
 8XZgxypymklkRWcv/Df3n8c7GIdsJnguRkfj9m84EA62tTx0iaSvD9z6o4266mC3Bsrg0+QDCJN
 23S6R8cAFj2jTrGmS5OhZ/4yVxv9JofnwKEv3rUfZwU1Z0JgX4vf2V1uCkfFF0yCruvprtWp/40
 sdnOpcH65fi2QeZFhJbby4FGa1FS/FaOmDjTeg4x1xBIZNW2XhGFFINviYVaG2eXy9mYXU7l3G9
 6Qyxa9Y8ZH1IHhp2pSow3x4GRdogSRuqS3L34IufbQN+xgpmgq1lKh4BqozYEtsFzVUelsC67wQ
 YfC2Q5zXt1UtcFw==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Enable the PMI8998 Type-C port controller with a USB-C connector
description for the Google Pixel 3 (blueline) and Pixel 3 XL
(crosshatch), which share the same USB-C hardware via this common dtsi.

The connector is configured as:
  - Sink-only power role with a 5V/3A sink PDO
  - Operating sink power 7.6W (matching downstream configuration)
  - Dual-role data with USB role switching

The VBUS output of the charger is not supported yet, so the port can't
act as a power source. Describe it as sink-only until VBUS support lands,
USB host mode is still reachable through a PD data role swap. Higher
voltage PDOs are left out until the charger driver programs the allowed
USBIN adapter voltage.

DisplayPort Alt Mode is not advertised as Google disabled DP output in
the Pixel 3 hardware design (downstream explicitly sets sde_dp to
disabled and excludes it from the MDSS connector list).

Wire the USB-C connector port graph:
  - port@0: DWC3 HS endpoint for USB role switching
  - port@1: QMP combo PHY for USB SS orientation switching

Switch the DWC3 controller from peripheral-only to OTG mode with
usb-role-switch to allow the TCPM framework to control USB host/device
role based on CC pin detection.

Assisted-by: LLM
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 arch/arm64/boot/dts/qcom/sdm845-google-common.dtsi | 59 +++++++++++++++++++++-
 1 file changed, 58 insertions(+), 1 deletion(-)

diff --git a/arch/arm64/boot/dts/qcom/sdm845-google-common.dtsi b/arch/arm64/boot/dts/qcom/sdm845-google-common.dtsi
index 9e952f9862f24..99f40a13b5d7f 100644
--- a/arch/arm64/boot/dts/qcom/sdm845-google-common.dtsi
+++ b/arch/arm64/boot/dts/qcom/sdm845-google-common.dtsi
@@ -2,16 +2,17 @@
 
 /dts-v1/;
 
 #include <dt-bindings/arm/qcom,ids.h>
 #include <dt-bindings/dma/qcom-gpi.h>
 #include <dt-bindings/input/linux-event-codes.h>
 #include <dt-bindings/interrupt-controller/irq.h>
 #include <dt-bindings/regulator/qcom,rpmh-regulator.h>
+#include <dt-bindings/usb/pd.h>
 
 #include "sdm845.dtsi"
 #include "pm8998.dtsi"
 #include "pmi8998.dtsi"
 
 /delete-node/ &mpss_region;
 /delete-node/ &venus_mem;
 /delete-node/ &cdsp_mem;
@@ -449,16 +450,63 @@ &pm8998_resin {
 };
 
 &pmi8998_charger {
 	monitored-battery = <&battery>;
 
 	status = "okay";
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
+		 */
+		power-role = "sink";
+		data-role = "dual";
+		self-powered;
+
+		sink-pdos = <PDO_FIXED(5000, 3000,
+				       PDO_FIXED_USB_COMM |
+				       PDO_FIXED_DATA_SWAP)>;
+		op-sink-microwatt = <7600000>;
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
 &qupv3_id_0 {
 	status = "okay";
 };
 
 &qupv3_id_1 {
 	status = "okay";
 };
 
@@ -549,17 +597,22 @@ &ufs_mem_phy {
 	status = "okay";
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
 	vdd-supply = <&vreg_l1a_0p875>;
 	vdda-pll-supply = <&vreg_l12a_1p8>;
 	vdda-phy-dpdm-supply = <&vreg_l24a_3p075>;
 
 	qcom,imp-res-offset-value = <8>;
@@ -572,16 +625,20 @@ &usb_1_hsphy {
 
 &usb_1_qmpphy {
 	vdda-phy-supply = <&vreg_l1a_0p875>;
 	vdda-pll-supply = <&vreg_l26a_1p2>;
 
 	status = "okay";
 };
 
+&usb_1_qmpphy_out {
+	remote-endpoint = <&pmi8998_typec_mux_in>;
+};
+
 &venus {
 	firmware-name = "qcom/sdm845/Google/blueline/venus.mbn";
 
 	status = "okay";
 };
 
 &wifi {
 	vdd-0.8-cx-mx-supply = <&vreg_l5a_0p8>;

-- 
2.55.0

