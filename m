From: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>
Date: Thu, 11 Jun 2026 16:28:57 +0100
Subject: [PATCH] iio: buffer-dmaengine: Add support for cyclic DMA
 transfers
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260611-iio-dma-cyclic-buffer-support-v1-1-bcf00e8d802c@analog.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMSw6CQAwA0KuQrm0yfELQqxgXUFqoUWbSYYiGc
 HdHXb7N2yGyKUe4FDsYbxrVLxnlqQCa+2Vi1DEbKle1rnVnVPU4PnukNz2UcEgibBhTCN5WlLJ
 zdSOd1A1BPoKx6Ov3X29/xzTcmdZvCsfxAa930tyBAAAA
X-Change-ID: 20260609-iio-dma-cyclic-buffer-support-f18034f8f34c
To: linux-iio@vger.kernel.org
Cc: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, Andy Shevchenko <andy@kernel.org>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1781191739; l=3259;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=yTXKmnTfjcEdNfZwzox0jk1OGw3HqgWvuIxVDaLrNrU=;
 b=PDPchxO//m0ASX5LLC5uSfxLs2dQDvAbsg2++DVzMB8mQ4JWEHA1zwNeOXHMtyVwvBwGufqwK
 zVJacfy/p/3D35NRYoNPQK93ASQeT6UL5tpzDwk6o9LckuO7zng97B4
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Allow buffer blocks flagged as cyclic to be submitted as repeating DMA
transfers. For cyclic blocks, use DMA_PREP_REPEAT so the engine keeps
replaying the descriptor.

Skip installing the completion callback for cyclic blocks. Since the
transfer is continuously replayed, the callback would fire on every
period, throwing off the block refcount.

Because nothing prevents a new cyclic transfer from replacing an
already active cyclic one, always set DMA_PREP_LOAD_EOT so the engine
correctly terminates the active transfer before loading the new
descriptor.

Signed-off-by: Nuno Sá <nuno.sa@analog.com>
---
There's one subtle choice in here. Given that the termination callback
is not set. We will never give the block refcount. That means cyclic
blocks are only completely freed when we disable the buffer and
iio_dmaengine_buffer_abort() get's called. So no leak, we just defer it
as it makes it more simple to handle. I also think this a fair
expectation from a cyclic transfer. We set it up and let it run until we
disable the buffer.

Alternatively, we can give in the refcount as soon as we give the block
to the DMA layer with dma_async_issue_pending(). But we also need to
make sure that the block is not added to the dmaengine_buffer->active list.
As said, I feel that the current approach is just simpler.
---
 drivers/iio/buffer/industrialio-buffer-dmaengine.c | 19 ++++++++++++++++---
 1 file changed, 16 insertions(+), 3 deletions(-)

diff --git a/drivers/iio/buffer/industrialio-buffer-dmaengine.c b/drivers/iio/buffer/industrialio-buffer-dmaengine.c
index 98acce909854..4a78cd3e7c7d 100644
--- a/drivers/iio/buffer/industrialio-buffer-dmaengine.c
+++ b/drivers/iio/buffer/industrialio-buffer-dmaengine.c
@@ -80,6 +80,8 @@ static int iio_dmaengine_buffer_submit_block(struct iio_dma_buffer_queue *queue,
 		dma_dir = DMA_MEM_TO_DEV;
 
 	if (block->sg_table) {
+		unsigned long flags;
+
 		sgl = block->sg_table->sgl;
 		nents = sg_nents_for_len(sgl, block->bytes_used);
 		if (nents < 0)
@@ -99,9 +101,18 @@ static int iio_dmaengine_buffer_submit_block(struct iio_dma_buffer_queue *queue,
 			sgl = sg_next(sgl);
 		}
 
+		if (block->cyclic)
+			flags = DMA_PREP_REPEAT;
+		else
+			flags = DMA_PREP_INTERRUPT;
+
+		/*
+		 * There's nothing preventing a cyclic transfer to replace an active
+		 * cyclic one. So always set the EOT flag.
+		 */
 		desc = dmaengine_prep_peripheral_dma_vec(dmaengine_buffer->chan,
 							 vecs, nents, dma_dir,
-							 DMA_PREP_INTERRUPT);
+							 flags | DMA_PREP_LOAD_EOT);
 		kfree(vecs);
 	} else {
 		max_size = min(block->size, dmaengine_buffer->max_size);
@@ -122,8 +133,10 @@ static int iio_dmaengine_buffer_submit_block(struct iio_dma_buffer_queue *queue,
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
base-commit: ae696dfa47c30016cd429b9db5e70b259b8f509e
change-id: 20260609-iio-dma-cyclic-buffer-support-f18034f8f34c
--

Thanks!
- Nuno Sá

