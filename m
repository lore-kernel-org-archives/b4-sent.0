From: Dimitri Fedrau <dimitri.fedrau@liebherr.com>
Date: Fri, 07 Mar 2025 11:30:01 +0100
Subject: [PATCH net-next 1/3] dt-bindings: net: ethernet-phy: add property
 mac-series-termination-ohms
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250307-dp83822-mac-impedance-v1-1-bdd85a759b45@liebherr.com>
References: <20250307-dp83822-mac-impedance-v1-0-bdd85a759b45@liebherr.com>
In-Reply-To: <20250307-dp83822-mac-impedance-v1-0-bdd85a759b45@liebherr.com>
To: Andrew Lunn <andrew@lunn.ch>, Heiner Kallweit <hkallweit1@gmail.com>, 
 Russell King <linux@armlinux.org.uk>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Florian Fainelli <f.fainelli@gmail.com>
Cc: netdev@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Dimitri Fedrau <dimitri.fedrau@liebherr.com>, 
 Dimitri Fedrau <dima.fedrau@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1741343404; l=1172;
 i=dimitri.fedrau@liebherr.com; s=20241202; h=from:subject:message-id;
 bh=ZGmwSQ66d6eh0REzIdZ/UIEpJ5tg0qml7Jgb30CA/sI=;
 b=saFDSQW7Jz8/Enl1FHon3rf594hns5gXEUgOWurxrpPav7KflToUD4W5QlRvITNlq/ZnSUojD
 +mRZ/XT/QMcAiir3nldKVFiiC1AKLJyVnxb8wl+3U6i439k7thfBH91
X-Developer-Key: i=dimitri.fedrau@liebherr.com; a=ed25519;
 pk=rT653x09JSQvotxIqQl4/XiI4AOiBZrdOGvxDUbb5m8=
X-Endpoint-Received: by B4 Relay for dimitri.fedrau@liebherr.com/20241202 with auth_id=290
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add property mac-series-termination-ohms in the device tree bindings for
selecting the resistance value of the builtin series termination resistors
of the PHY. Changing the resistance to an appropriate value can reduce
signal reflections and therefore improve signal quality.

Signed-off-by: Dimitri Fedrau <dimitri.fedrau@liebherr.com>
---
 Documentation/devicetree/bindings/net/ethernet-phy.yaml | 5 +++++
 1 file changed, 5 insertions(+)

diff --git a/Documentation/devicetree/bindings/net/ethernet-phy.yaml b/Documentation/devicetree/bindings/net/ethernet-phy.yaml
index 824bbe4333b7ed95cc39737d3c334a20aa890f01..4a710315a83ccf15bfc210ae432ae988cf31e04c 100644
--- a/Documentation/devicetree/bindings/net/ethernet-phy.yaml
+++ b/Documentation/devicetree/bindings/net/ethernet-phy.yaml
@@ -238,6 +238,11 @@ properties:
       peak-to-peak specified in ANSI X3.263. When omitted, the PHYs default
       will be left as is.
 
+  mac-series-termination-ohms:
+    description:
+      The resistance value of the series termination resistor. When omitted, the
+      PHYs default will be left as is.
+
   leds:
     type: object
 

-- 
2.39.5

