From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Sat, 21 Nov 2026 04:43:41 +0000
Subject: [PATCH net] net: stmmac: dwmac-sun8i: Limit the MTU to one
 descriptor buffer
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261121-sun8i-emac-mtu-limit-v1-1-22492842d318@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yWMQQrCMBAAv1L27EITdbF+RXpI47ZdMVGyiRRK/
 260xxmYWUE5CStcmxUSf0TlFSuYQwN+dnFilHtlsK0lY6xBLfEiyMF5DLngU4JkJHLdkVo6dXS
 Gmr4Tj7L8tzeInKHfpZbhwT7/hrBtX+W/R0x9AAAA
X-Change-ID: 20261121-sun8i-emac-mtu-limit-66a936064965
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
 Nicolai Buchwitz <nb@tipi-net.de>, stable@vger.kernel.org, 
 Arun Iyengar <aiyengar1990@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795236220; l=2306;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=nONg0VC5sVpR9PeT7YPsWCSGoSka8xMNeopCkcw71rY=;
 b=DUJUge213peq89DZSTZEFm8M6OTH3hROkg8KyslR/EHROF2fN+9kaQ/gVJtPjSlgug0E9VIqK
 Q+Lvc+ZVqaUC1r3MJHA11IMqj8aJbOiLbvfs2DWW8RNLceQht0q7TVb
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Russell King pointed out in [1] that max_mtu ignores the 11-bit buffer
size of normal descriptors. dwmac-sun8i always uses them in chain mode,
so a frame must fit one buffer, but max_mtu is SKB_MAX_HEAD() (3712 on
arm64). Sashiko asked in [2] for this to go in as a fix.

On an H616 the RX DMA fills 2044 bytes of a buffer and
ndesc_get_rx_status() drops a frame that spans two. On TX the MAC cuts
a frame after 2048 bytes (TX_FRM_LEN_CTL is clear). At MTU 2033 no UDP
datagram gets through in either direction.

Limit the MTU so that a frame with two VLAN tags and the FCS fits 2044
bytes (MTU 2018). MTU 2019-2026, which worked without VLAN tags, is now
refused.

Link: https://lore.kernel.org/r/E1vLJcL-0000000ExBL-0GFe@rmk-PC.armlinux.org.uk [1]
Link: https://lore.kernel.org/r/20261112-sun8i-emac-jumbo-v2-2-aca0cf23cf17@gmail.com [2]
Fixes: 9f93ac8d4085 ("net-next: stmmac: Add dwmac-sun8i")
Cc: Russell King <rmk+kernel@armlinux.org.uk>
Cc: Nicolai Buchwitz <nb@tipi-net.de>
Cc: stable@vger.kernel.org
Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
Tested on an Orange Pi Zero2 (H616) on net/main with and without this
patch (RX fill measured on v7.3.5). Claude (AI) helped write this patch;
I reviewed and tested it.
---
 drivers/net/ethernet/stmicro/stmmac/dwmac-sun8i.c | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/drivers/net/ethernet/stmicro/stmmac/dwmac-sun8i.c b/drivers/net/ethernet/stmicro/stmmac/dwmac-sun8i.c
index 2ece7ba9dd73..1f4fa722529f 100644
--- a/drivers/net/ethernet/stmicro/stmmac/dwmac-sun8i.c
+++ b/drivers/net/ethernet/stmicro/stmmac/dwmac-sun8i.c
@@ -6,6 +6,7 @@
  */
 
 #include <linux/clk.h>
+#include <linux/if_vlan.h>
 #include <linux/io.h>
 #include <linux/iopoll.h>
 #include <linux/mdio-mux.h>
@@ -1208,6 +1209,7 @@ static int sun8i_dwmac_probe(struct platform_device *pdev)
 	plat_dat->mac_setup = sun8i_dwmac_setup;
 	plat_dat->tx_fifo_size = 4096;
 	plat_dat->rx_fifo_size = 16384;
+	plat_dat->maxmtu = 2044 - ETH_HLEN - 2 * VLAN_HLEN - ETH_FCS_LEN;
 
 	ret = sun8i_dwmac_set_syscon(&pdev->dev, plat_dat);
 	if (ret)

---
base-commit: d5b89d55a322b632e2b465b392a4c1d9d338db9c
change-id: 20261121-sun8i-emac-mtu-limit-66a936064965

Best regards,
--  
Arun Iyengar <aiyengar1990@gmail.com>

