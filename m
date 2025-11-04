From: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>
Date: Tue, 04 Nov 2025 16:22:25 +0000
Subject: [PATCH RESEND 1/4] dma: dma-axi-dmac: fix SW cyclic transfers
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20251104-axi-dmac-fixes-and-improvs-v1-1-3e6fd9328f72@analog.com>
References: <20251104-axi-dmac-fixes-and-improvs-v1-0-3e6fd9328f72@analog.com>
In-Reply-To: <20251104-axi-dmac-fixes-and-improvs-v1-0-3e6fd9328f72@analog.com>
To: Vinod Koul <vkoul@kernel.org>, Lars-Peter Clausen <lars@metafoo.de>, 
 Paul Cercueil <paul@crapouillou.net>
Cc: Michael Hennerich <Michael.Hennerich@analog.com>, 
 dmaengine@vger.kernel.org, linux-kernel@vger.kernel.org
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1762273346; l=1405;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=h38Cp593uwl9c1SEt5NsKQomiYALx/d39utsfA9eGW4=;
 b=E2NgXxn7aKyCrbUdCy9amZZSWcULFuBhnycTQ9SxCbWHr/B1fmdCY4fOBik6A5zm+vY494NCk
 k8JjsdA6fF5CiSnhQKkn9bEs7cqFqRRAHNQ7fcJLP66/KCqByBuDOMO
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

If 'hw_cyclic' is false we should still be able to do cyclic transfers in
"software". That was not working for the case where 'desc->num_sgs' is 1
because 'chan->next_desc' is never set with the current desc which means
that the cyclic transfer only runs once and in the next SOT interrupt we
do nothing since vchan_next_desc() will return NULL.

Fix it by setting 'chan->next_desc' as soon as we get a new desc via
vchan_next_desc().

Fixes: 0e3b67b348b8 ("dmaengine: Add support for the Analog Devices AXI-DMAC DMA controller")
Signed-off-by: Nuno Sá <nuno.sa@analog.com>
---
 drivers/dma/dma-axi-dmac.c | 3 +--
 1 file changed, 1 insertion(+), 2 deletions(-)

diff --git a/drivers/dma/dma-axi-dmac.c b/drivers/dma/dma-axi-dmac.c
index 5b06b0dc67ee..e22639822045 100644
--- a/drivers/dma/dma-axi-dmac.c
+++ b/drivers/dma/dma-axi-dmac.c
@@ -247,6 +247,7 @@ static void axi_dmac_start_transfer(struct axi_dmac_chan *chan)
 			return;
 		list_move_tail(&vdesc->node, &chan->active_descs);
 		desc = to_axi_dmac_desc(vdesc);
+		chan->next_desc = desc;
 	}
 	sg = &desc->sg[desc->num_submitted];
 
@@ -265,8 +266,6 @@ static void axi_dmac_start_transfer(struct axi_dmac_chan *chan)
 		else
 			chan->next_desc = NULL;
 		flags |= AXI_DMAC_FLAG_LAST;
-	} else {
-		chan->next_desc = desc;
 	}
 
 	sg->hw->id = axi_dmac_read(dmac, AXI_DMAC_REG_TRANSFER_ID);

-- 
2.51.0

