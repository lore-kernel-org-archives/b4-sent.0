From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Sat, 28 Nov 2026 17:37:02 +0000
Subject: [PATCH net-next v5 3/6] net: stmmac: Balance runtime PM when the
 probe fails
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261128-sun8i-emac-mux-uaf-v5-3-0869f2ccdb8b@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795887420; l=1668;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=rH+Zx3E8Ab2jJngSw5MrXl2wadN+CIxd4Z/MEuIR690=;
 b=ZZuVlul74eZkfRspC30kctOJoK9HdJwPwlJ/KX46SvgNxnRgyEMr4Cncv2SZewpcMNwNFzrPy
 F5dOSRPvzhXB46a1Rn8reIJJDoDxpC50zsJ4rhZI+OH3y6nP4dvPCNe
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

__stmmac_dvr_probe() takes a usage count and, unless the bus already
did, enables runtime PM before it registers the MDIO bus, but its error
path undoes neither. After a failed or deferred probe the device never
runtime-suspends.

Drop the usage count, and disable runtime PM if the probe enabled it.

Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 drivers/net/ethernet/stmicro/stmmac/stmmac_main.c | 8 +++++++-
 1 file changed, 7 insertions(+), 1 deletion(-)

diff --git a/drivers/net/ethernet/stmicro/stmmac/stmmac_main.c b/drivers/net/ethernet/stmicro/stmmac/stmmac_main.c
index ca4c7fb11b73..1280496741e7 100644
--- a/drivers/net/ethernet/stmicro/stmmac/stmmac_main.c
+++ b/drivers/net/ethernet/stmicro/stmmac/stmmac_main.c
@@ -8091,6 +8091,7 @@ static int __stmmac_dvr_probe(struct device *device,
 			      struct stmmac_resources *res)
 {
 	struct net_device *ndev = NULL;
+	bool rpm_enabled = false;
 	struct stmmac_priv *priv;
 	int i, ret = 0;
 	u8 rxq;
@@ -8343,8 +8344,10 @@ static int __stmmac_dvr_probe(struct device *device,
 
 	pm_runtime_get_noresume(device);
 	pm_runtime_set_active(device);
-	if (!pm_runtime_enabled(device))
+	if (!pm_runtime_enabled(device)) {
 		pm_runtime_enable(device);
+		rpm_enabled = true;
+	}
 
 	ret = stmmac_mdio_register(ndev);
 	if (ret < 0) {
@@ -8398,6 +8401,9 @@ static int __stmmac_dvr_probe(struct device *device,
 error_pcs_setup:
 	stmmac_mdio_unregister(ndev);
 error_mdio_register:
+	if (rpm_enabled)
+		pm_runtime_disable(device);
+	pm_runtime_put_noidle(device);
 	stmmac_napi_del(ndev);
 error_hw_init:
 	destroy_workqueue(priv->wq);

-- 
2.55.0

