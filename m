From: Haoning CHENG <Haoning.CHENG@cn.bosch.com>
Date: Fri, 17 Jul 2026 14:35:35 +0800
Subject: [PATCH v9 1/3] dt-bindings: thermal: imx: Document temperature
 offset property
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260717-b4-symana21-11221-imx-thermal-support-upstream-6-18-v9-1-75f4af8974f4@cn.bosch.com>
References: <20260717-b4-symana21-11221-imx-thermal-support-upstream-6-18-v9-0-75f4af8974f4@cn.bosch.com>
In-Reply-To: <20260717-b4-symana21-11221-imx-thermal-support-upstream-6-18-v9-0-75f4af8974f4@cn.bosch.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784270138; l=2298;
 i=Haoning.CHENG@cn.bosch.com; s=20260709; h=from:subject:message-id;
 bh=PV3MnYc2Hk8Iy2pB7or+nfukgwcqkNEuWR6y8WvDrsg=;
 b=iqEwDbHQhnAlfvKPaj9J/P38F7tJfNrV2zE5yTWKDwZDOJxpYd9wBgWzq/p8SML8/m/gGyylp
 afNnUnhea7XC3vT8p7oRJJ9XUrg7dwk/kR3Xs20W9kE81E2U3Q5WMjI
X-Developer-Key: i=Haoning.CHENG@cn.bosch.com; a=ed25519;
 pk=glQGwad/fosRS5gZUJYbLDPPLGe7rFTrTV2VxY/ySdc=
X-Endpoint-Received: by B4 Relay for Haoning.CHENG@cn.bosch.com/20260709 with auth_id=860
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Some boards need the reported temperature to reflect the SoC
package-surface temperature rather than the internal die temperature.

Document the optional fsl,temp-calibration-offset-millicelsius property,
a signed offset in millicelsius applied to the internally measured
temperature to make it better correspond to the package-surface
temperature. The offset is board-specific and is determined through
thermal characterization. When absent, the offset is zero.

Reviewed-by: Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>
Reviewed-by: Lukasz Luba <lukasz.luba@arm.com>
Signed-off-by: Haoning CHENG <Haoning.CHENG@cn.bosch.com>
---
 .../devicetree/bindings/thermal/imx-thermal.yaml          | 15 +++++++++++++++
 1 file changed, 15 insertions(+)

diff --git a/Documentation/devicetree/bindings/thermal/imx-thermal.yaml b/Documentation/devicetree/bindings/thermal/imx-thermal.yaml
index 949b154856c5..6c268d56291b 100644
--- a/Documentation/devicetree/bindings/thermal/imx-thermal.yaml
+++ b/Documentation/devicetree/bindings/thermal/imx-thermal.yaml
@@ -59,6 +59,20 @@ properties:
   clocks:
     maxItems: 1
 
+  fsl,temp-calibration-offset-millicelsius:
+    minimum: -20000
+    maximum: 20000
+    description:
+      A signed offset, in millicelsius, added to the calculated
+      sensor temperature to make the TEMPMON reading better correspond
+      to the SoC package-surface temperature observed during board-level
+      thermal characterization. This is not a sensor calibration offset;
+      it is a board-specific conversion offset derived from the
+      relationship between the internal sensor reading and the
+      package-surface temperature, which depends on the package, PCB
+      layout, cooling arrangement, and operating environment. The range
+      is limited to ±20 °C. When absent, no offset is applied.
+
   "#thermal-sensor-cells":
     const: 0
 
@@ -109,6 +123,7 @@ examples:
             nvmem-cells = <&tempmon_calib>, <&tempmon_temp_grade>;
             nvmem-cell-names = "calib", "temp_grade";
             clocks = <&clks IMX6SX_CLK_PLL3_USB_OTG>;
+            fsl,temp-calibration-offset-millicelsius = <(-6400)>;
             #thermal-sensor-cells = <0>;
         };
     };

-- 
2.43.0

