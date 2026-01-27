From: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>
Date: Tue, 27 Jan 2026 14:28:23 +0000
Subject: [PATCH 2/5] dma: dma-axi-dmac: add cyclic transfers in
 .device_prep_peripheral_dma_vec()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260127-axi-dac-cyclic-support-v1-2-b32daca4b3c7@analog.com>
References: <20260127-axi-dac-cyclic-support-v1-0-b32daca4b3c7@analog.com>
In-Reply-To: <20260127-axi-dac-cyclic-support-v1-0-b32daca4b3c7@analog.com>
To: dmaengine@vger.kernel.org
Cc: Lars-Peter Clausen <lars@metafoo.de>, Vinod Koul <vkoul@kernel.org>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1769524107; l=1047;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=aTU9xL5dsmjMDpgb8es1E5jSSmA7HMSFgMKwQhyr59A=;
 b=TR2rHTx0MQaAMMQfYJIc6poHA9q7dyTjsxLRBCsrELI/OhqCnTzRqXix+KT7CTAc6fghbJuzE
 7VB16lGx84MBkKNMjfElFeNl4SZvW6pKo1bMRVduEMPe3SwJMkDpNDO
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add support for cyclic transfers by checking the DMA_PREP_REPEAT
flag. If we do see it, close the loop and clear the flag for the last
segment (the same as we do for .device_prep_dma_cyclic().

Signed-off-by: Nuno Sá <nuno.sa@analog.com>
---
 drivers/dma/dma-axi-dmac.c | 7 ++++++-
 1 file changed, 6 insertions(+), 1 deletion(-)

diff --git a/drivers/dma/dma-axi-dmac.c b/drivers/dma/dma-axi-dmac.c
index f5caf75dc0e7..b083b6176593 100644
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
2.52.0

