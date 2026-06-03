From: George Moussalem <george.moussalem@outlook.com>
Date: Wed, 03 Jun 2026 11:57:39 +0400
Subject: [PATCH next-next] net: dsa: qca8k: Add support for force mode for
 fixed link topology
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260603-qca8337-force-mode-v1-1-caf7670ffab3@outlook.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/x2MMQ6EIBAAv2K2vk0QlNP7irFAXLwtBAVjTIx/F
 20mmWLmhESRKcGvOCHSzomDz1J+CrB/4ydCHrODFFILLRSu1jRKfdGFaAnnMBK6wQ6mlq2uKg0
 5XCI5Pt5pB56ODR9Af1038ubuu28AAAA=
X-Change-ID: 20260603-qca8337-force-mode-fbcba5296446
To: Andrew Lunn <andrew@lunn.ch>, Vladimir Oltean <olteanv@gmail.com>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>
Cc: netdev@vger.kernel.org, linux-kernel@vger.kernel.org, 
 George Moussalem <george.moussalem@outlook.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1780473474; l=1952;
 i=george.moussalem@outlook.com; s=20250321; h=from:subject:message-id;
 bh=kxqS2bqjt6+ouza+vz/puCI2oc93WI/rb8uky+fmGoQ=;
 b=5fbNiQpDmiLWqNtCEftWZ+N3nuB7FW5BbnHHC7D4Do5MPkWYC9NnnMxRf1e83dHAmQ61uv8/z
 wg2uxmINcW0CtoyPAhqd9FBTaMhTNVrs9PDVccIbV1RoP76WdH2wz1k
X-Developer-Key: i=george.moussalem@outlook.com; a=ed25519;
 pk=/PuRTSI9iYiHwcc6Nrde8qF4ZDhJBlUgpHdhsIjnqIk=
X-Endpoint-Received: by B4 Relay for george.moussalem@outlook.com/20250321 with auth_id=364
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

A fixed link topology is commonly used to connect this switch (on port
0 or 6) to a SoC's MAC over SGMII. When inband negotiation is not used,
the switch needs to be configured to operate in force mode. As such,
enable support for force mode.

Signed-off-by: George Moussalem <george.moussalem@outlook.com>
---
 drivers/net/dsa/qca/qca8k-8xxx.c | 6 +++++-
 drivers/net/dsa/qca/qca8k.h      | 1 +
 2 files changed, 6 insertions(+), 1 deletion(-)

diff --git a/drivers/net/dsa/qca/qca8k-8xxx.c b/drivers/net/dsa/qca/qca8k-8xxx.c
index a36b8b07030e..3dbd18ab8638 100644
--- a/drivers/net/dsa/qca/qca8k-8xxx.c
+++ b/drivers/net/dsa/qca/qca8k-8xxx.c
@@ -1611,10 +1611,14 @@ static int qca8k_pcs_config(struct phylink_pcs *pcs, unsigned int neg_mode,
 	if (priv->ports_config.sgmii_tx_clk_falling_edge)
 		val |= QCA8K_PORT0_PAD_SGMII_TXCLK_FALLING_EDGE;
 
+	if (neg_mode == PHYLINK_PCS_NEG_OUTBAND)
+		val |= QCA8K_PORT_PAD_SGMII_FORCE_MODE;
+
 	if (val)
 		ret = qca8k_rmw(priv, reg,
 				QCA8K_PORT0_PAD_SGMII_RXCLK_FALLING_EDGE |
-				QCA8K_PORT0_PAD_SGMII_TXCLK_FALLING_EDGE,
+				QCA8K_PORT0_PAD_SGMII_TXCLK_FALLING_EDGE |
+				QCA8K_PORT_PAD_SGMII_FORCE_MODE,
 				val);
 
 	return 0;
diff --git a/drivers/net/dsa/qca/qca8k.h b/drivers/net/dsa/qca/qca8k.h
index 1a00e2f62fef..956338893032 100644
--- a/drivers/net/dsa/qca/qca8k.h
+++ b/drivers/net/dsa/qca/qca8k.h
@@ -58,6 +58,7 @@
 #define	  QCA8K_PORT_PAD_RGMII_TX_DELAY_EN		BIT(25)
 #define   QCA8K_PORT_PAD_RGMII_RX_DELAY_EN		BIT(24)
 #define   QCA8K_PORT_PAD_SGMII_EN			BIT(7)
+#define   QCA8K_PORT_PAD_SGMII_FORCE_MODE		BIT(3)
 #define QCA8K_REG_PWS					0x010
 #define   QCA8K_PWS_POWER_ON_SEL			BIT(31)
 /* This reg is only valid for QCA832x and toggle the package

---
base-commit: b7bee4ca5688e30ca50fbc87b1b8f7eed7006c17
change-id: 20260603-qca8337-force-mode-fbcba5296446

Best regards,
-- 
George Moussalem <george.moussalem@outlook.com>

