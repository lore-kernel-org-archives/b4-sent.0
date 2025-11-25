From: Rohan G Thomas <rohan.g.thomas@altera.com>
Date: Tue, 25 Nov 2025 22:50:02 +0800
Subject: [PATCH net-next] net: stmmac: Fix E2E delay mechanism
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251125-ext-ptp-fix-v1-1-83f9f069cb36@altera.com>
X-B4-Tracking: v=1; b=H4sIABnCJWkC/x2MSwqAMAwFr1KyNmALxc9VxIXGqNnU0hYpiHc3u
 JzHvHkgcxLOMJoHEt+S5QoKtjFA5xIORtmUwbXOW+s8ci0YS8RdKlK3sieiwfcW9BET6/zXJgh
 cMKgN8/t+7LtS/mcAAAA=
X-Change-ID: 20251125-ext-ptp-fix-c7be5ccc9581
To: Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Maxime Coquelin <mcoquelin.stm32@gmail.com>, 
 Alexandre Torgue <alexandre.torgue@foss.st.com>, 
 Richard Cochran <richardcochran@gmail.com>, 
 Jose Abreu <Jose.Abreu@synopsys.com>, Fugang Duan <fugang.duan@nxp.com>, 
 Kurt Kanzenbach <kurt@linutronix.de>
Cc: netdev@vger.kernel.org, linux-stm32@st-md-mailman.stormreply.com, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Rohan G Thomas <rohan.g.thomas@altera.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1764082219; l=2038;
 i=rohan.g.thomas@altera.com; s=20250815; h=from:subject:message-id;
 bh=9giETEfw4Xea/WCJLCrYatICsuoa8+YtsuLtOXU+oPY=;
 b=c8F4pHeoCSI1RPcep11xCPWbPXDyFRKxjwvkzhxCXXqAuX7O/zfrVBMKt4l4apHT8U4uDvcKQ
 CkeLYSEp+XHAg/w+hyLJGVQazRj6y5nXet9ekMLfvj11VXf57TVL2M5
X-Developer-Key: i=rohan.g.thomas@altera.com; a=ed25519;
 pk=5yZXkXswhfUILKAQwoIn7m6uSblwgV5oppxqde4g4TY=
X-Endpoint-Received: by B4 Relay for rohan.g.thomas@altera.com/20250815 with auth_id=494
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

For E2E delay mechanism, "received DELAY_REQ without timestamp" error
messages shows up for dwmac v3.70+ and dwxgmac IPs.

This issue affects socfpga platforms, Agilex7 (dwmac 3.70) and
Agilex5 (dwxgmac). According to the databook, to enable timestamping
for all events, the SNAPTYPSEL bit in the MAC_Timestamp_Control
register must be set to 2'b00, and the TSEVNTENA bit must be cleared
to 0'b0.

Commit 3cb958027cb8 ("net: stmmac: Fix E2E delay mechanism") already
addresses this problem for all dwmacs above version v4.10. However,
same holds true for v3.70 and above, as well as for dwxgmac. Updates
the check accordingly.

Fixes: 14f347334bf2 ("net: stmmac: Correctly take timestamp for PTPv2")
Fixes: f2fb6b6275eb ("net: stmmac: enable timestamp snapshot for required PTP packets in dwmac v5.10a")
Fixes: 3cb958027cb8 ("net: stmmac: Fix E2E delay mechanism")
Signed-off-by: Rohan G Thomas <rohan.g.thomas@altera.com>
---
 drivers/net/ethernet/stmicro/stmmac/stmmac_main.c | 3 ++-
 1 file changed, 2 insertions(+), 1 deletion(-)

diff --git a/drivers/net/ethernet/stmicro/stmmac/stmmac_main.c b/drivers/net/ethernet/stmicro/stmmac/stmmac_main.c
index 6cacedb2c9b3fefdd4c9ec8ba98d389443d21ebd..2885434cb0bea7166dca2a914a6c07e21c98e5b9 100644
--- a/drivers/net/ethernet/stmicro/stmmac/stmmac_main.c
+++ b/drivers/net/ethernet/stmicro/stmmac/stmmac_main.c
@@ -665,7 +665,8 @@ static int stmmac_hwtstamp_set(struct net_device *dev,
 			config->rx_filter = HWTSTAMP_FILTER_PTP_V2_EVENT;
 			ptp_v2 = PTP_TCR_TSVER2ENA;
 			snap_type_sel = PTP_TCR_SNAPTYPSEL_1;
-			if (priv->synopsys_id < DWMAC_CORE_4_10)
+			if (priv->synopsys_id < DWMAC_CORE_3_70 &&
+			    priv->plat->core_type != DWMAC_CORE_XGMAC)
 				ts_event_en = PTP_TCR_TSEVNTENA;
 			ptp_over_ipv4_udp = PTP_TCR_TSIPV4ENA;
 			ptp_over_ipv6_udp = PTP_TCR_TSIPV6ENA;

---
base-commit: e3daf0e7fe9758613bec324fd606ed9caa187f74
change-id: 20251125-ext-ptp-fix-c7be5ccc9581

Best regards,
-- 
Rohan G Thomas <rohan.g.thomas@altera.com>

