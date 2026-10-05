From: Serv Pol <servpol@tuta.io>
Date: Mon, 05 Oct 2026 22:25:24 +0000
Subject: [PATCH 1/2] dt-bindings: power: supply: Add GL.iNet GL-E750 MCU
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261005-gl-e750-mcu-v1-1-499d2e31f786@tuta.io>
References: <20261005-gl-e750-mcu-v1-0-499d2e31f786@tuta.io>
In-Reply-To: <20261005-gl-e750-mcu-v1-0-499d2e31f786@tuta.io>
To: Serv Pol <servpol@tuta.io>, Sebastian Reichel <sre@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-pm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791239123; l=2280;
 i=servpol@tuta.io; s=20261005; h=from:subject:message-id;
 bh=H7uqR2k0sKISYlRblSwjWKrBqVMzecHmO4gYPBxy3Zw=;
 b=xutWf7SoAUI29EWuNuI56TDPwetjyU7bjxjIK8oW6+i2dwBzX1C20pK5szA5MY+atm46J1jYx
 hoeEIxFaWk5A3GHvSxKPrPQHO3bWP1TaB8ZwIUWD0LR/+ynyM1G1HxO
X-Developer-Key: i=servpol@tuta.io; a=ed25519;
 pk=2HCjaqYjXxgwTYu30Nem9DOHT8mtKgjitt1vEXKpwrE=
X-Endpoint-Received: by B4 Relay for servpol@tuta.io/20261005 with auth_id=1120
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The GL.iNet GL-E750 (Mudi) travel router has a microcontroller on the SoC
UART. It drives the OLED status screen, monitors the battery and reports
when the power switch is turned off, a few seconds before it cuts the
power. Add a binding for it.

Assisted-by: Claude:claude-opus-5-5
Signed-off-by: Serv Pol <servpol@tuta.io>
---
 .../bindings/power/supply/glinet,gl-e750-mcu.yaml  | 37 ++++++++++++++++++++++
 MAINTAINERS                                        |  6 ++++
 2 files changed, 43 insertions(+)

diff --git a/Documentation/devicetree/bindings/power/supply/glinet,gl-e750-mcu.yaml b/Documentation/devicetree/bindings/power/supply/glinet,gl-e750-mcu.yaml
new file mode 100644
index 000000000..a7ea4dde8
--- /dev/null
+++ b/Documentation/devicetree/bindings/power/supply/glinet,gl-e750-mcu.yaml
@@ -0,0 +1,37 @@
+# SPDX-License-Identifier: (GPL-2.0-only OR BSD-2-Clause)
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/power/supply/glinet,gl-e750-mcu.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: GL.iNet GL-E750 status MCU
+
+maintainers:
+  - Serv Pol <servpol@tuta.io>
+
+description:
+  The GL.iNet GL-E750 (Mudi) travel router has a microcontroller connected
+  to the SoC UART. It drives the OLED status screen, monitors the battery
+  and reports when the power switch is turned off, a few seconds before it
+  cuts the power.
+
+allOf:
+  - $ref: power-supply.yaml#
+  - $ref: /schemas/serial/serial-peripheral-props.yaml#
+
+properties:
+  compatible:
+    const: glinet,gl-e750-mcu
+
+required:
+  - compatible
+
+unevaluatedProperties: false
+
+examples:
+  - |
+    serial {
+        mcu {
+            compatible = "glinet,gl-e750-mcu";
+        };
+    };
diff --git a/MAINTAINERS b/MAINTAINERS
index 3a19da74d..247432449 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -11105,6 +11105,12 @@ L:	platform-driver-x86@vger.kernel.org
 S:	Maintained
 F:	drivers/platform/x86/gigabyte-wmi.c
 
+GL.INET GL-E750 MCU BATTERY DRIVER
+M:	Serv Pol <servpol@tuta.io>
+L:	linux-pm@vger.kernel.org
+S:	Maintained
+F:	Documentation/devicetree/bindings/power/supply/glinet,gl-e750-mcu.yaml
+
 GNSS SUBSYSTEM
 M:	Johan Hovold <johan@kernel.org>
 S:	Maintained

-- 
2.47.3

