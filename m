From: George Moussalem <george.moussalem@outlook.com>
Date: Tue, 02 Jun 2026 10:50:37 +0400
Subject: [PATCH v2 1/4] dt-bindings: net: ethernet-phy: move clocks
 property to invidivual PHY bindings
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260602-ipq5018-gephy-clocks-v2-1-65a1f1d881f3@outlook.com>
References: <20260602-ipq5018-gephy-clocks-v2-0-65a1f1d881f3@outlook.com>
In-Reply-To: <20260602-ipq5018-gephy-clocks-v2-0-65a1f1d881f3@outlook.com>
To: Andrew Lunn <andrew@lunn.ch>, Heiner Kallweit <hkallweit1@gmail.com>, 
 Russell King <linux@armlinux.org.uk>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Florian Fainelli <f.fainelli@gmail.com>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>
Cc: netdev@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>, 
 linux-arm-msm@vger.kernel.org, 
 George Moussalem <george.moussalem@outlook.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1780383045; l=2564;
 i=george.moussalem@outlook.com; s=20250321; h=from:subject:message-id;
 bh=JF+9D9ibIujy3R8OCamEf63tGtDhuH5LrP1BT4APw7g=;
 b=qmYr1njuSRFfbA8TCMCe9/wzVxkvnZ1e2EEziVPHMEjgm/0ygSsOwXmDxgPIyLpZtgeytdr6a
 szM4/13e3aHAdGZmNX96G2RXH4GxbYkH1Yme64KJh+r6Ip29QK6vCIs
X-Developer-Key: i=george.moussalem@outlook.com; a=ed25519;
 pk=/PuRTSI9iYiHwcc6Nrde8qF4ZDhJBlUgpHdhsIjnqIk=
X-Endpoint-Received: by B4 Relay for george.moussalem@outlook.com/20250321 with auth_id=364
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Move the clock property and restriction from the ethernet-phy.yaml file
to the individual PHY binding files. This allows each PHY to manage its
own clock requirements.

Signed-off-by: George Moussalem <george.moussalem@outlook.com>
---
Commit 350b7a258f20 introduced the clocks property with a restriction to
maximum 1 to the main ethernet-phy.yaml binding for Realtek to add an
optional external clock source. This is restrictive to all PHY bindings,
as some PHYs may require more than 1 clock such as the IPQ5018 PHY which
requires 2 clocks (for RX and TX).

There are three other PHY drivers that require clock management:
- Micrel: requires 1 optional clock and the micrel.yaml file already
accomodates for the clock property.
- SMSC: requires an optional clock and the legacy bindings file
(smsc-lan87xx.txt) already accomodates for the clock property.
- BCM7xxx: requires an optional clock. I could not find a bindings file
for this PHY family.
---
 Documentation/devicetree/bindings/net/ethernet-phy.yaml    | 6 ------
 Documentation/devicetree/bindings/net/realtek,rtl82xx.yaml | 6 ++++++
 2 files changed, 6 insertions(+), 6 deletions(-)

diff --git a/Documentation/devicetree/bindings/net/ethernet-phy.yaml b/Documentation/devicetree/bindings/net/ethernet-phy.yaml
index 21a1a63506f0..709ea976ef79 100644
--- a/Documentation/devicetree/bindings/net/ethernet-phy.yaml
+++ b/Documentation/devicetree/bindings/net/ethernet-phy.yaml
@@ -105,12 +105,6 @@ properties:
       1BR-10 names. The PHY must be configured to operate in BroadR-Reach mode
       by software.
 
-  clocks:
-    maxItems: 1
-    description:
-      External clock connected to the PHY. If not specified it is assumed
-      that the PHY uses a fixed crystal or an internal oscillator.
-
   enet-phy-lane-swap:
     $ref: /schemas/types.yaml#/definitions/flag
     description:
diff --git a/Documentation/devicetree/bindings/net/realtek,rtl82xx.yaml b/Documentation/devicetree/bindings/net/realtek,rtl82xx.yaml
index 45033c31a2d5..8a26f6941dc4 100644
--- a/Documentation/devicetree/bindings/net/realtek,rtl82xx.yaml
+++ b/Documentation/devicetree/bindings/net/realtek,rtl82xx.yaml
@@ -38,6 +38,12 @@ properties:
       - ethernet-phy-id001c.cad0
       - ethernet-phy-id001c.cb00
 
+  clocks:
+    maxItems: 1
+    description:
+      External clock connected to the PHY. If not specified it is assumed
+      that the PHY uses a fixed crystal or an internal oscillator.
+
   leds: true
 
   realtek,aldps-enable:

-- 
2.53.0

