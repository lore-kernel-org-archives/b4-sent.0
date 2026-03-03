From: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>
Date: Tue, 03 Mar 2026 10:25:03 +0000
Subject: [PATCH v2 4/5] dmaengine: dma-axi-dmac: Gracefully terminate SW
 cyclic transfers
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260303-axi-dac-cyclic-support-v2-4-0db27b4be95a@analog.com>
References: <20260303-axi-dac-cyclic-support-v2-0-0db27b4be95a@analog.com>
In-Reply-To: <20260303-axi-dac-cyclic-support-v2-0-0db27b4be95a@analog.com>
To: dmaengine@vger.kernel.org
Cc: Lars-Peter Clausen <lars@metafoo.de>, Vinod Koul <vkoul@kernel.org>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1772533501; l=2568;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=by16V5/NLFw/3DRhfR0r4tQVR69bWmLI/moWu8EK0w0=;
 b=ZCJTjmqmBu0fkqNoG+OfB7eMaUU/Z1l91yuLS/Oag2TdVLrMGeYmnyFH3GDwWXZAzQjZ32d6O
 HauB8Ma4x/YDyxzv3Bbw2WBzb24wco1ArcBoeCupeR4EiiN1lw4NVtc
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

As of now, to terminate a cyclic transfer, one pretty much needs to use
brute force and terminate all transfers with .device_terminate_all().
With this change, when a cyclic transfer terminates (and generates an
EOT interrupt), look at any new pending transfer with the DMA_PREP_LOAD_EOT
flag set. If there is one, the current cyclic transfer is terminated and
the next one is enqueued. If the flag is not set, that transfer is ignored.

Signed-off-by: Nuno Sá <nuno.sa@analog.com>
---
 drivers/dma/dma-axi-dmac.c | 34 +++++++++++++++++++++++++++++++++-
 1 file changed, 33 insertions(+), 1 deletion(-)

diff --git a/drivers/dma/dma-axi-dmac.c b/drivers/dma/dma-axi-dmac.c
index a47e08d3dbbc..e9814d725322 100644
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
2.53.0

