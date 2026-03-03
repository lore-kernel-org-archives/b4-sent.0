From: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>
Date: Tue, 03 Mar 2026 10:25:02 +0000
Subject: [PATCH v2 3/5] dmaengine: dma-axi-dmac: Add helper for getting
 next desc
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260303-axi-dac-cyclic-support-v2-3-0db27b4be95a@analog.com>
References: <20260303-axi-dac-cyclic-support-v2-0-0db27b4be95a@analog.com>
In-Reply-To: <20260303-axi-dac-cyclic-support-v2-0-0db27b4be95a@analog.com>
To: dmaengine@vger.kernel.org
Cc: Lars-Peter Clausen <lars@metafoo.de>, Vinod Koul <vkoul@kernel.org>, 
 Frank Li <Frank.Li@nxp.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1772533501; l=1978;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=ahOiSW4VtsiQwIe3hhYDseeE6OAZGhuM2ZkOpgAjXNU=;
 b=rUwOlZWJthORkrYXkSyfm8b3GChcw1/ZKQfd9NmqFOcnLjurFOH9Y2BFy7CwS81t4oPmeP0Ce
 A+HgbWYs3vZDo4PGnBGXHhjco59lYcw6Qx0samhgsg0cTx3Gp+/C5m7
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a new helper for getting the next valid struct axi_dmac_desc. This
will be extended in follow up patches to support to gracefully terminate
cyclic transfers.

Reviewed-by: Frank Li <Frank.Li@nxp.com>
Signed-off-by: Nuno Sá <nuno.sa@analog.com>
---
 drivers/dma/dma-axi-dmac.c | 33 +++++++++++++++++++++++----------
 1 file changed, 23 insertions(+), 10 deletions(-)

diff --git a/drivers/dma/dma-axi-dmac.c b/drivers/dma/dma-axi-dmac.c
index 79c01b7d9732..a47e08d3dbbc 100644
--- a/drivers/dma/dma-axi-dmac.c
+++ b/drivers/dma/dma-axi-dmac.c
@@ -227,10 +227,29 @@ static bool axi_dmac_check_addr(struct axi_dmac_chan *chan, dma_addr_t addr)
 	return true;
 }
 
+static struct axi_dmac_desc *axi_dmac_get_next_desc(struct axi_dmac *dmac,
+						    struct axi_dmac_chan *chan)
+{
+	struct virt_dma_desc *vdesc;
+	struct axi_dmac_desc *desc;
+
+	if (chan->next_desc)
+		return chan->next_desc;
+
+	vdesc = vchan_next_desc(&chan->vchan);
+	if (!vdesc)
+		return NULL;
+
+	list_move_tail(&vdesc->node, &chan->active_descs);
+	desc = to_axi_dmac_desc(vdesc);
+	chan->next_desc = desc;
+
+	return desc;
+}
+
 static void axi_dmac_start_transfer(struct axi_dmac_chan *chan)
 {
 	struct axi_dmac *dmac = chan_to_axi_dmac(chan);
-	struct virt_dma_desc *vdesc;
 	struct axi_dmac_desc *desc;
 	struct axi_dmac_sg *sg;
 	unsigned int flags = 0;
@@ -240,16 +259,10 @@ static void axi_dmac_start_transfer(struct axi_dmac_chan *chan)
 	if (val) /* Queue is full, wait for the next SOT IRQ */
 		return;
 
-	desc = chan->next_desc;
+	desc = axi_dmac_get_next_desc(dmac, chan);
+	if (!desc)
+		return;
 
-	if (!desc) {
-		vdesc = vchan_next_desc(&chan->vchan);
-		if (!vdesc)
-			return;
-		list_move_tail(&vdesc->node, &chan->active_descs);
-		desc = to_axi_dmac_desc(vdesc);
-		chan->next_desc = desc;
-	}
 	sg = &desc->sg[desc->num_submitted];
 
 	/* Already queued in cyclic mode. Wait for it to finish */

-- 
2.53.0

