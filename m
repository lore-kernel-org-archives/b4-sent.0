From: =?utf-8?q?Ar=C4=B1n=C3=A7_=C3=9CNAL?= <arinc.unal@arinc9.com>
Date: Tue, 30 Apr 2024 08:01:33 +0300
Subject: [PATCH net-next v2] net: dsa: mt7530: detect PHY muxing when PHY
 is defined on switch MDIO bus
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20240430-b4-for-netnext-mt7530-use-switch-mdio-bus-for-phy-muxing-v2-1-9104d886d0db@arinc9.com>
X-B4-Tracking: v=1; b=H4sIACx7MGYC/6WOSw6DMBBDr1LNulNBIHy66j0qFhAGmAUJSgIFI
 e7eNFeovLJsPfsER5bJwfN2gqWNHRsdjLjfQE2tHgm5Dx5EIvIkFzV2OQ7Goiavafc4+1JmCa6
 O0H3Yqwnnng12q4u1ZTpwXnfWI8qqEEWdlamSEgJ+sTTwHqffEHD440ETkomdN/aIn7Y05v/Pb
 ykGDWUp6yqjVMpXa1mr+qHMDM11XV8dryM7CwEAAA==
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1714453297; l=1949;
 i=arinc.unal@arinc9.com; s=arinc9-PC; h=from:subject:message-id;
 bh=c3IRARdnxa6x5otHszH4xrnla2RxJAal1114ej/d2wE=;
 b=FL4WEHh4zYu1gBE7wbaN+X2OMCOIMJVsYBkXurHM0IC3CnI6XfpKE1V5QLUSXby75WZfvQ0se
 lrMQos/eOAaCNbkyxUkmwb3opbC915iywMECA0lv/g0IAo6snRYzMae
X-Developer-Key: i=arinc.unal@arinc9.com; a=ed25519;
 pk=Bd1s2kQtNfZAWyeLHg39jaWBDqt8Ud1WJXLFh7gxl20=
X-Endpoint-Received: by B4 Relay for arinc.unal@arinc9.com/arinc9-PC with auth_id=158
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Currently, the MT7530 DSA subdriver configures the MT7530 switch to provide
direct access to switch PHYs, meaning, the switch PHYs listen on the MDIO
bus the switch listens on. The PHY muxing feature makes use of this.

This is problematic as the PHY may be attached before the switch is
initialised, in which case, the PHY will fail to be attached.

Since commit 91374ba537bd ("net: dsa: mt7530: support OF-based registration
of switch MDIO bus"), we can describe the switch PHYs on the MDIO bus of
the switch on the device tree. Extend the check to detect PHY muxing when
the PHY is defined on the MDIO bus of the switch on the device tree.

When the PHY is described this way, the switch will be initialised first,
then the switch MDIO bus will be registered. Only after these steps, the
PHY will be attached.

Signed-off-by: Arınç ÜNAL <arinc.unal@arinc9.com>
---
Changes in v2:
- Address the terminology on the patch log.
- Link to v1: https://lore.kernel.org/r/20240429-b4-for-netnext-mt7530-use-switch-mdio-bus-for-phy-muxing-v1-1-1f775983e155@arinc9.com
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

