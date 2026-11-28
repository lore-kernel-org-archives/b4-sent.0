From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Sat, 28 Nov 2026 17:37:03 +0000
Subject: [PATCH net-next v5 4/6] net: stmmac: Assert the resets after
 unregistering the MDIO bus
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261128-sun8i-emac-mux-uaf-v5-4-0869f2ccdb8b@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795887420; l=1603;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=DTcXXb/dRBfp8NpiHWgnCWsLsU86F3mVbGpIU8u2ol0=;
 b=AEKUf92gWY3A4K8xq2XRY0xCM684mn6oYBwycKoJe9TEu88aRMssuK+zyJEcOw9seIPp7a0b0
 YtUDvbnF3kODba9T8TItV75dk0Thym41WLGPrxcv90+nRkDX/E4QbkU
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

stmmac_dvr_remove() asserts the MAC resets before it unregisters the
MDIO bus, so the PHYs on the bus are removed with the MDIO master in
reset. The probe error path does not assert them at all.

Assert them after the PCS and the MDIO bus are gone in both.

Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 drivers/net/ethernet/stmicro/stmmac/stmmac_main.c | 9 ++++++---
 1 file changed, 6 insertions(+), 3 deletions(-)

diff --git a/drivers/net/ethernet/stmicro/stmmac/stmmac_main.c b/drivers/net/ethernet/stmicro/stmmac/stmmac_main.c
index 1280496741e7..da03a8223bba 100644
--- a/drivers/net/ethernet/stmicro/stmmac/stmmac_main.c
+++ b/drivers/net/ethernet/stmicro/stmmac/stmmac_main.c
@@ -8406,6 +8406,9 @@ static int __stmmac_dvr_probe(struct device *device,
 	pm_runtime_put_noidle(device);
 	stmmac_napi_del(ndev);
 error_hw_init:
+	if (priv->plat->stmmac_rst)
+		reset_control_assert(priv->plat->stmmac_rst);
+	reset_control_assert(priv->plat->stmmac_ahb_rst);
 	destroy_workqueue(priv->wq);
 error_wq_init:
 	bitmap_free(priv->af_xdp_zc_qps);
@@ -8465,13 +8468,13 @@ void stmmac_dvr_remove(struct device *dev)
 	stmmac_unregister_devlink(priv);
 
 	phylink_destroy(priv->phylink);
+	stmmac_pcs_clean(ndev);
+	stmmac_mdio_unregister(ndev);
+
 	if (priv->plat->stmmac_rst)
 		reset_control_assert(priv->plat->stmmac_rst);
 	reset_control_assert(priv->plat->stmmac_ahb_rst);
 
-	stmmac_pcs_clean(ndev);
-	stmmac_mdio_unregister(ndev);
-
 	destroy_workqueue(priv->wq);
 	mutex_destroy(&priv->lock);
 	mutex_destroy(&priv->est_lock);

-- 
2.55.0

