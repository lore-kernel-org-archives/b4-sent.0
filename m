From: =?utf-8?q?Ar=C4=B1n=C3=A7_=C3=9CNAL?= <arinc.unal@arinc9.com>
Date: Sat, 13 Apr 2024 16:01:40 +0300
Subject: [PATCH net 2/2] net: dsa: mt7530: fix port mirroring for MT7988
 SoC switch
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20240413-b4-for-net-mt7530-fix-mirroring-to-local-port-and-mt7988-v1-2-476deff8cc06@arinc9.com>
References: <20240413-b4-for-net-mt7530-fix-mirroring-to-local-port-and-mt7988-v1-0-476deff8cc06@arinc9.com>
In-Reply-To: <20240413-b4-for-net-mt7530-fix-mirroring-to-local-port-and-mt7988-v1-0-476deff8cc06@arinc9.com>
To: Daniel Golle <daniel@makrotopia.org>, DENG Qingfang <dqfext@gmail.com>, 
 Sean Wang <sean.wang@mediatek.com>, Andrew Lunn <andrew@lunn.ch>, 
 Florian Fainelli <f.fainelli@gmail.com>, 
 Vladimir Oltean <olteanv@gmail.com>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Matthias Brugger <matthias.bgg@gmail.com>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>
Cc: Holger Stadali <hs@giax.de>, 
 Bartel Eerdekens <bartel.eerdekens@constell8.be>, mithat.guner@xeront.com, 
 erkin.bozoglu@xeront.com, netdev@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-mediatek@lists.infradead.org, 
 =?utf-8?q?Ar=C4=B1n=C3=A7_=C3=9CNAL?= <arinc.unal@arinc9.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1713013352; l=1595;
 i=arinc.unal@arinc9.com; s=arinc9-patatt; h=from:subject:message-id;
 bh=J5sBZDEYQ2MZhOw2PxMAD+gQryIOB3G0EIw5h33fGKY=;
 b=1ey++0YizyHi3vcP2NlwKUdn8ZXxyN89dYXm/TAlv6xdycNAjjkoeViF08Xq34iWLaB/yBlgs
 7aq3qAX1yCuA5RcztQ1SxOoidtaDCWL3nktMXq4ac2BoLg8BcYRTy5I
X-Developer-Key: i=arinc.unal@arinc9.com; a=ed25519;
 pk=VmvgMWwm73yVIrlyJYvGtnXkQJy9CvbaeEqPQO9Z4kA=
X-Endpoint-Received: by B4 Relay for arinc.unal@arinc9.com/arinc9-patatt with auth_id=115
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The "MT7988A Wi-Fi 7 Generation Router Platform: Datasheet (Open Version)
v0.1" document shows bits 16 to 18 as the MIRROR_PORT field of the CPU
forward control register. Currently, the MT7530 DSA subdriver configures
bits 0 to 2 of the CPU forward control register which breaks the port
mirroring feature for the MT7988 SoC switch.

Fix this by using the MT7531_MIRROR_PORT_GET() and MT7531_MIRROR_PORT_SET()
macros which utilise the correct bits.

Fixes: 110c18bfed41 ("net: dsa: mt7530: introduce driver for MT7988 built-in switch")
Signed-off-by: Arınç ÜNAL <arinc.unal@arinc9.com>
---
 drivers/net/dsa/mt7530.c | 10 ++++++----
 1 file changed, 6 insertions(+), 4 deletions(-)

diff --git a/drivers/net/dsa/mt7530.c b/drivers/net/dsa/mt7530.c
index b84e1845fa02..8090390edaf9 100644
--- a/drivers/net/dsa/mt7530.c
+++ b/drivers/net/dsa/mt7530.c
@@ -1883,14 +1883,16 @@ mt7530_port_vlan_del(struct dsa_switch *ds, int port,
 
 static int mt753x_mirror_port_get(unsigned int id, u32 val)
 {
-	return (id == ID_MT7531) ? MT7531_MIRROR_PORT_GET(val) :
-				   MIRROR_PORT(val);
+	return (id == ID_MT7531 || id == ID_MT7988) ?
+		       MT7531_MIRROR_PORT_GET(val) :
+		       MIRROR_PORT(val);
 }
 
 static int mt753x_mirror_port_set(unsigned int id, u32 val)
 {
-	return (id == ID_MT7531) ? MT7531_MIRROR_PORT_SET(val) :
-				   MIRROR_PORT(val);
+	return (id == ID_MT7531 || id == ID_MT7988) ?
+		       MT7531_MIRROR_PORT_SET(val) :
+		       MIRROR_PORT(val);
 }
 
 static int mt753x_port_mirror_add(struct dsa_switch *ds, int port,

-- 
2.40.1

