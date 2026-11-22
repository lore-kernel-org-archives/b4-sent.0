From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Sun, 22 Nov 2026 09:13:48 +0000
Subject: [PATCH net v2 2/2] net: stmmac: dwmac-sun8i: Limit the MTU to 2018
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261122-sun8i-emac-mtu-limit-v2-2-c4081e5b83cf@gmail.com>
References: <20261122-sun8i-emac-mtu-limit-v2-0-c4081e5b83cf@gmail.com>
In-Reply-To: <20261122-sun8i-emac-mtu-limit-v2-0-c4081e5b83cf@gmail.com>
To: Maxime Chevallier <maxime.chevallier@bootlin.com>, 
 Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@kernel.org>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Chen-Yu Tsai <wens@kernel.org>, Jernej Skrabec <jernej.skrabec@gmail.com>, 
 Samuel Holland <samuel@sholland.org>, 
 Maxime Coquelin <mcoquelin.stm32@gmail.com>, 
 Alexandre Torgue <alexandre.torgue@foss.st.com>, 
 LABBE Corentin <clabbe.montjoie@gmail.com>
Cc: netdev@vger.kernel.org, linux-stm32@st-md-mailman.stormreply.com, 
 linux-arm-kernel@lists.infradead.org, linux-sunxi@lists.linux.dev, 
 Russell King <rmk+kernel@armlinux.org.uk>, 
 Nicolai Buchwitz <nb@tipi-net.de>, Arun Iyengar <aiyengar1990@gmail.com>, 
 stable@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795338826; l=1070;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=hoWHCAAprzrO2D+coALtPpyIBw9Qkx95wvyejnjliCM=;
 b=so3ZK26Uz/bNPFobSNeO22ZQm5P4aH7euK1OUEWe1ZVZE0wm4pIfqRAkW6IWpaCz3BSNnqcoH
 8J38CexopsuDI097y8ytNlosmfgYlB7QO7/ZFWQ1GLxpzn+Ltn+ToJd
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The H616 RX DMA fills only 2044 bytes of a buffer, so frames of 2045 to
2047 bytes, allowed by the previous patch, are dropped. Limit the MTU
so that a frame with two VLAN tags and the FCS fits 2044 bytes.

Fixes: 9f93ac8d4085 ("net-next: stmmac: Add dwmac-sun8i")
Cc: stable@vger.kernel.org
Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 drivers/net/ethernet/stmicro/stmmac/dwmac-sun8i.c | 1 +
 1 file changed, 1 insertion(+)

diff --git a/drivers/net/ethernet/stmicro/stmmac/dwmac-sun8i.c b/drivers/net/ethernet/stmicro/stmmac/dwmac-sun8i.c
index 2ece7ba9dd73..ec401cae8187 100644
--- a/drivers/net/ethernet/stmicro/stmmac/dwmac-sun8i.c
+++ b/drivers/net/ethernet/stmicro/stmmac/dwmac-sun8i.c
@@ -1208,6 +1208,7 @@ static int sun8i_dwmac_probe(struct platform_device *pdev)
 	plat_dat->mac_setup = sun8i_dwmac_setup;
 	plat_dat->tx_fifo_size = 4096;
 	plat_dat->rx_fifo_size = 16384;
+	plat_dat->maxmtu = 2044 - ETH_HLEN - 2 * VLAN_HLEN - ETH_FCS_LEN;
 
 	ret = sun8i_dwmac_set_syscon(&pdev->dev, plat_dat);
 	if (ret)

-- 
2.55.0

