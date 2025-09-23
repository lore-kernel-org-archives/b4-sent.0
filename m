From: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>
Date: Tue, 23 Sep 2025 09:23:35 +0100
Subject: [PATCH RESEND 1/4] dma: dma-axi-dmac: fix SW cyclic transfers
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250923-b4-dev-axi-dmac-fixes-v1-1-5896dcbbd909@analog.com>
References: <20250923-b4-dev-axi-dmac-fixes-v1-0-5896dcbbd909@analog.com>
In-Reply-To: <20250923-b4-dev-axi-dmac-fixes-v1-0-5896dcbbd909@analog.com>
To: dmaengine@vger.kernel.org
Cc: Vinod Koul <vkoul@kernel.org>, Lars-Peter Clausen <lars@metafoo.de>, 
 Paul Cercueil <paul@crapouillou.net>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1758615815; l=1461;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=BAuoxEsSrmFa/FKz+UWCZwjeXC6UYdc6O9UDaRqXuRY=;
 b=Dv5EdzWjRC4w+RwTCWLgSMfXZwZTy90VSGG8JGHegvWnstMM6cxCtISHRnVYCsgvX2qcxfOct
 9kRCFoBmiwhA8LtAbj7jvMJ+4MxQoTQoBH0m9yFYRTC1XQMQW26Icbu
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
index 5b06b0dc67ee12017c165bf815fb7c0e1bf5abd8..e22639822045f237ebcd1fa012a75bbe7dc536c5 100644
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

