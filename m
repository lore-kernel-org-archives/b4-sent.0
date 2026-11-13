From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Fri, 13 Nov 2026 07:55:00 +0000
Subject: [PATCH net-next v2] net: stmmac: dwmac-sun8i: Fix use-after-free
 in the MDIO mux error path
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261113-sun8i-emac-mux-uaf-v2-1-6203666b2687@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/32NzQ6CMBCEX8Xs2TVsjVg9+R6GQ6lbWCPF9IdgC
 O8u4N3jl5n5ZoLIQTjCdTdB4EGi9H4Btd+BbY1vGOWxMKhClUSkMGavBbkzFrs8YjYOqTZanxR
 dHDMsw3dgJ+MmvYPnhJ7HBNUvibl+sk2rc+22ElMfPtv/QNvi39VASHgstOEzl846dWs6I6+D7
 Tuo5nn+AhTscW/QAAAA
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794556499; l=1964;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=NA8bN4vdYnbD8Ubperq81cDG9VH7nmrLZlmkjA0DuNI=;
 b=cDtf6HyIYs9kKxz/DU3DMnuaFJxtsme6r42uIwnosHwItkgWxmYMNmK9McP7j2AbGcDRnYa0A
 4s93602poFgAD/01apDkyX9WWqsTaJZysHRMbkXRbXj9Qq7pdJwWsoE
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

If mdio_mux_init() fails after the scan of the internal bus has powered
the internal PHY (the external bus returns -EPROBE_DEFER, or an
allocation fails), the dwmac_mux error path puts rst_ephy and ephy_clk
and then calls stmmac_pltfr_remove(). sun8i_dwmac_exit() then unpowers
the PHY through the clock and reset control that were just released.

Unpower the internal PHY before releasing them, as sun8i_dwmac_remove()
does.

Fixes: 529254216773 ("net: stmmac: dwmac-sun8i: Balance internal PHY resource references")
Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
Sashiko's review of another dwmac-sun8i series of mine pointed this
out. Build-tested only (arm64 and arm, W=1): I have no board with the
internal PHY (H3, H5 or V3s), so the error path was not exercised.

This patch was developed with Claude (Anthropic), which checked the
report against the code and wrote the fix and the commit message. I
reviewed it.
---
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
base-commit: 573af801552999954caa8347e4490b04cf4763f0
change-id: 20261112-sun8i-emac-mux-uaf-1ba885219fee

Best regards,
--  
Arun Iyengar <aiyengar1990@gmail.com>

