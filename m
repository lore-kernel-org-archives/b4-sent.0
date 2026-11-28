From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Sat, 28 Nov 2026 17:37:04 +0000
Subject: [PATCH net-next v5 5/6] net: stmmac: Add MDIO init and exit
 platform hooks
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261128-sun8i-emac-mux-uaf-v5-5-0869f2ccdb8b@gmail.com>
References: <20261128-sun8i-emac-mux-uaf-v5-0-0869f2ccdb8b@gmail.com>
In-Reply-To: <20261128-sun8i-emac-mux-uaf-v5-0-0869f2ccdb8b@gmail.com>
To: Maxime Chevallier <maxime.chevallier@bootlin.com>, 
 Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@kernel.org>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Maxime Coquelin <mcoquelin.stm32@gmail.com>, 
 Alexandre Torgue <alexandre.torgue@foss.st.com>, 
 Chen-Yu Tsai <wens@kernel.org>, Jernej Skrabec <jernej.skrabec@gmail.com>, 
 Samuel Holland <samuel@sholland.org>, 
 Philipp Zabel <p.zabel@pengutronix.de>, 
 Russell King <linux@armlinux.org.uk>
Cc: netdev@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-sunxi@lists.linux.dev, linux-stm32@st-md-mailman.stormreply.com, 
 linux-kernel@vger.kernel.org, Arun Iyengar <aiyengar1990@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795887420; l=2267;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=sU4OlMg5eue6XUYJySuNOsinRijL+atE1x8U133YDQM=;
 b=tti/PpR+O7WEXV9w5+WzUOeBJXHtLQUROe4pAggucvugryhlXV52A5oVyLJAZhotgZMZ8iOyT
 4HghA+OARWqBaVZf7bvCW49gVTanwZpUdZ+4YThKkCGV4SaMQ+ErW6n
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

A glue driver that adds devices on top of the stmmac MDIO bus, such as
an MDIO mux, can only do so after stmmac_dvr_probe() has registered the
netdev.

Add mdio_init(), called once the bus is registered, and mdio_exit(),
called before it is unregistered.

Suggested-by: Maxime Chevallier <maxime.chevallier@bootlin.com>
Tested-by: Maxime Chevallier <maxime.chevallier@bootlin.com>
Reviewed-by: Maxime Chevallier <maxime.chevallier@bootlin.com>
Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 drivers/net/ethernet/stmicro/stmmac/stmmac_mdio.c | 11 +++++++++++
 include/linux/stmmac.h                            |  3 +++
 2 files changed, 14 insertions(+)

diff --git a/drivers/net/ethernet/stmicro/stmmac/stmmac_mdio.c b/drivers/net/ethernet/stmicro/stmmac/stmmac_mdio.c
index 7396b68899c6..fb1f7b1a5323 100644
--- a/drivers/net/ethernet/stmicro/stmmac/stmmac_mdio.c
+++ b/drivers/net/ethernet/stmicro/stmmac/stmmac_mdio.c
@@ -682,8 +682,16 @@ int stmmac_mdio_register(struct net_device *ndev)
 bus_register_done:
 	priv->mii = new_bus;
 
+	if (priv->plat->mdio_init) {
+		err = priv->plat->mdio_init(priv);
+		if (err)
+			goto mdio_init_fail;
+	}
+
 	return 0;
 
+mdio_init_fail:
+	priv->mii = NULL;
 no_phy_found:
 	mdiobus_unregister(new_bus);
 bus_register_fail:
@@ -703,6 +711,9 @@ int stmmac_mdio_unregister(struct net_device *ndev)
 	if (!priv->mii)
 		return 0;
 
+	if (priv->plat->mdio_exit)
+		priv->plat->mdio_exit(priv);
+
 	mdiobus_unregister(priv->mii);
 	priv->mii->priv = NULL;
 	mdiobus_free(priv->mii);
diff --git a/include/linux/stmmac.h b/include/linux/stmmac.h
index 00be2df63d22..a67f1f71eb28 100644
--- a/include/linux/stmmac.h
+++ b/include/linux/stmmac.h
@@ -296,6 +296,9 @@ struct plat_stmmacenet_data {
 	int (*crosststamp)(ktime_t *device, struct system_counterval_t *system,
 			   void *ctx);
 	void (*dump_debug_regs)(void *priv);
+	/* Run while the MDIO bus is registered and the MAC is out of reset */
+	int (*mdio_init)(struct stmmac_priv *priv);
+	void (*mdio_exit)(struct stmmac_priv *priv);
 	int (*pcs_init)(struct stmmac_priv *priv);
 	void (*pcs_exit)(struct stmmac_priv *priv);
 	struct phylink_pcs *(*select_pcs)(struct stmmac_priv *priv,

-- 
2.55.0

