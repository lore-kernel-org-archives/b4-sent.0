From: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>
Date: Tue, 27 Jan 2026 14:28:25 +0000
Subject: [PATCH 4/5] dma: dma-axi-dmac: Gracefully terminate SW cyclic
 transfers
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260127-axi-dac-cyclic-support-v1-4-b32daca4b3c7@analog.com>
References: <20260127-axi-dac-cyclic-support-v1-0-b32daca4b3c7@analog.com>
In-Reply-To: <20260127-axi-dac-cyclic-support-v1-0-b32daca4b3c7@analog.com>
To: dmaengine@vger.kernel.org
Cc: Lars-Peter Clausen <lars@metafoo.de>, Vinod Koul <vkoul@kernel.org>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1769524107; l=2541;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=Slzv8A3zvxjLZy++p0j3/rLtEyvn8HAns4tsjJyxk/4=;
 b=PXe5QqFI/r2x0RY7axMcxsuWcd+I8k0dfPVmyau2m1Hi7eXDjElF8Ijs0OeZyz5d7SJDT13rQ
 1GAAYxQhsa8A3fvF7bC59rH13PQgh11V/5oBQqGmgygtyQ2080QI8uf
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

As of now, to terminate a cyclic transfer, one pretty much needs to use
brute force and terminate all transfers with .device_terminate_all().
With this change, when a cyclic transfer terminates we look and see if
we have any pending transfer with the DMA_PREP_LOAD_EOT flag set. If
we do, we terminate the cyclic transfer and prepare to start the next
one. If we don't see the flag we'll ignore that transfer.

Signed-off-by: Nuno Sá <nuno.sa@analog.com>
---
 drivers/dma/dma-axi-dmac.c | 34 +++++++++++++++++++++++++++++++++-
 1 file changed, 33 insertions(+), 1 deletion(-)

diff --git a/drivers/dma/dma-axi-dmac.c b/drivers/dma/dma-axi-dmac.c
index 3984236717a6..638625647152 100644
--- a/drivers/dma/dma-axi-dmac.c
+++ b/drivers/dma/dma-axi-dmac.c
@@ -233,6 +233,11 @@ static struct axi_dmac_desc *axi_dmac_get_next_desc(struct axi_dmac *dmac,
 	struct virt_dma_desc *vdesc;
 	struct axi_dmac_desc *desc;
 
+	/*
+	 * It means a SW cyclic transfer is in place so we should just return
+	 * the same descriptor. SW cyclic transfer termination is handled
+	 * in axi_dmac_transfer_done().
+	 */
 	if (chan->next_desc)
 		return chan->next_desc;
 
@@ -411,6 +416,32 @@ static void axi_dmac_compute_residue(struct axi_dmac_chan *chan,
 	}
 }
 
+static bool axi_dmac_handle_cyclic_eot(struct axi_dmac_chan *chan,
+				       struct axi_dmac_desc *active)
+{
+	struct device *dev = chan_to_axi_dmac(chan)->dma_dev.dev;
+	struct virt_dma_desc *vdesc;
+
+	/* wrap around */
+	active->num_completed = 0;
+
+	vdesc = vchan_next_desc(&chan->vchan);
+	if (!vdesc)
+		return false;
+	if (!(vdesc->tx.flags & DMA_PREP_LOAD_EOT)) {
+		dev_warn(dev, "Discarding non EOT transfer after cyclic\n");
+		list_del(&vdesc->node);
+		return false;
+	}
+
+	/* then let's end the cyclic transfer */
+	chan->next_desc = NULL;
+	list_del(&active->vdesc.node);
+	vchan_cookie_complete(&active->vdesc);
+
+	return true;
+}
+
 static bool axi_dmac_transfer_done(struct axi_dmac_chan *chan,
 	unsigned int completed_transfers)
 {
@@ -458,7 +489,8 @@ static bool axi_dmac_transfer_done(struct axi_dmac_chan *chan,
 			if (active->num_completed == active->num_sgs ||
 			    sg->partial_len) {
 				if (active->cyclic) {
-					active->num_completed = 0; /* wrap around */
+					/* keep start_next as is, if already true... */
+					start_next |= axi_dmac_handle_cyclic_eot(chan, active);
 				} else {
 					list_del(&active->vdesc.node);
 					vchan_cookie_complete(&active->vdesc);

-- 
2.52.0

