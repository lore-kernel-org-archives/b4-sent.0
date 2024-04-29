From: =?utf-8?q?Ar=C4=B1n=C3=A7_=C3=9CNAL?= <arinc.unal@arinc9.com>
Date: Mon, 29 Apr 2024 12:46:43 +0300
Subject: [PATCH net-next] net: dsa: mt7530: detect PHY muxing when PHY is
 defined on switch MDIO bus
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20240429-b4-for-netnext-mt7530-use-switch-mdio-bus-for-phy-muxing-v1-1-1f775983e155@arinc9.com>
X-B4-Tracking: v=1; b=H4sIAIJsL2YC/x3NQQ6DIBCF4auYWXcSRNDaq5guqo4yC8AAtjTGu
 5e6/JOX7x0QKTBFeFQHBHpzZO9K1LcKJvNyKyHPpUEKqYSSPY4KFx/QUXKUE9rU6UbgHgnjh9N
 k0M7scdzjNdvMF+2e2a2o761s+6arJ62h8FughfN1PUDh8O/B8zx/gMKG6ZQAAAA=
To: Daniel Golle <daniel@makrotopia.org>, DENG Qingfang <dqfext@gmail.com>, 
 Sean Wang <sean.wang@mediatek.com>, Andrew Lunn <andrew@lunn.ch>, 
 Florian Fainelli <f.fainelli@gmail.com>, 
 Vladimir Oltean <olteanv@gmail.com>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Matthias Brugger <matthias.bgg@gmail.com>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>
Cc: Bartel Eerdekens <bartel.eerdekens@constell8.be>, 
 mithat.guner@xeront.com, erkin.bozoglu@xeront.com, netdev@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-mediatek@lists.infradead.org, 
 =?utf-8?q?Ar=C4=B1n=C3=A7_=C3=9CNAL?= <arinc.unal@arinc9.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1714384017; l=1737;
 i=arinc.unal@arinc9.com; s=arinc9-patatt; h=from:subject:message-id;
 bh=aV0b87E50oYhQ0oa+qVZ0uBYjOG8eoZT/UzGqSKMX+s=;
 b=Nq09mU0p4YPp/xi2o2FjpG+iFQnXvtEU3rSX2+/m1lN0qfURodE/M/xzNPYmVb0YMAjA29jt+
 mrN3+nAmij2A4jISevUV4uDaSgAoMYbC1kaiDm0ucx49S8SbqUYx8X2
X-Developer-Key: i=arinc.unal@arinc9.com; a=ed25519;
 pk=VmvgMWwm73yVIrlyJYvGtnXkQJy9CvbaeEqPQO9Z4kA=
X-Endpoint-Received: by B4 Relay for arinc.unal@arinc9.com/arinc9-patatt with auth_id=115
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Currently, the MT7530 DSA subdriver configures the MT7530 switch to provide
direct access to switch PHYs, meaning, the switch PHYs listen on the MDIO
bus the switch listens on. The PHY muxing feature makes use of this.

This is problematic as the PHY may be probed before the switch is
initialised, in which case attaching the PHY will fail.

Since commit 91374ba537bd ("net: dsa: mt7530: support OF-based registration
of switch MDIO bus"), we can describe the switch PHYs on the MDIO bus of
the switch on the device tree. Extend the check to detect PHY muxing when
the PHY is defined on the MDIO bus of the switch on the device tree.

When the PHY is described this way, the switch will be initialised first,
then the switch MDIO bus will be registered. Only after these steps, the
PHY will be probed.

Signed-off-by: Arınç ÜNAL <arinc.unal@arinc9.com>
---
 drivers/net/dsa/mt7530.c | 3 ++-
 1 file changed, 2 insertions(+), 1 deletion(-)

diff --git a/drivers/net/dsa/mt7530.c b/drivers/net/dsa/mt7530.c
index 2b9f904a98f0..6cf21c9d523b 100644
--- a/drivers/net/dsa/mt7530.c
+++ b/drivers/net/dsa/mt7530.c
@@ -2483,7 +2483,8 @@ mt7530_setup(struct dsa_switch *ds)
 			if (!phy_node)
 				continue;
 
-			if (phy_node->parent == priv->dev->of_node->parent) {
+			if (phy_node->parent == priv->dev->of_node->parent ||
+			    phy_node->parent->parent == priv->dev->of_node) {
 				ret = of_get_phy_mode(mac_np, &interface);
 				if (ret && ret != -ENODEV) {
 					of_node_put(mac_np);

---
base-commit: 5c4c0edca68a5841a8d53ccd49596fe199c8334c
change-id: 20240429-b4-for-netnext-mt7530-use-switch-mdio-bus-for-phy-muxing-586269371c55

Best regards,
-- 
Arınç ÜNAL <arinc.unal@arinc9.com>

