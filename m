From: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>
Date: Tue, 03 Mar 2026 10:25:01 +0000
Subject: [PATCH v2 2/5] dmaengine: dma-axi-dmac: Add cyclic transfers in
 .device_prep_peripheral_dma_vec()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260303-axi-dac-cyclic-support-v2-2-0db27b4be95a@analog.com>
References: <20260303-axi-dac-cyclic-support-v2-0-0db27b4be95a@analog.com>
In-Reply-To: <20260303-axi-dac-cyclic-support-v2-0-0db27b4be95a@analog.com>
To: dmaengine@vger.kernel.org
Cc: Lars-Peter Clausen <lars@metafoo.de>, Vinod Koul <vkoul@kernel.org>, 
 Frank Li <Frank.Li@nxp.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1772533501; l=1088;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=J1Cpr1txWVAI64Jhdqr7+Os1z7iyvgdh75sSDV3Ci4k=;
 b=v/I3MEIlmudS9FWZXswCKKIV1hCc23eFisTDnAq2LK31K86cQVZ+436CChEmxUDV0xKYqfKwP
 L5JfIE1cqljD74nUQVs2LXbQH9he3OFJYyTMtxFFyFXpi69mgX9AOh1
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add support for cyclic transfers by checking the DMA_PREP_REPEAT
flag. If the flag is set, close the loop and clear the flag for the last
segment (the same done for .device_prep_dma_cyclic().

Reviewed-by: Frank Li <Frank.Li@nxp.com>
Signed-off-by: Nuno Sá <nuno.sa@analog.com>
---
 drivers/dma/dma-axi-dmac.c | 7 ++++++-
 1 file changed, 6 insertions(+), 1 deletion(-)

diff --git a/drivers/dma/dma-axi-dmac.c b/drivers/dma/dma-axi-dmac.c
index eb65872c5d5c..79c01b7d9732 100644
--- a/drivers/dma/dma-axi-dmac.c
+++ b/drivers/dma/dma-axi-dmac.c
@@ -657,7 +657,12 @@ axi_dmac_prep_peripheral_dma_vec(struct dma_chan *c, const struct dma_vec *vecs,
 					      vecs[i].len, dsg);
 	}
 
-	desc->cyclic = false;
+	desc->cyclic = flags & DMA_PREP_REPEAT;
+	if (desc->cyclic) {
+		/* Chain the last descriptor to the first, and remove its "last" flag */
+		desc->sg[num_sgs - 1].hw->flags &= ~AXI_DMAC_HW_FLAG_LAST;
+		desc->sg[num_sgs - 1].hw->next_sg_addr = desc->sg[0].hw_phys;
+	}
 
 	return vchan_tx_prep(&chan->vchan, &desc->vdesc, flags);
 }

-- 
2.53.0

