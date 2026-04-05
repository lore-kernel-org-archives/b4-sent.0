From: Markus Probst <markus.probst@posteo.de>
Date: Sun, 05 Apr 2026 19:36:29 +0200
Subject: [PATCH v6 2/2] dt-bindings: embedded-controller: Add synology
 microp devices
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260405-synology_microp_initial-v6-2-08fde474b6c9@posteo.de>
References: <20260405-synology_microp_initial-v6-0-08fde474b6c9@posteo.de>
In-Reply-To: <20260405-synology_microp_initial-v6-0-08fde474b6c9@posteo.de>
To: Hans de Goede <hansg@kernel.org>, 
 =?utf-8?q?Ilpo_J=C3=A4rvinen?= <ilpo.jarvinen@linux.intel.com>, 
 Bryan O'Donoghue <bryan.odonoghue@linaro.org>, Lee Jones <lee@kernel.org>, 
 Pavel Machek <pavel@kernel.org>, Miguel Ojeda <ojeda@kernel.org>, 
 Boqun Feng <boqun@kernel.org>, Gary Guo <gary@garyguo.net>, 
 =?utf-8?q?Bj=C3=B6rn_Roy_Baron?= <bjorn3_gh@protonmail.com>, 
 Benno Lossin <lossin@kernel.org>, Andreas Hindborg <a.hindborg@kernel.org>, 
 Alice Ryhl <aliceryhl@google.com>, Trevor Gross <tmgross@umich.edu>, 
 Danilo Krummrich <dakr@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>
Cc: platform-driver-x86@vger.kernel.org, linux-leds@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 rust-for-linux@vger.kernel.org, Markus Probst <markus.probst@posteo.de>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=5337;
 i=markus.probst@posteo.de; h=from:subject:message-id;
 bh=fHl3WzBXTZoWL7NeZc8DC8ZKuATEEU9zJoDi3XrrDYY=;
 b=owEBiQJ2/ZANAwAIATR2H/jnrUPSAcsmYgBp0p2i0v1m+Z5fO9TcT7v5suSdzKGVcrxAnP6Km
 0uUGYbEEYKJAk8EAAEIADkWIQSCdBjE9KxY53IwxHM0dh/4561D0gUCadKdohsUgAAAAAAEAA5t
 YW51MiwyLjUrMS4xMiwyLDIACgkQNHYf+OetQ9IACA//dZsOw8pTiglnPnPxOIG5fYzp5D0O9qM
 APG7JPRR4ylyYCv2N25NEXiC6GFCxD8JviRCjSAj3lpsgMZNjTlo0w59bpKv/K9za8no9g7YN8X
 p646e0Bi+OkaVsuutNt8/jryqAnNemFppLKnpjTbxrMHHZuUn1vP3SFYdfuDzfUXJPtYI4avPZH
 rciF1W0TqO7NiYQzsDsqLu++OsbnBTS10q9eAvg0kQTozJFjVzfqxWg8KXIC9FvwQTIb5WomA/S
 bcvCBjYhXnayr79mkOTAL1y9uOFiPc/K+zXeWSu7TfFVbk6FZGJ/r7SKFDvLFanzh9xFrBvNKy6
 tpaCpVRvcR99lztK8+xVBDUa+wWXD1tIABwZpuBiwI9ZxPpG5WaCHXsNBfNf90eA5V6F13vb+Rl
 yrCz7ivo6NCJp9VYhUTxXfn7ujCTI0JnprUadhyTq4MHPldq3dIKfbTLMmJ8ytKR2Y2oQvkGACx
 PaH36/9BpNHtrMCMXGuhdoYubcy+EnE31Y+EnAlGb3dfY1/R7xY4x1xllrywfUfIDe5T7fmhNwB
 mc1nAnk008akv4nCWVlJoDebso0+fxhKc1bVRbrB30hkoyGuKg9rddhFeTw82sedz9CNh4rT5Jn
 71QMaWAIZS7cUyWvMpLwGr0bYp46Q2kctvMYRpmPVedSgQz2P9Lc=
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

This includes the following compatible ids:
 - synology,ds923p-microp
 - synology,ds918p-microp
 - synology,ds214play-microp
 - synology,ds225p-microp
 - synology,ds425p-microp
 - synology,ds710p-microp
 - synology,ds1010p-microp
 - synology,ds723p-microp
 - synology,ds1522p-microp
 - synology,rs422p-microp
 - synology,ds725p-microp
 - synology,ds118-microp
 - synology,ds124-microp
 - synology,ds223-microp
 - synology,ds223j-microp
 - synology,ds1823xsp-microp
 - synology,rs822p-microp
 - synology,rs1221p-microp
 - synology,rs1221rpp-microp
 - synology,ds925p-microp
 - synology,ds1525p-microp
 - synology,ds1825p-microp

Signed-off-by: Markus Probst <markus.probst@posteo.de>
---
 .../synology,ds923p-microp.yaml                    | 112 +++++++++++++++++++++
 MAINTAINERS                                        |   1 +
 2 files changed, 113 insertions(+)

diff --git a/Documentation/devicetree/bindings/embedded-controller/synology,ds923p-microp.yaml b/Documentation/devicetree/bindings/embedded-controller/synology,ds923p-microp.yaml
new file mode 100644
index 000000000000..4518e9b74be1
--- /dev/null
+++ b/Documentation/devicetree/bindings/embedded-controller/synology,ds923p-microp.yaml
@@ -0,0 +1,112 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/embedded-controller/synology,ds923p-microp.yaml#
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
+  It is necessary to properly shutdown and reboot the NAS device and
+  provides additional functionality such as led control, fan speed control,
+  a beeper and buttons on the NAS device.
+
+properties:
+  compatible:
+    enum:
+      - synology,ds923p-microp
+      - synology,ds918p-microp
+      - synology,ds214play-microp
+      - synology,ds225p-microp
+      - synology,ds425p-microp
+      - synology,ds710p-microp
+      - synology,ds1010p-microp
+      - synology,ds723p-microp
+      - synology,ds1522p-microp
+      - synology,rs422p-microp
+      - synology,ds725p-microp
+      - synology,ds118-microp
+      - synology,ds124-microp
+      - synology,ds223-microp
+      - synology,ds223j-microp
+      - synology,ds1823xsp-microp
+      - synology,rs822p-microp
+      - synology,rs1221p-microp
+      - synology,rs1221rpp-microp
+      - synology,ds925p-microp
+      - synology,ds1525p-microp
+      - synology,ds1825p-microp
+
+  fan-failure-gpios:
+    description: GPIOs needed to determine which fans stopped working on a fan failure event.
+    minItems: 2
+    maxItems: 3
+
+required:
+  - compatible
+
+allOf:
+  - if:
+      properties:
+        compatible:
+          contains:
+            enum:
+              - synology,ds214play-microp
+              - synology,ds225p-microp
+              - synology,ds710p-microp
+              - synology,ds723p-microp
+              - synology,ds725p-microp
+              - synology,ds118-microp
+              - synology,ds124-microp
+              - synology,ds223-microp
+              - synology,ds223j-microp
+              - synology,ds1823xsp-microp
+              - synology,rs822p-microp
+              - synology,rs1221p-microp
+              - synology,rs1221rpp-microp
+              - synology,ds1825p-microp
+    then:
+      properties:
+        fan-failure-gpios: false
+    else:
+      required:
+        - fan-failure-gpios
+
+additionalProperties: false
+
+examples:
+  - |
+    #include <dt-bindings/leds/common.h>
+    #include <dt-bindings/gpio/gpio.h>
+
+    embedded-controller {
+      compatible = "synology,ds923p-microp";
+
+      fan-failure-gpios = <&gpio 68 GPIO_ACTIVE_HIGH>, <&gpio 69 GPIO_ACTIVE_HIGH>;
+    };
+
+  - |
+    #include <dt-bindings/leds/common.h>
+    #include <dt-bindings/gpio/gpio.h>
+
+    embedded-controller {
+      compatible = "synology,ds723p-microp";
+    };
+
+  - |
+    #include <dt-bindings/leds/common.h>
+    #include <dt-bindings/gpio/gpio.h>
+
+    embedded-controller {
+      compatible = "synology,rs422p-microp";
+
+      fan-failure-gpios = <&gpio 68 GPIO_ACTIVE_HIGH>,
+                          <&gpio 69 GPIO_ACTIVE_HIGH>,
+                          <&gpio 40 GPIO_ACTIVE_HIGH>;
+    };
diff --git a/MAINTAINERS b/MAINTAINERS
index 78c99d831431..72075c9a2016 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -25557,6 +25557,7 @@ F:	include/uapi/linux/sync_file.h
 SYNOLOGY MICROP DRIVER
 M:	Markus Probst <markus.probst@posteo.de>
 S:	Maintained
+F:	Documentation/devicetree/bindings/embedded-controller/synology,ds923p-microp.yaml
 F:	drivers/platform/synology_microp/
 
 SYNOPSYS ARC ARCHITECTURE

-- 
2.52.0

