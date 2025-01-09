From: PavithraUdayakumar-adi <pavithra.u@analog.com>
Date: Thu, 09 Jan 2025 15:59:57 +0530
Subject: [PATCH v3 1/2] dt-bindings: rtc: max31335: Add max31331 support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250109-add_support_max31331_fix_3-v1-1-a74fac29bf49@analog.com>
References: <20250109-add_support_max31331_fix_3-v1-0-a74fac29bf49@analog.com>
In-Reply-To: <20250109-add_support_max31331_fix_3-v1-0-a74fac29bf49@analog.com>
To: Antoniu Miclaus <antoniu.miclaus@analog.com>, 
 Alexandre Belloni <alexandre.belloni@bootlin.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Jean Delvare <jdelvare@suse.com>, 
 Guenter Roeck <linux@roeck-us.net>, 
 Christophe JAILLET <christophe.jaillet@wanadoo.fr>
Cc: linux-rtc@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-hwmon@vger.kernel.org, 
 PavithraUdayakumar-adi <pavithra.u@analog.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1736418610; l=1896;
 i=pavithra.u@analog.com; s=20241220; h=from:subject:message-id;
 bh=CSTscMKCGJQV0sJTo05LWTvBCwbI5QwOv/6bQjL/k98=;
 b=MVUREwDDBzAEkOP2qrqKCJPk/uE6DnHkF4z6YLsKaq6Z+Jgqphj2k94/7x4dqdB5PEK2kYBk6
 ZhfmV5059f4BbPHp4rZH9u3clqzeSOtNkOz5b7N0aQDwB+4Mu9NRLmY
X-Developer-Key: i=pavithra.u@analog.com; a=ed25519;
 pk=RIhZrdpg71GEnmwm1eNn95TYUMDJOKVsFd37Fv8xf1U=
X-Endpoint-Received: by B4 Relay for pavithra.u@analog.com/20241220 with auth_id=303
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

MAX31331 is an ultra-low-power, I2C Real-Time Clock RTC with flexible
crystal support. While, MAX31335 offers higher precision, MEMS resonator,
and integrated temperature sensor. MAX31331 uses I2C address as 0x68
where as max31335 uses 0x69.

Changes: Added example for max31331 and modified the register address
for max31335.

Signed-off-by: PavithraUdayakumar-adi <pavithra.u@analog.com>
---
 .../devicetree/bindings/rtc/adi,max31335.yaml      | 22 ++++++++++++++++++----
 1 file changed, 18 insertions(+), 4 deletions(-)

diff --git a/Documentation/devicetree/bindings/rtc/adi,max31335.yaml b/Documentation/devicetree/bindings/rtc/adi,max31335.yaml
index 0125cf6727cc3d9eb3e0253299904ee363ec40ca..f249313bc485d7a6154ce684726d6a950405ef0e 100644
--- a/Documentation/devicetree/bindings/rtc/adi,max31335.yaml
+++ b/Documentation/devicetree/bindings/rtc/adi,max31335.yaml
@@ -18,10 +18,13 @@ allOf:
 
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
@@ -57,9 +60,9 @@ examples:
         #address-cells = <1>;
         #size-cells = <0>;
 
-        rtc@68 {
+        rtc@69 {
             compatible = "adi,max31335";
-            reg = <0x68>;
+            reg = <0x69>;
             pinctrl-0 = <&rtc_nint_pins>;
             interrupts-extended = <&gpio1 16 IRQ_TYPE_LEVEL_HIGH>;
             aux-voltage-chargeable = <1>;
@@ -67,4 +70,15 @@ examples:
             adi,tc-diode = "schottky";
         };
     };
+  - |
+    #include <dt-bindings/interrupt-controller/irq.h>
+    i2c {
+        #address-cells = <1>;
+        #size-cells = <0>;
+
+        rtc@68 {
+            reg = <0x68>;
+            compatible = "adi,max31331";
+        };
+    };
 ...

-- 
2.25.1

