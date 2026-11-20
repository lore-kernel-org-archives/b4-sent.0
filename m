From: Arun Iyengar <aiyengar1990@gmail.com>
Subject: [PATCH net-next v4 0/5] net: stmmac: dwmac-sun8i: Fix the EPHY and
 MDIO mux ordering
Date: Fri, 20 Nov 2026 10:45:31 +0000
Message-Id: <20261120-sun8i-emac-mux-uaf-v4-0-57eba8915f25@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/33NQQ6CMBAF0KuYrh3DTKUWV97DuChlqjVSDAWCM
 dzdihtijMufmf/+U0RuPUexXz1Fy4OPvgkpbNcrYS8mnBl8lbKgjBQiEsQ+aA9cGwt1P0JvHGB
 ptM4JC8csUvHesvPjjB5F4A4Cj504fS6xL69su7f5/r342DXtY94fcG78mxoQEGSmDe9YOevoc
 K6Nv21sU88DAy0J+ZOgRCjKpFKqJKV334RcEvlPQibCqqLaoi5yWVRLYpqmF0tVMYlWAQAA
X-Change-ID: 20261112-sun8i-emac-mux-uaf-1ba885219fee
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795171532; l=3022;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=WJ/5m93RaYcJ6kzFBxoH9WTbOEaZuKI4g+7TKGt/avg=;
 b=lphcq+u8z/ZxON+fh+Je8MmEEU451tWNsOlrfS7Mk2eY45sEODdRt+4YaH9+pMVJZmTiH5fWs
 dloagX31biNDj3qaemOvPjfjzabavGjar5sDI060W354zN3TNI1IZvV
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Chen-Yu Tsai pointed out that the probe error path and remove() put the
EPHY clock and reset before sun8i_dwmac_exit() uses them (patch 1).
Sashiko and Maxime Chevallier pointed out that the EPHY lookup and the
mux registration run after register_netdev(), and Maxime suggested
registering the mux in the MDIO setup (patches 2, 4 and 5). Patch 2
replaces "Defer probe when the EPHY clock is not ready" [1]. Patch 3
balances runtime PM on the stmmac probe error path, which a mux failure
now takes.

Tested on QEMU orangepi-pc (H3, internal PHY) with KASAN; I have no H3,
H5 or V3s board. On net-next, a test-only mdio_mux_init() failure gives
a KASAN use-after-free in clk_disable() from sun8i_dwmac_exit(), and
unbinding with the link up oopses in phy_stop(). With the series both
are clean, a test device tree whose EPHY clock has no provider
(fw_devlink=permissive) defers before the netdev exists, and three
unbind/bind cycles with the link up pass. Without patch 3, after the
failed probe and a rebind the MAC stays runtime active with usage count
1; with it the MAC runtime-suspends (usage 0).

Developed with Claude (Anthropic); I reviewed it.

[1] https://lore.kernel.org/r/20261113-b4-sun8i-emac-ephy-defer-v1-1-12a8591702fe@gmail.com

---
Changes in v4:
- Put the EPHY clock and reset after stmmac_pltfr_remove() (Chen-Yu Tsai)
- Get the EPHY clock and reset before the MAC probe, defer on the clock (Sashiko, Maxime Chevallier)
- Balance runtime PM when the stmmac probe fails (new patch 3)
- Register the mux through new stmmac mdio_init()/mdio_exit() hooks (Maxime Chevallier)
- Now a series, new cover subject
- Link to v3: https://patch.msgid.link/20261115-sun8i-emac-mux-uaf-v3-1-c69d4189539d@gmail.com

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
Arun Iyengar (5):
      net: stmmac: dwmac-sun8i: Put the EPHY clock and reset after the MAC
      net: stmmac: dwmac-sun8i: Get the EPHY clock and reset before the MAC probe
      net: stmmac: Balance runtime PM when the probe fails
      net: stmmac: Add MDIO init and exit platform hooks
      net: stmmac: dwmac-sun8i: Register the MDIO mux in the MDIO setup

 drivers/net/ethernet/stmicro/stmmac/dwmac-sun8i.c | 82 +++++++++--------------
 drivers/net/ethernet/stmicro/stmmac/stmmac_main.c |  2 +
 drivers/net/ethernet/stmicro/stmmac/stmmac_mdio.c | 11 +++
 include/linux/stmmac.h                            |  2 +
 4 files changed, 48 insertions(+), 49 deletions(-)
---
base-commit: 2208ab00f4f213ade91ab775e7f8c4dacdcc856e
change-id: 20261112-sun8i-emac-mux-uaf-1ba885219fee

Best regards,
--  
Arun Iyengar <aiyengar1990@gmail.com>

