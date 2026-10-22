From: "Jeff C. Jensen" <kernel@nullptr.com>
Date: Thu, 22 Oct 2026 15:11:30 -0700
Subject: [PATCH 1/5] dmaengine: xilinx_dma: Reject transfers that map no
 data
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261022-xilinx-dma-work-v1-1-20faea2e7a80@nullptr.com>
References: <20261022-xilinx-dma-work-v1-0-20faea2e7a80@nullptr.com>
In-Reply-To: <20261022-xilinx-dma-work-v1-0-20faea2e7a80@nullptr.com>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=2155; i=kernel@nullptr.com;
 s=openpgp-2026; h=from:subject:message-id;
 bh=4HSoHWwpvRObiCk9NoS17klkZW5nP/aozCZjxK9JszY=;
 b=owGbwMvMwCV2439B4wpuQQ7G02pJDFm3ugIqTHk057113Wq+c/as+yY/3Xevzkhfa2C1dcoT0
 wN1vjZHOkpZGMS4GGTFFFmOH5u2M9/Wv66o+n4VzBxWJpAhDFycAjCRE3cZGS4df5qnIF2dcvm4
 vMHG08suzOv9fMFrZVi+6JOj8qb7V7AwMqxm+eHYnPjv4NmIuob0q3JKu8LvCliUH/EoXfXgzrT
 ldUwA
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
Assisted-by: Claude:claude-fable-5-1
Signed-off-by: Jeff C. Jensen <kernel@nullptr.com>
---
 drivers/dma/xilinx/xilinx_dma.c | 9 +++++++++
 1 file changed, 9 insertions(+)

diff --git a/drivers/dma/xilinx/xilinx_dma.c b/drivers/dma/xilinx/xilinx_dma.c
index cffe7c6fa640..5ccc9f9d58a3 100644
--- a/drivers/dma/xilinx/xilinx_dma.c
+++ b/drivers/dma/xilinx/xilinx_dma.c
@@ -2305,6 +2305,9 @@ static struct dma_async_tx_descriptor *xilinx_dma_prep_peripheral_dma_vec(
 		}
 	}
 
+	if (list_empty(&desc->segments))
+		goto error;
+
 	head = list_first_entry(&desc->segments, struct xilinx_axidma_tx_segment, node);
 	desc->async_tx.phys = head->phys;
 
@@ -2406,6 +2409,9 @@ static struct dma_async_tx_descriptor *xilinx_dma_prep_slave_sg(
 		}
 	}
 
+	if (list_empty(&desc->segments))
+		goto error;
+
 	segment = list_first_entry(&desc->segments,
 				   struct xilinx_axidma_tx_segment, node);
 	desc->async_tx.phys = segment->phys;
@@ -2613,6 +2619,9 @@ xilinx_mcdma_prep_slave_sg(struct dma_chan *dchan, struct scatterlist *sgl,
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

