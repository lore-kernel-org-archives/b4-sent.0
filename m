From: Hleb Shauchenka <me@marleb.org>
Date: Sat, 07 Nov 2026 18:00:45 +0100
Subject: [PATCH net-next v2 1/3] dt-bindings: net: ethernet-phy: add
 property #thermal-sensor-cells
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261107-realtek-hwmon-tz-v2-1-6b9a69d44470@marleb.org>
References: <20261107-realtek-hwmon-tz-v2-0-6b9a69d44470@marleb.org>
In-Reply-To: <20261107-realtek-hwmon-tz-v2-0-6b9a69d44470@marleb.org>
To: Andrew Lunn <andrew@lunn.ch>, Heiner Kallweit <hkallweit1@gmail.com>, 
 Russell King <linux@armlinux.org.uk>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@kernel.org>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Florian Fainelli <f.fainelli@gmail.com>
Cc: netdev@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Hleb Shauchenka <me@marleb.org>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1484; i=me@marleb.org;
 h=from:subject:message-id; bh=VRuFxemFp//Th1i9H61fWbV1u2h1anUlOxoYWqWx9q0=;
 b=owJ4nJvAy8zAJTZJnM368y8lXsbTakkMWe8jU1vCJM7/avVac2vXYu5HlrZ79kdtD3cWWFmz8
 LDbsbav/T4dpSwMYlwMsmKKLJuai0Sfrox+61q9JwtmDisTyBAGLk4BmIjvHUaGrZvXHbo7iUX1
 +dPNhrZzD4s9NW/csG6zxL/Wt18fXWpj9mL4w8/16nh+7c1XC1fqBbrLVt815mT2lNnPf6xuy3f
 RxT7XuQGD2ktR
X-Developer-Key: i=me@marleb.org; a=openpgp;
 fpr=B2837215E5A95BED457BBC6A9217063BF3FA220D
X-Endpoint-Received: by B4 Relay for me@marleb.org/default with auth_id=1394
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Aquantia and Marvell PHY drivers register their hwmon temperature
sensor with the thermal framework, and a following patch does the same
for Realtek PHYs, so a thermal zone can reference the PHY node through
thermal-sensors. That requires #thermal-sensor-cells in the PHY node,
which no PHY binding allows: dtbs_check rejects it under MDIO buses
whose PHY children use unevaluatedProperties: false, such as
realtek,rtl9301-mdio.

Allow it in the common PHY binding.

This patch was prepared with AI assistance (Claude Opus 5.5), after an
AI review of the previous posting pointed out the missing property.

Signed-off-by: Hleb Shauchenka <me@marleb.org>
---
 Documentation/devicetree/bindings/net/ethernet-phy.yaml | 6 ++++++
 1 file changed, 6 insertions(+)

diff --git a/Documentation/devicetree/bindings/net/ethernet-phy.yaml b/Documentation/devicetree/bindings/net/ethernet-phy.yaml
index df50c4c33..e2e9e615f 100644
--- a/Documentation/devicetree/bindings/net/ethernet-phy.yaml
+++ b/Documentation/devicetree/bindings/net/ethernet-phy.yaml
@@ -269,6 +269,12 @@ properties:
       have to be placed on board. When omitted, the PHYs default will be left as
       is.
 
+  '#thermal-sensor-cells':
+    const: 0
+    description:
+      Present when the PHY has a temperature sensor that thermal zones can
+      reference.
+
   marvell,reg-init:
     $ref: /schemas/types.yaml#/definitions/uint32-matrix
     deprecated: true

-- 
2.56.0

