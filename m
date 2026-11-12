From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Thu, 12 Nov 2026 05:28:05 +0000
Subject: [PATCH net] net: stmmac: dwmac-sun8i: Fix use-after-free in the
 MDIO mux error path
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261112-sun8i-emac-mux-uaf-v1-1-308ae7e6fcf2@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yWMwQrCMBAFf6Xs2QU3YIn+inhI44uu0CjZphRK/
 91UjzMws5KhKIwu3UoFs5q+cwM5dBSfIT/Aem9M7uh6EXFsNXtljCHyWBeuIbEMwfuTk3MCqIW
 fgqTLb3qljIluf2l1eCFO+4627QucXK9qewAAAA==
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
 linux-kernel@vger.kernel.org, stable@vger.kernel.org, 
 Arun Iyengar <aiyengar1990@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794461284; l=2672;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=NsburT4Rs6TuKeRLvNh9ntKMBycWNUHji+Gwj+018cs=;
 b=KuvZTvy/m2KLD0YOLU883uIqDNTznxKHAhJWD8davNR1BvQqXeosLyiPNYJbDYPG6qKvJDQdR
 LcFJgmVCqFeAlJD1ouD1bdILIdSCBHTVE1tYyniSitGLJ+rn/Vi2tK2
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

mdio_mux_init() registers the child MDIO buses one after the other.
Scanning the internal bus makes mdio_mux_syscon_switch_fn() select the
internal PHY and power it, which sets gmac->internal_phy_powered. If
mdio_mux_init() then fails without switching away from the internal
bus, for example because registering the external bus returns
-EPROBE_DEFER before any access to it, or because an allocation for it
fails, sun8i_dwmac_probe() jumps to dwmac_mux with the PHY still
powered.

That error path releases gmac->rst_ephy and gmac->ephy_clk and only
then calls stmmac_pltfr_remove(), which ends in sun8i_dwmac_exit().
Since the PHY is still marked as powered, sun8i_dwmac_exit() calls
sun8i_dwmac_unpower_internal_phy(), which passes the clock and the
reset control that were just freed to clk_disable_unprepare() and
reset_control_assert().

Unpower the internal PHY before releasing its clock and reset control,
as sun8i_dwmac_remove() does. The later call from sun8i_dwmac_exit()
then does nothing because internal_phy_powered is already cleared.

Fixes: 529254216773 ("net: stmmac: dwmac-sun8i: Balance internal PHY resource references")
Cc: stable@vger.kernel.org
Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
The problem was pointed out by the Sashiko AI review of an unrelated
dwmac-sun8i series of mine. It holds against the code: clk_put() and
reset_control_put() free the per-consumer struct clk and the exclusive
reset control, and nothing between the dwmac_mux label and
sun8i_dwmac_exit() clears internal_phy_powered.

This is build-tested only (arm64 and arm, W=1). I have no board with the
internal PHY (H3, H5 or V3s), so the error path was not exercised.

This patch was developed with Claude (Anthropic) as a coding assistant:
it checked the report against the code and wrote the fix and the commit
message. I reviewed it.
---
 drivers/net/ethernet/stmicro/stmmac/dwmac-sun8i.c | 1 +
 1 file changed, 1 insertion(+)

diff --git a/drivers/net/ethernet/stmicro/stmmac/dwmac-sun8i.c b/drivers/net/ethernet/stmicro/stmmac/dwmac-sun8i.c
index 47954537b29e..4436532af2dc 100644
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
base-commit: 145480b28ca82e9fae789427cc4569e596515a32
change-id: 20261112-sun8i-emac-mux-uaf-1ba885219fee

Best regards,
--  
Arun Iyengar <aiyengar1990@gmail.com>

