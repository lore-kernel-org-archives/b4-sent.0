From: Markus Probst <markus.probst@posteo.de>
Date: Sat, 30 May 2026 03:17:11 +0200
Subject: [PATCH v13 1/2] dt-bindings: embedded-controller: Add synology
 microp devices
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260530-synology_microp_initial-v13-1-aa2bb9c56efc@posteo.de>
References: <20260530-synology_microp_initial-v13-0-aa2bb9c56efc@posteo.de>
In-Reply-To: <20260530-synology_microp_initial-v13-0-aa2bb9c56efc@posteo.de>
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
 rust-for-linux@vger.kernel.org, Markus Probst <markus.probst@posteo.de>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=4079;
 i=markus.probst@posteo.de; h=from:subject:message-id;
 bh=alrwaULuLrijlaEQo59qC6IZr7fepf0GBhjIrFXTxGk=;
 b=owEBiQJ2/ZANAwAIATR2H/jnrUPSAcsmYgBqGjqcMpahqMRlzruQRKCgpppH4Tpux7t2xQMTC
 W/1mEG5YTCJAk8EAAEIADkWIQSCdBjE9KxY53IwxHM0dh/4561D0gUCaho6nBsUgAAAAAAEAA5t
 YW51MiwyLjUrMS4xMiwyLDIACgkQNHYf+OetQ9Kbqw/+Oy7iSMDQDR7bkSnQAlMWSvPU293oLmj
 keubOVM1vygTA8V2Or3R5bCaucQRdQqITQ3nhC0V2WnbqSUbKNtLp+dY5Wo2AWYSU3hJz0udve7
 F6q6LNZIXABYVxZAVZ5hx0clJ+DxriLgm0c2BnJ+fZAzL8W24HVfbjC0XaZu+g6Cdvl5aDVUAss
 tWLsp2UEkcxThbEuYr992DuUHweSD0KHEGgudUSNOtENxAI78+Cj/2ZJqqx8dbgCPF5n/KL27Bh
 641q74lfoxF/E7AaZryg6naKmZXiTaWH7R+Vy3BZaZ2WfzhX+BRWjnRoWin4wMvfkV2AiaczFWa
 jETZkK/1IRuo/QYeVObDKIOLc4v2+beqX3EA7CK7e8gXZ8wSvD7Row5Vg5OqHkVERQ2ofMSoJNR
 AAUjRRtdrBPsWHD/QPqgW+ulGv6/c/4BFw/iFQcvM7iNkqJ4sQS1nhW0QlSlVcapY+VBuuy3942
 JQaCNAKFgdSCKoqEgbT+6F1opJUfyKc4OdRAwb1+GcjS7bXLfhqLBw8jz6e01fvxTY/PWILIqf2
 gf0EKLD2UC5ebogi7hdrpz6K57t987zTKekar2fbI/z1xTWctXJfruxdvJuTuVaTbvTtIdec8/Q
 2ABfrQIJ+mthN5TFmD9YzMyDb6M42TowxU7BXzGO6vcrFl0aelLA=
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

The device has a different feature set depending on the Synology NAS
model, like having different number of fans, buttons and leds. Depending
on the architecture of the model, they also need a different system
shutdown behaviour.

Reviewed-by: Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>
Signed-off-by: Markus Probst <markus.probst@posteo.de>
---
 .../synology,ds918p-microp.yaml                    | 100 +++++++++++++++++++++
 1 file changed, 100 insertions(+)

diff --git a/Documentation/devicetree/bindings/embedded-controller/synology,ds918p-microp.yaml b/Documentation/devicetree/bindings/embedded-controller/synology,ds918p-microp.yaml
new file mode 100644
index 000000000000..eb1c9d3fac07
--- /dev/null
+++ b/Documentation/devicetree/bindings/embedded-controller/synology,ds918p-microp.yaml
@@ -0,0 +1,100 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/embedded-controller/synology,ds918p-microp.yaml#
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
+    oneOf:
+      - items:
+          - enum:
+              - synology,ds1221rpp-microp
+              - synology,rs822p-microp
+              - synology,rs422p-microp
+          - const: synology,rs1221p-microp
+
+      - items:
+          - const: synology,ds1825p-microp
+          - const: synology,ds1823xsp-microp
+
+      - items:
+          - enum:
+              - synology,ds725p-microp
+              - synology,ds225p-microp
+              - synology,ds723p-microp
+              - synology,ds710p-microp
+          - const: synology,ds214play-microp
+
+      - items:
+          - enum:
+              - synology,ds425p-microp
+              - synology,ds1525p-microp
+              - synology,ds925p-microp
+              - synology,ds923p-microp
+              - synology,ds1522p-microp
+              - synology,ds1010p-microp
+              - synology,ds411p-microp
+          - const: synology,ds918p-microp
+
+      - items:
+          - enum:
+              - synology,ds124-microp
+              - synology,ds223j-microp
+              - synology,ds223-microp
+          - const: synology,ds118-microp
+
+      - enum:
+          - synology,ds118-microp
+          - synology,ds1823xsp-microp
+          - synology,rs1221p-microp
+          - synology,ds918p-microp
+          - synology,ds214play-microp
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
+              - synology,ds918p-microp
+              - synology,rs422p-microp
+    then:
+      required:
+        - fan-failure-gpios
+    else:
+      properties:
+        fan-failure-gpios: false
+
+additionalProperties: false
+
+examples:
+  - |
+    #include <dt-bindings/gpio/gpio.h>
+
+    embedded-controller {
+      compatible = "synology,ds923p-microp", "synology,ds918p-microp";
+
+      fan-failure-gpios = <&gpio 68 GPIO_ACTIVE_HIGH>, <&gpio 69 GPIO_ACTIVE_HIGH>;
+    };

-- 
2.53.0

