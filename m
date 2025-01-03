From: PavithraUdayakumar-adi <pavithra.u@analog.com>
Date: Fri, 03 Jan 2025 12:34:19 +0530
Subject: [PATCH v2 1/2] dtbindings:rtc:max31335:Add max31331 support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250103-add_support_max31331_fix-v1-1-8ff3c7a81734@analog.com>
References: <20250103-add_support_max31331_fix-v1-0-8ff3c7a81734@analog.com>
In-Reply-To: <20250103-add_support_max31331_fix-v1-0-8ff3c7a81734@analog.com>
To: Antoniu Miclaus <antoniu.miclaus@analog.com>, 
 Alexandre Belloni <alexandre.belloni@bootlin.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Jean Delvare <jdelvare@suse.com>, 
 Guenter Roeck <linux@roeck-us.net>
Cc: linux-rtc@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-hwmon@vger.kernel.org, 
 PavithraUdayakumar-adi <pavithra.u@analog.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1735887863; l=1825;
 i=pavithra.u@analog.com; s=20241220; h=from:subject:message-id;
 bh=SV+d5UQrPERXNNuAfmb0jc/f8Kg97z5CNfrIJM6WaU0=;
 b=jKZKwRwrfwRQfOulh/SzXa4ZTW/bP9nBhYN3nM1L5AwcNF/YIgnZiWYz57BDM2g3GYlJx4yCn
 YpxUaoKnYL7CF+5B4HVRA4TDwUQYngkb7S22PO/bC97ZyLrwm25g8jk
X-Developer-Key: i=pavithra.u@analog.com; a=ed25519;
 pk=RIhZrdpg71GEnmwm1eNn95TYUMDJOKVsFd37Fv8xf1U=
X-Endpoint-Received: by B4 Relay for pavithra.u@analog.com/20241220 with auth_id=303
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add support to max31331 RTC chip in adi,max31335.yaml

Signed-off-by: PavithraUdayakumar-adi <pavithra.u@analog.com>
---
 .../devicetree/bindings/rtc/adi,max31335.yaml      | 32 ++++++++++++++++++----
 1 file changed, 26 insertions(+), 6 deletions(-)

diff --git a/Documentation/devicetree/bindings/rtc/adi,max31335.yaml b/Documentation/devicetree/bindings/rtc/adi,max31335.yaml
index 0125cf6727cc3d9eb3e0253299904ee363ec40ca..6953553d98afd42ed9b79bac476657ffc8ec9210 100644
--- a/Documentation/devicetree/bindings/rtc/adi,max31335.yaml
+++ b/Documentation/devicetree/bindings/rtc/adi,max31335.yaml
@@ -13,15 +13,15 @@ description:
   Analog Devices MAX31335 I2C RTC ±2ppm Automotive Real-Time Clock with
   Integrated MEMS Resonator.
 
-allOf:
-  - $ref: rtc.yaml#
-
 properties:
   compatible:
-    const: adi,max31335
+    enum:
+      - adi,max31331
+      - adi,max31335
 
   reg:
-    maxItems: 1
+    items:
+      - enum: [0x68, 0x69]
 
   interrupts:
     maxItems: 1
@@ -50,6 +50,26 @@ required:
 
 unevaluatedProperties: false
 
+allOf:
+  - $ref: rtc.yaml#
+
+  - if:
+      properties:
+        compatible:
+          contains:
+            enum:
+              - adi,max31335
+    then:
+      properties:
+        reg:
+          items:
+            - const: 0x69
+    else:
+      properties:
+        reg:
+          items:
+            - const: 0x68
+
 examples:
   - |
     #include <dt-bindings/interrupt-controller/irq.h>
@@ -58,7 +78,7 @@ examples:
         #size-cells = <0>;
 
         rtc@68 {
-            compatible = "adi,max31335";
+            compatible = "adi,max31331";
             reg = <0x68>;
             pinctrl-0 = <&rtc_nint_pins>;
             interrupts-extended = <&gpio1 16 IRQ_TYPE_LEVEL_HIGH>;

-- 
2.25.1

