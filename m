From: "Jeff C. Jensen" <kernel@nullptr.com>
Date: Sun, 15 Nov 2026 19:43:04 -0800
Subject: [PATCH v2 1/3] dmaengine: xilinx_dma: Reject transfers that map no
 data
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261115-xilinx-dma-work-v2-1-681ed00c15a1@nullptr.com>
References: <20261115-xilinx-dma-work-v2-0-681ed00c15a1@nullptr.com>
In-Reply-To: <20261115-xilinx-dma-work-v2-0-681ed00c15a1@nullptr.com>
To: Vinod Koul <vkoul@kernel.org>, dmaengine@vger.kernel.org
Cc: Frank Li <Frank.Li@kernel.org>, Michal Simek <michal.simek@amd.com>, 
 Suraj Gupta <suraj.gupta2@amd.com>, 
 Radhey Shyam Pandey <radhey.shyam.pandey@amd.com>, 
 Alex Bereza <alex@bereza.email>, 
 Folker Schwesinger <dev@folker-schwesinger.de>, 
 Tomi Valkeinen <tomi.valkeinen@ideasonboard.com>, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 "Jeff C. Jensen" <kernel@nullptr.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=2208; i=kernel@nullptr.com;
 s=openpgp-2026; h=from:subject:message-id;
 bh=QYC4vX1LRQq4IFV/4oVzvQGjzHrh3TFPTAyJaiMRS6w=;
 b=owGbwMvMwCV2439B4wpuQQ7G02pJDFm/qu9u37Bwf9cj464VdyWPnon2l2u6kPzRpZLx88IJx
 x+//tC/o6OUhUGMi0FWTJHl+LFpO/Nt/euKqu9XwcxhZQIZwsDFKQATub+N4X+KD8f0mzM0Dq8T
 WSZbuSz5RtqrSJtPHeGqa+z3NzvKn9zFyHD7ysuA2sK8Q/Z2Ky1m+R5a8HT9wWOpa6p5+tYGzpe
 s1OEFAA==
X-Developer-Key: i=kernel@nullptr.com; a=openpgp;
 fpr=C7C696B96F3D4F7E727BDF7AD8FF7081A80B1108
X-Endpoint-Received: by B4 Relay for kernel@nullptr.com/openpgp-2026 with auth_id=1265
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

If every entry of a scatterlist or a DMA vector array has zero length,
the preparation loops in xilinx_dma_prep_slave_sg(),
xilinx_dma_prep_peripheral_dma_vec() and xilinx_mcdma_prep_slave_sg()
allocate no segments. Each function then takes list_first_entry() of the
empty segment list anyway, so desc->async_tx.phys, which is later
programmed as the current descriptor, is derived from the list head
rather than from a segment. For DMA_MEM_TO_DEV, the SOP and EOP bits are
also set through pointers that do not point at a segment.

Fail the preparation when no segment was allocated.

Fixes: c0bba3a99f07 ("dmaengine: vdma: Add Support for Xilinx AXI Direct Memory Access Engine")
Fixes: 6ccd692bfb7f ("dmaengine: xilinx_dma: Add Xilinx AXI MCDMA Engine driver support")
Fixes: 38433a6fdfb7 ("dmaengine: xilinx_dma: Support descriptor setup from dma_vecs")
Reviewed-by: Frank Li <Frank.Li@nxp.com>
Reviewed-by: Suraj Gupta <suraj.gupta2@amd.com>
Signed-off-by: Jeff C. Jensen <kernel@nullptr.com>
---
 drivers/dma/xilinx/xilinx_dma.c | 9 +++++++++
 1 file changed, 9 insertions(+)

diff --git a/drivers/dma/xilinx/xilinx_dma.c b/drivers/dma/xilinx/xilinx_dma.c
index 0336941d4095..6f00ab41b143 100644
--- a/drivers/dma/xilinx/xilinx_dma.c
+++ b/drivers/dma/xilinx/xilinx_dma.c
@@ -2362,6 +2362,9 @@ static struct dma_async_tx_descriptor *xilinx_dma_prep_peripheral_dma_vec(
 		}
 	}
 
+	if (list_empty(&desc->segments))
+		goto error;
+
 	head = list_first_entry(&desc->segments, struct xilinx_axidma_tx_segment, node);
 	desc->async_tx.phys = head->phys;
 
@@ -2463,6 +2466,9 @@ static struct dma_async_tx_descriptor *xilinx_dma_prep_slave_sg(
 		}
 	}
 
+	if (list_empty(&desc->segments))
+		goto error;
+
 	segment = list_first_entry(&desc->segments,
 				   struct xilinx_axidma_tx_segment, node);
 	desc->async_tx.phys = segment->phys;
@@ -2670,6 +2676,9 @@ xilinx_mcdma_prep_slave_sg(struct dma_chan *dchan, struct scatterlist *sgl,
 		}
 	}
 
+	if (list_empty(&desc->segments))
+		goto error;
+
 	segment = list_first_entry(&desc->segments,
 				   struct xilinx_aximcdma_tx_segment, node);
 	desc->async_tx.phys = segment->phys;

-- 
2.43.0

