From: Abid Ali <dev.taqnialabs@gmail.com>
Date: Thu, 21 May 2026 16:32:46 +0000
Subject: [PATCH v2] net: stmmac: mmc: Remove duplicate mmc_rx crc
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260521-xgmac-mmc_rx_crc-cleanup-v2-1-7d9de09f5898@gmail.com>
X-B4-Tracking: v=1; b=H4sIAK0zD2oC/42NUQ6CMBBEr0L67RpaAoJf3sMQsq5b2IQCaZVgS
 O9u5QR+vsnMm10F9sJBXbNdeV4lyDwlMKdM0YBTzyDPxMrkpspLk8PWOyRwjjq/deQJaGSc3gu
 gJcbKItb4UGm+eLayHep7m3iQ8Jr953ha9S/9Q7pq0HDRRWFL09RlY2+pKeOZZqfaGOMX/Bkb+
 8AAAAA=
To: Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Maxime Coquelin <mcoquelin.stm32@gmail.com>, 
 Alexandre Torgue <alexandre.torgue@foss.st.com>
Cc: netdev@vger.kernel.org, linux-stm32@st-md-mailman.stormreply.com, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Abid Ali <dev.taqnialabs@gmail.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1779381166; l=1735;
 i=dev.taqnialabs@gmail.com; s=20260425; h=from:subject:message-id;
 bh=YT6MwxbT32LmsJ0Q4toXiSUGLZ0LUkCCQs3ZtA9Xc6A=;
 b=4nb99cKuWhzcka7MVU0baeVQGR1KS14hPy/Qj6o+FR+zkwGaooEwyN2rZln4L5Ctvpa4Fl4/0
 VoiHf/eHZF6CxH9tbvd1DO3g0ClGL8324bUtCG3NHSJgcWl2owhEIwL
X-Developer-Key: i=dev.taqnialabs@gmail.com; a=ed25519;
 pk=4Syx51HH/MOySSUpi79M2ToLOdwt1yiNb338eKZBJNk=
X-Endpoint-Received: by B4 Relay for dev.taqnialabs@gmail.com/20260425 with auth_id=752
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

MMC_XGMAC_RX_CRC_ERR is clear-on-read, and just a single read would
update the mmc_rx_crc_error counter.

[1] commit b6cdf09 ("net: stmmac: xgmac: Implement MMC counters").
The duplicate read appears to have been unintentionally introduced in
the intial MMC counter implementation. The databook does not mention
MMC_XGMAC_RX_CRC_ERR needing the additional read.

Fixes: b6cdf09 ("net: stmmac: xgmac: Implement MMC counters")
Signed-off-by: Abid Ali <dev.taqnialabs@gmail.com>
---
Changes in v2:
- Updated why the redundant read is removed based on feedback.
- Link to v1: https://lore.kernel.org/r/20260520-xgmac-mmc_rx_crc-cleanup-v1-1-7133f529859f@gmail.com
---
 drivers/net/ethernet/stmicro/stmmac/mmc_core.c | 2 --
 1 file changed, 2 deletions(-)

diff --git a/drivers/net/ethernet/stmicro/stmmac/mmc_core.c b/drivers/net/ethernet/stmicro/stmmac/mmc_core.c
index 1b3b114e7..d81581dfa 100644
--- a/drivers/net/ethernet/stmicro/stmmac/mmc_core.c
+++ b/drivers/net/ethernet/stmicro/stmmac/mmc_core.c
@@ -479,8 +479,6 @@ static void dwxgmac_mmc_read(void __iomem *mmcaddr, struct stmmac_counters *mmc)
 			     &mmc->mmc_rx_multicastframe_g);
 	dwxgmac_read_mmc_reg(mmcaddr, MMC_XGMAC_RX_CRC_ERR,
 			     &mmc->mmc_rx_crc_error);
-	dwxgmac_read_mmc_reg(mmcaddr, MMC_XGMAC_RX_CRC_ERR,
-			     &mmc->mmc_rx_crc_error);
 	mmc->mmc_rx_run_error += readl(mmcaddr + MMC_XGMAC_RX_RUNT_ERR);
 	mmc->mmc_rx_jabber_error += readl(mmcaddr + MMC_XGMAC_RX_JABBER_ERR);
 	mmc->mmc_rx_undersize_g += readl(mmcaddr + MMC_XGMAC_RX_UNDER);

---
base-commit: 028ef9c96e96197026887c0f092424679298aae8
change-id: 20260520-xgmac-mmc_rx_crc-cleanup-afcea6faa8ab

Best regards,
-- 
Abid Ali <dev.taqnialabs@gmail.com>

