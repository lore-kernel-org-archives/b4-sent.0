From: Abid Ali <dev.taqnialabs@gmail.com>
Date: Fri, 22 May 2026 07:09:27 +0000
Subject: [PATCH v2] net: stmmac: fix RX DMA leak on TX alloc failure
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260522-stmmac-rx-desc-cleanup-v2-1-76e78eb471e1@gmail.com>
X-B4-Tracking: v=1; b=H4sIACYBEGoC/4WNQQqDMBBFryKz7pQ4jK3tynsUFyGOOmBUEisW8
 e5NvUD5q/fhv79DlKAS4ZntEGTVqNOYgC4ZuN6OnaA2iYEM3QxTgXHx3joMGzYSHbpB7Piekdm
 0pii54AdBGs9BWt1O8atO3GtcpvA5f9b81/5Vrjmm2Ly0d8OOiarOWx2ubvJQH8fxBRZJ+qW8A
 AAA
To: Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Maxime Coquelin <mcoquelin.stm32@gmail.com>, 
 Alexandre Torgue <alexandre.torgue@foss.st.com>
Cc: netdev@vger.kernel.org, linux-stm32@st-md-mailman.stormreply.com, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Abid Ali <dev.taqnialabs@gmail.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1779433768; l=1102;
 i=dev.taqnialabs@gmail.com; s=20260425; h=from:subject:message-id;
 bh=EIgrw7dXm9oPWp3zniVVX0HGvfR5iqNaEldPBGWkDIg=;
 b=hdVWBxzASNSfqv2s2Nbdsqb2HKzuMkf5yETC5Qk0aOAbyTz2fCbXgQSNPGOm5QD6odXNFnEhV
 SQbDhBYjaBMCsywRVUjkT/8JlHiG/CY7a+CIU++RSilyke3vIhGeR7s
X-Developer-Key: i=dev.taqnialabs@gmail.com; a=ed25519;
 pk=4Syx51HH/MOySSUpi79M2ToLOdwt1yiNb338eKZBJNk=
X-Endpoint-Received: by B4 Relay for dev.taqnialabs@gmail.com/20260425 with auth_id=752
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Free RX DMA resources when alloc_dma_tx_desc_resources() fails in
alloc_dma_desc_resources().

Signed-off-by: Abid Ali <dev.taqnialabs@gmail.com>
---
Changes in v2:
- Restructured return path based on feedback.
- Link to v1: https://lore.kernel.org/r/20260425-stmmac-rx-desc-cleanup-v1-1-1a18a704c422@gmail.com
---
 drivers/net/ethernet/stmicro/stmmac/stmmac_main.c | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/drivers/net/ethernet/stmicro/stmmac/stmmac_main.c b/drivers/net/ethernet/stmicro/stmmac/stmmac_main.c
index 13d3cac05..240453daa 100644
--- a/drivers/net/ethernet/stmicro/stmmac/stmmac_main.c
+++ b/drivers/net/ethernet/stmicro/stmmac/stmmac_main.c
@@ -2370,6 +2370,8 @@ static int alloc_dma_desc_resources(struct stmmac_priv *priv,
 		return ret;
 
 	ret = alloc_dma_tx_desc_resources(priv, dma_conf);
+	if (ret)
+		free_dma_rx_desc_resources(priv, dma_conf);
 
 	return ret;
 }

---
base-commit: 028ef9c96e96197026887c0f092424679298aae8
change-id: 20260425-stmmac-rx-desc-cleanup-440f05845492

Best regards,
-- 
Abid Ali <dev.taqnialabs@gmail.com>

