From: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>
Date: Wed, 03 Dec 2025 15:11:39 +0000
Subject: [PATCH 4/6] iio: buffer-dma: Fix coding style complains
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20251203-iio-dmabuf-improvs-v1-4-0e4907ce7322@analog.com>
References: <20251203-iio-dmabuf-improvs-v1-0-0e4907ce7322@analog.com>
In-Reply-To: <20251203-iio-dmabuf-improvs-v1-0-0e4907ce7322@analog.com>
To: linux-iio@vger.kernel.org
Cc: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, Andy Shevchenko <andy@kernel.org>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1764774697; l=5579;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=bkD+oeC7CbBzogPRDCpQ4//FHbqQ9QKsRtFhfVUZXV8=;
 b=viWCc6JRO0damDWjcVNvvi2ENXX8OovBD/LmWY5zg3wZ4dAcMtSbEWWx7Nz1zl9yOHe/kk3Hu
 UAFGXket45oDyQnheXugXjD0jI64PfdaeKTpliEwgl3trzqNW24MTXL
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Just making sure checkpatch is happy. No functional change intended.

Signed-off-by: Nuno Sá <nuno.sa@analog.com>
---
 drivers/iio/buffer/industrialio-buffer-dma.c | 23 ++++++++++-------------
 include/linux/iio/buffer-dma.h               | 16 ++++++++++------
 2 files changed, 20 insertions(+), 19 deletions(-)

diff --git a/drivers/iio/buffer/industrialio-buffer-dma.c b/drivers/iio/buffer/industrialio-buffer-dma.c
index 0a6891541ed3..5c34cab28d34 100644
--- a/drivers/iio/buffer/industrialio-buffer-dma.c
+++ b/drivers/iio/buffer/industrialio-buffer-dma.c
@@ -169,8 +169,9 @@ static struct iio_dma_buffer_queue *iio_buffer_to_queue(struct iio_buffer *buf)
 	return container_of(buf, struct iio_dma_buffer_queue, buffer);
 }
 
-static struct iio_dma_buffer_block *iio_dma_buffer_alloc_block(
-	struct iio_dma_buffer_queue *queue, size_t size, bool fileio)
+static struct iio_dma_buffer_block *iio_dma_buffer_alloc_block(struct iio_dma_buffer_queue *queue,
+							       size_t size,
+							       bool fileio)
 {
 	struct iio_dma_buffer_block *block __free(kfree) = kzalloc(sizeof(*block), GFP_KERNEL);
 	if (!block)
@@ -253,7 +254,7 @@ EXPORT_SYMBOL_NS_GPL(iio_dma_buffer_block_done, "IIO_DMA_BUFFER");
  * hand the blocks back to the queue.
  */
 void iio_dma_buffer_block_list_abort(struct iio_dma_buffer_queue *queue,
-	struct list_head *list)
+				     struct list_head *list)
 {
 	struct iio_dma_buffer_block *block, *_block;
 	bool cookie;
@@ -433,7 +434,7 @@ static void iio_dma_buffer_fileio_free(struct iio_dma_buffer_queue *queue)
 }
 
 static void iio_dma_buffer_submit_block(struct iio_dma_buffer_queue *queue,
-	struct iio_dma_buffer_block *block)
+					struct iio_dma_buffer_block *block)
 {
 	int ret;
 
@@ -477,8 +478,7 @@ static void iio_dma_buffer_submit_block(struct iio_dma_buffer_queue *queue,
  *
  * This will allocate the DMA buffers and start the DMA transfers.
  */
-int iio_dma_buffer_enable(struct iio_buffer *buffer,
-	struct iio_dev *indio_dev)
+int iio_dma_buffer_enable(struct iio_buffer *buffer, struct iio_dev *indio_dev)
 {
 	struct iio_dma_buffer_queue *queue = iio_buffer_to_queue(buffer);
 	struct iio_dma_buffer_block *block, *_block;
@@ -502,8 +502,7 @@ EXPORT_SYMBOL_NS_GPL(iio_dma_buffer_enable, "IIO_DMA_BUFFER");
  * Needs to be called when the device that the buffer is attached to stops
  * sampling. Typically should be the iio_buffer_access_ops disable callback.
  */
-int iio_dma_buffer_disable(struct iio_buffer *buffer,
-	struct iio_dev *indio_dev)
+int iio_dma_buffer_disable(struct iio_buffer *buffer, struct iio_dev *indio_dev)
 {
 	struct iio_dma_buffer_queue *queue = iio_buffer_to_queue(buffer);
 
@@ -518,7 +517,7 @@ int iio_dma_buffer_disable(struct iio_buffer *buffer,
 EXPORT_SYMBOL_NS_GPL(iio_dma_buffer_disable, "IIO_DMA_BUFFER");
 
 static void iio_dma_buffer_enqueue(struct iio_dma_buffer_queue *queue,
-	struct iio_dma_buffer_block *block)
+				   struct iio_dma_buffer_block *block)
 {
 	if (block->state == IIO_BLOCK_STATE_DEAD) {
 		iio_buffer_block_put(block);
@@ -530,8 +529,7 @@ static void iio_dma_buffer_enqueue(struct iio_dma_buffer_queue *queue,
 	}
 }
 
-static struct iio_dma_buffer_block *iio_dma_buffer_dequeue(
-	struct iio_dma_buffer_queue *queue)
+static struct iio_dma_buffer_block *iio_dma_buffer_dequeue(struct iio_dma_buffer_queue *queue)
 {
 	struct iio_dma_buffer_block *block;
 	unsigned int idx;
@@ -660,8 +658,7 @@ size_t iio_dma_buffer_usage(struct iio_buffer *buf)
 	for (i = 0; i < ARRAY_SIZE(queue->fileio.blocks); i++) {
 		block = queue->fileio.blocks[i];
 
-		if (block != queue->fileio.active_block
-		    && block->state == IIO_BLOCK_STATE_DONE)
+		if (block != queue->fileio.active_block && block->state == IIO_BLOCK_STATE_DONE)
 			data_available += block->size;
 	}
 
diff --git a/include/linux/iio/buffer-dma.h b/include/linux/iio/buffer-dma.h
index 91f678e5be71..8573a21a33ba 100644
--- a/include/linux/iio/buffer-dma.h
+++ b/include/linux/iio/buffer-dma.h
@@ -119,7 +119,12 @@ struct iio_dma_buffer_queue {
 	struct device *dev;
 	const struct iio_dma_buffer_ops *ops;
 
+	/*
+	 * mutex to protect accessing, configuring (eg: enqueuing DMA blocks)
+	 * and do file IO on struct iio_dma_buffer_queue objects.
+	 */
 	struct mutex lock;
+	/* spinlock to protect adding/removing blocks to the queue list */
 	spinlock_t list_lock;
 	struct list_head incoming;
 
@@ -136,20 +141,19 @@ struct iio_dma_buffer_queue {
  */
 struct iio_dma_buffer_ops {
 	int (*submit)(struct iio_dma_buffer_queue *queue,
-		struct iio_dma_buffer_block *block);
+		      struct iio_dma_buffer_block *block);
 	void (*abort)(struct iio_dma_buffer_queue *queue);
 };
 
 void iio_dma_buffer_block_done(struct iio_dma_buffer_block *block);
 void iio_dma_buffer_block_list_abort(struct iio_dma_buffer_queue *queue,
-	struct list_head *list);
+				     struct list_head *list);
 
-int iio_dma_buffer_enable(struct iio_buffer *buffer,
-	struct iio_dev *indio_dev);
+int iio_dma_buffer_enable(struct iio_buffer *buffer, struct iio_dev *indio_dev);
 int iio_dma_buffer_disable(struct iio_buffer *buffer,
-	struct iio_dev *indio_dev);
+			   struct iio_dev *indio_dev);
 int iio_dma_buffer_read(struct iio_buffer *buffer, size_t n,
-	char __user *user_buffer);
+			char __user *user_buffer);
 int iio_dma_buffer_write(struct iio_buffer *buffer, size_t n,
 			 const char __user *user_buffer);
 size_t iio_dma_buffer_usage(struct iio_buffer *buffer);

-- 
2.52.0

