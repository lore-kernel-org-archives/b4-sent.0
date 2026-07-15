From: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>
Date: Wed, 15 Jul 2026 13:24:53 +0200
Subject: [PATCH v2] iio: buffer-dmaengine: Add support for cyclic DMA
 transfers
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260715-iio-dma-cyclic-v2-1-268a3a28ff84@analog.com>
X-B4-Tracking: v=1; b=H4sIAARuV2oC/x3MMQqAMAxA0atIZgM1iAWvIg4ljRrQVloQRXp3i
 +Mb/n8hS1LJMDYvJLk0awwV1DbAmwuroPpqIEODsV2PqhH94ZAf3pXRkPPWMjH3Bmp0Jln0/of
 TXMoH+FQcMWAAAAA=
X-Change-ID: 20260714-iio-dma-cyclic-02ad77c2cc40
To: linux-iio@vger.kernel.org
Cc: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, Andy Shevchenko <andy@kernel.org>
X-Mailer: b4 0.15-dev-52d38
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784114695; l=4101;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=h1rRMQmOttcGtDUJBsj6Y7Srh7vH59QdLhE14FvpwAY=;
 b=e/ZqMawUYSHQVv0VUyVqjyOddHRt7/VQ1Rp9pGm3ujx55M+VB8g9ceJ7JrWlbyMsZ03Jl5m5G
 cNYLjGPgfKSA9VJtik5rbR//N2ou5daLKeQsrbeMXo+t5HzwLkmhICU
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Allow buffer blocks flagged as cyclic to be submitted as repeating DMA
transfers. For cyclic blocks, use DMA_PREP_REPEAT so the engine keeps
replaying the descriptor.

This is useful for output buffers where the same data should be driven
continuously without userspace having to requeue it. Examples include
continuous RF transmit paths replaying a calibration, test or beacon
pattern.

Skip installing the completion callback for cyclic blocks. Since the
transfer is continuously replayed, the callback would fire on every
period, throwing off the block refcount.

Because nothing prevents a new cyclic transfer from replacing an
already active cyclic one, always set DMA_PREP_LOAD_EOT so the engine
correctly terminates the active transfer before loading the new
descriptor.

Limit the DMA buffer queue to one cyclic DMABUF at a time. There is
currently no known use case for queueing multiple cyclic blocks, and
cyclic blocks stay referenced until the buffer is disabled.

Signed-off-by: Nuno Sá <nuno.sa@analog.com>
---
Changes in v2:
* Improved commit message for usecase;
* Safety cap cyclic transfers to one  (see v1 for context).
* Link to v1: https://lore.kernel.org/linux-iio/20260611-iio-dma-cyclic-buffer-support-v1-1-bcf00e8d802c@analog.com/
---
 drivers/iio/buffer/industrialio-buffer-dmaengine.c | 41 ++++++++++++++++++++--
 1 file changed, 38 insertions(+), 3 deletions(-)

diff --git a/drivers/iio/buffer/industrialio-buffer-dmaengine.c b/drivers/iio/buffer/industrialio-buffer-dmaengine.c
index 98acce909854..639bac135539 100644
--- a/drivers/iio/buffer/industrialio-buffer-dmaengine.c
+++ b/drivers/iio/buffer/industrialio-buffer-dmaengine.c
@@ -56,6 +56,23 @@ static void iio_dmaengine_buffer_block_done(void *data,
 	iio_dma_buffer_block_done(block);
 }
 
+/*
+ * Cyclic transfers run until abort. Cap active cyclic blocks to one until there
+ * is a use case for more.
+ */
+static bool iio_dmaengine_buffer_has_active_cyclic(struct dmaengine_buffer *dmaengine_buffer)
+{
+	struct iio_dma_buffer_block *block;
+
+	guard(spinlock_irqsave)(&dmaengine_buffer->queue.list_lock);
+	list_for_each_entry(block, &dmaengine_buffer->active, head) {
+		if (block->cyclic)
+			return true;
+	}
+
+	return false;
+}
+
 static int iio_dmaengine_buffer_submit_block(struct iio_dma_buffer_queue *queue,
 					     struct iio_dma_buffer_block *block)
 {
@@ -79,7 +96,14 @@ static int iio_dmaengine_buffer_submit_block(struct iio_dma_buffer_queue *queue,
 	else
 		dma_dir = DMA_MEM_TO_DEV;
 
+	if (block->cyclic && iio_dmaengine_buffer_has_active_cyclic(dmaengine_buffer)) {
+		dev_err(queue->dev, "cyclic DMA transfer already active\n");
+		return -EBUSY;
+	}
+
 	if (block->sg_table) {
+		unsigned long flags;
+
 		sgl = block->sg_table->sgl;
 		nents = sg_nents_for_len(sgl, block->bytes_used);
 		if (nents < 0)
@@ -99,9 +123,18 @@ static int iio_dmaengine_buffer_submit_block(struct iio_dma_buffer_queue *queue,
 			sgl = sg_next(sgl);
 		}
 
+		if (block->cyclic)
+			flags = DMA_PREP_REPEAT;
+		else
+			flags = DMA_PREP_INTERRUPT;
+
+		/*
+		 * A new transfer may need to end an already active cyclic transfer
+		 * before it can run, so always set the EOT flag.
+		 */
 		desc = dmaengine_prep_peripheral_dma_vec(dmaengine_buffer->chan,
 							 vecs, nents, dma_dir,
-							 DMA_PREP_INTERRUPT);
+							 flags | DMA_PREP_LOAD_EOT);
 		kfree(vecs);
 	} else {
 		max_size = min(block->size, dmaengine_buffer->max_size);
@@ -122,8 +155,10 @@ static int iio_dmaengine_buffer_submit_block(struct iio_dma_buffer_queue *queue,
 	if (!desc)
 		return -ENOMEM;
 
-	desc->callback_result = iio_dmaengine_buffer_block_done;
-	desc->callback_param = block;
+	if (!block->cyclic) {
+		desc->callback_result = iio_dmaengine_buffer_block_done;
+		desc->callback_param = block;
+	}
 
 	cookie = dmaengine_submit(desc);
 	if (dma_submit_error(cookie))

---
base-commit: aa58ecc73466d0cb8c418de98e2225490bf600e3
change-id: 20260714-iio-dma-cyclic-02ad77c2cc40
--

Thanks!
- Nuno Sá

