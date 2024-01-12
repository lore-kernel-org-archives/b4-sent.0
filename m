From: Hui Liu <quic_huliu@quicinc.com>
Date: Fri, 12 Jan 2024 11:05:23 +0800
Subject: [PATCH v4] arm64: dts: qcom: qcs6490-idp: Add definition for three
 LEDs.
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240112-lpg-v4-1-c4004026686b@quicinc.com>
X-B4-Tracking: v=1; b=H4sIAHOsoGUC/1WOwQqDMBAFf0Vy7hY3UVt66n8UKTHZaECNJja0i
 P/e6KX0ODBveCsL5C0FdstW5inaYN2YoDhlTHVybAmsTsx4zgVyLKGfWiik1FpciiuiZMmcPBn
 7PiqPOrHxboCl8yR/W8QcZuWGZ086QOSAIJTUaJpGVaW8zy+r7KjOSdmTnQ2L85/jVxR7+P9CF
 ClQENdNriptSvMXqLdt+wIYOIwp2wAAAA==
To: Andy Gross <agross@kernel.org>, Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konrad.dybcio@linaro.org>, Rob Herring <robh+dt@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Hui Liu <quic_huliu@quicinc.com>
X-Mailer: b4 0.13-dev-83828
X-Developer-Signature: v=1; a=ed25519-sha256; t=1705028860; l=1784;
 i=quic_huliu@quicinc.com; s=20230823; h=from:subject:message-id;
 bh=3J2JAmE3HrG4pHWMcjf5Ib9yX4UdsBMnHOiWMa/2sVY=;
 b=4oaVWMLN1he3cUfY5Yh3QWaWm4vA/7unhwaDc9/wahU6XZdUUep1PyqUWSuYjECf9jRZS3vXc
 Pxi6qLX+FD7BUa1/QrNmtBqQtRV+oD7j8TqIsC9Ut5cLC16wAu5PnML
X-Developer-Key: i=quic_huliu@quicinc.com; a=ed25519;
 pk=1z+A50UnTuKe/FdQv2c0W3ajDsJOYddwIHo2iivhTTA=
X-Endpoint-Received: by B4 Relay for quic_huliu@quicinc.com/20230823 with auth_id=80
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add definition for three LEDs to make sure they can
be enabled base on QCOM LPG LED driver.

Signed-off-by: Hui Liu <quic_huliu@quicinc.com>
---
Changes in v4:
- Removed "label" definition and added "function" definition.
- Link to v3: https://lore.kernel.org/r/20231215-lpg-v3-1-4e2db0c6df5f@quicinc.com

Changes in v3:
- Rephrased commit text and updated the nodes to qcm6490-idp board file.
- Link to v2: https://lore.kernel.org/all/20231110-qcom_leds-v2-1-3cad1fbbc65a@quicinc.com/

Changes in v2:
- Rephrased commit text and updated the nodes to board file.
- Link to v1: https://lore.kernel.org/r/20231108-qcom_leds-v1-1-c3e1c8572cb0@quicinc.com
---
 arch/arm64/boot/dts/qcom/qcm6490-idp.dts | 23 +++++++++++++++++++++++
 1 file changed, 23 insertions(+)

diff --git a/arch/arm64/boot/dts/qcom/qcm6490-idp.dts b/arch/arm64/boot/dts/qcom/qcm6490-idp.dts
index 37c91fdf3ab9..8268fad505e7 100644
--- a/arch/arm64/boot/dts/qcom/qcm6490-idp.dts
+++ b/arch/arm64/boot/dts/qcom/qcm6490-idp.dts
@@ -5,6 +5,7 @@
 
 /dts-v1/;
 
+#include <dt-bindings/leds/common.h>
 #include <dt-bindings/regulator/qcom,rpmh-regulator.h>
 #include "sc7280.dtsi"
 #include "pm7325.dtsi"
@@ -414,6 +415,28 @@ vreg_bob_3p296: bob {
 	};
 };
 
+&pm8350c_pwm {
+	function = LED_FUNCTION_STATUS;
+	#address-cells = <1>;
+	#size-cells = <0>;
+	status = "okay";
+
+	led@1 {
+		reg = <1>;
+		color = <LED_COLOR_ID_RED>;
+	};
+
+	led@2 {
+		reg = <2>;
+		color = <LED_COLOR_ID_GREEN>;
+	};
+
+	led@3 {
+		reg = <3>;
+		color = <LED_COLOR_ID_BLUE>;
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

