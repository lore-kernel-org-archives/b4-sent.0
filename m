From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Sat, 28 Nov 2026 17:28:09 +0000
Subject: [PATCH net-next v2] net: stmmac: dwmac-sun8i: Drop received MAC
 control frames
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261128-sun8i-emac-ctl-frames-v2-1-fdfb23123c38@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/3WOwQ6CMBBEf4Xs2TVtMUg9+R+GQ1lXqKHFtIVgC
 P8uoFePk5k3MzNEDpYjXLIZAo822t6vQh0yoNb4htHeVw1KqEJKpTAOvrTIzhBS6vARjOOIsix
 I5CzyXGtY2Vfgh5323ht4Tuh5SlB9nTjUT6a01W7Z1sbUh/d+YZQ78Vsr/qyNEiWyFob0qaaSz
 tfGGdsdqXdQLcvyAfa5FK/WAAAA
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795886889; l=1808;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=Tg24+za4ID7UyLamOD5zPKEccZ2A2sTrNusAybm3U38=;
 b=tu+zcFWid5Ar1Bt5QKT37pI6OpxjxQEPNq78+eB6b+0zN0Udo4lyx86fEHBBVQjRUWOIS1l6r
 nR7Msp+l84kAMxyuFfn2wy7QvSNPK3zgNgMQfviYmMJkapfRV6QRZJZ
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
Tested on an Orange Pi Zero2 (H616), net-next, MAC loopback, PAUSE
(quanta 0xffff) sent to itself from a raw socket: the next frame waits
32.6 ms with and without this patch; rx_dropped per 20 PAUSE 20 -> 0.
ethtool -t Flow Control passes on both (the test sets promiscuous mode).
Claude (AI) helped find the cause and write the patch; I reviewed and
tested it.
---
Changes in v2:
- Target net-next (Maxime).
- Keep the EMAC_FRM_FLT_CTL define (Andrew).
- Add the flow control test results (Maxime).
- Link to v1: https://patch.msgid.link/20261126-sun8i-emac-ctl-frames-v1-1-e90ac94bc8c7@gmail.com
---
 drivers/net/ethernet/stmicro/stmmac/dwmac-sun8i.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/net/ethernet/stmicro/stmmac/dwmac-sun8i.c b/drivers/net/ethernet/stmicro/stmmac/dwmac-sun8i.c
index 613199da57c1..aa1b62f84d07 100644
--- a/drivers/net/ethernet/stmicro/stmmac/dwmac-sun8i.c
+++ b/drivers/net/ethernet/stmicro/stmmac/dwmac-sun8i.c
@@ -728,7 +728,7 @@ static void sun8i_dwmac_set_filter(struct mac_device_info *hw,
 	struct netdev_hw_addr *ha;
 	int macaddrs = netdev_uc_count(dev) + netdev_mc_count(dev) + 1;
 
-	v = EMAC_FRM_FLT_CTL;
+	v = 0;
 
 	if (dev->flags & IFF_PROMISC) {
 		v = EMAC_FRM_FLT_RXALL;

---
base-commit: ccb81d5e317b0ae2cc66ca1c628c0ca907928f94
change-id: 20261122-sun8i-emac-ctl-frames-186c03e03399

Best regards,
--  
Arun Iyengar <aiyengar1990@gmail.com>

