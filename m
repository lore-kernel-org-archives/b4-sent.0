From: Dimitri Fedrau <dimitri.fedrau@liebherr.com>
Date: Tue, 04 Feb 2025 14:09:15 +0100
Subject: [PATCH net-next v3 1/3] dt-bindings: net: ethernet-phy: add
 property tx-amplitude-100base-tx-percent
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250204-dp83822-tx-swing-v3-1-9798e96500d9@liebherr.com>
References: <20250204-dp83822-tx-swing-v3-0-9798e96500d9@liebherr.com>
In-Reply-To: <20250204-dp83822-tx-swing-v3-0-9798e96500d9@liebherr.com>
To: Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Andrew Davis <afd@ti.com>, 
 Andrew Lunn <andrew@lunn.ch>, Heiner Kallweit <hkallweit1@gmail.com>, 
 Russell King <linux@armlinux.org.uk>, 
 Florian Fainelli <f.fainelli@gmail.com>
Cc: netdev@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Dimitri Fedrau <dimitri.fedrau@liebherr.com>, 
 Dimitri Fedrau <dima.fedrau@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1738674559; l=1249;
 i=dimitri.fedrau@liebherr.com; s=20241202; h=from:subject:message-id;
 bh=s00iyFuKz8UzLLfIh0z0U6zzS8bBlyQj8K8lOchvczI=;
 b=UlxNzjCWowzu+lbfqGh7k4BTqsZ0KaVPCMf5LoIs6ovZ81mTRfPefhNoD4liDZrAOQVyHB63/
 VIg9i06lHRiCfcZ0D4tKDx6nyrr4Kc5hoI1pCTRa9MZ7+diTTFv8T0E
X-Developer-Key: i=dimitri.fedrau@liebherr.com; a=ed25519;
 pk=rT653x09JSQvotxIqQl4/XiI4AOiBZrdOGvxDUbb5m8=
X-Endpoint-Received: by B4 Relay for dimitri.fedrau@liebherr.com/20241202 with auth_id=290
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add property tx-amplitude-100base-tx-percent in the device tree bindings
for configuring the tx amplitude of 100BASE-TX PHYs. Modifying it can be
necessary to compensate losses on the PCB and connector, so the voltages
measured on the RJ45 pins are conforming.

Signed-off-by: Dimitri Fedrau <dimitri.fedrau@liebherr.com>
---
 Documentation/devicetree/bindings/net/ethernet-phy.yaml | 7 +++++++
 1 file changed, 7 insertions(+)

diff --git a/Documentation/devicetree/bindings/net/ethernet-phy.yaml b/Documentation/devicetree/bindings/net/ethernet-phy.yaml
index 2c71454ae8e362e7032e44712949e12da6826070..04f42961035f273990fdf4368ad1352397fc3774 100644
--- a/Documentation/devicetree/bindings/net/ethernet-phy.yaml
+++ b/Documentation/devicetree/bindings/net/ethernet-phy.yaml
@@ -232,6 +232,13 @@ properties:
       PHY's that have configurable TX internal delays. If this property is
       present then the PHY applies the TX delay.
 
+  tx-amplitude-100base-tx-percent:
+    description: |
+      Transmit amplitude gain applied for 100BASE-TX. When omitted, the PHYs
+      default will be left as is.
+    $ref: /schemas/types.yaml#/definitions/uint32
+    default: 100
+
   leds:
     type: object
 

-- 
2.39.5

