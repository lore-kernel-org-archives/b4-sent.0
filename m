From: Qian Zhang <qian.zhang@oss.qualcomm.com>
Date: Mon, 11 May 2026 14:18:01 +0530
Subject: [PATCH v3] arm64: dts: qcom: arduino-monza: add WLAN enable and
 rfkill GPIO
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260511-linux-next-v3-1-3e22737e71eb@oss.qualcomm.com>
X-B4-Tracking: v=1; b=H4sIAMCXAWoC/y2NQQ6CMBREr0L+2jb9INi68h6GRYUqP4FWWiBVw
 t0txM0kb5J5s0IwnkyAa7aCNwsFcjZBccqg6bR9GUZtYshFXokSkfVk58isiRMT8lzptpQPjRL
 S4O3Nk+Ihu9eJOwqT85/DvRR7+9cITCqFkqNS4oIFQzaStvy7P95cCHycdd+4YeApoN627Qfc2
 K+iqQAAAA==
X-Change-ID: 20260511-linux-next-0846ad58ba18
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Qian Zhang <qian.zhang@oss.qualcomm.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1778489280; l=3025;
 i=qian.zhang@oss.qualcomm.com; s=20260511; h=from:subject:message-id;
 bh=UvfCcSS+NNYGPij6dEX9rRsuz5DeGDSI2ga/3v1YAXo=;
 b=AkqF63xY1DcsQ89bMnQFRi95GL3r7GC9vg6Z2nAOMKskoWE3sZ2QLlq7kVnJeJLqx1QU0RVGR
 ztolhJlftx3DYso+XE2+F0JaLg+QmJfkPh2xwjssZ5BViI7n8J0q9kP
X-Developer-Key: i=qian.zhang@oss.qualcomm.com; a=ed25519;
 pk=bPnvg+qtu7WOMbd5NyWuvI8LCSGKP2BQwbycyqy3gIA=
X-Endpoint-Received: by B4 Relay for qian.zhang@oss.qualcomm.com/20260511 with auth_id=775
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The QCNFA765 M.2 PCIe WLAN module requires GPIO56 (wlan_en) to be
asserted before PCIe enumeration, and GPIO54 to control the RF kill
line.

Model GPIO56 as a regulator-fixed node (wlan_en) referenced from the
PCIe node via vddpe-3v3-supply to ensure correct power sequencing.
Model GPIO54 as a rfkill-gpio node to allow the rfkill subsystem to
manage RF state.

Signed-off-by: Qian Zhang <qian.zhang@oss.qualcomm.com>
---
The Arduino VENTUNO Q board uses a QCNFA765 M.2 PCIe WLAN module
connected to PCIe0. Two GPIOs are required for proper WLAN operation:

- GPIO56 (wlan_en): The WLAN module enable line. It must be asserted
  before PCIe enumeration begins, otherwise the module is not detected
  by the PCIe root complex. This is modeled as a regulator-fixed node
  (wlan_en) referenced from the PCIe node via vddpe-3v3-supply, which
  ensures the GPIO is asserted with a 20ms startup delay before PCIe
  enumeration starts.

- GPIO54 (rfkill): The RF kill line. It is modeled as a rfkill-gpio
  node so that the rfkill subsystem can properly manage RF state,
  including software-triggered airplane mode.

Testing:
- WLAN module (QCNFA765) successfully enumerated on PCIe after boot
- WiFi scan detects available networks
- rfkill block/unblock correctly toggles GPIO54
- GPIO56 remains high throughout rfkill block/unblock
---
Changes in v3:
- Replace regulator-fixed with rfkill-gpio for GPIO54 (rfkill)
- Reference wlan_en from PCIe node via vddpe-3v3-supply
- Fix subject prefix
- Link to v2: https://lore.kernel.org/r/20260501051918.1990713-1-qian.zhang@oss.qualcomm.com
---
 arch/arm64/boot/dts/qcom/monaco-arduino-monza.dts | 21 ++++++++++++++++++++-
 1 file changed, 20 insertions(+), 1 deletion(-)

diff --git a/arch/arm64/boot/dts/qcom/monaco-arduino-monza.dts b/arch/arm64/boot/dts/qcom/monaco-arduino-monza.dts
index ca14f0ea4dae..e0ffe87bba90 100644
--- a/arch/arm64/boot/dts/qcom/monaco-arduino-monza.dts
+++ b/arch/arm64/boot/dts/qcom/monaco-arduino-monza.dts
@@ -153,6 +153,25 @@ vreg_nvme: regulator-3p3-m2 {
 		enable-active-high;
 		startup-delay-us = <20000>;
 	};
+
+	rfkill-wlan {
+		compatible = "rfkill-gpio";
+		label = "wlan";
+		radio-type = "wlan";
+		shutdown-gpios = <&tlmm 54 GPIO_ACTIVE_HIGH>;
+	};
+
+	wlan_reg_3v3: wlan-3v3-regulator {
+		compatible = "regulator-fixed";
+		regulator-name = "wlan_en";
+		regulator-min-microvolt = <3300000>;
+		regulator-max-microvolt = <3300000>;
+		vin-supply = <&vdc_3v3>;
+		gpio = <&tlmm 56 GPIO_ACTIVE_HIGH>;
+		enable-active-high;
+		startup-delay-us = <20000>;
+		regulator-boot-on;
+	};
 };
 
 &ethernet0 {
@@ -326,7 +345,7 @@ &pcie0 {
 	pinctrl-0 = <&pcie0_default_state>;
 	pinctrl-names = "default";
 
-	vddpe-3v3-supply = <&vdc_3v3>;
+	vddpe-3v3-supply = <&wlan_reg_3v3>;
 };
 
 &pcie1 {

---
base-commit: e98d21c170b01ddef366f023bbfcf6b31509fa83
change-id: 20260511-linux-next-0846ad58ba18

Best regards,
-- 
Qian Zhang <qian.zhang@oss.qualcomm.com>

