From: =?utf-8?q?Y=C4=B0=C4=9E=C4=B0TCAN_KAVAKLI?= <kavakliyigitcan@gmail.com>
Date: Fri, 11 Sep 2026 11:50:58 +0300
Subject: [PATCH RFC 01/10] dt-bindings: backlight: add Kinetic KTD3136
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260911-ginkgo-submission-final-v1-1-0e68e63a18d4@gmail.com>
References: <20260911-ginkgo-submission-final-v1-0-0e68e63a18d4@gmail.com>
In-Reply-To: <20260911-ginkgo-submission-final-v1-0-0e68e63a18d4@gmail.com>
To: Lee Jones <lee@kernel.org>, Daniel Thompson <danielt@kernel.org>, 
 Jingoo Han <jingoohan1@gmail.com>, Pavel Machek <pavel@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Helge Deller <deller@gmx.de>, 
 Liam Girdwood <lgirdwood@gmail.com>, Mark Brown <broonie@kernel.org>, 
 Sumit Semwal <sumit.semwal@linaro.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Jessica Zhang <jesszhan0024@gmail.com>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Dmitry Torokhov <dmitry.torokhov@gmail.com>, 
 Henrik Rydberg <rydberg@bitmath.org>, 
 Rob Clark <robin.clark@oss.qualcomm.com>, 
 Dmitry Baryshkov <lumag@kernel.org>, 
 Abhinav Kumar <abhinav.kumar@linux.dev>, Sean Paul <sean@poorly.run>, 
 Marijn Suijten <marijn.suijten@somainline.org>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>
Cc: dri-devel@lists.freedesktop.org, linux-leds@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-fbdev@vger.kernel.org, linux-input@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, freedreno@lists.freedesktop.org, 
 =?utf-8?q?Y=C4=B0=C4=9E=C4=B0TCAN_KAVAKLI?= <kavakliyigitcan@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789116671; l=2380;
 i=kavakliyigitcan@gmail.com; s=20260911; h=from:subject:message-id;
 bh=1qOWka2RqpGg1tbdhR9VbVnp2Dr9kAnrMfXquGM3d6U=;
 b=tPsC38NGiMj10cf2MHZTTpvh8GU5kjYbScAMNbDcYn3V2e+KSk4lCvwoX6GGsgBKF0/jvxY1j
 92U/sQgU3zNC9FOygauFmLnU35Ax7LZfLjiF0lcSDwfW4mxZjFKgCHj
X-Developer-Key: i=kavakliyigitcan@gmail.com; a=ed25519;
 pk=W2GaxVotULs2vAjRMMLheaDtMMYs4037zO1LVVfFtPI=
X-Endpoint-Received: by B4 Relay for kavakliyigitcan@gmail.com/20260911 with auth_id=1024
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add devicetree binding documentation for the Kinetic Technologies
KTD3136 3-channel LED backlight driver using the official "kinetic"
vendor prefix.

The device is controlled over I2C and supports an optional hardware
enable GPIO line (enable-gpios), supply regulators, and standard
backlight brightness range properties.

Signed-off-by: YİĞİTCAN KAVAKLI <kavakliyigitcan@gmail.com>
---
 .../bindings/leds/backlight/kinetic,ktd3136.yaml   | 65 ++++++++++++++++++++++
 1 file changed, 65 insertions(+)

diff --git a/Documentation/devicetree/bindings/leds/backlight/kinetic,ktd3136.yaml b/Documentation/devicetree/bindings/leds/backlight/kinetic,ktd3136.yaml
new file mode 100644
index 0000000000000000000000000000000000000000..f85381c29964529a09989a1ff60d9c9fe4897bb7
--- /dev/null
+++ b/Documentation/devicetree/bindings/leds/backlight/kinetic,ktd3136.yaml
@@ -0,0 +1,65 @@
+# SPDX-License-Identifier: (GPL-2.0 OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/leds/backlight/kinetic,ktd3136.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: Kinetic Technologies KTD3136 3-Channel LED Backlight Driver
+
+maintainers:
+  - Lee Jones <lee@kernel.org>
+
+description: |
+  The Kinetic Technologies KTD3136 is a high efficiency, 3-channel LED
+  backlight driver with 11-bit exponential or linear dimming control
+  via I2C interface.
+
+allOf:
+  - $ref: common.yaml#
+
+properties:
+  compatible:
+    const: kinetic,ktd3136
+
+  reg:
+    maxItems: 1
+
+  enable-gpios:
+    description: GPIO connected to the HWEN (Chip Enable) pin.
+    maxItems: 1
+
+  vin-supply:
+    description: Regulator providing power to the VIN pin.
+
+  default-brightness:
+    minimum: 0
+    maximum: 2047
+    default: 2047
+
+  max-brightness:
+    minimum: 0
+    maximum: 2047
+    default: 2047
+
+required:
+  - compatible
+  - reg
+
+additionalProperties: false
+
+examples:
+  - |
+    #include <dt-bindings/gpio/gpio.h>
+
+    i2c {
+        #address-cells = <1>;
+        #size-cells = <0>;
+
+        backlight@36 {
+            compatible = "kinetic,ktd3136";
+            reg = <0x36>;
+            enable-gpios = <&gpio 6 GPIO_ACTIVE_HIGH>;
+            default-brightness = <2047>;
+            max-brightness = <2047>;
+        };
+    };

-- 
2.47.3

