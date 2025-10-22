From: Dimitri Fedrau <dimitri.fedrau@liebherr.com>
Date: Wed, 22 Oct 2025 21:47:47 +0200
Subject: [PATCH 1/2] dt-bindings: power: supply: gpio-charger: add support
 for fast-charge timer
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251022-gpio-charger-timer-v1-1-b557409400f2@liebherr.com>
References: <20251022-gpio-charger-timer-v1-0-b557409400f2@liebherr.com>
In-Reply-To: <20251022-gpio-charger-timer-v1-0-b557409400f2@liebherr.com>
To: Sebastian Reichel <sre@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-pm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Dimitri Fedrau <dimitri.fedrau@liebherr.com>, 
 Dimitri Fedrau <dima.fedrau@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1761162472; l=1423;
 i=dimitri.fedrau@liebherr.com; s=20241202; h=from:subject:message-id;
 bh=ajr1Bhnew2d+8SEwahiJrcr8lGScQzBku79JG1XD9nE=;
 b=EbKil6gHNtCPvQq7QlU/s/o4Q/ljGbZTtEI51tMdUowtCJReRu89E9V2OiOkZWmaR+01fU767
 fTQj21i8v7gCBIhSQBI0kC/yzJE8aQ3bGQRSfr2vMEWCTeEZU5i2FKn
X-Developer-Key: i=dimitri.fedrau@liebherr.com; a=ed25519;
 pk=rT653x09JSQvotxIqQl4/XiI4AOiBZrdOGvxDUbb5m8=
X-Endpoint-Received: by B4 Relay for dimitri.fedrau@liebherr.com/20241202 with auth_id=290
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

On some devices like TIs BQ24081 battery charger it is possible to activate
or deactivate a fast-charge timer that provides a backup safety for charge
termination via GPIO. In case of the BQ24081 it is a fixed 7-hour timer.

Signed-off-by: Dimitri Fedrau <dimitri.fedrau@liebherr.com>
---
 Documentation/devicetree/bindings/power/supply/gpio-charger.yaml | 5 +++++
 1 file changed, 5 insertions(+)

diff --git a/Documentation/devicetree/bindings/power/supply/gpio-charger.yaml b/Documentation/devicetree/bindings/power/supply/gpio-charger.yaml
index 25826bfc289c1c00c338fd0cee2ae6932529cfc3..0edacc104186497118d4ba41f80947009a9aacf6 100644
--- a/Documentation/devicetree/bindings/power/supply/gpio-charger.yaml
+++ b/Documentation/devicetree/bindings/power/supply/gpio-charger.yaml
@@ -62,6 +62,10 @@ properties:
     description: Default charge current limit. Must be listed in
       charge-current-limit-mapping.
 
+  fast-charge-timer-gpios:
+    maxItems: 1
+    description: GPIO used for enabling/disabling the fast-charge timer
+
 required:
   - compatible
 
@@ -97,4 +101,5 @@ examples:
                                      <700000 0x01>, // 700 mA => GPIO A.12 high
                                      <0 0x02>; // 0 mA => GPIO A.11 high
       charge-current-limit-default-microamp = <700000>;
+      fast-charge-timer-gpios = <&gpioA 13 GPIO_ACTIVE_LOW>;
     };

-- 
2.39.5

