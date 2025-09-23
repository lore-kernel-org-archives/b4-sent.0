From: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>
Date: Tue, 23 Sep 2025 09:23:36 +0100
Subject: [PATCH RESEND 2/4] dma: dma-axi-dmac: fix HW scatter-gather not
 looking at the queue
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250923-b4-dev-axi-dmac-fixes-v1-2-5896dcbbd909@analog.com>
References: <20250923-b4-dev-axi-dmac-fixes-v1-0-5896dcbbd909@analog.com>
In-Reply-To: <20250923-b4-dev-axi-dmac-fixes-v1-0-5896dcbbd909@analog.com>
To: dmaengine@vger.kernel.org
Cc: Vinod Koul <vkoul@kernel.org>, Lars-Peter Clausen <lars@metafoo.de>, 
 Paul Cercueil <paul@crapouillou.net>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1758615815; l=1232;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=4b9dcvl8c/l0P11QEVGkDqWnjYO8C6p4SEA8/PG0B24=;
 b=+C/tzslfewHJVs9tVxaLVN1RfA2OFiO9M5oqmx/Oa20eUoaw9AQpXpHT/6h4QkHgkVtec1hxs
 psWR4TopmJTCvJyzXhAnVUhzhwBDGCDU0rRAcKXv9fR76PEO4uS2Ylv
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

For HW scatter gather transfers we still need to look for the queue. The
HW is capable of queueing 3 concurrent transfers and if we try more than
that we'll get the submit queue full and should return. Otherwise, if we
go ahead and program the new transfer, we end up discarding it.

Fixes: e97dc7435972 ("dmaengine: axi-dmac: Add support for scatter-gather transfers")
Signed-off-by: Nuno Sá <nuno.sa@analog.com>
---
 drivers/dma/dma-axi-dmac.c | 8 +++-----
 1 file changed, 3 insertions(+), 5 deletions(-)

diff --git a/drivers/dma/dma-axi-dmac.c b/drivers/dma/dma-axi-dmac.c
index e22639822045f237ebcd1fa012a75bbe7dc536c5..0f25f6d8ae71fa73fb24c58b3e2ecfea452cd158 100644
--- a/drivers/dma/dma-axi-dmac.c
+++ b/drivers/dma/dma-axi-dmac.c
@@ -233,11 +233,9 @@ static void axi_dmac_start_transfer(struct axi_dmac_chan *chan)
 	unsigned int flags = 0;
 	unsigned int val;
 
-	if (!chan->hw_sg) {
-		val = axi_dmac_read(dmac, AXI_DMAC_REG_START_TRANSFER);
-		if (val) /* Queue is full, wait for the next SOT IRQ */
-			return;
-	}
+	val = axi_dmac_read(dmac, AXI_DMAC_REG_START_TRANSFER);
+	if (val) /* Queue is full, wait for the next SOT IRQ */
+		return;
 
 	desc = chan->next_desc;
 

-- 
2.51.0

