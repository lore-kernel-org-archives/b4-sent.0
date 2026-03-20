From: Markus Probst <markus.probst@posteo.de>
Date: Fri, 20 Mar 2026 23:09:53 +0100
Subject: [PATCH v4 1/2] dt-bindings: embedded-controller: Add
 synology,microp device
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260320-synology_microp_initial-v4-1-0423ddb83ca4@posteo.de>
References: <20260320-synology_microp_initial-v4-0-0423ddb83ca4@posteo.de>
In-Reply-To: <20260320-synology_microp_initial-v4-0-0423ddb83ca4@posteo.de>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Miguel Ojeda <ojeda@kernel.org>, 
 Boqun Feng <boqun@kernel.org>, Gary Guo <gary@garyguo.net>, 
 =?utf-8?q?Bj=C3=B6rn_Roy_Baron?= <bjorn3_gh@protonmail.com>, 
 Benno Lossin <lossin@kernel.org>, Andreas Hindborg <a.hindborg@kernel.org>, 
 Alice Ryhl <aliceryhl@google.com>, Trevor Gross <tmgross@umich.edu>, 
 Danilo Krummrich <dakr@kernel.org>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 rust-for-linux@vger.kernel.org, Markus Probst <markus.probst@posteo.de>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=2203;
 i=markus.probst@posteo.de; h=from:subject:message-id;
 bh=LpsLV+PtJsvp3bFmqlbGf98MY1TUHG8bfm5oAyDigeE=;
 b=owEBiQJ2/ZANAwAIATR2H/jnrUPSAcsmYgBpvcXgRgjqTZrKGss4psDMJbSgpmwLljPO/uzRG
 C6pfff9WgGJAk8EAAEIADkWIQSCdBjE9KxY53IwxHM0dh/4561D0gUCab3F4BsUgAAAAAAEAA5t
 YW51MiwyLjUrMS4xMSwyLDIACgkQNHYf+OetQ9Jsdw//bYfL3OjCaMvyGfdRKr4sRhL4LUG1OVv
 h7pBSmNl0gn67uVM73gK8oKraDlkvUxYmUG+WXB5Rojc25e6bCkRIFpYkSG6FaU292Ta4rYg2gr
 uvRjX7Ro6ry1a84XiOeOz6O2gTlez4d20Jry4qS7eN5GDGwj5BsJkigbxUl06U9OaM80jFXzbaH
 eJ0XDlUkQuVnkTEB4LUnmCrlYLdREqFXnsaKQw2RQP35xbk1yfOy3VqqUhqveyTrzuHT7GVUItH
 iLQCBe+wmm78LUSbwKRXTedJgPM7pSZL5sNuCGUC75OPwVs3RGCar0ZYNke+A5P/lv3muIpsI2Q
 EoZrwLcwnsfAHyiWUfLvb8m9exKGdkihR8Pxjz9k8l2OrrThH2J9TtAKrK0C+v7l21ObOLxRxG1
 TKwRMiXsGXGMUFSpHktuTzg4nbOXJSg9waiFZBC6zJrO705u3EoJh/afSAlTocM1v3dgSaOME14
 gwhprfqDy0GOvrggEN5bYSAU+0zlDLQK0OtrtJXqEK/VMrVbHqq+Iv3qer0O+7ss/BXEyn/EBj/
 MwOOVK0XVRQmGwkjQ2rr+b3k7anUZ/3Y7TbeAhk0gLwgOvnn2CWKbYaV1YYKkl2qtNk2T3c5OkW
 FFftp4xoUKhqejxGiezgKtmjF/1izsPGIkBhB59UQqOlFZX+JUQA=
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
 .../embedded-controller/synology,microp.yaml       | 52 ++++++++++++++++++++++
 1 file changed, 52 insertions(+)

diff --git a/Documentation/devicetree/bindings/embedded-controller/synology,microp.yaml b/Documentation/devicetree/bindings/embedded-controller/synology,microp.yaml
new file mode 100644
index 000000000000..3068da6f2a6a
--- /dev/null
+++ b/Documentation/devicetree/bindings/embedded-controller/synology,microp.yaml
@@ -0,0 +1,52 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/embedded-controller/synology,microp.yaml#
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
+    const: synology,microp
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
+
+examples:
+  - |
+    #include <dt-bindings/leds/common.h>
+
+    embedded-controller {
+      compatible = "synology,microp";
+
+      power-led {
+        color = <LED_COLOR_ID_BLUE>;
+        function = LED_FUNCTION_POWER;
+      };
+
+      status-led {
+        color = <LED_COLOR_ID_MULTI>;
+        function = LED_FUNCTION_STATUS;
+      };
+    };

-- 
2.52.0

