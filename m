From: =?utf-8?q?Ar=C4=B1n=C3=A7_=C3=9CNAL?= <arinc.unal@arinc9.com>
Date: Mon, 22 Apr 2024 10:15:12 +0300
Subject: [PATCH net-next v2 05/15] net: dsa: mt7530: refactor MT7530_MFC
 and MT7531_CFC, add MT7531_QRY_FFP
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20240422-for-netnext-mt7530-improvements-4-v2-5-a75157ba76ad@arinc9.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1713770127; l=7840;
 i=arinc.unal@arinc9.com; s=arinc9-Xeront; h=from:subject:message-id;
 bh=sGSHaq4RxnxW2EpnmYPnfHMUSXd9a7KtPXo7IfxtfVg=;
 b=3XeJYXIoO1fygU8zz4F6hUky4tO0ajkfTVRj5WSwUlUiulhOrjBQ3qXDfHtvLjeteW+WoaIkN
 AfFhHMxRJJHCPcgfcPhz+4jBpCHS1OZ+1IU87I60RxlfOObm/qav3+k
X-Developer-Key: i=arinc.unal@arinc9.com; a=ed25519;
 pk=z49tLn29CyiL4uwBTrqH9HO1Wu3sZIuRp4DaLZvtP9M=
X-Endpoint-Received: by B4 Relay for arinc.unal@arinc9.com/arinc9-Xeront with auth_id=137
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The MT7530_MFC register is on MT7530, MT7531, and the switch on the MT7988
SoC. Rename it to MT753X_MFC. Bit 7 to 0 differs between MT7530 and
MT7531/MT7988. Add MT7530 prefix to these definitions, and define the
IGMP/MLD Query Frame Flooding Ports mask for MT7531.

Rename the cases of MIRROR_MASK to MIRROR_PORT_MASK.

Move mt753x_mirror_port_get() and mt753x_port_mirror_set() to mt7530.h as
macros.

Signed-off-by: Arınç ÜNAL <arinc.unal@arinc9.com>
---
 drivers/net/dsa/mt7530.c | 38 +++++++++-----------------
 drivers/net/dsa/mt7530.h | 69 ++++++++++++++++++++++++++++++------------------
 2 files changed, 57 insertions(+), 50 deletions(-)

diff --git a/drivers/net/dsa/mt7530.c b/drivers/net/dsa/mt7530.c
index 7f864f895ba0..39c47499036b 100644
--- a/drivers/net/dsa/mt7530.c
+++ b/drivers/net/dsa/mt7530.c
@@ -1147,7 +1147,7 @@ mt753x_cpu_port_enable(struct dsa_switch *ds, int port)
 		     PORT_SPEC_TAG);
 
 	/* Enable flooding on the CPU port */
-	mt7530_set(priv, MT7530_MFC, BC_FFP(BIT(port)) | UNM_FFP(BIT(port)) |
+	mt7530_set(priv, MT753X_MFC, BC_FFP(BIT(port)) | UNM_FFP(BIT(port)) |
 		   UNU_FFP(BIT(port)));
 
 	/* Add the CPU port to the CPU port bitmap for MT7531 and the switch on
@@ -1311,15 +1311,15 @@ mt7530_port_bridge_flags(struct dsa_switch *ds, int port,
 			   flags.val & BR_LEARNING ? 0 : SA_DIS);
 
 	if (flags.mask & BR_FLOOD)
-		mt7530_rmw(priv, MT7530_MFC, UNU_FFP(BIT(port)),
+		mt7530_rmw(priv, MT753X_MFC, UNU_FFP(BIT(port)),
 			   flags.val & BR_FLOOD ? UNU_FFP(BIT(port)) : 0);
 
 	if (flags.mask & BR_MCAST_FLOOD)
-		mt7530_rmw(priv, MT7530_MFC, UNM_FFP(BIT(port)),
+		mt7530_rmw(priv, MT753X_MFC, UNM_FFP(BIT(port)),
 			   flags.val & BR_MCAST_FLOOD ? UNM_FFP(BIT(port)) : 0);
 
 	if (flags.mask & BR_BCAST_FLOOD)
-		mt7530_rmw(priv, MT7530_MFC, BC_FFP(BIT(port)),
+		mt7530_rmw(priv, MT753X_MFC, BC_FFP(BIT(port)),
 			   flags.val & BR_BCAST_FLOOD ? BC_FFP(BIT(port)) : 0);
 
 	return 0;
@@ -1855,20 +1855,6 @@ mt7530_port_vlan_del(struct dsa_switch *ds, int port,
 	return 0;
 }
 
-static int mt753x_mirror_port_get(unsigned int id, u32 val)
-{
-	return (id == ID_MT7531 || id == ID_MT7988) ?
-		       MT7531_MIRROR_PORT_GET(val) :
-		       MIRROR_PORT(val);
-}
-
-static int mt753x_mirror_port_set(unsigned int id, u32 val)
-{
-	return (id == ID_MT7531 || id == ID_MT7988) ?
-		       MT7531_MIRROR_PORT_SET(val) :
-		       MIRROR_PORT(val);
-}
-
 static int mt753x_port_mirror_add(struct dsa_switch *ds, int port,
 				  struct dsa_mall_mirror_tc_entry *mirror,
 				  bool ingress, struct netlink_ext_ack *extack)
@@ -1884,14 +1870,14 @@ static int mt753x_port_mirror_add(struct dsa_switch *ds, int port,
 	val = mt7530_read(priv, MT753X_MIRROR_REG(priv->id));
 
 	/* MT7530 only supports one monitor port */
-	monitor_port = mt753x_mirror_port_get(priv->id, val);
+	monitor_port = MT753X_MIRROR_PORT_GET(priv->id, val);
 	if (val & MT753X_MIRROR_EN(priv->id) &&
 	    monitor_port != mirror->to_local_port)
 		return -EEXIST;
 
 	val |= MT753X_MIRROR_EN(priv->id);
-	val &= ~MT753X_MIRROR_MASK(priv->id);
-	val |= mt753x_mirror_port_set(priv->id, mirror->to_local_port);
+	val &= ~MT753X_MIRROR_PORT_MASK(priv->id);
+	val |= MT753X_MIRROR_PORT_SET(priv->id, mirror->to_local_port);
 	mt7530_write(priv, MT753X_MIRROR_REG(priv->id), val);
 
 	val = mt7530_read(priv, MT7530_PCR_P(port));
@@ -2533,7 +2519,7 @@ mt7531_setup_common(struct dsa_switch *ds)
 	mt7530_mib_reset(ds);
 
 	/* Disable flooding on all ports */
-	mt7530_clear(priv, MT7530_MFC, BC_FFP_MASK | UNM_FFP_MASK |
+	mt7530_clear(priv, MT753X_MFC, BC_FFP_MASK | UNM_FFP_MASK |
 		     UNU_FFP_MASK);
 
 	for (i = 0; i < MT7530_NUM_PORTS; i++) {
@@ -3089,10 +3075,12 @@ mt753x_conduit_state_change(struct dsa_switch *ds,
 	else
 		priv->active_cpu_ports &= ~mask;
 
-	if (priv->active_cpu_ports)
-		val = CPU_EN | CPU_PORT(__ffs(priv->active_cpu_ports));
+	if (priv->active_cpu_ports) {
+		val = MT7530_CPU_EN |
+		      MT7530_CPU_PORT(__ffs(priv->active_cpu_ports));
+	}
 
-	mt7530_rmw(priv, MT7530_MFC, CPU_EN | CPU_PORT_MASK, val);
+	mt7530_rmw(priv, MT753X_MFC, MT7530_CPU_EN | MT7530_CPU_PORT_MASK, val);
 }
 
 static int mt7988_setup(struct dsa_switch *ds)
diff --git a/drivers/net/dsa/mt7530.h b/drivers/net/dsa/mt7530.h
index 0d5167f5ba6b..c6ef20b7bbdd 100644
--- a/drivers/net/dsa/mt7530.h
+++ b/drivers/net/dsa/mt7530.h
@@ -36,36 +36,55 @@ enum mt753x_id {
 #define MT753X_AGC			0xc
 #define  LOCAL_EN			BIT(7)
 
-/* Registers to mac forward control for unknown frames */
-#define MT7530_MFC			0x10
-#define  BC_FFP(x)			(((x) & 0xff) << 24)
-#define  BC_FFP_MASK			BC_FFP(~0)
-#define  UNM_FFP(x)			(((x) & 0xff) << 16)
-#define  UNM_FFP_MASK			UNM_FFP(~0)
-#define  UNU_FFP(x)			(((x) & 0xff) << 8)
-#define  UNU_FFP_MASK			UNU_FFP(~0)
-#define  CPU_EN				BIT(7)
-#define  CPU_PORT_MASK			GENMASK(6, 4)
-#define  CPU_PORT(x)			FIELD_PREP(CPU_PORT_MASK, x)
-#define  MIRROR_EN			BIT(3)
-#define  MIRROR_PORT(x)			((x) & 0x7)
-#define  MIRROR_MASK			0x7
-
-/* Registers for CPU forward control */
+/* Register for MAC forward control */
+#define MT753X_MFC			0x10
+#define  BC_FFP_MASK			GENMASK(31, 24)
+#define  BC_FFP(x)			FIELD_PREP(BC_FFP_MASK, x)
+#define  UNM_FFP_MASK			GENMASK(23, 16)
+#define  UNM_FFP(x)			FIELD_PREP(UNM_FFP_MASK, x)
+#define  UNU_FFP_MASK			GENMASK(15, 8)
+#define  UNU_FFP(x)			FIELD_PREP(UNU_FFP_MASK, x)
+#define  MT7530_CPU_EN			BIT(7)
+#define  MT7530_CPU_PORT_MASK		GENMASK(6, 4)
+#define  MT7530_CPU_PORT(x)		FIELD_PREP(MT7530_CPU_PORT_MASK, x)
+#define  MT7530_MIRROR_EN		BIT(3)
+#define  MT7530_MIRROR_PORT_MASK	GENMASK(2, 0)
+#define  MT7530_MIRROR_PORT_GET(x)	FIELD_GET(MT7530_MIRROR_PORT_MASK, x)
+#define  MT7530_MIRROR_PORT_SET(x)	FIELD_PREP(MT7530_MIRROR_PORT_MASK, x)
+#define  MT7531_QRY_FFP_MASK		GENMASK(7, 0)
+#define  MT7531_QRY_FFP(x)		FIELD_PREP(MT7531_QRY_FFP_MASK, x)
+
+/* Register for CPU forward control */
 #define MT7531_CFC			0x4
 #define  MT7531_MIRROR_EN		BIT(19)
-#define  MT7531_MIRROR_MASK		(MIRROR_MASK << 16)
-#define  MT7531_MIRROR_PORT_GET(x)	(((x) >> 16) & MIRROR_MASK)
-#define  MT7531_MIRROR_PORT_SET(x)	(((x) & MIRROR_MASK) << 16)
+#define  MT7531_MIRROR_PORT_MASK	GENMASK(18, 16)
+#define  MT7531_MIRROR_PORT_GET(x)	FIELD_GET(MT7531_MIRROR_PORT_MASK, x)
+#define  MT7531_MIRROR_PORT_SET(x)	FIELD_PREP(MT7531_MIRROR_PORT_MASK, x)
 #define  MT7531_CPU_PMAP_MASK		GENMASK(7, 0)
 #define  MT7531_CPU_PMAP(x)		FIELD_PREP(MT7531_CPU_PMAP_MASK, x)
 
-#define MT753X_MIRROR_REG(id)		((((id) == ID_MT7531) || ((id) == ID_MT7988)) ?	\
-					 MT7531_CFC : MT7530_MFC)
-#define MT753X_MIRROR_EN(id)		((((id) == ID_MT7531) || ((id) == ID_MT7988)) ?	\
-					 MT7531_MIRROR_EN : MIRROR_EN)
-#define MT753X_MIRROR_MASK(id)		((((id) == ID_MT7531) || ((id) == ID_MT7988)) ?	\
-					 MT7531_MIRROR_MASK : MIRROR_MASK)
+#define MT753X_MIRROR_REG(id)		((id == ID_MT7531 || \
+					  id == ID_MT7988) ? \
+					 MT7531_CFC : MT753X_MFC)
+
+#define MT753X_MIRROR_EN(id)		((id == ID_MT7531 || \
+					  id == ID_MT7988) ? \
+					 MT7531_MIRROR_EN : MT7530_MIRROR_EN)
+
+#define MT753X_MIRROR_PORT_MASK(id)	((id == ID_MT7531 || \
+					  id == ID_MT7988) ? \
+					 MT7531_MIRROR_PORT_MASK : \
+					 MT7530_MIRROR_PORT_MASK)
+
+#define MT753X_MIRROR_PORT_GET(id, val)	((id == ID_MT7531 || \
+					  id == ID_MT7988) ? \
+					 MT7531_MIRROR_PORT_GET(val) : \
+					 MT7530_MIRROR_PORT_GET(val))
+
+#define MT753X_MIRROR_PORT_SET(id, val)	((id == ID_MT7531 || \
+					  id == ID_MT7988) ? \
+					 MT7531_MIRROR_PORT_SET(val) : \
+					 MT7530_MIRROR_PORT_SET(val))
 
 /* Register for BPDU and PAE frame control */
 #define MT753X_BPC			0x24

-- 
2.40.1

