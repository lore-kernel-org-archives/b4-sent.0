From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Fri, 13 Nov 2026 08:04:00 +0000
Subject: [PATCH net-next] net: stmmac: dwmac-sun8i: Defer probe when the
 EPHY clock is not ready
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261113-b4-sun8i-emac-ephy-defer-v1-1-12a8591702fe@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yWMwQ6CMBAFf4Xs2U0obQj4K8ZDKQ9ZEyvpFoMh/
 LtVj5PJzE6KJFA6VzslvETlGQuYU0Vh9vEGlrEwNXXTGmMsD451jZ0wHj4wlvnNIyYkdl0dbG9
 7h9ZTyZeESbbf+kIRmSO2TNe/0XW4I+TvmY7jAySUWp6GAAAA
X-Change-ID: 20261113-b4-sun8i-emac-ephy-defer-480c39394e6a
To: Maxime Chevallier <maxime.chevallier@bootlin.com>, 
 Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@kernel.org>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Maxime Coquelin <mcoquelin.stm32@gmail.com>, 
 Alexandre Torgue <alexandre.torgue@foss.st.com>, 
 Chen-Yu Tsai <wens@kernel.org>, Jernej Skrabec <jernej.skrabec@gmail.com>, 
 Samuel Holland <samuel@sholland.org>, 
 Corentin Labbe <clabbe.montjoie@gmail.com>
Cc: netdev@vger.kernel.org, linux-stm32@st-md-mailman.stormreply.com, 
 linux-arm-kernel@lists.infradead.org, linux-sunxi@lists.linux.dev, 
 linux-kernel@vger.kernel.org, Arun Iyengar <aiyengar1990@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794557039; l=2284;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=3vOWWV9l/RPEbbthTMkW1C/XCstj8pm3YVWcUELiCkk=;
 b=Zh00xt2IqE0H4WmqmMEFzkuWSzcVdr9Qa1Qf6eTGMm86i/HvyogK5dSaE/9LQJc9xcVZIiy9D
 Q9zA4UQMzy0DKdbTShY1TsZo15qzneFaut3ohv/froP6aUhibJFsMIG
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

get_ephy_nodes() skips an internal PHY node on any of_clk_get() error.
If the EPHY clock provider is not registered yet, the node is skipped,
the function returns -ENODEV and the probe fails for good. The reset
lookup right below already returns -EPROBE_DEFER in this case.

Return -EPROBE_DEFER for the clock too. Other clock errors still skip
the node, as before.

Fixes: 9f93ac8d4085 ("net-next: stmmac: Add dwmac-sun8i")
Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
Reported by the Sashiko review bot while it reviewed my MDIO mux error
path fix for this driver:
https://sashiko.dev/#/bug/linux-98384c14-541e-410e-a074-fff5e98b3820

Only the H3/H5 and V3s variants (soc_has_internal_phy) reach this code.
With the in-tree device trees the EPHY clock comes from the same CCU as
the EMAC clock and reset, so the EMAC probe already waits for that CCU
and this cannot fail there. It matters when the EPHY clock comes
from a provider that probes later. Build-tested only (W=1, arm64 and
arm); I have no board with the internal PHY.

This patch was developed with Claude (Anthropic) as a coding assistant:
it checked the report against the code and wrote the fix and the commit
message. I reviewed it.
---
 drivers/net/ethernet/stmicro/stmmac/dwmac-sun8i.c | 7 ++++++-
 1 file changed, 6 insertions(+), 1 deletion(-)

diff --git a/drivers/net/ethernet/stmicro/stmmac/dwmac-sun8i.c b/drivers/net/ethernet/stmicro/stmmac/dwmac-sun8i.c
index 2ece7ba9dd73..8163e49fa7ad 100644
--- a/drivers/net/ethernet/stmicro/stmmac/dwmac-sun8i.c
+++ b/drivers/net/ethernet/stmicro/stmmac/dwmac-sun8i.c
@@ -801,8 +801,13 @@ static int get_ephy_nodes(struct stmmac_priv *priv)
 		struct clk *ephy_clk;
 
 		ephy_clk = of_clk_get(iphynode, 0);
-		if (IS_ERR(ephy_clk))
+		if (IS_ERR(ephy_clk)) {
+			if (PTR_ERR(ephy_clk) == -EPROBE_DEFER) {
+				of_node_put(mdio_internal);
+				return -EPROBE_DEFER;
+			}
 			continue;
+		}
 		gmac->rst_ephy = of_reset_control_get_exclusive(iphynode, NULL);
 		if (IS_ERR(gmac->rst_ephy)) {
 			ret = PTR_ERR(gmac->rst_ephy);

---
base-commit: 573af801552999954caa8347e4490b04cf4763f0
change-id: 20261113-b4-sun8i-emac-ephy-defer-480c39394e6a

Best regards,
--  
Arun Iyengar <aiyengar1990@gmail.com>

