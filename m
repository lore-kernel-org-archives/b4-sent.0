From: Michael Reeves <michael.reeves077@gmail.com>
Date: Tue, 30 Jun 2026 22:54:32 +1000
Subject: [PATCH 04/10] dt-bindings: input: apple: Add DockChannel HID
 transport
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260630-apple-mtp-keyboard-final-v1-4-506d936a1707@gmail.com>
References: <20260630-apple-mtp-keyboard-final-v1-0-506d936a1707@gmail.com>
In-Reply-To: <20260630-apple-mtp-keyboard-final-v1-0-506d936a1707@gmail.com>
To: Sven Peter <sven@kernel.org>, Janne Grunau <j@jannau.net>, 
 Neal Gompa <neal@gompa.dev>, Jassi Brar <jassisinghbrar@gmail.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Hector Martin <marcan@marcan.st>, 
 "Joerg Roedel (AMD)" <joro@8bytes.org>, Will Deacon <will@kernel.org>, 
 Robin Murphy <robin.murphy@arm.com>, 
 Dmitry Torokhov <dmitry.torokhov@gmail.com>, Jiri Kosina <jikos@kernel.org>, 
 Benjamin Tissoires <bentiss@kernel.org>
Cc: asahi@lists.linux.dev, linux-arm-kernel@lists.infradead.org, 
 linux-kernel@vger.kernel.org, devicetree@vger.kernel.org, 
 iommu@lists.linux.dev, linux-input@vger.kernel.org, 
 Michael Reeves <michael.reeves077@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1782824083; l=3901;
 i=michael.reeves077@gmail.com; s=20260105; h=from:subject:message-id;
 bh=S+mJ7/0W8yggglspV7mBGvZpocgLQ5/14vlk/i1q+EE=;
 b=kvnAjnNdsJMkbhDfx6ggwVclKX6UNdtvslL6PgSX5VfGVa+W8FQ7uZQuvrQ1zINfACt6W6h3V
 iukHyN9YO1BCIuVAMwl8S5q+rX7wb4xI0Gj4oggqMX5z4yJZxKtSMB+
X-Developer-Key: i=michael.reeves077@gmail.com; a=ed25519;
 pk=QIrgWBGCm3LG0YYc6MLCDkwuVXLTGGooVBdWX/KhSiU=
X-Endpoint-Received: by B4 Relay for michael.reeves077@gmail.com/20260105 with auth_id=591
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Apple internal keyboards and trackpads behind MTP are exposed through a
DockChannel HID transport.

Add the client binding tying together the RTKit ASC mailbox,
DockChannel mailbox, and MTP DART. The keyboard child can provide the
HID country code used by hid-apple to distinguish layout variants.

Signed-off-by: Michael Reeves <michael.reeves077@gmail.com>
---
 .../bindings/input/apple,dockchannel-hid.yaml      | 91 ++++++++++++++++++++++
 MAINTAINERS                                        |  1 +
 2 files changed, 92 insertions(+)

diff --git a/Documentation/devicetree/bindings/input/apple,dockchannel-hid.yaml b/Documentation/devicetree/bindings/input/apple,dockchannel-hid.yaml
new file mode 100644
index 000000000000..dbba4fc38971
--- /dev/null
+++ b/Documentation/devicetree/bindings/input/apple,dockchannel-hid.yaml
@@ -0,0 +1,91 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/input/apple,dockchannel-hid.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: Apple DockChannel HID Transport
+
+maintainers:
+  - Michael Reeves <michael.reeves077@gmail.com>
+
+description:
+  HID transport for keyboard and trackpad devices connected via the
+  DockChannel FIFO mailbox on Apple Silicon SoCs. The endpoint includes a
+  small RTKit coprocessor called MTP which must be booted before the HID
+  transport becomes available.
+
+properties:
+  compatible:
+    oneOf:
+      - items:
+          - const: apple,t8112-dockchannel-hid
+      - items:
+          - enum:
+              - apple,t6020-dockchannel-hid
+              - apple,t8122-dockchannel-hid
+          - const: apple,t8112-dockchannel-hid
+
+  reg:
+    items:
+      - description: Coprocessor ASC registers
+      - description: Coprocessor SRAM/mailbox registers
+
+  reg-names:
+    items:
+      - const: coproc-asc
+      - const: coproc-sram
+
+  mboxes:
+    items:
+      - description: ASC mailbox used for RTKit control
+      - description: DockChannel FIFO mailbox used for HID packets
+
+  mbox-names:
+    items:
+      - const: asc
+      - const: dockchannel
+
+  iommus:
+    maxItems: 1
+
+  keyboard:
+    type: object
+    properties:
+      hid-country-code:
+        $ref: /schemas/types.yaml#/definitions/uint32
+        description:
+          HID country code for the keyboard layout variant.
+
+    additionalProperties: false
+
+required:
+  - compatible
+  - reg
+  - reg-names
+  - mboxes
+  - mbox-names
+  - iommus
+
+additionalProperties: false
+
+examples:
+  - |
+    soc {
+        #address-cells = <2>;
+        #size-cells = <2>;
+
+        hid@24e400000 {
+            compatible = "apple,t8112-dockchannel-hid";
+            reg = <0x2 0x4e400000 0x0 0x4000>,
+                  <0x2 0x4ec00000 0x0 0x100000>;
+            reg-names = "coproc-asc", "coproc-sram";
+            mboxes = <&mtp_mbox>, <&mtp_dockchannel>;
+            mbox-names = "asc", "dockchannel";
+            iommus = <&mtp_dart 1>;
+
+            keyboard {
+                hid-country-code = <0>;
+            };
+        };
+    };
diff --git a/MAINTAINERS b/MAINTAINERS
index 741974f0f326..1f3c2cdb6e19 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -2589,6 +2589,7 @@ F:	Documentation/devicetree/bindings/gpio/apple,smc-gpio.yaml
 F:	Documentation/devicetree/bindings/gpu/apple,agx.yaml
 F:	Documentation/devicetree/bindings/hwmon/apple,smc-hwmon.yaml
 F:	Documentation/devicetree/bindings/i2c/apple,i2c.yaml
+F:	Documentation/devicetree/bindings/input/apple,dockchannel-hid.yaml
 F:	Documentation/devicetree/bindings/input/touchscreen/apple,z2-multitouch.yaml
 F:	Documentation/devicetree/bindings/interrupt-controller/apple,*
 F:	Documentation/devicetree/bindings/iommu/apple,dart.yaml

-- 
2.51.2

