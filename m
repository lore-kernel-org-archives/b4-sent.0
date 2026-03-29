From: Markus Probst <markus.probst@posteo.de>
Date: Sun, 29 Mar 2026 20:02:15 +0200
Subject: [PATCH v5 1/4] dt-bindings: embedded-controller: Add synology
 microp devices
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260329-synology_microp_initial-v5-1-27cb80bdf591@posteo.de>
References: <20260329-synology_microp_initial-v5-0-27cb80bdf591@posteo.de>
In-Reply-To: <20260329-synology_microp_initial-v5-0-27cb80bdf591@posteo.de>
To: Hans de Goede <hansg@kernel.org>, 
 =?utf-8?q?Ilpo_J=C3=A4rvinen?= <ilpo.jarvinen@linux.intel.com>, 
 Bryan O'Donoghue <bryan.odonoghue@linaro.org>, Lee Jones <lee@kernel.org>, 
 Pavel Machek <pavel@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Miguel Ojeda <ojeda@kernel.org>, 
 Boqun Feng <boqun@kernel.org>, Gary Guo <gary@garyguo.net>, 
 =?utf-8?q?Bj=C3=B6rn_Roy_Baron?= <bjorn3_gh@protonmail.com>, 
 Benno Lossin <lossin@kernel.org>, Andreas Hindborg <a.hindborg@kernel.org>, 
 Alice Ryhl <aliceryhl@google.com>, Trevor Gross <tmgross@umich.edu>, 
 Danilo Krummrich <dakr@kernel.org>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 "Rafael J. Wysocki" <rafael@kernel.org>, Len Brown <lenb@kernel.org>, 
 Saravana Kannan <saravanak@kernel.org>
Cc: platform-driver-x86@vger.kernel.org, linux-leds@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 rust-for-linux@vger.kernel.org, linux-acpi@vger.kernel.org, 
 Markus Probst <markus.probst@posteo.de>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=2847;
 i=markus.probst@posteo.de; h=from:subject:message-id;
 bh=LjFpIfANTZFo1+4IPCHrW+YIb3KmnE+ivKHsB6gln08=;
 b=owEBiQJ2/ZANAwAIATR2H/jnrUPSAcsmYgBpyWk57cnwGnzCYU7bX9FQiaKM/eXTH6tO9Tsvs
 8PqY3PJRquJAk8EAAEIADkWIQSCdBjE9KxY53IwxHM0dh/4561D0gUCaclpORsUgAAAAAAEAA5t
 YW51MiwyLjUrMS4xMSwyLDIACgkQNHYf+OetQ9IgDA/+MkrrYxXzol9wLHQzbRjvpCsg6A/6Hn6
 H0AoQgev00ZuBP8o5HPBJW2wL0BSIZ8hEg/hIxrGg/vxBYMKHz90cfSGPjF3tyqVJw7tf1wlcwP
 bNRykHuuxTXqNeQ+vtEhLD5oa/y4pbwkDoTFmGfRxCmPpj3h/5iEo4k6yOVRA+toNg63jEtMCzJ
 Hm9aq4s6vaWN/X9Hf4+1jdJi4PUZN4gozqI3iqp1zLIuFKx2S/M5wrlTp9whdBqunWSDYYgcyZ5
 RoZ/kNYb+049oFVOHCwX46k1+J7C3s58MemHgWiIO0JL0t2y45exFk4ozUVw94/68rEd2gq4yZ3
 ZAAN4RyhqCBQRgUeQREp3CA1W++fodZZvkfV9H7Wy7d+q82wvmLmM8LA1X2Q+zyOmw3RmuXMYs9
 /APKwzC5fDHFOHpsmIPsEIqVwdPldK1Ks//Pk/hbtNso3D7lsMOr4oZqNzdZX5JragSPj7xQU0d
 ITPdapX3ODn4R/yTCsVvEKra7yBbBPTXOA2NtaDri54URNPhMOWMdQiouADGMCksBjS9sGKM//W
 PtWNKFQh2n+d4kBn3+0rL6epwa7Ut344MIYHN1fxtSfZS2QPtDTw6hS88OcFQU93DvwEo5R28h/
 BAKU8Sbn74AVHk0n0D6UHZuBbWlKJVvWckYrJ7+xj86jWoINbFt0=
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
 .../synology,ds923p-microp.yaml                    | 65 ++++++++++++++++++++++
 1 file changed, 65 insertions(+)

diff --git a/Documentation/devicetree/bindings/embedded-controller/synology,ds923p-microp.yaml b/Documentation/devicetree/bindings/embedded-controller/synology,ds923p-microp.yaml
new file mode 100644
index 000000000000..599d32ce2be9
--- /dev/null
+++ b/Documentation/devicetree/bindings/embedded-controller/synology,ds923p-microp.yaml
@@ -0,0 +1,65 @@
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

-- 
2.52.0

