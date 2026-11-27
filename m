From: Juraj Sladek <juraj.sladek@littleit.sk>
Date: Fri, 27 Nov 2026 13:15:54 +0000
Subject: [PATCH net 1/2] net: dsa: realtek: rtl8365mb: reset SerDes data
 path when conduit comes up
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261127-rtl8365mb-hsgmii-fix-v1-1-f2827126aa6a@littleit.sk>
References: <20261127-rtl8365mb-hsgmii-fix-v1-0-f2827126aa6a@littleit.sk>
In-Reply-To: <20261127-rtl8365mb-hsgmii-fix-v1-0-f2827126aa6a@littleit.sk>
To: Linus Walleij <linusw@kernel.org>, 
 Luiz Angelo Daros de Luca <luizluca@gmail.com>, 
 =?utf-8?q?Alvin_=C5=A0ipraga?= <alvin.sipraga@analog.com>, 
 Andrew Lunn <andrew@lunn.ch>, Vladimir Oltean <olteanv@gmail.com>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@kernel.org>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Russell King <linux@armlinux.org.uk>
Cc: Johan Alvarado <contact@c127.dev>, netdev@vger.kernel.org, 
 Juraj Sladek <juraj.sladek@littleit.sk>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795785355; l=5683;
 i=juraj.sladek@littleit.sk; s=20261127; h=from:subject:message-id;
 bh=0YUSMA7OC6o+AJt4wzQ06SzhSjjaDllSgGI4mRa2E5s=;
 b=thEX+Vwxp7Sex2jlME4gfPBQ5NrIooUZ7X6gaT59LF9dceoRsXoLXkgLe382M9JZNhyErJAdR
 GZ0HoE1c4l2B5I29iJy8YwPIZZEMhPgWsTZRJLF1I5sgsOiSLDig3xs
X-Developer-Key: i=juraj.sladek@littleit.sk; a=ed25519;
 pk=AqKiPr9Cm4+alKqIg7OT5xi2bB7LmUEaCQbSaKx1bCs=
X-Endpoint-Received: by B4 Relay for juraj.sladek@littleit.sk/20261127 with auth_id=1667
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The SerDes of the external interface is configured from phylink long
before the conduit Ethernet controller starts transmitting on the link.
On a TP-Link Archer AX55 v1, where the IPQ5018 GMAC is connected to port
6 of an RTL8367S over a 2500base-x (HSGMII) fixed link, the SerDes
receiver regularly comes out of this in a state where every frame
received from the CPU is counted with an FCS error, so the CPU port does
not work at all until the switch is reset.

rtl8365mb_pcs_config() already resets the SerDes data path right after
taking the SerDes out of reset. Repeating that reset once the link
partner actually transmits recovers the receiver, so factor it out and
call it again from the .conduit_state_change() callback when the conduit
becomes operational.

Fixes: 987137345f33 ("net: dsa: realtek: rtl8365mb: add HSGMII support for RTL8367S")
Signed-off-by: Juraj Sladek <juraj.sladek@littleit.sk>
---
 drivers/net/dsa/realtek/rtl8365mb_main.c | 66 +++++++++++++++++++++++++-------
 1 file changed, 53 insertions(+), 13 deletions(-)

diff --git a/drivers/net/dsa/realtek/rtl8365mb_main.c b/drivers/net/dsa/realtek/rtl8365mb_main.c
index da06f952a..54d90121e 100644
--- a/drivers/net/dsa/realtek/rtl8365mb_main.c
+++ b/drivers/net/dsa/realtek/rtl8365mb_main.c
@@ -858,6 +858,7 @@ struct rtl8365mb_port {
  * @pcs: PCS for the SerDes external interface
  * @sds_supported: SerDes tuning parameters match the chip option, so the
  *                 SerDes interface modes can be advertised
+ * @sds_in_use: the SerDes external interface has been configured
  *
  * Private data for this driver.
  */
@@ -870,6 +871,7 @@ struct rtl8365mb {
 	struct rtl8365mb_port ports[RTL8365MB_MAX_NUM_PORTS];
 	struct phylink_pcs pcs;
 	bool sds_supported;
+	bool sds_in_use;
 };
 
 #define pcs_to_rtl8365mb(_pcs) container_of((_pcs), struct rtl8365mb, pcs)
@@ -1380,6 +1382,24 @@ static int rtl8365mb_sds_raise_rate_limits(struct realtek_priv *priv)
 				  RTL8365MB_PORT6_EGRESSBW_CTRL1_MASK);
 }
 
+/* Reset the SerDes data path and resync its PLL, mirroring what the vendor
+ * firmware does right after deasserting the SerDes reset. This flushes the
+ * FIFOs and ensures a clean state for the link, preventing silent drops and
+ * CRC errors.
+ */
+static int rtl8365mb_sds_reset_datapath(struct realtek_priv *priv)
+{
+	int ret;
+
+	ret = rtl8365mb_sds_write(priv, RTL8365MB_SDS_REG_BMCR,
+				  RTL8365MB_SDS_BMCR_DPRST_PHASE1);
+	if (ret)
+		return ret;
+
+	return rtl8365mb_sds_write(priv, RTL8365MB_SDS_REG_BMCR,
+				   RTL8365MB_SDS_BMCR_DPRST_PHASE2);
+}
+
 static int rtl8365mb_pcs_config(struct phylink_pcs *pcs, unsigned int neg_mode,
 				phy_interface_t interface,
 				const unsigned long *advertising,
@@ -1467,18 +1487,7 @@ static int rtl8365mb_pcs_config(struct phylink_pcs *pcs, unsigned int neg_mode,
 	if (ret)
 		return ret;
 
-	/* Reset the SerDes data path and resync its PLL, mirroring what the
-	 * vendor firmware does right after deasserting the SerDes reset.
-	 * This flushes the FIFOs and ensures a clean state for the link,
-	 * preventing silent drops and CRC errors.
-	 */
-	ret = rtl8365mb_sds_write(priv, RTL8365MB_SDS_REG_BMCR,
-				  RTL8365MB_SDS_BMCR_DPRST_PHASE1);
-	if (ret)
-		return ret;
-
-	ret = rtl8365mb_sds_write(priv, RTL8365MB_SDS_REG_BMCR,
-				  RTL8365MB_SDS_BMCR_DPRST_PHASE2);
+	ret = rtl8365mb_sds_reset_datapath(priv);
 	if (ret)
 		return ret;
 
@@ -1492,7 +1501,13 @@ static int rtl8365mb_pcs_config(struct phylink_pcs *pcs, unsigned int neg_mode,
 	val &= ~RTL8365MB_SDS_NWAY_EN_MASK;
 	val |= RTL8365MB_SDS_NWAY_RESTART_MASK;
 
-	return rtl8365mb_sds_write(priv, RTL8365MB_SDS_REG_NWAY, val);
+	ret = rtl8365mb_sds_write(priv, RTL8365MB_SDS_REG_NWAY, val);
+	if (ret)
+		return ret;
+
+	mb->sds_in_use = true;
+
+	return 0;
 }
 
 static bool rtl8365mb_interface_is_serdes(phy_interface_t interface)
@@ -3079,6 +3094,29 @@ static int rtl8365mb_reset_chip(struct realtek_priv *priv)
 					20000, 1e6);
 }
 
+/* The SerDes is configured from phylink long before the conduit Ethernet
+ * controller starts transmitting on the link, so its receiver initially locks
+ * on an idle line. On an RTL8367S connected to an IPQ5018 over HSGMII this
+ * regularly left the switch receiving every frame from the CPU with an FCS
+ * error. Reset the SerDes data path again once the conduit is up.
+ */
+static void rtl8365mb_conduit_state_change(struct dsa_switch *ds,
+					   const struct net_device *conduit,
+					   bool operational)
+{
+	struct realtek_priv *priv = ds->priv;
+	struct rtl8365mb *mb = priv->chip_data;
+	int ret;
+
+	if (!operational || !mb->sds_in_use)
+		return;
+
+	ret = rtl8365mb_sds_reset_datapath(priv);
+	if (ret)
+		dev_err(priv->dev, "failed to reset SerDes data path: %pe\n",
+			ERR_PTR(ret));
+}
+
 static int rtl8365mb_setup(struct dsa_switch *ds)
 {
 	struct realtek_priv *priv = ds->priv;
@@ -3093,6 +3131,7 @@ static int rtl8365mb_setup(struct dsa_switch *ds)
 	cpu = &mb->cpu;
 
 	mb->pcs.ops = &rtl8365mb_pcs_ops;
+	mb->sds_in_use = false;
 
 	/* The SerDes has no link interrupt wired up, so phylink must poll the
 	 * PCS for link changes when it tracks the link through pcs_get_state()
@@ -3414,6 +3453,7 @@ static int rtl8365mb_set_mac_eee(struct dsa_switch *ds, int port,
 }
 
 static const struct dsa_switch_ops rtl8365mb_switch_ops = {
+	.conduit_state_change = rtl8365mb_conduit_state_change,
 	.get_tag_protocol = rtl8365mb_get_tag_protocol,
 	.change_tag_protocol = rtl8365mb_change_tag_protocol,
 	.setup = rtl8365mb_setup,

-- 
2.53.0

