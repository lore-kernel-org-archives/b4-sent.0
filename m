From: PavithraUdayakumar-adi <pavithra.u@analog.com>
Date: Mon, 23 Dec 2024 11:57:44 +0530
Subject: [PATCH 1/2] dtbindings:rtc:max31335:Add max31331 support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20241223-max31331-driver-support-v1-1-f9499bd598f5@analog.com>
References: <20241223-max31331-driver-support-v1-0-f9499bd598f5@analog.com>
In-Reply-To: <20241223-max31331-driver-support-v1-0-f9499bd598f5@analog.com>
To: Antoniu Miclaus <antoniu.miclaus@analog.com>, 
 Alexandre Belloni <alexandre.belloni@bootlin.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Jean Delvare <jdelvare@suse.com>, 
 Guenter Roeck <linux@roeck-us.net>
Cc: linux-rtc@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-hwmon@vger.kernel.org, 
 PavithraUdayakumar-adi <pavithra.u@analog.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1734935277; l=1825;
 i=pavithra.u@analog.com; s=20241220; h=from:subject:message-id;
 bh=mTwNwMEdUX2ezuu+9NDkzYCZ9EeOKu6++/AuTgXj4JE=;
 b=LLD4gNlg5/48BU0ZB3+vRs7+dccaSP4Nnfm/huC+YiIchIKvti/7UGnAqfoIKC1X/eVzYfb7T
 dHYS7JD63s8CyWlt44IvYSnHvnm1OwGi7JcaypGJBRobXGyiV05+gTf
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
index 0125cf6727cc3d9eb3e0253299904ee363ec40ca..2379600911304e995086de6393fae1fd24f5c653 100644
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
@@ -59,7 +79,7 @@ examples:
 
         rtc@68 {
             compatible = "adi,max31335";
-            reg = <0x68>;
+            reg = <0x69>;
             pinctrl-0 = <&rtc_nint_pins>;
             interrupts-extended = <&gpio1 16 IRQ_TYPE_LEVEL_HIGH>;
             aux-voltage-chargeable = <1>;

-- 
2.25.1

