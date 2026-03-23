From: Dimitri Fedrau <dimitri.fedrau@liebherr.com>
Date: Mon, 23 Mar 2026 17:04:06 +0100
Subject: [PATCH v3 1/2] dt-bindings: power: supply: gpio-charger: add
 support for fast-charge timer
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260323-gpio-charger-timer-v3-1-885796d681a5@liebherr.com>
References: <20260323-gpio-charger-timer-v3-0-885796d681a5@liebherr.com>
In-Reply-To: <20260323-gpio-charger-timer-v3-0-885796d681a5@liebherr.com>
To: Sebastian Reichel <sre@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-pm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Dimitri Fedrau <dimitri.fedrau@liebherr.com>, 
 Dimitri Fedrau <dima.fedrau@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1774281855; l=1976;
 i=dimitri.fedrau@liebherr.com; s=20241202; h=from:subject:message-id;
 bh=qVR6Vlf2NNZxUIBX8M/euAC/Z+4KL1Wd23n+lTvvOvU=;
 b=qRmAOLjR6UzvKW8cPZJQ3T9OJVvl50z8wxEwmvMLqS2Dra+xb0jUNQ24eg3yq4GfoOvy9EuaO
 cTTFvIKcLkPB1A0Kp3mTsggf0o+4pM3FwQz8WGQ2qhpA1MEOXC22u8g
X-Developer-Key: i=dimitri.fedrau@liebherr.com; a=ed25519;
 pk=rT653x09JSQvotxIqQl4/XiI4AOiBZrdOGvxDUbb5m8=
X-Endpoint-Received: by B4 Relay for dimitri.fedrau@liebherr.com/20241202 with auth_id=290
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

On some devices like TIs BQ24081 battery charger it is possible to activate
or deactivate a fast-charge timer that provides a backup safety for charge
termination via GPIO. In case of the BQ24081 it is a fixed 7-hour timer.

Signed-off-by: Dimitri Fedrau <dimitri.fedrau@liebherr.com>
---
 .../bindings/power/supply/gpio-charger.yaml        | 22 +++++++++++++++++++++-
 1 file changed, 21 insertions(+), 1 deletion(-)

diff --git a/Documentation/devicetree/bindings/power/supply/gpio-charger.yaml b/Documentation/devicetree/bindings/power/supply/gpio-charger.yaml
index 25826bfc289c1c00c338fd0cee2ae6932529cfc3..fefa09cb24ec2f501099f486c9a4eb77e64cda67 100644
--- a/Documentation/devicetree/bindings/power/supply/gpio-charger.yaml
+++ b/Documentation/devicetree/bindings/power/supply/gpio-charger.yaml
@@ -16,7 +16,12 @@ description:
 
 properties:
   compatible:
-    const: gpio-charger
+    oneOf:
+      - const: gpio-charger
+      - items:
+          - enum:
+              - ti,bq24081
+          - const: gpio-charger
 
   charger-type:
     enum:
@@ -62,6 +67,10 @@ properties:
     description: Default charge current limit. Must be listed in
       charge-current-limit-mapping.
 
+  fast-charge-timer-gpios:
+    maxItems: 1
+    description: GPIO used for enabling/disabling the fast-charge timer
+
 required:
   - compatible
 
@@ -98,3 +107,14 @@ examples:
                                      <0 0x02>; // 0 mA => GPIO A.11 high
       charge-current-limit-default-microamp = <700000>;
     };
+  - |
+    #include <dt-bindings/gpio/gpio.h>
+
+    charger {
+      compatible = "ti,bq24081", "gpio-charger";
+      charger-type = "battery";
+      charge-status-gpios = <&gpio1 4 GPIO_ACTIVE_LOW>;
+      charge-current-limit-gpios = <&gpio1 3 GPIO_ACTIVE_LOW>;
+      charge-current-limit-mapping = <206000 0x1>, <0 0x0>;
+      fast-charge-timer-gpios = <&gpio1 6 GPIO_ACTIVE_LOW>;
+    };

-- 
2.39.5

