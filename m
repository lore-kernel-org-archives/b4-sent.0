From: George Moussalem <george.moussalem@outlook.com>
Date: Fri, 05 Jun 2026 16:41:26 +0400
Subject: [PATCH v3 1/4] dt-bindings: net: ethernet-phy: increase max clock
 count to two
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260605-ipq5018-gephy-clocks-v3-1-f232d9ca0966@outlook.com>
References: <20260605-ipq5018-gephy-clocks-v3-0-f232d9ca0966@outlook.com>
In-Reply-To: <20260605-ipq5018-gephy-clocks-v3-0-f232d9ca0966@outlook.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1780663297; l=1689;
 i=george.moussalem@outlook.com; s=20250321; h=from:subject:message-id;
 bh=LaY00tRcmZfFwiKiQy3sLDDbN7PRP6JIqJfZseU/bhY=;
 b=Ej4W7dTZsUe7bJ0nU4A8yVnozkz8GdTH0hVntcxUuPQzJYRIsytXROniAzIPdr//9IZNg5gT7
 v3gRNnJPwSyBrYZgLw1DkNcHByDhSIeIwj8v/9VIfxL8OqOfnSPTCny
X-Developer-Key: i=george.moussalem@outlook.com; a=ed25519;
 pk=/PuRTSI9iYiHwcc6Nrde8qF4ZDhJBlUgpHdhsIjnqIk=
X-Endpoint-Received: by B4 Relay for george.moussalem@outlook.com/20250321 with auth_id=364
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The clocks property has a restriction to maximum one.
Yet, some PHYs may require more than 1 clock such as the IPQ5018 PHY
which requires two clocks for RX and TX. As such, increase maxItems to
two.

Signed-off-by: George Moussalem <george.moussalem@outlook.com>
---
Commit 350b7a258f20 introduced the clocks property with a restriction to
maximum 1 to the main ethernet-phy.yaml binding for Realtek to add an
optional external clock source. This is restrictive to all PHY bindings,
as some PHYs may require more than 1 clock such as the IPQ5018 PHY which
requires 2 clocks (for RX and TX).
---
 Documentation/devicetree/bindings/net/ethernet-phy.yaml | 9 ++++++---
 1 file changed, 6 insertions(+), 3 deletions(-)

diff --git a/Documentation/devicetree/bindings/net/ethernet-phy.yaml b/Documentation/devicetree/bindings/net/ethernet-phy.yaml
index 21a1a63506f0..c3ebb3af8b52 100644
--- a/Documentation/devicetree/bindings/net/ethernet-phy.yaml
+++ b/Documentation/devicetree/bindings/net/ethernet-phy.yaml
@@ -106,10 +106,13 @@ properties:
       by software.
 
   clocks:
-    maxItems: 1
+    minItems: 1
+    maxItems: 2
     description:
-      External clock connected to the PHY. If not specified it is assumed
-      that the PHY uses a fixed crystal or an internal oscillator.
+      External clock connected to the PHY or RX and TX clocks that the PHY
+      requires to enable explicitly. If not specified it is assumed
+      that the PHY uses a fixed crystal or an internal oscillator or that the
+      RX/TX clocks are hardware enabled by default.
 
   enet-phy-lane-swap:
     $ref: /schemas/types.yaml#/definitions/flag

-- 
2.53.0

