From: Hui Liu <quic_huliu@quicinc.com>
Date: Fri, 15 Dec 2023 17:33:32 +0800
Subject: [PATCH v3] arm64: dts: qcom: qcs6490-idp: Add definition for three
 LEDs.
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20231215-lpg-v3-1-4e2db0c6df5f@quicinc.com>
X-B4-Tracking: v=1; b=H4sIAHAdfGUC/0XMQQ6CMBCF4auQWTuGaUGNK+9hjBnaASYBCq0SE
 8Ldbdy4/JL/vQ2SRJUE12KDKKsmDVOGPRTgep46QfXZYEpjyVCNw9xhxey9PVcXIoZczlFa/fx
 e7o/sNoYRX30U/m+JSlxcGJ+D+ISrQULr2FPbNO5U8215q9PJHXMC+/4FmQQtqJgAAAA=
To: Andy Gross <agross@kernel.org>, Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konrad.dybcio@linaro.org>, Rob Herring <robh+dt@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Hui Liu <quic_huliu@quicinc.com>
X-Mailer: b4 0.13-dev-83828
X-Developer-Signature: v=1; a=ed25519-sha256; t=1702633636; l=1646;
 i=quic_huliu@quicinc.com; s=20230823; h=from:subject:message-id;
 bh=jkgKPcTHB0LvObnOdM+JMFH2yGRqbzzTL1fwXf6UZho=;
 b=8cRQyf8GFCz6G7Lm8RUia1YB/uRkxLY/eTLY+R57RE12nYTwiZcxIu40k7vqcqHeR5rBPK33r
 b4+KOeOABaKCoioDKb2XNu2GP83ffvmeGQobZ0KgCb0vzcXQ2u/SMUz
X-Developer-Key: i=quic_huliu@quicinc.com; a=ed25519;
 pk=1z+A50UnTuKe/FdQv2c0W3ajDsJOYddwIHo2iivhTTA=
X-Endpoint-Received: by B4 Relay for quic_huliu@quicinc.com/20230823 with auth_id=80
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add definition for three LEDs to make sure they can
be enabled base on QCOM LPG LED driver.

Signed-off-by: Hui Liu <quic_huliu@quicinc.com>
---
Changes in v3:
- Rephrased commit text and updated the nodes to qcm6490-idp board file.
- Link to v2: https://lore.kernel.org/all/20231110-qcom_leds-v2-1-3cad1fbbc65a@quicinc.com/

Changes in v2:
- Rephrased commit text and updated the nodes to board file.
- Link to v1: https://lore.kernel.org/r/20231108-qcom_leds-v1-1-c3e1c8572cb0@quicinc.com
---
 arch/arm64/boot/dts/qcom/qcm6490-idp.dts | 25 +++++++++++++++++++++++++
 1 file changed, 25 insertions(+)

diff --git a/arch/arm64/boot/dts/qcom/qcm6490-idp.dts b/arch/arm64/boot/dts/qcom/qcm6490-idp.dts
index 37c91fdf3ab9..f801144a1556 100644
--- a/arch/arm64/boot/dts/qcom/qcm6490-idp.dts
+++ b/arch/arm64/boot/dts/qcom/qcm6490-idp.dts
@@ -5,6 +5,7 @@
 
 /dts-v1/;
 
+#include <dt-bindings/leds/common.h>
 #include <dt-bindings/regulator/qcom,rpmh-regulator.h>
 #include "sc7280.dtsi"
 #include "pm7325.dtsi"
@@ -414,6 +415,30 @@ vreg_bob_3p296: bob {
 	};
 };
 
+&pm8350c_pwm {
+	#address-cells = <1>;
+	#size-cells = <0>;
+	status = "okay";
+
+	led@1 {
+		reg = <1>;
+		color = <LED_COLOR_ID_RED>;
+		label = "red";
+	};
+
+	led@2 {
+		reg = <2>;
+		color = <LED_COLOR_ID_GREEN>;
+		label = "green";
+	};
+
+	led@3 {
+		reg = <3>;
+		color = <LED_COLOR_ID_BLUE>;
+		label = "blue";
+	};
+};
+
 &qupv3_id_0 {
 	status = "okay";
 };

---
base-commit: 17cb8a20bde66a520a2ca7aad1063e1ce7382240
change-id: 20231215-lpg-4aadd374811a

Best regards,
-- 
Hui Liu <quic_huliu@quicinc.com>

