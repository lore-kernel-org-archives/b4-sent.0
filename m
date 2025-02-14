From: Dimitri Fedrau <dimitri.fedrau@liebherr.com>
Date: Fri, 14 Feb 2025 15:14:09 +0100
Subject: [PATCH net-next v5 1/3] dt-bindings: net: ethernet-phy: add
 property tx-amplitude-100base-tx-percent
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250214-dp83822-tx-swing-v5-1-02ca72620599@liebherr.com>
References: <20250214-dp83822-tx-swing-v5-0-02ca72620599@liebherr.com>
In-Reply-To: <20250214-dp83822-tx-swing-v5-0-02ca72620599@liebherr.com>
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
 Dimitri Fedrau <dima.fedrau@gmail.com>, 
 Conor Dooley <conor.dooley@microchip.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1739542465; l=1291;
 i=dimitri.fedrau@liebherr.com; s=20241202; h=from:subject:message-id;
 bh=gyZm/1v6xiCoF5uqR707anExlbQRcIOzUUiGOITwpxE=;
 b=SBuwnrqzF6QTwF9+w/3C5Swl95+cSy18Hddgj0XLt3YUL+Xezz/oAjTOX3UE/6LO4LWycnCv7
 okgKIiFFh9OCNpQfWZxy7RBfGjBzqiq/orDoP9Kf6e3AZGDT81egVQr
X-Developer-Key: i=dimitri.fedrau@liebherr.com; a=ed25519;
 pk=rT653x09JSQvotxIqQl4/XiI4AOiBZrdOGvxDUbb5m8=
X-Endpoint-Received: by B4 Relay for dimitri.fedrau@liebherr.com/20241202 with auth_id=290
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add property tx-amplitude-100base-tx-percent in the device tree bindings
for configuring the tx amplitude of 100BASE-TX PHYs. Modifying it can be
necessary to compensate losses on the PCB and connector, so the voltages
measured on the RJ45 pins are conforming.

Acked-by: Conor Dooley <conor.dooley@microchip.com>
Signed-off-by: Dimitri Fedrau <dimitri.fedrau@liebherr.com>
---
 Documentation/devicetree/bindings/net/ethernet-phy.yaml | 6 ++++++
 1 file changed, 6 insertions(+)

diff --git a/Documentation/devicetree/bindings/net/ethernet-phy.yaml b/Documentation/devicetree/bindings/net/ethernet-phy.yaml
index 2c71454ae8e362e7032e44712949e12da6826070..824bbe4333b7ed95cc39737d3c334a20aa890f01 100644
--- a/Documentation/devicetree/bindings/net/ethernet-phy.yaml
+++ b/Documentation/devicetree/bindings/net/ethernet-phy.yaml
@@ -232,6 +232,12 @@ properties:
       PHY's that have configurable TX internal delays. If this property is
       present then the PHY applies the TX delay.
 
+  tx-amplitude-100base-tx-percent:
+    description:
+      Transmit amplitude gain applied for 100BASE-TX. 100% matches 2V
+      peak-to-peak specified in ANSI X3.263. When omitted, the PHYs default
+      will be left as is.
+
   leds:
     type: object
 

-- 
2.39.5

