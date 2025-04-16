From: Dimitri Fedrau <dimitri.fedrau@liebherr.com>
Date: Wed, 16 Apr 2025 19:14:47 +0200
Subject: [PATCH net-next v3 1/4] dt-bindings: net: ethernet-phy: add
 property mac-termination-ohms
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250416-dp83822-mac-impedance-v3-1-028ac426cddb@liebherr.com>
References: <20250416-dp83822-mac-impedance-v3-0-028ac426cddb@liebherr.com>
In-Reply-To: <20250416-dp83822-mac-impedance-v3-0-028ac426cddb@liebherr.com>
To: Andrew Lunn <andrew@lunn.ch>, Heiner Kallweit <hkallweit1@gmail.com>, 
 Russell King <linux@armlinux.org.uk>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Florian Fainelli <f.fainelli@gmail.com>, 
 Andrew Lunn <andrew+netdev@lunn.ch>, Andrew Davis <afd@ti.com>
Cc: netdev@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Dimitri Fedrau <dimitri.fedrau@liebherr.com>, 
 Dimitri Fedrau <dima.fedrau@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1744823698; l=1479;
 i=dimitri.fedrau@liebherr.com; s=20241202; h=from:subject:message-id;
 bh=W06lAoB8Jv78d0khXNAifsDKyfyzdH2gHN2GrvRj/lg=;
 b=8/NvEZKKh+Qh07muudfgPl+CobttKPe/dIYCo/6qpaXAyDrTUDrT0vQBuyl8cLqncY4NzjazH
 327bpfB7LnvBVI1pXYlyN/MW9h6jVytm4HsT8vkOPaOr+c2HBdBly+d
X-Developer-Key: i=dimitri.fedrau@liebherr.com; a=ed25519;
 pk=rT653x09JSQvotxIqQl4/XiI4AOiBZrdOGvxDUbb5m8=
X-Endpoint-Received: by B4 Relay for dimitri.fedrau@liebherr.com/20241202 with auth_id=290
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add property mac-termination-ohms in the device tree bindings for selecting
the resistance value of the builtin series termination resistors of the
PHY. Changing the resistance to an appropriate value can reduce signal
reflections and therefore improve signal quality.

Signed-off-by: Dimitri Fedrau <dimitri.fedrau@liebherr.com>
---
 Documentation/devicetree/bindings/net/ethernet-phy.yaml | 10 ++++++++++
 1 file changed, 10 insertions(+)

diff --git a/Documentation/devicetree/bindings/net/ethernet-phy.yaml b/Documentation/devicetree/bindings/net/ethernet-phy.yaml
index 824bbe4333b7ed95cc39737d3c334a20aa890f01..71e2cd32580f2e9e1af88e6f74517ccb92d1c20f 100644
--- a/Documentation/devicetree/bindings/net/ethernet-phy.yaml
+++ b/Documentation/devicetree/bindings/net/ethernet-phy.yaml
@@ -238,6 +238,16 @@ properties:
       peak-to-peak specified in ANSI X3.263. When omitted, the PHYs default
       will be left as is.
 
+  mac-termination-ohms:
+    maximum: 200
+    description:
+      The xMII signals need series termination on the driver side to match both
+      the output driver impedance and the line characteristic impedance, to
+      prevent reflections and EMI problems. Select a resistance value which is
+      supported by the builtin resistors of the PHY, otherwise the resistors may
+      have to be placed on board. When omitted, the PHYs default will be left as
+      is.
+
   leds:
     type: object
 

-- 
2.39.5

