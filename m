From: =?utf-8?q?Ar=C4=B1n=C3=A7_=C3=9CNAL?= <arinc.unal@arinc9.com>
Date: Mon, 22 Apr 2024 10:15:19 +0300
Subject: [PATCH net-next v2 12/15] net: dsa: mt7530: get rid of
 mac_port_validate member of mt753x_info
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20240422-for-netnext-mt7530-improvements-4-v2-12-a75157ba76ad@arinc9.com>
References: <20240422-for-netnext-mt7530-improvements-4-v2-0-a75157ba76ad@arinc9.com>
In-Reply-To: <20240422-for-netnext-mt7530-improvements-4-v2-0-a75157ba76ad@arinc9.com>
To: Daniel Golle <daniel@makrotopia.org>, DENG Qingfang <dqfext@gmail.com>, 
 Sean Wang <sean.wang@mediatek.com>, Andrew Lunn <andrew@lunn.ch>, 
 Florian Fainelli <f.fainelli@gmail.com>, 
 Vladimir Oltean <olteanv@gmail.com>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Matthias Brugger <matthias.bgg@gmail.com>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>, 
 Russell King <linux@armlinux.org.uk>
Cc: Bartel Eerdekens <bartel.eerdekens@constell8.be>, 
 mithat.guner@xeront.com, erkin.bozoglu@xeront.com, netdev@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-mediatek@lists.infradead.org, 
 =?utf-8?q?Ar=C4=B1n=C3=A7_=C3=9CNAL?= <arinc.unal@arinc9.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1713770127; l=1895;
 i=arinc.unal@arinc9.com; s=arinc9-Xeront; h=from:subject:message-id;
 bh=eQVxi9XpKVjFwy7G/fq5LbkX2JyuVqKa+YvcokozwTs=;
 b=GgpCu/Y1Z9ir60LhRY9KQrTo4YU8dcdz5TAEg6d1AtWSTPBmF2HFUtGt8VLQ4EH5FL+8o1UVO
 YEf/r6ytza4BZ+zDswwMeepMid3wYdwg9dfqG8+ydAhoONXgB2awpwl
X-Developer-Key: i=arinc.unal@arinc9.com; a=ed25519;
 pk=z49tLn29CyiL4uwBTrqH9HO1Wu3sZIuRp4DaLZvtP9M=
X-Endpoint-Received: by B4 Relay for arinc.unal@arinc9.com/arinc9-Xeront with auth_id=137
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The mac_port_validate member of the mt753x_info structure is not being
used, remove it. Improve the member description section in the process.

Signed-off-by: Arınç ÜNAL <arinc.unal@arinc9.com>
---
 drivers/net/dsa/mt7530.h | 10 +++-------
 1 file changed, 3 insertions(+), 7 deletions(-)

diff --git a/drivers/net/dsa/mt7530.h b/drivers/net/dsa/mt7530.h
index 6a6ef34b48c4..2ea4e24628c6 100644
--- a/drivers/net/dsa/mt7530.h
+++ b/drivers/net/dsa/mt7530.h
@@ -743,15 +743,14 @@ struct mt753x_pcs {
 
 /* struct mt753x_info -	This is the main data structure for holding the specific
  *			part for each supported device
+ * @id:			Holding the identifier to a switch model
+ * @pcs_ops:		Holding the pointer to the MAC PCS operations structure
  * @sw_setup:		Holding the handler to a device initialization
  * @phy_read_c22:	Holding the way reading PHY port using C22
  * @phy_write_c22:	Holding the way writing PHY port using C22
  * @phy_read_c45:	Holding the way reading PHY port using C45
  * @phy_write_c45:	Holding the way writing PHY port using C45
- * @phy_mode_supported:	Check if the PHY type is being supported on a certain
- *			port
- * @mac_port_validate:	Holding the way to set addition validate type for a
- *			certan MAC port
+ * @mac_port_get_caps:	Holding the handler that provides MAC capabilities
  * @mac_port_config:	Holding the way setting up the PHY attribute to a
  *			certain MAC port
  */
@@ -770,9 +769,6 @@ struct mt753x_info {
 			     int regnum, u16 val);
 	void (*mac_port_get_caps)(struct dsa_switch *ds, int port,
 				  struct phylink_config *config);
-	void (*mac_port_validate)(struct dsa_switch *ds, int port,
-				  phy_interface_t interface,
-				  unsigned long *supported);
 	void (*mac_port_config)(struct dsa_switch *ds, int port,
 				unsigned int mode,
 				phy_interface_t interface);

-- 
2.40.1

