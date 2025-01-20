From: Dimitri Fedrau <dimitri.fedrau@liebherr.com>
Date: Mon, 20 Jan 2025 14:50:21 +0100
Subject: [PATCH net-next v2 1/3] dt-bindings: net: ethernet-phy: add
 property tx-amplitude-100base-tx-gain-milli
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250120-dp83822-tx-swing-v2-1-07c99dc42627@liebherr.com>
References: <20250120-dp83822-tx-swing-v2-0-07c99dc42627@liebherr.com>
In-Reply-To: <20250120-dp83822-tx-swing-v2-0-07c99dc42627@liebherr.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1737381028; l=1340;
 i=dimitri.fedrau@liebherr.com; s=20241202; h=from:subject:message-id;
 bh=o9/uYCQMqtj7aA5WdqSP5I74ZoABiwwXrCBqYSBeaRI=;
 b=HzyehliKyx0cDcSOOj1zdjTN00xtHbx8p1oWQhEu6VA+ZEHW4tacLpYoWV+UINcjc+I4h7prx
 Qi9d8HHyTAmD0s4KUAnN6oAkRgRiacX5MoX82SV9n0eucRtIOeerheh
X-Developer-Key: i=dimitri.fedrau@liebherr.com; a=ed25519;
 pk=rT653x09JSQvotxIqQl4/XiI4AOiBZrdOGvxDUbb5m8=
X-Endpoint-Received: by B4 Relay for dimitri.fedrau@liebherr.com/20241202 with auth_id=290
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add property tx-amplitude-100base-tx-gain-milli in the device tree bindings
for configuring the tx amplitude of 100BASE-TX PHYs. Modifying it can be
necessary to compensate losses on the PCB and connector, so the voltages
measured on the RJ45 pins are conforming.

Signed-off-by: Dimitri Fedrau <dimitri.fedrau@liebherr.com>
---
 Documentation/devicetree/bindings/net/ethernet-phy.yaml | 8 ++++++++
 1 file changed, 8 insertions(+)

diff --git a/Documentation/devicetree/bindings/net/ethernet-phy.yaml b/Documentation/devicetree/bindings/net/ethernet-phy.yaml
index 2c71454ae8e362e7032e44712949e12da6826070..ce65413410c2343a3525e746e72b6c6c8bb120d0 100644
--- a/Documentation/devicetree/bindings/net/ethernet-phy.yaml
+++ b/Documentation/devicetree/bindings/net/ethernet-phy.yaml
@@ -232,6 +232,14 @@ properties:
       PHY's that have configurable TX internal delays. If this property is
       present then the PHY applies the TX delay.
 
+  tx-amplitude-100base-tx-gain-milli:
+    description: |
+      Transmit amplitude gain applied (in milli units) for 100BASE-TX. When
+      omitted, the PHYs default will be left as is. If not present, default to
+      1000 (no actual gain applied).
+    $ref: /schemas/types.yaml#/definitions/uint32
+    default: 1000
+
   leds:
     type: object
 

-- 
2.39.5

