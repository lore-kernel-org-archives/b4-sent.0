From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Sun, 22 Nov 2026 09:13:47 +0000
Subject: [PATCH net v2 1/2] net: stmmac: Limit the MTU of normal
 descriptors to one buffer
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261122-sun8i-emac-mtu-limit-v2-1-c4081e5b83cf@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795338826; l=1453;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=ydeE7IevavZwGHNIu116JiJ5XTZiQzYRPI/kkGQMzGs=;
 b=OLm0NCIxVOoxm3a4kij2GdUDVN9qdNUwsdi1iIXrDZaiZGALtLXXIx9TtK0tjAzcFaWaxY1k8
 mGSIgLgx6xqC513OzVh3vXdfOC+UQQ/ED6uVIfpTgaEe/CLkDlGWvW+
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Russell King noted in [1] that max_mtu for normal descriptors,
SKB_MAX_HEAD() (3712 on arm64), does not match the hardware. Their
buffer sizes are 11 bits, and stmmac neither splits TX frames nor joins
RX descriptors for them, so a frame must fit one 2047-byte buffer.

Limit max_mtu so that a frame with two VLAN tags and the FCS fits.

Link: https://lore.kernel.org/r/E1vLJcL-0000000ExBL-0GFe@rmk-PC.armlinux.org.uk [1]
Fixes: 48febf7e6476 ("stmmac: allow mtu bigger than 1500 in case of normal desc (V4)")
Cc: Russell King <rmk+kernel@armlinux.org.uk>
Cc: stable@vger.kernel.org
Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 drivers/net/ethernet/stmicro/stmmac/stmmac_main.c | 3 +++
 1 file changed, 3 insertions(+)

diff --git a/drivers/net/ethernet/stmicro/stmmac/stmmac_main.c b/drivers/net/ethernet/stmicro/stmmac/stmmac_main.c
index a685ce4638f6..2a27e1e7f9b9 100644
--- a/drivers/net/ethernet/stmicro/stmmac/stmmac_main.c
+++ b/drivers/net/ethernet/stmicro/stmmac/stmmac_main.c
@@ -8247,6 +8247,9 @@ static int __stmmac_dvr_probe(struct device *device,
 		ndev->max_mtu = XGMAC_JUMBO_LEN;
 	else if (priv->plat->enh_desc || priv->synopsys_id >= DWMAC_CORE_4_00)
 		ndev->max_mtu = JUMBO_LEN;
+	else if (priv->hw->desc == &ndesc_ops)
+		ndev->max_mtu = BUF_SIZE_2KiB - 1 - ETH_HLEN - 2 * VLAN_HLEN -
+				ETH_FCS_LEN;
 	else
 		ndev->max_mtu = SKB_MAX_HEAD(NET_SKB_PAD + NET_IP_ALIGN);
 

-- 
2.55.0

