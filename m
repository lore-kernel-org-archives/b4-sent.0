From: Rohan G Thomas <rohan.g.thomas@altera.com>
Date: Wed, 29 Oct 2025 16:06:14 +0800
Subject: [PATCH net-next 2/4] net: stmmac: socfpga: Enable TBS support for
 Agilex5
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251029-agilex5_ext-v1-2-1931132d77d6@altera.com>
References: <20251029-agilex5_ext-v1-0-1931132d77d6@altera.com>
In-Reply-To: <20251029-agilex5_ext-v1-0-1931132d77d6@altera.com>
To: Maxime Chevallier <maxime.chevallier@bootlin.com>, 
 Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Maxime Coquelin <mcoquelin.stm32@gmail.com>, 
 Alexandre Torgue <alexandre.torgue@foss.st.com>, 
 Richard Cochran <richardcochran@gmail.com>, 
 Steffen Trumtrar <s.trumtrar@pengutronix.de>
Cc: netdev@vger.kernel.org, linux-stm32@st-md-mailman.stormreply.com, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Rohan G Thomas <rohan.g.thomas@altera.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1761725182; l=1189;
 i=rohan.g.thomas@altera.com; s=20250815; h=from:subject:message-id;
 bh=xSJKSpzgBUj6X7SaRiqPgyeJfwi6PIzrINgCzQeog7s=;
 b=8SDkbxGig66XtJrELUxq38wXz640VIOzsR/gO+kkHJvQzQZVfXdl5J7m1gsIdbdgDYQZiKbl0
 cKATRITmZzNDbB6AewGNQndYuQwl85NB0G5Y9LEWVUbJ0LywdZ8FRxM
X-Developer-Key: i=rohan.g.thomas@altera.com; a=ed25519;
 pk=5yZXkXswhfUILKAQwoIn7m6uSblwgV5oppxqde4g4TY=
X-Endpoint-Received: by B4 Relay for rohan.g.thomas@altera.com/20250815 with auth_id=494
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Agilex5 supports Time-Based Scheduling(TBS) for Tx queue 6 and Tx
queue 7. This commit enables TBS support for these queues.

Signed-off-by: Rohan G Thomas <rohan.g.thomas@altera.com>
---
 drivers/net/ethernet/stmicro/stmmac/dwmac-socfpga.c | 13 +++++++++++++
 1 file changed, 13 insertions(+)

diff --git a/drivers/net/ethernet/stmicro/stmmac/dwmac-socfpga.c b/drivers/net/ethernet/stmicro/stmmac/dwmac-socfpga.c
index 3dae4f3c103802ed1c2cd390634bd5473192d4ee..c02e6fa715bbea2f703bcdeee9d7a41be51ce91c 100644
--- a/drivers/net/ethernet/stmicro/stmmac/dwmac-socfpga.c
+++ b/drivers/net/ethernet/stmicro/stmmac/dwmac-socfpga.c
@@ -473,6 +473,19 @@ static void socfpga_agilex5_setup_plat_dat(struct socfpga_dwmac *dwmac)
 	socfpga_common_plat_dat(dwmac);
 
 	plat_dat->core_type = DWMAC_CORE_XGMAC;
+
+	/* Enable TBS */
+	switch (plat_dat->tx_queues_to_use) {
+	case 8:
+		plat_dat->tx_queues_cfg[7].tbs_en = true;
+		fallthrough;
+	case 7:
+		plat_dat->tx_queues_cfg[6].tbs_en = true;
+		break;
+	default:
+		/* Tx Queues 0 - 5 doesn't support TBS on Agilex5 */
+		break;
+	}
 }
 
 static int socfpga_dwmac_probe(struct platform_device *pdev)

-- 
2.43.7

