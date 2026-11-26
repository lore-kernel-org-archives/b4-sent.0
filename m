From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Thu, 26 Nov 2026 09:56:52 +0000
Subject: [PATCH net] net: stmmac: dwmac-sun8i: Drop received MAC control
 frames
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261126-sun8i-emac-ctl-frames-v1-1-e90ac94bc8c7@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yWMzQrCMBAGX6Xs2YX8QGl9FfEQ16+6YqNkUxFK3
 92oxxmYWclQFEb7bqWCl5o+cgO/60iuKV/Aem5MwYXe+xDYljwoY07CUu88lTTD2A+9uAgX4zh
 Sa58Fk75/3wNlVDr+pS2nG6R+j7RtHx4Uktp+AAAA
X-Change-ID: 20261122-sun8i-emac-ctl-frames-186c03e03399
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
 Arun Iyengar <aiyengar1990@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795687012; l=1712;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=Df1pc3deUNfFedjsrZXgOgDGpSA2ac6nDP3eQt7sHjQ=;
 b=q1CFqPkAPrZs2g4vYOtNI7W132Z93BqBt+PMmQcYJrCbvoGMx1oQRQ56FW2IJjE/AxxRTsLpF
 cGg2wV7DhB8CGRTgggaEvZwlps5LJbUI6CBLya36IvQZsO+UGB2dDE4
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

sun8i_dwmac_set_filter() sets CTL_FRM_FILTER to "receive all control
frames", so every PAUSE frame reaches the stack and is counted in
rx_dropped. Leave it at 0, "drop", as the Allwinner BSP does; the MAC
still obeys PAUSE.

Fixes: 9f93ac8d4085 ("net-next: stmmac: Add dwmac-sun8i")
Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
Tested on an Orange Pi Zero2 (H616), net/main, MAC loopback: TX still
waits 32.6 ms per PAUSE; rx_dropped per 20 PAUSE frames 20 -> 0.
Claude (AI) helped find the cause and write the patch; I reviewed and
tested it.
---
 drivers/net/ethernet/stmicro/stmmac/dwmac-sun8i.c | 3 +--
 1 file changed, 1 insertion(+), 2 deletions(-)

diff --git a/drivers/net/ethernet/stmicro/stmmac/dwmac-sun8i.c b/drivers/net/ethernet/stmicro/stmmac/dwmac-sun8i.c
index 2ece7ba9dd73..f669bf22b7dc 100644
--- a/drivers/net/ethernet/stmicro/stmmac/dwmac-sun8i.c
+++ b/drivers/net/ethernet/stmicro/stmmac/dwmac-sun8i.c
@@ -192,7 +192,6 @@ static const struct emac_variant emac_variant_h616_emac1 = {
 
 /* Used in EMAC_RX_FRM_FLT */
 #define EMAC_FRM_FLT_RXALL              BIT(0)
-#define EMAC_FRM_FLT_CTL                BIT(13)
 #define EMAC_FRM_FLT_MULTICAST          BIT(16)
 
 /* Used in RX_CTL1*/
@@ -720,7 +719,7 @@ static void sun8i_dwmac_set_filter(struct mac_device_info *hw,
 	struct netdev_hw_addr *ha;
 	int macaddrs = netdev_uc_count(dev) + netdev_mc_count(dev) + 1;
 
-	v = EMAC_FRM_FLT_CTL;
+	v = 0;
 
 	if (dev->flags & IFF_PROMISC) {
 		v = EMAC_FRM_FLT_RXALL;

---
base-commit: e509726660dd06ce107437aecf7c106c9d3fc1e7
change-id: 20261122-sun8i-emac-ctl-frames-186c03e03399

Best regards,
--  
Arun Iyengar <aiyengar1990@gmail.com>

