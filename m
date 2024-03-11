From: Hui Liu <quic_huliu@quicinc.com>
Date: Mon, 11 Mar 2024 18:09:31 +0800
Subject: [PATCH v5] arm64: dts: qcom: qcm6490-idp: enable PMIC Volume and
 Power buttons
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240311-gpio-keys-v5-1-08823582f6c9@quicinc.com>
X-B4-Tracking: v=1; b=H4sIAGDY7mUC/23MTQ6CMBCG4auQrq3pH+3gynsYF9AWmRgpUiUaw
 90tbKzR5TeZ532R6Ef0keyKFxn9hBFDn0a5KYjt6v7kKbq0iWBCMcE0PQ0Y6Nk/I+USmsZByUQ
 FJP0Po2/xsbYOx7Q7jLcwPtf0xJfrv8rEKadGgzRV5eoW3P56R4u93dpwIUtnEpkVMrciWV61C
 hrpwGjxa+XHSsZzK5O1tdbKeTCmtL9W5VblViXLpGbKGQMW9Led5/kNMvYqhVgBAAA=
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konrad.dybcio@linaro.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Hui Liu <quic_huliu@quicinc.com>
X-Mailer: b4 0.13-dev-83828
X-Developer-Signature: v=1; a=ed25519-sha256; t=1710151870; l=2997;
 i=quic_huliu@quicinc.com; s=20230823; h=from:subject:message-id;
 bh=P49AauHmA6KJoQvdRRaGDstedPDavIC2nds8wmnutYE=;
 b=03Wz5EeAwzrpIdHG6XXQbaisCr4nHg3GdAT6B7ypyIHxfudc4Nx9fJWoORpCeNxkq6pe7htPr
 hjwB5uUJ1b0AuKECDnFsM4EWhMV1VfMQqhv+CE1woGdo4tqj9t2Y91U
X-Developer-Key: i=quic_huliu@quicinc.com; a=ed25519;
 pk=1z+A50UnTuKe/FdQv2c0W3ajDsJOYddwIHo2iivhTTA=
X-Endpoint-Received: by B4 Relay for quic_huliu@quicinc.com/20230823 with auth_id=80
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Volume Down & Power buttons are controlled by the PMIC via
the PON hardware, and the Volume Up is connected to a PMIC gpio.

Enable the necessary hardware and setup the GPIO state for the
Volume Up gpio key.

Signed-off-by: Hui Liu <quic_huliu@quicinc.com>
---
Changes in v5:
- Removed the status setting for pmk8350_pon, because the default
status is "okay".
- Link to v4: https://lore.kernel.org/r/20240304-gpio-keys-v4-1-03604d778c86@quicinc.com

Changes in v4:
- Switch the order of "pinctrl-0" and "pinctrl-names".
- Update "volume_up" to "Volume_up".
- Remove "linux,input-type", because the default value is 1(EV_KEY).
- Link to v3: https://lore.kernel.org/r/20240301-gpio-keys-v3-1-ca664de8775c@quicinc.com

Changes in v3:
- Update the commit more concise and explicit.
- remove "power-source" property and update the numeric value to defined
name for "qcom,drive-strength".
- Link to v2: https://lore.kernel.org/r/20240223-gpio-keys-v2-1-19f48b3d8762@quicinc.com

Changes in v2:
- Update the commit description.
- Link to v1: https://lore.kernel.org/r/20240206-gpio-keys-v1-1-7683799daf8d@quicinc.com
---
 arch/arm64/boot/dts/qcom/qcm6490-idp.dts | 37 ++++++++++++++++++++++++++++++++
 1 file changed, 37 insertions(+)

diff --git a/arch/arm64/boot/dts/qcom/qcm6490-idp.dts b/arch/arm64/boot/dts/qcom/qcm6490-idp.dts
index acf145d1d97c..a4a7d55fb45c 100644
--- a/arch/arm64/boot/dts/qcom/qcm6490-idp.dts
+++ b/arch/arm64/boot/dts/qcom/qcm6490-idp.dts
@@ -9,7 +9,9 @@
 #define PM7250B_SID 8
 #define PM7250B_SID1 9
 
+#include <dt-bindings/input/linux-event-codes.h>
 #include <dt-bindings/leds/common.h>
+#include <dt-bindings/pinctrl/qcom,pmic-gpio.h>
 #include <dt-bindings/regulator/qcom,rpmh-regulator.h>
 #include "sc7280.dtsi"
 #include "pm7250b.dtsi"
@@ -39,6 +41,22 @@ chosen {
 		stdout-path = "serial0:115200n8";
 	};
 
+	gpio-keys {
+		compatible = "gpio-keys";
+
+		pinctrl-0 = <&key_vol_up_default>;
+		pinctrl-names = "default";
+
+		key-volume-up {
+			label = "Volume_up";
+			gpios = <&pm7325_gpios 6 GPIO_ACTIVE_LOW>;
+			linux,code = <KEY_VOLUMEUP>;
+			wakeup-source;
+			debounce-interval = <15>;
+			linux,can-disable;
+		};
+	};
+
 	reserved-memory {
 		xbl_mem: xbl@80700000 {
 			reg = <0x0 0x80700000 0x0 0x100000>;
@@ -421,6 +439,16 @@ vreg_bob_3p296: bob {
 	};
 };
 
+&pm7325_gpios {
+	key_vol_up_default: key-vol-up-state {
+		pins = "gpio6";
+		function = "normal";
+		input-enable;
+		bias-pull-up;
+		qcom,drive-strength = <PMIC_GPIO_STRENGTH_LOW>;
+	};
+};
+
 &pm8350c_pwm {
 	status = "okay";
 
@@ -448,6 +476,15 @@ led@3 {
 	};
 };
 
+&pon_pwrkey {
+	status = "okay";
+};
+
+&pon_resin {
+	linux,code = <KEY_VOLUMEDOWN>;
+	status = "okay";
+};
+
 &qupv3_id_0 {
 	status = "okay";
 };

---
base-commit: 23e11d0318521e8693459b0e4d23aec614b3b68b
change-id: 20240206-gpio-keys-138bbd850298

Best regards,
-- 
Hui Liu <quic_huliu@quicinc.com>

