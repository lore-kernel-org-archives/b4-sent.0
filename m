From: Dimitri Fedrau <dimitri.fedrau@liebherr.com>
Date: Wed, 11 Dec 2024 08:29:09 +0100
Subject: [PATCH 1/2] dt-bindings: power: supply: gpio-charger: add support
 for default charge current limit
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241211-default-charge-current-limit-v1-1-7819ba06ee2a@liebherr.com>
References: <20241211-default-charge-current-limit-v1-0-7819ba06ee2a@liebherr.com>
In-Reply-To: <20241211-default-charge-current-limit-v1-0-7819ba06ee2a@liebherr.com>
To: Sebastian Reichel <sre@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-pm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Dimitri Fedrau <dimitri.fedrau@liebherr.com>, 
 Dimitri Fedrau <dima.fedrau@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1733902172; l=942;
 i=dimitri.fedrau@liebherr.com; s=20241202; h=from:subject:message-id;
 bh=Pxa2UR9+jiJf91z+v5TVU4+c8Xt5Dl0NVFgqfKJqVu4=;
 b=u37K86IYjQzBWwkt1ZG7stCRoxjAK/KU//ICWnpPcv+Gu3I/b2+JEDN6Lh4igcLFXsr7RXnsd
 W4WNCm1lSpwBRqlTf6uCAsr2J8P6h0DEqF9sJQDMOwgT2/tTYJ4/pR8
X-Developer-Key: i=dimitri.fedrau@liebherr.com; a=ed25519;
 pk=rT653x09JSQvotxIqQl4/XiI4AOiBZrdOGvxDUbb5m8=
X-Endpoint-Received: by B4 Relay for dimitri.fedrau@liebherr.com/20241202 with auth_id=290
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add binding for default charge current limit.

Signed-off-by: Dimitri Fedrau <dimitri.fedrau@liebherr.com>
---
 Documentation/devicetree/bindings/power/supply/gpio-charger.yaml | 4 ++++
 1 file changed, 4 insertions(+)

diff --git a/Documentation/devicetree/bindings/power/supply/gpio-charger.yaml b/Documentation/devicetree/bindings/power/supply/gpio-charger.yaml
index 89f8e2bcb2d7836c6a4308aff51721bd83fa3ba1..545fdd7133daf67b5bc238c5af26d0cbd8b44eae 100644
--- a/Documentation/devicetree/bindings/power/supply/gpio-charger.yaml
+++ b/Documentation/devicetree/bindings/power/supply/gpio-charger.yaml
@@ -58,6 +58,10 @@ properties:
             charge-current-limit-gpios property. Bit 1 second to last
             GPIO and so on.
 
+  charge-current-limit-default:
+    $ref: /schemas/types.yaml#/definitions/uint32
+    description: Default charge current limit in uA.
+
 required:
   - compatible
 

-- 
2.39.5

