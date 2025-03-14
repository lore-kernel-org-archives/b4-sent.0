From: David Heidelberg <david@ixit.cz>
Date: Fri, 14 Mar 2025 20:58:27 +0100
Subject: [PATCH v2] media: dt-bindings: Convert Analog Devices ad5820 to DT
 schema
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250314-b4-ad5820-dt-yaml-v2-1-287958c3c07c@ixit.cz>
X-B4-Tracking: v=1; b=H4sIAGKK1GcC/yWNQQqDMBBFryKz7shkjKBd9R7FRTRJHWi1JCJay
 d2b2uV78N8/ILogLsK1OCC4VaLMUwa+FDCMZno4FJsZmLimSmnsNRpbN0xoF9zN64kVM/WevXK
 aIO/ewXnZzua9yzxKXOawnxer+tl/jallqlpNpapbahpUaM0q9iabLOXwgS6l9AX/gf3DoQAAA
 A==
X-Change-ID: 20250314-b4-ad5820-dt-yaml-3220bf2f1e40
To: Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Pavel Machek <pavel@kernel.org>, 
 Sakari Ailus <sakari.ailus@linux.intel.com>
Cc: Pavel Machek <pavel@ucw.cz>, linux-media@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=4138; i=david@ixit.cz;
 h=from:subject:message-id; bh=z81Yqbut3SZDaJXDHotF1NCKDbHx0Fdm/k4FGFc127s=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBn1Ipm2nYSDpgV9ujf/RnKXz3/hUx5ecREWpynY
 I6pg8cGtIuJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCZ9SKZgAKCRBgAj/E00kg
 cspeD/97vOwKteluX4cjW3PO5WfeMenU4W3nCdvvBfjJYetpVEXUBfqy+pb13vHSDZezopxd39O
 lT5CeFtteh1dzlf7j6IXSlEOtJUuSSjL3p/2/C3JAYTbk+UNss1mDR/YPbZyLC6LEo2U18235BF
 wRv2FIz4G1E9i1nZ3yDKT1iB7im8nwkfK678qxZAK0VgSw/+D8dhh6SQcniok376fhYEceHG9fM
 K7tlXovESZbxepoKFnprKWi8K8XlfSV75ZTESFMg6wW1L+IP6mlwducL/dIFLy316qj2qeukjfs
 fW1TUQXPy/VZlPhOH291QTec+xsjqnchC9ytJU/nfJs+Je1bFMJUs5xk0J88kwMsXFX9PmD9BDJ
 5U686vtu3Q8/j1Ov8xXSUzW0EgSjRs//Hzlv4bRZQ/SD6nT8ryRFVVOrH81IG6kYwGL56HAIrBH
 pRKQjlhjiED7/+t3ugzLzE3NWR5PHddngCXyiEIb6wuoYLWvslVinPmhTxs9l/7GKH9EjCoW3qF
 CxrDRcn5BptiwvxG7XwpdT8/J2FHXjUxyWoW4yXzC0BJR/2k2czk6VSk+i7U7SHM75+7M2V9u9v
 bh+ZMa/24sKynJHxElKEU5PYyXAAYiOe9+wzvFnKJ3kUAsrOXNW/VR6/FpeAZ0VH9Y1ka/7NLor
 p9YDZoD7nz2eudw==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Convert the Analog Devices ad5820 to DT schema format.

Add the previously undocumented io-channel-cells property,
which can be omitted. If present, it must be set to 0,
as the device provides only one channel.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
Changes in v2:
- added MAINTAINERS entry for the binding
- documented why io-channel-cells got added into the binding.
- dropped io-channel-cells in required properties.
- adjusted example indentation to 4 spaces.
- Link to v1: https://lore.kernel.org/r/20250209203940.159088-1-david@ixit.cz
---
 .../devicetree/bindings/media/i2c/ad5820.txt       | 28 ----------
 .../devicetree/bindings/media/i2c/adi,ad5820.yaml  | 59 ++++++++++++++++++++++
 MAINTAINERS                                        |  1 +
 3 files changed, 60 insertions(+), 28 deletions(-)

diff --git a/Documentation/devicetree/bindings/media/i2c/ad5820.txt b/Documentation/devicetree/bindings/media/i2c/ad5820.txt
deleted file mode 100644
index 5764cbedf9b73387ad1bfa9acf99c643f959b84a..0000000000000000000000000000000000000000
--- a/Documentation/devicetree/bindings/media/i2c/ad5820.txt
+++ /dev/null
@@ -1,28 +0,0 @@
-* Analog Devices AD5820 autofocus coil
-
-Required Properties:
-
-  - compatible: Must contain one of:
-		- "adi,ad5820"
-		- "adi,ad5821"
-		- "adi,ad5823"
-
-  - reg: I2C slave address
-
-  - VANA-supply: supply of voltage for VANA pin
-
-Optional properties:
-
-   - enable-gpios : GPIO spec for the XSHUTDOWN pin. The XSHUTDOWN signal is
-active low, a high level on the pin enables the device.
-
-Example:
-
-       ad5820: coil@c {
-               compatible = "adi,ad5820";
-               reg = <0x0c>;
-
-               VANA-supply = <&vaux4>;
-               enable-gpios = <&msmgpio 26 GPIO_ACTIVE_HIGH>;
-       };
-
diff --git a/Documentation/devicetree/bindings/media/i2c/adi,ad5820.yaml b/Documentation/devicetree/bindings/media/i2c/adi,ad5820.yaml
new file mode 100644
index 0000000000000000000000000000000000000000..7967b8dcd77a2171074829625d71dbb53a80fbc6
--- /dev/null
+++ b/Documentation/devicetree/bindings/media/i2c/adi,ad5820.yaml
@@ -0,0 +1,59 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/media/i2c/adi,ad5820.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: Analog Devices AD5820 autofocus coil
+
+maintainers:
+  - Pavel Machek <pavel@ucw.cz>
+
+description:
+  The AD5820 is a current sink driver designed for precise control of
+  voice coil motors (VCMs) in camera autofocus systems.
+
+properties:
+  compatible:
+    enum:
+      - adi,ad5820
+      - adi,ad5821
+      - adi,ad5823
+
+  reg:
+    maxItems: 1
+
+  enable-gpios:
+    maxItems: 1
+    description:
+      GPIO spec for the XSHUTDOWN pin. The XSHUTDOWN signal is active low,
+      a high level on the pin enables the device.
+
+  VANA-supply:
+    description: supply of voltage for VANA pin
+
+  '#io-channel-cells':
+    const: 0
+
+required:
+  - compatible
+  - reg
+  - VANA-supply
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
+        coil@c {
+            compatible = "adi,ad5820";
+            reg = <0x0c>;
+
+            enable-gpios = <&msmgpio 26 GPIO_ACTIVE_HIGH>;
+            VANA-supply = <&vaux4>;
+        };
+    };
diff --git a/MAINTAINERS b/MAINTAINERS
index e4b6545aab3ec75f92c0daaabe2fc1bb1d483969..238c00d3abe2f53ea7b7e6ba265d560ad5c3fe86 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -17073,6 +17073,7 @@ M:	Pavel Machek <pavel@kernel.org>
 M:	Sakari Ailus <sakari.ailus@iki.fi>
 L:	linux-media@vger.kernel.org
 S:	Maintained
+F:	Documentation/devicetree/bindings/media/i2c/adi,ad5820.yaml
 F:	drivers/media/i2c/ad5820.c
 F:	drivers/media/i2c/et8ek8
 

---
base-commit: da920b7df701770e006928053672147075587fb2
change-id: 20250314-b4-ad5820-dt-yaml-3220bf2f1e40

Best regards,
-- 
David Heidelberg <david@ixit.cz>

