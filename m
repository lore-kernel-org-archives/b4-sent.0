From: Dimitri Fedrau <dimitri.fedrau@liebherr.com>
Date: Wed, 18 Dec 2024 09:35:00 +0100
Subject: [PATCH v3 1/2] dt-bindings: power: supply: gpio-charger: add
 support for default charge current limit
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241218-default-charge-current-limit-v3-1-b26118cf06b5@liebherr.com>
References: <20241218-default-charge-current-limit-v3-0-b26118cf06b5@liebherr.com>
In-Reply-To: <20241218-default-charge-current-limit-v3-0-b26118cf06b5@liebherr.com>
To: Sebastian Reichel <sre@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-pm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Dimitri Fedrau <dimitri.fedrau@liebherr.com>, 
 Dimitri Fedrau <dima.fedrau@gmail.com>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@linaro.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1734510905; l=2130;
 i=dimitri.fedrau@liebherr.com; s=20241202; h=from:subject:message-id;
 bh=2q5GV8EMl0sfSm2ZGPWeIF1Jp2pHQa5oOgDB+AtoPSY=;
 b=j0TSn+iRF/6M3+yrgNDKIOv6HLfnRBYJvjDbCAIyCVbDOjY9Thes2n4OEfO0eDpTHa67sgRCt
 0Dd42ziCRWiCOK6MupHq2dcCnhy2LjAGIcHzATwgi97HRHhBf/Dq8Rb
X-Developer-Key: i=dimitri.fedrau@liebherr.com; a=ed25519;
 pk=rT653x09JSQvotxIqQl4/XiI4AOiBZrdOGvxDUbb5m8=
X-Endpoint-Received: by B4 Relay for dimitri.fedrau@liebherr.com/20241202 with auth_id=290
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

With DT properties charge-current-limit-gpios and
charge-current-limit-mapping one can define charge current limits in uA
using up to 32 GPIOs. Add property charge-current-limit-default-microamp
which selects a default charge current limit that must be listed in
charge-current-limit-mapping.
This is helpful when the smallest possible charge current limit is 0uA. The
driver defaults to the smallest possible value at the moment, which
disables charging on probe. With the default its possible to setup a safe
charge current limit.

Reviewed-by: Krzysztof Kozlowski <krzysztof.kozlowski@linaro.org>
Signed-off-by: Dimitri Fedrau <dimitri.fedrau@liebherr.com>
---
 Documentation/devicetree/bindings/power/supply/gpio-charger.yaml | 6 ++++++
 1 file changed, 6 insertions(+)

diff --git a/Documentation/devicetree/bindings/power/supply/gpio-charger.yaml b/Documentation/devicetree/bindings/power/supply/gpio-charger.yaml
index 89f8e2bcb2d7836c6a4308aff51721bd83fa3ba1..25826bfc289c1c00c338fd0cee2ae6932529cfc3 100644
--- a/Documentation/devicetree/bindings/power/supply/gpio-charger.yaml
+++ b/Documentation/devicetree/bindings/power/supply/gpio-charger.yaml
@@ -58,6 +58,10 @@ properties:
             charge-current-limit-gpios property. Bit 1 second to last
             GPIO and so on.
 
+  charge-current-limit-default-microamp:
+    description: Default charge current limit. Must be listed in
+      charge-current-limit-mapping.
+
 required:
   - compatible
 
@@ -72,6 +76,7 @@ anyOf:
 dependencies:
   charge-current-limit-gpios: [ charge-current-limit-mapping ]
   charge-current-limit-mapping: [ charge-current-limit-gpios ]
+  charge-current-limit-default-microamp: [charge-current-limit-mapping]
 
 additionalProperties: false
 
@@ -91,4 +96,5 @@ examples:
       charge-current-limit-mapping = <2500000 0x00>, // 2.5 A => both GPIOs low
                                      <700000 0x01>, // 700 mA => GPIO A.12 high
                                      <0 0x02>; // 0 mA => GPIO A.11 high
+      charge-current-limit-default-microamp = <700000>;
     };

-- 
2.39.5

