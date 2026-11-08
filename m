From: Michael Reeves <michael.reeves077@gmail.com>
Date: Sun, 08 Nov 2026 07:25:07 +0000
Subject: [PATCH v5 2/8] dt-bindings: input: apple: Add DockChannel HID
 transport
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261108-b4-apple-mtp-keyboard-v5-2-e2c97b82669a@gmail.com>
References: <20261108-b4-apple-mtp-keyboard-v5-0-e2c97b82669a@gmail.com>
In-Reply-To: <20261108-b4-apple-mtp-keyboard-v5-0-e2c97b82669a@gmail.com>
To: Sven Peter <sven@kernel.org>, Janne Grunau <j@jannau.net>, 
 Neal Gompa <neal@gompa.dev>, Jassi Brar <jassisinghbrar@gmail.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Dmitry Torokhov <dmitry.torokhov@gmail.com>, Jiri Kosina <jikos@kernel.org>, 
 Benjamin Tissoires <bentiss@kernel.org>, 
 Michael Reeves <michael.reeves077@gmail.com>
Cc: asahi@lists.linux.dev, linux-arm-kernel@lists.infradead.org, 
 linux-kernel@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-input@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794122710; l=4202;
 i=michael.reeves077@gmail.com; s=20261107; h=from:subject:message-id;
 bh=mRZFOVFEWZlmTQo/secoMGKBAQBA5BcBUwvtUqnYZBk=;
 b=ITnYdgO+IbIaCMxxcMeaaK554tNgPqysgmMp2QCn84oEvcQuCKtp0H1CWfaB/kb5SC1/oy0TC
 P06AnslxJ+kD+3TfvKznMIqnARnqz/Gl+9azSHX8pz1ffbGDiQMmoym
X-Developer-Key: i=michael.reeves077@gmail.com; a=ed25519;
 pk=ykwkLcuByJYb/cdLc2UuoYP03pIzwrscEZg30+4tJL8=
X-Endpoint-Received: by B4 Relay for michael.reeves077@gmail.com/20261107 with auth_id=1442
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Apple internal keyboards and trackpads behind MTP are exposed through a
DockChannel HID transport.

Describe the transport's mailboxes, DART, and input properties. An
optional apple,has-stm property indicates shared device identifiers and
serial numbers are detectable. hid-country-code specifies the keyboard
layout variant, which is filled by the bootloader, and is not prefixed
as it is a generic HID property.

Signed-off-by: Michael Reeves <michael.reeves077@gmail.com>
---
 .../input/apple,t8112-dockchannel-hid.yaml         | 92 ++++++++++++++++++++++
 MAINTAINERS                                        |  1 +
 2 files changed, 93 insertions(+)

diff --git a/Documentation/devicetree/bindings/input/apple,t8112-dockchannel-hid.yaml b/Documentation/devicetree/bindings/input/apple,t8112-dockchannel-hid.yaml
new file mode 100644
index 000000000000..55732cd59964
--- /dev/null
+++ b/Documentation/devicetree/bindings/input/apple,t8112-dockchannel-hid.yaml
@@ -0,0 +1,92 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/input/apple,t8112-dockchannel-hid.yaml#
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
+              - apple,t6030-dockchannel-hid
+              - apple,t6031-dockchannel-hid
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
+      - const: asc
+      - const: sram
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
+  apple,has-stm:
+    type: boolean
+    description:
+      Specifies that the coprocessor provides STM device and serial
+      number query endpoints that must be ready before registering HID devices.
+
+  hid-country-code:
+    $ref: /schemas/types.yaml#/definitions/uint32
+    description:
+      HID country code for the keyboard layout variant.
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
+            reg-names = "asc", "sram";
+            mboxes = <&mtp_mbox>, <&mtp_dockchannel>;
+            mbox-names = "asc", "dockchannel";
+            iommus = <&mtp_dart 1>;
+            apple,has-stm;
+            hid-country-code = <0>;
+        };
+    };
diff --git a/MAINTAINERS b/MAINTAINERS
index 0c1963150f04..41b12717c657 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -2714,6 +2714,7 @@ F:	Documentation/devicetree/bindings/gpio/apple,smc-gpio.yaml
 F:	Documentation/devicetree/bindings/gpu/apple,agx.yaml
 F:	Documentation/devicetree/bindings/hwmon/apple,smc-hwmon.yaml
 F:	Documentation/devicetree/bindings/i2c/apple,i2c.yaml
+F:	Documentation/devicetree/bindings/input/apple,t8112-dockchannel-hid.yaml
 F:	Documentation/devicetree/bindings/input/touchscreen/apple,z2-multitouch.yaml
 F:	Documentation/devicetree/bindings/interrupt-controller/apple,*
 F:	Documentation/devicetree/bindings/iommu/apple,dart.yaml

-- 
2.56.0

