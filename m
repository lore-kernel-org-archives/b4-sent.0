From: Amit Sunil Dhamne <amitsd@google.com>
Date: Sun, 23 Nov 2025 08:35:48 +0000
Subject: [PATCH 1/6] dt-bindings: power: supply: Add Maxim MAX77759 charger
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251123-max77759-charger-v1-1-6b2e4b8f7f54@google.com>
References: <20251123-max77759-charger-v1-0-6b2e4b8f7f54@google.com>
In-Reply-To: <20251123-max77759-charger-v1-0-6b2e4b8f7f54@google.com>
To: Sebastian Reichel <sre@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 =?utf-8?q?Andr=C3=A9_Draszik?= <andre.draszik@linaro.org>, 
 Lee Jones <lee@kernel.org>, Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Badhri Jagan Sridharan <badhri@google.com>, 
 Heikki Krogerus <heikki.krogerus@linux.intel.com>, 
 Peter Griffin <peter.griffin@linaro.org>, 
 Tudor Ambarus <tudor.ambarus@linaro.org>, 
 Alim Akhtar <alim.akhtar@samsung.com>
Cc: linux-kernel@vger.kernel.org, linux-pm@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-usb@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-samsung-soc@vger.kernel.org, 
 RD Babiera <rdbabiera@google.com>, Kyle Tso <kyletso@google.com>, 
 Amit Sunil Dhamne <amitsd@google.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1763886983; l=1642;
 i=amitsd@google.com; s=20241031; h=from:subject:message-id;
 bh=7bFNW9hXhJq5LkheOx7QT7tuIMKAsDDQ1dSnkeZc7ig=;
 b=1aO4U9DUYtJHenszVku1+O2T8S0nKCzm7caOTnUbbR7qLLHyk8/pXvsmaDh9xS/wwoHBFtI1i
 5FyzzbHT56JAG1hlMR9W/gfQN/Zrra9GnRBfHBL0jK6C45CtkvlFvmg
X-Developer-Key: i=amitsd@google.com; a=ed25519;
 pk=wD+XZSST4dmnNZf62/lqJpLm7fiyT8iv462zmQ3H6bI=
X-Endpoint-Received: by B4 Relay for amitsd@google.com/20241031 with auth_id=262
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add bindings for Maxim max77759 charger device.

Signed-off-by: Amit Sunil Dhamne <amitsd@google.com>
---
 .../power/supply/maxim,max77759-charger.yaml       | 36 ++++++++++++++++++++++
 1 file changed, 36 insertions(+)

diff --git a/Documentation/devicetree/bindings/power/supply/maxim,max77759-charger.yaml b/Documentation/devicetree/bindings/power/supply/maxim,max77759-charger.yaml
new file mode 100644
index 000000000000..71f866419774
--- /dev/null
+++ b/Documentation/devicetree/bindings/power/supply/maxim,max77759-charger.yaml
@@ -0,0 +1,36 @@
+# SPDX-License-Identifier: GPL-2.0-only OR BSD-2-Clause
+%YAML 1.2
+---
+$id: http://devicetree.org/schemas/power/supply/maxim,max77759-charger.yaml#
+$schema: http://devicetree.org/meta-schemas/core.yaml#
+
+title: Maxim Integrated MAX77759 Battery charger
+
+maintainers:
+  - Amit Sunil Dhamne <amitsd@google.com>
+
+description: |
+  This module is part of the MAX77759 PMIC. For additional information, see
+  Documentation/devicetree/bindings/mfd/maxim,max77759.yaml.
+
+  The Maxim MAX77759 is a dual input switch mode battery charger for portable
+  applications. It supports wired and wireless charging and can operate in buck
+  and boost mode.
+
+allOf:
+  - $ref: power-supply.yaml#
+
+properties:
+  compatible:
+    const: maxim,max77759-charger
+
+  usb-otg-vbus-regulator:
+    type: object
+    description: Provides Boost for sourcing VBUS.
+    $ref: /schemas/regulator/regulator.yaml#
+    unevaluatedProperties: false
+
+required:
+  - compatible
+
+unevaluatedProperties: false

-- 
2.52.0.rc2.455.g230fcf2819-goog

