From: Abid Ali <dev.taqnialabs@gmail.com>
Date: Sat, 25 Apr 2026 12:38:34 +0000
Subject: [PATCH] net: stmmac: fix RX DMA leak on TX alloc failure
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260425-stmmac-rx-desc-cleanup-v1-1-1a18a704c422@gmail.com>
X-B4-Tracking: v=1; b=H4sIAMm17GkC/x3MQQqEMAxA0atI1gZqScXxKoOLUqMGtCPNKELx7
 haXb/F/BuUkrNBXGRKfovKLBU1dQVh8nBllLAZrbGvIOtT/tvmA6cKRNWBY2cdjRyIzGdeRo4+
 FEu+JJ7ne8Xe47we0+LlFaAAAAA==
To: Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Maxime Coquelin <mcoquelin.stm32@gmail.com>, 
 Alexandre Torgue <alexandre.torgue@foss.st.com>
Cc: netdev@vger.kernel.org, linux-stm32@st-md-mailman.stormreply.com, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Abid Ali <dev.taqnialabs@gmail.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1777120721; l=998;
 i=dev.taqnialabs@gmail.com; s=20260425; h=from:subject:message-id;
 bh=6KNXYVuQw7qzkBuKkHzTHDqB5iOSzE7NC8yleiDYCcg=;
 b=EahVl7YbST7PFQZTcka11Q36pigH8utz9YqMXE8P+DU+sn23jzKVHG85DfrDfWEzR+sWFhWOw
 /h/aEKBo3ucCFAMZBnSU4000q8fFB8aF7BvvRihgWI7wK5bi7GsKhhe
X-Developer-Key: i=dev.taqnialabs@gmail.com; a=ed25519;
 pk=4Syx51HH/MOySSUpi79M2ToLOdwt1yiNb338eKZBJNk=
X-Endpoint-Received: by B4 Relay for dev.taqnialabs@gmail.com/20260425 with auth_id=752
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Free RX DMA resources when alloc_dma_tx_desc_resources() fails in
alloc_dma_desc_resources().

Signed-off-by: Abid Ali <dev.taqnialabs@gmail.com>
---
 drivers/net/ethernet/stmicro/stmmac/stmmac_main.c | 6 +++++-
 1 file changed, 5 insertions(+), 1 deletion(-)

diff --git a/drivers/net/ethernet/stmicro/stmmac/stmmac_main.c b/drivers/net/ethernet/stmicro/stmmac/stmmac_main.c
index 13d3cac05..8bb843b55 100644
--- a/drivers/net/ethernet/stmicro/stmmac/stmmac_main.c
+++ b/drivers/net/ethernet/stmicro/stmmac/stmmac_main.c
@@ -2370,8 +2370,12 @@ static int alloc_dma_desc_resources(struct stmmac_priv *priv,
 		return ret;
 
 	ret = alloc_dma_tx_desc_resources(priv, dma_conf);
+	if (ret) {
+		free_dma_rx_desc_resources(priv, dma_conf);
+		return ret;
+	}
 
-	return ret;
+	return 0;
 }
 
 /**

---
base-commit: 028ef9c96e96197026887c0f092424679298aae8
change-id: 20260425-stmmac-rx-desc-cleanup-440f05845492

Best regards,
-- 
Abid Ali <dev.taqnialabs@gmail.com>

