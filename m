From: George Moussalem <george.moussalem@outlook.com>
Date: Fri, 05 Jun 2026 12:11:29 +0400
Subject: [PATCH next-next v2] net: dsa: qca8k: Add support for force mode
 for fixed link topology
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260605-qca8337-force-mode-v2-1-d9a6b6545bfa@outlook.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/32NTQ6CMBCFr0Jm7ZjSYlFX3sOwKGUqjdLRFgmGc
 HcrB3Dzki/vb4FE0VOCc7FApMknzyGD3BVgexNuhL7LDFJILbRQ+LLmqFSNjqMlHLgjdK1tzUG
 edFVpyMVnJOfnbfQKgeYRfwJNtnqfRo6f7W4qt8C/5anEEq1xta6Fc6ZVF36PD+b73vIAzbquX
 0/JJvLBAAAA
X-Change-ID: 20260603-qca8337-force-mode-fbcba5296446
To: Andrew Lunn <andrew@lunn.ch>, Vladimir Oltean <olteanv@gmail.com>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>
Cc: netdev@vger.kernel.org, linux-kernel@vger.kernel.org, 
 George Moussalem <george.moussalem@outlook.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1780647089; l=3187;
 i=george.moussalem@outlook.com; s=20250321; h=from:subject:message-id;
 bh=/1K49g/Q0+wrB8ffa0QJHaW9eANv5Yae+dqQkwbdI4U=;
 b=Xn7RwqPiLUqBSMkfjxaoyatDwqn+EhlJZVxXog3mgyAtwLsVAImKiBsVWVvKVPlXJ//K6hwlv
 IPyVfdFw1CBAI5t89drX8j9nLQevPmF9+g75OyKnuqOsk4jD9ZFIckZ
X-Developer-Key: i=george.moussalem@outlook.com; a=ed25519;
 pk=/PuRTSI9iYiHwcc6Nrde8qF4ZDhJBlUgpHdhsIjnqIk=
X-Endpoint-Received: by B4 Relay for george.moussalem@outlook.com/20250321 with auth_id=364
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

A fixed link topology is commonly used to connect this switch (on port
0 or 6) to a SoC's MAC over SGMII. When inband negotiation is not used,
the switch needs to be configured to operate in force mode. As such,
enable support for force mode.

Reviewed-by: Andrew Lunn <andrew@lunn.ch>
Signed-off-by: George Moussalem <george.moussalem@outlook.com>
---
Changes in v2:
- Added check for QCA8337 switch ID and build up the register mask
  accordingly before writing the force mode bit to avoid overwriting the
  bit on switches other than QCA8337 for which there's no documentation
  on whether force mode is supported or not.
- Added comment to state that regardless of port used (0 or 6), the
  force mode bit is written to the PORT0 PAD register as per vendor SDK.
- Link to v1: https://lore.kernel.org/r/20260603-qca8337-force-mode-v1-1-caf7670ffab3@outlook.com
---
 drivers/net/dsa/qca/qca8k-8xxx.c | 22 ++++++++++++++++------
 drivers/net/dsa/qca/qca8k.h      |  1 +
 2 files changed, 17 insertions(+), 6 deletions(-)

diff --git a/drivers/net/dsa/qca/qca8k-8xxx.c b/drivers/net/dsa/qca/qca8k-8xxx.c
index a36b8b07030e..4c928983b862 100644
--- a/drivers/net/dsa/qca/qca8k-8xxx.c
+++ b/drivers/net/dsa/qca/qca8k-8xxx.c
@@ -1538,7 +1538,7 @@ static int qca8k_pcs_config(struct phylink_pcs *pcs, unsigned int neg_mode,
 {
 	struct qca8k_priv *priv = pcs_to_qca8k_pcs(pcs)->priv;
 	int cpu_port_index, ret, port;
-	u32 reg, val;
+	u32 mask, reg, val;
 
 	port = pcs_to_qca8k_pcs(pcs)->port;
 	switch (port) {
@@ -1611,11 +1611,21 @@ static int qca8k_pcs_config(struct phylink_pcs *pcs, unsigned int neg_mode,
 	if (priv->ports_config.sgmii_tx_clk_falling_edge)
 		val |= QCA8K_PORT0_PAD_SGMII_TXCLK_FALLING_EDGE;
 
-	if (val)
-		ret = qca8k_rmw(priv, reg,
-				QCA8K_PORT0_PAD_SGMII_RXCLK_FALLING_EDGE |
-				QCA8K_PORT0_PAD_SGMII_TXCLK_FALLING_EDGE,
-				val);
+	mask = (val) ? (QCA8K_PORT0_PAD_SGMII_RXCLK_FALLING_EDGE |
+			QCA8K_PORT0_PAD_SGMII_TXCLK_FALLING_EDGE) : 0;
+
+	/*
+	 * (Un)set force mode on QCA8337 only, don't include it in the mask for
+	 * others. It is written to the PORT0 PAD register for both port 0 and 6.
+	 */
+	if (priv->switch_id == QCA8K_ID_QCA8337) {
+		if (neg_mode == PHYLINK_PCS_NEG_OUTBAND)
+			val |= QCA8K_PORT_PAD_SGMII_FORCE_MODE;
+		mask |= QCA8K_PORT_PAD_SGMII_FORCE_MODE;
+	}
+
+	if (mask)
+		ret = qca8k_rmw(priv, reg, mask, val);
 
 	return 0;
 }
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

