From: Markus Probst <markus.probst@posteo.de>
Date: Fri, 13 Mar 2026 20:03:09 +0100
Subject: [PATCH v3 5/7] dt-bindings: mfd: Add synology,microp device
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260313-synology_microp_initial-v3-5-ad6ac463a201@posteo.de>
References: <20260313-synology_microp_initial-v3-0-ad6ac463a201@posteo.de>
In-Reply-To: <20260313-synology_microp_initial-v3-0-ad6ac463a201@posteo.de>
To: Lee Jones <lee@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Miguel Ojeda <ojeda@kernel.org>, Boqun Feng <boqun@kernel.org>, 
 Gary Guo <gary@garyguo.net>, 
 =?utf-8?q?Bj=C3=B6rn_Roy_Baron?= <bjorn3_gh@protonmail.com>, 
 Benno Lossin <lossin@kernel.org>, Andreas Hindborg <a.hindborg@kernel.org>, 
 Alice Ryhl <aliceryhl@google.com>, Trevor Gross <tmgross@umich.edu>, 
 Danilo Krummrich <dakr@kernel.org>, "Rafael J. Wysocki" <rafael@kernel.org>, 
 Igor Korotin <igor.korotin.linux@gmail.com>, 
 Daniel Almeida <daniel.almeida@collabora.com>, 
 Bjorn Helgaas <bhelgaas@google.com>, 
 =?utf-8?q?Krzysztof_Wilczy=C5=84ski?= <kwilczynski@kernel.org>, 
 Pavel Machek <pavel@kernel.org>, Len Brown <lenb@kernel.org>, 
 Robert Moore <robert.moore@intel.com>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 rust-for-linux@vger.kernel.org, driver-core@lists.linux.dev, 
 linux-pci@vger.kernel.org, linux-leds@vger.kernel.org, 
 linux-acpi@vger.kernel.org, acpica-devel@lists.linux.dev, 
 Markus Probst <markus.probst@posteo.de>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=3421;
 i=markus.probst@posteo.de; h=from:subject:message-id;
 bh=BWCjYQBHaSfDWg8Gx+1WSTdoVU+3MjA/rzyHsPChX7o=;
 b=owEBiQJ2/ZANAwAIATR2H/jnrUPSAcsmYgBptF95QKk57C5wGYpOrgF+665YuLzVFk9/o6152
 RHv7L3t4L+JAk8EAAEIADkWIQSCdBjE9KxY53IwxHM0dh/4561D0gUCabRfeRsUgAAAAAAEAA5t
 YW51MiwyLjUrMS4xMSwyLDIACgkQNHYf+OetQ9LkWQ/+I5FvYw6cc5ThLEBTFpIlGUb3vXxj0s5
 CMgyALXltBdsVCG2cfRtMB29vkjz+PvR6DyghJpfPk8T8gO6XZWmqEh4op9aX4e535Hz4UIEITw
 HMU2whDV/W88fVa9PFICGUOZPSqs44t5Mp3Hwb0OFeOyUdXZine/3B7uPy6X8zCzgj5aGklO8z9
 olqCaoOR98NeWTlu+MP1jj6nPeG6scgII52M7pmsb2cSV3AX2sNmJPvq6f4nHE5t1F9ILwNDM70
 VLBbMCsZeM75Lbq1bhGiHw78C+zeVv0Qov4JQuajcVwFSVVsa8zi9kEpP4ZhZo905JDuXvokEGI
 7Ah3Vcu51/8I9yF0ettPL1L8WuRbuIrwSJoyNleb/lA+8TzdyWFMIxL+fUXfH8llWvnj8/S77CF
 Y/YmR2IFxAorinV8vwHyIhf4cCXp7KAu+Ia1MdM6ADMDVIvFHzgNQKKjZQ//iEX6B6vuzi0xrVo
 ad4DSpIcRrN8JlLB3gePGKehcoM5ahQHE4oF18ASh0kq7xsPRGL77wXnHzLAGz+WTUi4I+Q7UnZ
 Z5N4OKW6s5iKcD+Zyp65fNxkAg4wGHOaabS7sEaTjNxROsBlCWF9llL60oYal2Pqb2nMQWXC2ue
 LKVuxQ7jsuxM3+O9Oh3SSF7DNcqCzl3xkbEUt6VOe2GgyXZ3FtG4=
X-Developer-Key: i=markus.probst@posteo.de; a=openpgp;
 fpr=827418C4F4AC58E77230C47334761FF8E7AD43D2
X-Endpoint-Received: by B4 Relay for markus.probst@posteo.de/default with auth_id=680
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the Synology Microp devicetree bindings. Those devices are
microcontrollers found on Synology NAS devices. They are connected to a
serial port on the host device.

Those devices are used to control certain LEDs, fan speeds, a beeper, to
handle buttons, fan failures and to properly shutdown and reboot the
device.

Signed-off-by: Markus Probst <markus.probst@posteo.de>
---
 .../devicetree/bindings/leds/synology,microp.yaml  | 40 +++++++++++++++++
 .../devicetree/bindings/mfd/synology,microp.yaml   | 51 ++++++++++++++++++++++
 2 files changed, 91 insertions(+)

diff --git a/Documentation/devicetree/bindings/leds/synology,microp.yaml b/Documentation/devicetree/bindings/leds/synology,microp.yaml
new file mode 100644
index 000000000000..f7bf32c240f7
--- /dev/null
+++ b/Documentation/devicetree/bindings/leds/synology,microp.yaml
@@ -0,0 +1,40 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/leds/synology,microp.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: Synology NAS on-board Microcontroller LEDs
+
+maintainers:
+  - Markus Probst <markus.probst@posteo.de>
+
+description: |
+  This is part of device tree bindings for Synology NAS on-board
+  Microcontroller.
+
+  This device can manage up to 4 leds in Synology NAS devices:
+  - Power
+  - Status
+  - Alert
+  - USB
+
+  The Power and Status LEDs are available on every Synology NAS model,
+  therefore the associated child nodes are mandatory. If the NAS also has
+  a alert or usb led, the associated child nodes need to be added.
+
+properties:
+  compatible:
+    const: synology,microp-leds
+
+patternProperties:
+  "^(power|status|alert|usb)-led$":
+    $ref: /schemas/leds/common.yaml
+    unevaluatedProperties: false
+
+required:
+  - compatible
+  - power-led
+  - status-led
+
+additionalProperties: false
diff --git a/Documentation/devicetree/bindings/mfd/synology,microp.yaml b/Documentation/devicetree/bindings/mfd/synology,microp.yaml
new file mode 100644
index 000000000000..57bb986d24f7
--- /dev/null
+++ b/Documentation/devicetree/bindings/mfd/synology,microp.yaml
@@ -0,0 +1,51 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/mfd/synology,microp.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: Synology NAS on-board Microcontroller
+
+maintainers:
+  - Markus Probst <markus.probst@posteo.de>
+
+description: |
+  Synology Microp is a microcontroller found in Synology NAS devices.
+  It is connected to a serial port on the host device.
+
+  It is a multifunction device with the following sub modules:
+  - LEDs
+
+properties:
+  compatible:
+    const: synology,microp
+
+  leds:
+    $ref: /schemas/leds/synology,microp.yaml
+
+required:
+  - compatible
+
+additionalProperties: false
+
+examples:
+  - |
+    #include <dt-bindings/leds/common.h>
+
+    mcu {
+      compatible = "synology,microp";
+
+      leds {
+        compatible = "synology,microp-leds";
+
+        power-led {
+          color = <LED_COLOR_ID_BLUE>;
+          function = LED_FUNCTION_POWER;
+        };
+
+        status-led {
+          color = <LED_COLOR_ID_MULTI>;
+          function = LED_FUNCTION_STATUS;
+        };
+      };
+    };

-- 
2.52.0

