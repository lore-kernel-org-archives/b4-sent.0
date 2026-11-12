From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Thu, 12 Nov 2026 08:41:47 +0000
Subject: [PATCH net-next v2 1/2] net: stmmac: dwmac-sun8i: Fix the RX_TH
 threshold encoding
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261112-sun8i-emac-jumbo-v2-1-aca0cf23cf17@gmail.com>
References: <20261112-sun8i-emac-jumbo-v2-0-aca0cf23cf17@gmail.com>
In-Reply-To: <20261112-sun8i-emac-jumbo-v2-0-aca0cf23cf17@gmail.com>
To: Maxime Chevallier <maxime.chevallier@bootlin.com>, 
 Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@kernel.org>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Chen-Yu Tsai <wens@kernel.org>, Jernej Skrabec <jernej.skrabec@gmail.com>, 
 Samuel Holland <samuel@sholland.org>, 
 Maxime Coquelin <mcoquelin.stm32@gmail.com>, 
 Alexandre Torgue <alexandre.torgue@foss.st.com>
Cc: netdev@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-sunxi@lists.linux.dev, linux-stm32@st-md-mailman.stormreply.com, 
 linux-kernel@vger.kernel.org, Corentin Labbe <clabbe.montjoie@gmail.com>, 
 Arun Iyengar <aiyengar1990@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794472906; l=1409;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=kKoyz2jSo9MVW4lEE52oWjQ6i8jVq1b7o2hmZSQuCoE=;
 b=g8/W7nlPeZfYmpu56asT03d91iiJSKK5MO6rRapGGZ4M0mZcYBIwI++ufmrkm7msjELJkc4ZP
 xOnoSwueTxHDS9gfJKD91a9yncVGseAqgU+tyhpEWbNQMSzzSsbFplb
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The EMAC RX_CTL1 RX_TH field (bits 5:4) encodes 00 = 64 bytes and
01 = 32 bytes (H616 user manual v1.0, 6.5.10; 10 = 96 and 11 = 128 bytes
as in the driver). The driver has the first two swapped.

The values are only used in RX threshold mode, which stmmac selects only
when the snps,force_thresh_dma_mode property is set. No Allwinner device
tree sets it, so no in-tree board is affected.

Fixes: 9f93ac8d4085 ("net-next: stmmac: Add dwmac-sun8i")
Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 drivers/net/ethernet/stmicro/stmmac/dwmac-sun8i.c | 5 +++--
 1 file changed, 3 insertions(+), 2 deletions(-)

diff --git a/drivers/net/ethernet/stmicro/stmmac/dwmac-sun8i.c b/drivers/net/ethernet/stmicro/stmmac/dwmac-sun8i.c
index 47954537b29e..0c82662fbe6e 100644
--- a/drivers/net/ethernet/stmicro/stmmac/dwmac-sun8i.c
+++ b/drivers/net/ethernet/stmicro/stmmac/dwmac-sun8i.c
@@ -198,8 +198,9 @@ static const struct emac_variant emac_variant_h616_emac1 = {
 /* Used in RX_CTL1*/
 #define EMAC_RX_MD              BIT(1)
 #define EMAC_RX_TH_MASK		GENMASK(5, 4)
-#define EMAC_RX_TH_32		0
-#define EMAC_RX_TH_64		(0x1 << 4)
+/* RX_CTL1 RX_TH encoding (H616 UM 6.5.10): 00 = 64, 01 = 32 bytes */
+#define EMAC_RX_TH_32		(0x1 << 4)
+#define EMAC_RX_TH_64		0
 #define EMAC_RX_TH_96		(0x2 << 4)
 #define EMAC_RX_TH_128		(0x3 << 4)
 #define EMAC_RX_DMA_EN  BIT(30)

-- 
2.55.0

