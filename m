From: Rudraksha Gupta <guptarud@gmail.com>
Date: Fri, 06 Mar 2026 16:58:02 -0800
Subject: [PATCH 1/3] dt-bindings: leds: rt8515: Support single-GPIO flash
 ICs with unlock gate
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260306-expressatt_camera_flash-v1-1-b1996f7cdfdd@gmail.com>
References: <20260306-expressatt_camera_flash-v1-0-b1996f7cdfdd@gmail.com>
In-Reply-To: <20260306-expressatt_camera_flash-v1-0-b1996f7cdfdd@gmail.com>
To: Lee Jones <lee@kernel.org>, Pavel Machek <pavel@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Linus Walleij <linusw@kernel.org>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>
Cc: linux-leds@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 Rudraksha Gupta <guptarud@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1772845083; l=2686;
 i=guptarud@gmail.com; s=20240916; h=from:subject:message-id;
 bh=XkKexDy/wzuB27iB2DnLFEzKOovyf++JmlP+fQT4Q6o=;
 b=he6Q2vN99zHB/nJKmrP5qVDhXsKuAugWXRoYsVze3J2hDLS/1EGDegxeETpbLfSdCc+i4D8XY
 PVNa65EVPyMCnkBk9e5dqxgRft8bIKI1MvtPOQ5pHGJcJtxpHI7rYic
X-Developer-Key: i=guptarud@gmail.com; a=ed25519;
 pk=ETrudRugWAtOpr0OhRiheQ1lXM4Kk4KGFnBySlKDi2I=
X-Endpoint-Received: by B4 Relay for guptarud@gmail.com/20240916 with auth_id=211
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Some flash ICs use the same one-wire pulse-count protocol as the RT8515
but have only a single GPIO line for both flash and torch modes, plus an
optional unlock gate (e.g. a PMIC MPP) that must be driven high before
the chip responds to the enable GPIO.

Make ent-gpios optional and add an unlock-gpios property to support
these variants. Add a oneOf constraint requiring exactly one of
ent-gpios or unlock-gpios. Add a binding example showing the
single-GPIO configuration.

Signed-off-by: Rudraksha Gupta <guptarud@gmail.com>
---
 .../devicetree/bindings/leds/richtek,rt8515.yaml   | 36 +++++++++++++++++++++-
 1 file changed, 35 insertions(+), 1 deletion(-)

diff --git a/Documentation/devicetree/bindings/leds/richtek,rt8515.yaml b/Documentation/devicetree/bindings/leds/richtek,rt8515.yaml
index 0356371a6b01..820cf8c55090 100644
--- a/Documentation/devicetree/bindings/leds/richtek,rt8515.yaml
+++ b/Documentation/devicetree/bindings/leds/richtek,rt8515.yaml
@@ -15,6 +15,10 @@ description: |
   current for each mode is defined in hardware using two resistors
   RFS and RTS.
 
+  This driver also supports single-GPIO flash ICs that use the same
+  one-wire pulse-count protocol on one line for both flash and torch.
+  For these, only enf-gpios is required.
+
 properties:
   compatible:
     const: richtek,rt8515
@@ -26,6 +30,14 @@ properties:
   ent-gpios:
     maxItems: 1
     description: A connection to the 'ENT' (enable torch) pin.
+      Optional for single-GPIO flash ICs where enf-gpios is used for
+      both flash and torch modes.
+
+  unlock-gpios:
+    maxItems: 1
+    description: Optional GPIO to unlock the flash LED circuit. Some
+      boards use a PMIC MPP pin that must be driven high before the
+      flash IC will respond to the enable GPIOs.
 
   richtek,rfs-ohms:
     minimum: 7680
@@ -81,10 +93,15 @@ properties:
 
 required:
   - compatible
-  - ent-gpios
   - enf-gpios
   - led
 
+oneOf:
+  - required:
+      - ent-gpios
+  - required:
+      - unlock-gpios
+
 additionalProperties: false
 
 examples:
@@ -108,4 +125,21 @@ examples:
         };
     };
 
+  - |
+    /* Single-GPIO flash IC with unlock gate */
+    #include <dt-bindings/gpio/gpio.h>
+    #include <dt-bindings/leds/common.h>
+
+    led-controller {
+        compatible = "richtek,rt8515";
+        enf-gpios = <&tlmm 3 GPIO_ACTIVE_HIGH>;
+        unlock-gpios = <&pm8921_mpps 4 GPIO_ACTIVE_HIGH>;
+
+        led {
+            function = LED_FUNCTION_FLASH;
+            color = <LED_COLOR_ID_WHITE>;
+            flash-max-timeout-us = <250000>;
+        };
+    };
+
 ...

-- 
2.53.0

