From: Dimitri Fedrau <dimitri.fedrau@liebherr.com>
Date: Mon, 13 Jan 2025 06:40:12 +0100
Subject: [PATCH net-next 1/2] dt-bindings: net: dp83822: Add support for
 changing the transmit amplitude voltage
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250113-dp83822-tx-swing-v1-1-7ed5a9d80010@liebherr.com>
References: <20250113-dp83822-tx-swing-v1-0-7ed5a9d80010@liebherr.com>
In-Reply-To: <20250113-dp83822-tx-swing-v1-0-7ed5a9d80010@liebherr.com>
To: Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Andrew Davis <afd@ti.com>, 
 Andrew Lunn <andrew@lunn.ch>, Heiner Kallweit <hkallweit1@gmail.com>, 
 Russell King <linux@armlinux.org.uk>
Cc: netdev@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Dimitri Fedrau <dimitri.fedrau@liebherr.com>, 
 Dimitri Fedrau <dima.fedrau@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1736746828; l=1391;
 i=dimitri.fedrau@liebherr.com; s=20241202; h=from:subject:message-id;
 bh=CZ9EoWKNP+/yooo8m8ATI3MQdPGKi2t5WYkqruGrKw0=;
 b=c5f72qmNQb5JqM9ZYOTk316s1HqpmHm+ubmPZGydKgvEGgl4AIPtz3jmnIMLY7MGYK1UrFPLT
 tVdcQmVAauuBrRyKanAb7ENtKR1ZRDK8TMXkuwHWRRGUTHt0omFYolp
X-Developer-Key: i=dimitri.fedrau@liebherr.com; a=ed25519;
 pk=rT653x09JSQvotxIqQl4/XiI4AOiBZrdOGvxDUbb5m8=
X-Endpoint-Received: by B4 Relay for dimitri.fedrau@liebherr.com/20241202 with auth_id=290
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add support for changing the transmit amplitude voltage in 100BASE-TX mode.
Add binding to support this feature.

Signed-off-by: Dimitri Fedrau <dimitri.fedrau@liebherr.com>
---
 Documentation/devicetree/bindings/net/ti,dp83822.yaml | 11 +++++++++++
 1 file changed, 11 insertions(+)

diff --git a/Documentation/devicetree/bindings/net/ti,dp83822.yaml b/Documentation/devicetree/bindings/net/ti,dp83822.yaml
index 50c24248df266f1950371b950cd9c4d417835f97..b44f7068011b8e594f2ba245c526f4f48e3c5963 100644
--- a/Documentation/devicetree/bindings/net/ti,dp83822.yaml
+++ b/Documentation/devicetree/bindings/net/ti,dp83822.yaml
@@ -122,6 +122,16 @@ properties:
       - free-running
       - recovered
 
+  ti,tx-amplitude-100base-tx-millivolt:
+    description: |
+       DP83822 PHY only.
+       Transmit amplitude voltage for 100BASE-TX in millivolt. When omitted,
+       the PHY's default will be left as is.
+    $ref: /schemas/types.yaml#/definitions/uint32
+    enum: [1600, 1633, 1667, 1700, 1733, 1767, 1800, 1833,
+           1867, 1900, 1933, 1967, 2000, 2033, 2067, 2100]
+    default: 2000
+
 required:
   - reg
 
@@ -137,6 +147,7 @@ examples:
         rx-internal-delay-ps = <1>;
         tx-internal-delay-ps = <1>;
         ti,gpio2-clk-out = "xi";
+        ti,tx-amplitude-100base-tx-millivolt = <2100>;
       };
     };
 

-- 
2.39.5

