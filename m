From: Arun Iyengar <aiyengar1990@gmail.com>
Subject: [PATCH net-next v5 0/6] net: stmmac: dwmac-sun8i: Fix the EPHY and
 MDIO mux ordering
Date: Sat, 28 Nov 2026 17:36:59 +0000
Message-Id: <20261128-sun8i-emac-mux-uaf-v5-0-0869f2ccdb8b@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/33QwW6DMAwG4Fepcp6nxCEh6WnvMe0QgtNmGmEig
 Kgq3r0pu6AK7WjZ//dLvrNMQ6TMzqc7G2iOOfapDOrtxPzVpQtBbMvMkKMWQiDkKZkI1DkP3bT
 A5AKIxhmjUNhAxErwd6AQlw39ZIlGSLSM7Otvk6fmm/z4NJ+315jHfrht/bPYEv9VzQIESG4c1
 aSDD/hx6Vz8efd9txXMuCfkIYGF0Mil1rpBbepXQu4JdUjIQnht20oYq6RtX4lqRyA/JCrgoGo
 qr7NCBVR7Yl3XB/yk/NqZAQAA
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795887420; l=4310;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=diqyOokNxmNMXVp6r/2ll5hIionfItCESuvwZR7mZac=;
 b=iaaHRECaQj0T/wPlU+ecYtNIym+zRISillh5j2gvc+L9GN2+SJiS+T0LfYUatFdAGxUXZXq8J
 qV2hk1ak4UyCMrzVrQsdr1nlxjJokfKDa0M+vXOQYs2wsHjNL4OkHvk
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Chen-Yu Tsai pointed out that the probe error path and remove() put the
EPHY clock and reset before sun8i_dwmac_exit() uses them (patch 1).
Sashiko and Maxime Chevallier pointed out that the EPHY lookup and the
mux registration run after register_netdev(), and Maxime suggested
registering the mux in the MDIO setup (patches 2, 5 and 6). Patch 2
replaces "Defer probe when the EPHY clock is not ready" [1]. Patches 3
and 4 make the stmmac probe error path, which a mux failure now takes,
undo runtime PM and the resets as remove() does. Patch 4 also asserts
the resets only after the MDIO bus is gone, so mdio_exit() runs with
the MAC out of reset.

Tested on QEMU orangepi-pc (H3, internal PHY) with KASAN; I have no H3,
H5 or V3s board. On net-next, a test-only mdio_mux_init() failure gives
a KASAN use-after-free in clk_disable(), and unbinding with the link up
oopses in phy_stop(). With the series both are clean, an EPHY clock
without a provider defers before the netdev exists, and unbind/bind
cycles pass. With patch 3 the MAC runtime-suspends after a failed probe
and rebind (usage 0, was 1). A test-only emulation of a bus that enables
runtime PM before probe keeps it enabled after the failed probe; PCI
itself is untested.

On an H616 (Orange Pi Zero2, external PHY), a forced -EPROBE_DEFER from
the MDIO setup leaves runtime PM disabled with usage 0, and the MAC
suspends after rebind. With patch 4 the MAC is in reset after the failed
probe, and a test PHY ID read from mdio_exit() on unbind returns
0x001cc916 (0 without patch 4).

Developed with Claude (Anthropic); I reviewed it.

[1] https://lore.kernel.org/r/20261113-b4-sun8i-emac-ephy-defer-v1-1-12a8591702fe@gmail.com

---
Changes in v5:
- Patch 2: say why the lookup moves; the deferral fix only matters for out-of-tree DTs (Sashiko)
- Patch 3: disable runtime PM only if the probe enabled it (Sashiko, Maxime Chevallier)
- New patch 4: assert the resets after the MDIO bus is gone, also on probe failure (Sashiko)
- Patch 5: document when the hooks run
- Patch 6: name the hooks patch (Sashiko)
- No Fixes tags, as this is net-next; patch 6 reverses the ordering from 634db83b8265 and 529254216773 (Sashiko, Andrew Lunn)
- Not changed (pre-existing): get_ephy_nodes() needs an mdio-mux node; stmmac_dvr_remove() disables runtime PM unconditionally
- Rebased onto net-next
- Link to v4: https://patch.msgid.link/20261120-sun8i-emac-mux-uaf-v4-0-57eba8915f25@gmail.com

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
Arun Iyengar (6):
      net: stmmac: dwmac-sun8i: Put the EPHY clock and reset after the MAC
      net: stmmac: dwmac-sun8i: Get the EPHY clock and reset before the MAC probe
      net: stmmac: Balance runtime PM when the probe fails
      net: stmmac: Assert the resets after unregistering the MDIO bus
      net: stmmac: Add MDIO init and exit platform hooks
      net: stmmac: dwmac-sun8i: Register the MDIO mux in the MDIO setup

 drivers/net/ethernet/stmicro/stmmac/dwmac-sun8i.c | 82 +++++++++--------------
 drivers/net/ethernet/stmicro/stmmac/stmmac_main.c | 17 +++--
 drivers/net/ethernet/stmicro/stmmac/stmmac_mdio.c | 11 +++
 include/linux/stmmac.h                            |  3 +
 4 files changed, 60 insertions(+), 53 deletions(-)
---
base-commit: 8f0f7f39913e8b1571f2e6a8295a700356492f2a
change-id: 20261112-sun8i-emac-mux-uaf-1ba885219fee

Best regards,
--  
Arun Iyengar <aiyengar1990@gmail.com>

