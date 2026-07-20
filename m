From: Haoning CHENG <Haoning.CHENG@cn.bosch.com>
Date: Mon, 20 Jul 2026 10:19:40 +0800
Subject: [PATCH v10 1/3] dt-bindings: thermal: imx: Document calibration
 offset property
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260720-b4-symana21-11221-imx-thermal-support-upstream-6-18-v10-1-f8c3dcd9a57e@cn.bosch.com>
References: <20260720-b4-symana21-11221-imx-thermal-support-upstream-6-18-v10-0-f8c3dcd9a57e@cn.bosch.com>
In-Reply-To: <20260720-b4-symana21-11221-imx-thermal-support-upstream-6-18-v10-0-f8c3dcd9a57e@cn.bosch.com>
To: "Rafael J. Wysocki" <rafael@kernel.org>, 
 Daniel Lezcano <daniel.lezcano@linaro.org>, Zhang Rui <rui.zhang@intel.com>, 
 Lukasz Luba <lukasz.luba@arm.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Shawn Guo <shawnguo@kernel.org>, 
 Sascha Hauer <s.hauer@pengutronix.de>, 
 Pengutronix Kernel Team <kernel@pengutronix.de>, 
 Fabio Estevam <festevam@gmail.com>
Cc: linux-pm@vger.kernel.org, devicetree@vger.kernel.org, 
 imx@lists.linux.dev, linux-arm-kernel@lists.infradead.org, 
 linux-kernel@vger.kernel.org, Haoning CHENG <Haoning.CHENG@cn.bosch.com>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784513984; l=2030;
 i=Haoning.CHENG@cn.bosch.com; s=20260709; h=from:subject:message-id;
 bh=Ue37UPF1teuZxiSxC/xhzQKQfZyk1Yq+nuequgJPOG4=;
 b=jxz6ca8ybOk3Ed5IQc6Kz7G2jIX9lX2YRBEq3bn259hBuDSVo5LBshXKXZ7SLa+XfkBsORtV6
 lS0+UAwP1xZABeGB+nnXN97wzLoDjJHv4Kywp8wKeWfJD48+kN8LEQ6
X-Developer-Key: i=Haoning.CHENG@cn.bosch.com; a=ed25519;
 pk=glQGwad/fosRS5gZUJYbLDPPLGe7rFTrTV2VxY/ySdc=
X-Endpoint-Received: by B4 Relay for Haoning.CHENG@cn.bosch.com/20260709 with auth_id=860
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The TEMPMON sensor reading may deviate from the theoretical SoC
junction temperature. Document the optional
fsl,temp-calibration-offset-millicelsius property, a signed offset
in millicelsius applied to correct the sensor reading toward the
theoretical junction temperature.

The offset is determined through thermal characterization by
comparing the sensor output against the calculated junction
temperature. When absent, the offset is zero.

Reviewed-by: Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>
Reviewed-by: Lukasz Luba <lukasz.luba@arm.com>
Signed-off-by: Haoning CHENG <Haoning.CHENG@cn.bosch.com>
---
 Documentation/devicetree/bindings/thermal/imx-thermal.yaml | 12 ++++++++++++
 1 file changed, 12 insertions(+)

diff --git a/Documentation/devicetree/bindings/thermal/imx-thermal.yaml b/Documentation/devicetree/bindings/thermal/imx-thermal.yaml
index 949b154856c5..503a6e7a2c68 100644
--- a/Documentation/devicetree/bindings/thermal/imx-thermal.yaml
+++ b/Documentation/devicetree/bindings/thermal/imx-thermal.yaml
@@ -59,6 +59,17 @@ properties:
   clocks:
     maxItems: 1
 
+  fsl,temp-calibration-offset-millicelsius:
+    minimum: -20000
+    maximum: 20000
+    description:
+      A signed offset, in millicelsius, applied to the TEMPMON
+      sensor reading to correct it toward the theoretical SoC
+      junction temperature. The offset is determined through
+      thermal characterization by comparing the sensor output
+      against the calculated junction temperature. The range is
+      limited to ±20 °C. When absent, no offset is applied.
+
   "#thermal-sensor-cells":
     const: 0
 
@@ -109,6 +120,7 @@ examples:
             nvmem-cells = <&tempmon_calib>, <&tempmon_temp_grade>;
             nvmem-cell-names = "calib", "temp_grade";
             clocks = <&clks IMX6SX_CLK_PLL3_USB_OTG>;
+            fsl,temp-calibration-offset-millicelsius = <(-6400)>;
             #thermal-sensor-cells = <0>;
         };
     };

-- 
2.43.0

