From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Sun, 15 Nov 2026 09:05:07 +0000
Subject: [PATCH net-next v3] net: stmmac: dwmac-sun8i: Fix use-after-free
 in the MDIO mux error path
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261115-sun8i-emac-mux-uaf-v3-1-c69d4189539d@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/33NQQ6CMBAF0KuYrh1Dp7FUV97DuCh1CjVSDKUNh
 nB3C25YGJc/M//9iQXqHQV23k2sp+SC63wOYr9jptG+JnD3nBkWKDnnCCF65YBabaCNI0RtgVd
 aqSPykyViufjqybpxRa/M0wCexoHdvpcQqweZYTGX38aFoevf637ia+PfVOLAQRRKU0nSGouXu
 tXueTBduw4k3BLiJ4GZkFgIKWWFUpVbYp7nD9R3qGETAQAA
X-Change-ID: 20261112-sun8i-emac-mux-uaf-1ba885219fee
To: Maxime Chevallier <maxime.chevallier@bootlin.com>, 
 Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@kernel.org>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Maxime Coquelin <mcoquelin.stm32@gmail.com>, 
 Alexandre Torgue <alexandre.torgue@foss.st.com>, 
 Chen-Yu Tsai <wens@kernel.org>, Jernej Skrabec <jernej.skrabec@gmail.com>, 
 Samuel Holland <samuel@sholland.org>, 
 Philipp Zabel <p.zabel@pengutronix.de>
Cc: netdev@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-sunxi@lists.linux.dev, linux-stm32@st-md-mailman.stormreply.com, 
 linux-kernel@vger.kernel.org, Arun Iyengar <aiyengar1990@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794733507; l=1719;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=+y0GcY4/PVmv5CEIOUChNpzRjsd6qAFwqN8yUicaQ8g=;
 b=WGxB9GPqMj1G3uOyPfh5GdwBrWsH+43WV1Oy91ghXj3UHSYqtPOjYOO9ZUbcawnPfHKKSQZIV
 wqJkLbTlGtqAaq9v9D/6boTgG+ufsgKqVVr5mtNEHt4mj2Rq7hd9I9S
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

If mdio_mux_init() fails after the internal PHY was powered, the error
path releases rst_ephy and ephy_clk before sun8i_dwmac_exit() uses them
to unpower it. Unpower the PHY first, as sun8i_dwmac_remove() does.

Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
Found by Sashiko's review of another dwmac-sun8i series of mine.
Build-tested only (arm64 and arm, W=1): I have no board with the
internal PHY (H3, H5 or V3s), so the error path was not exercised.

Developed with Claude (Anthropic); I reviewed it.
---
Changes in v3:
- Drop the Fixes tag (Andrew Lunn)
- Shorter commit message
- Link to v2: https://patch.msgid.link/20261113-sun8i-emac-mux-uaf-v2-1-6203666b2687@gmail.com

Changes in v2:
- Target net-next instead of net, drop Cc: stable (Andrew Lunn)
- Shorter commit message
- Rebased onto net-next
- Link to v1: https://patch.msgid.link/20261112-sun8i-emac-mux-uaf-v1-1-308ae7e6fcf2@gmail.com
---
 drivers/net/ethernet/stmicro/stmmac/dwmac-sun8i.c | 1 +
 1 file changed, 1 insertion(+)

diff --git a/drivers/net/ethernet/stmicro/stmmac/dwmac-sun8i.c b/drivers/net/ethernet/stmicro/stmmac/dwmac-sun8i.c
index 2ece7ba9dd73..898560e8e95c 100644
--- a/drivers/net/ethernet/stmicro/stmmac/dwmac-sun8i.c
+++ b/drivers/net/ethernet/stmicro/stmmac/dwmac-sun8i.c
@@ -1245,6 +1245,7 @@ static int sun8i_dwmac_probe(struct platform_device *pdev)
 	return 0;
 
 dwmac_mux:
+	sun8i_dwmac_unpower_internal_phy(gmac);
 	reset_control_put(gmac->rst_ephy);
 	clk_put(gmac->ephy_clk);
 dwmac_remove:

---
base-commit: 6964ff21c5d8b75649211a52dbfd92753e605649
change-id: 20261112-sun8i-emac-mux-uaf-1ba885219fee

Best regards,
--  
Arun Iyengar <aiyengar1990@gmail.com>

