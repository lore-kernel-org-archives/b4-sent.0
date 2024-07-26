From: Nuno Sa <nuno.sa@analog.com>
Date: Fri, 26 Jul 2024 13:31:15 +0200
Subject: [PATCH] iio: buffer-dma: Move exports into IIO_DMA_BUFFER
 namespace
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20240726-dev-iio-dma-buf-mod-namespace-v1-1-8877cfe7f68e@analog.com>
X-B4-Tracking: v=1; b=H4sIAAKJo2YC/x3MMQqEMBAF0KvI1A5ojK7rVcQia746RRJJUATx7
 hssX/NuSoiCRENxU8QpSYLPqMuC5s34FSw2m1SldPVRHVucLBLYOsO/Y2EXLHvjkHYzg1vVoNX
 1t9e9pnzsEYtc7z9Oz/MHfQvUJm8AAAA=
To: linux-iio@vger.kernel.org
Cc: Jonathan Cameron <jic23@kernel.org>, 
 Lars-Peter Clausen <lars@metafoo.de>
X-Mailer: b4 0.14.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1721993475; l=7129;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=76KN45pWp9MF4JylEXizXpsfiEB/qHdPlOkyB2Qqqis=;
 b=Pm8ZzgBv5bDILllFgrdv2Xk+Kb9g8bktMZHTrYRhfqTWWcNTuByfZX27Arq2v/GZVaJYlmjRb
 Iin13ecRPgDDUPRCZH5VBSO/LSxL5Pr/wR+N69pmJFBzqBXA8cAh0jz
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Avoid unnecessary pollution of the global symbol namespace and move
global APIs into a specific namespace. Import that into the places that
use them

Signed-off-by: Nuno Sa <nuno.sa@analog.com>
---
 drivers/iio/buffer/industrialio-buffer-dma.c       | 36 +++++++++++-----------
 drivers/iio/buffer/industrialio-buffer-dmaengine.c |  1 +
 2 files changed, 19 insertions(+), 18 deletions(-)

diff --git a/drivers/iio/buffer/industrialio-buffer-dma.c b/drivers/iio/buffer/industrialio-buffer-dma.c
index 647f417a045e..dbde1443d6ed 100644
--- a/drivers/iio/buffer/industrialio-buffer-dma.c
+++ b/drivers/iio/buffer/industrialio-buffer-dma.c
@@ -248,7 +248,7 @@ void iio_dma_buffer_block_done(struct iio_dma_buffer_block *block)
 	iio_dma_buffer_queue_wake(queue);
 	dma_fence_end_signalling(cookie);
 }
-EXPORT_SYMBOL_GPL(iio_dma_buffer_block_done);
+EXPORT_SYMBOL_NS_GPL(iio_dma_buffer_block_done, IIO_DMA_BUFFER);
 
 /**
  * iio_dma_buffer_block_list_abort() - Indicate that a list block has been
@@ -287,7 +287,7 @@ void iio_dma_buffer_block_list_abort(struct iio_dma_buffer_queue *queue,
 	iio_dma_buffer_queue_wake(queue);
 	dma_fence_end_signalling(cookie);
 }
-EXPORT_SYMBOL_GPL(iio_dma_buffer_block_list_abort);
+EXPORT_SYMBOL_NS_GPL(iio_dma_buffer_block_list_abort, IIO_DMA_BUFFER);
 
 static bool iio_dma_block_reusable(struct iio_dma_buffer_block *block)
 {
@@ -420,7 +420,7 @@ int iio_dma_buffer_request_update(struct iio_buffer *buffer)
 
 	return ret;
 }
-EXPORT_SYMBOL_GPL(iio_dma_buffer_request_update);
+EXPORT_SYMBOL_NS_GPL(iio_dma_buffer_request_update, IIO_DMA_BUFFER);
 
 static void iio_dma_buffer_fileio_free(struct iio_dma_buffer_queue *queue)
 {
@@ -506,7 +506,7 @@ int iio_dma_buffer_enable(struct iio_buffer *buffer,
 
 	return 0;
 }
-EXPORT_SYMBOL_GPL(iio_dma_buffer_enable);
+EXPORT_SYMBOL_NS_GPL(iio_dma_buffer_enable, IIO_DMA_BUFFER);
 
 /**
  * iio_dma_buffer_disable() - Disable DMA buffer
@@ -530,7 +530,7 @@ int iio_dma_buffer_disable(struct iio_buffer *buffer,
 
 	return 0;
 }
-EXPORT_SYMBOL_GPL(iio_dma_buffer_disable);
+EXPORT_SYMBOL_NS_GPL(iio_dma_buffer_disable, IIO_DMA_BUFFER);
 
 static void iio_dma_buffer_enqueue(struct iio_dma_buffer_queue *queue,
 	struct iio_dma_buffer_block *block)
@@ -636,7 +636,7 @@ int iio_dma_buffer_read(struct iio_buffer *buffer, size_t n,
 {
 	return iio_dma_buffer_io(buffer, n, user_buffer, false);
 }
-EXPORT_SYMBOL_GPL(iio_dma_buffer_read);
+EXPORT_SYMBOL_NS_GPL(iio_dma_buffer_read, IIO_DMA_BUFFER);
 
 /**
  * iio_dma_buffer_write() - DMA buffer write callback
@@ -653,7 +653,7 @@ int iio_dma_buffer_write(struct iio_buffer *buffer, size_t n,
 	return iio_dma_buffer_io(buffer, n,
 				 (__force __user char *)user_buffer, true);
 }
-EXPORT_SYMBOL_GPL(iio_dma_buffer_write);
+EXPORT_SYMBOL_NS_GPL(iio_dma_buffer_write, IIO_DMA_BUFFER);
 
 /**
  * iio_dma_buffer_usage() - DMA buffer data_available and
@@ -696,7 +696,7 @@ size_t iio_dma_buffer_usage(struct iio_buffer *buf)
 
 	return data_available;
 }
-EXPORT_SYMBOL_GPL(iio_dma_buffer_usage);
+EXPORT_SYMBOL_NS_GPL(iio_dma_buffer_usage, IIO_DMA_BUFFER);
 
 struct iio_dma_buffer_block *
 iio_dma_buffer_attach_dmabuf(struct iio_buffer *buffer,
@@ -723,7 +723,7 @@ iio_dma_buffer_attach_dmabuf(struct iio_buffer *buffer,
 
 	return block;
 }
-EXPORT_SYMBOL_GPL(iio_dma_buffer_attach_dmabuf);
+EXPORT_SYMBOL_NS_GPL(iio_dma_buffer_attach_dmabuf, IIO_DMA_BUFFER);
 
 void iio_dma_buffer_detach_dmabuf(struct iio_buffer *buffer,
 				  struct iio_dma_buffer_block *block)
@@ -731,7 +731,7 @@ void iio_dma_buffer_detach_dmabuf(struct iio_buffer *buffer,
 	block->state = IIO_BLOCK_STATE_DEAD;
 	iio_buffer_block_put_atomic(block);
 }
-EXPORT_SYMBOL_GPL(iio_dma_buffer_detach_dmabuf);
+EXPORT_SYMBOL_NS_GPL(iio_dma_buffer_detach_dmabuf, IIO_DMA_BUFFER);
 
 static int iio_dma_can_enqueue_block(struct iio_dma_buffer_block *block)
 {
@@ -784,7 +784,7 @@ int iio_dma_buffer_enqueue_dmabuf(struct iio_buffer *buffer,
 
 	return ret;
 }
-EXPORT_SYMBOL_GPL(iio_dma_buffer_enqueue_dmabuf);
+EXPORT_SYMBOL_NS_GPL(iio_dma_buffer_enqueue_dmabuf, IIO_DMA_BUFFER);
 
 void iio_dma_buffer_lock_queue(struct iio_buffer *buffer)
 {
@@ -792,7 +792,7 @@ void iio_dma_buffer_lock_queue(struct iio_buffer *buffer)
 
 	mutex_lock(&queue->lock);
 }
-EXPORT_SYMBOL_GPL(iio_dma_buffer_lock_queue);
+EXPORT_SYMBOL_NS_GPL(iio_dma_buffer_lock_queue, IIO_DMA_BUFFER);
 
 void iio_dma_buffer_unlock_queue(struct iio_buffer *buffer)
 {
@@ -800,7 +800,7 @@ void iio_dma_buffer_unlock_queue(struct iio_buffer *buffer)
 
 	mutex_unlock(&queue->lock);
 }
-EXPORT_SYMBOL_GPL(iio_dma_buffer_unlock_queue);
+EXPORT_SYMBOL_NS_GPL(iio_dma_buffer_unlock_queue, IIO_DMA_BUFFER);
 
 /**
  * iio_dma_buffer_set_bytes_per_datum() - DMA buffer set_bytes_per_datum callback
@@ -816,7 +816,7 @@ int iio_dma_buffer_set_bytes_per_datum(struct iio_buffer *buffer, size_t bpd)
 
 	return 0;
 }
-EXPORT_SYMBOL_GPL(iio_dma_buffer_set_bytes_per_datum);
+EXPORT_SYMBOL_NS_GPL(iio_dma_buffer_set_bytes_per_datum, IIO_DMA_BUFFER);
 
 /**
  * iio_dma_buffer_set_length - DMA buffer set_length callback
@@ -836,7 +836,7 @@ int iio_dma_buffer_set_length(struct iio_buffer *buffer, unsigned int length)
 
 	return 0;
 }
-EXPORT_SYMBOL_GPL(iio_dma_buffer_set_length);
+EXPORT_SYMBOL_NS_GPL(iio_dma_buffer_set_length, IIO_DMA_BUFFER);
 
 /**
  * iio_dma_buffer_init() - Initialize DMA buffer queue
@@ -864,7 +864,7 @@ int iio_dma_buffer_init(struct iio_dma_buffer_queue *queue,
 
 	return 0;
 }
-EXPORT_SYMBOL_GPL(iio_dma_buffer_init);
+EXPORT_SYMBOL_NS_GPL(iio_dma_buffer_init, IIO_DMA_BUFFER);
 
 /**
  * iio_dma_buffer_exit() - Cleanup DMA buffer queue
@@ -882,7 +882,7 @@ void iio_dma_buffer_exit(struct iio_dma_buffer_queue *queue)
 
 	mutex_unlock(&queue->lock);
 }
-EXPORT_SYMBOL_GPL(iio_dma_buffer_exit);
+EXPORT_SYMBOL_NS_GPL(iio_dma_buffer_exit, IIO_DMA_BUFFER);
 
 /**
  * iio_dma_buffer_release() - Release final buffer resources
@@ -896,7 +896,7 @@ void iio_dma_buffer_release(struct iio_dma_buffer_queue *queue)
 {
 	mutex_destroy(&queue->lock);
 }
-EXPORT_SYMBOL_GPL(iio_dma_buffer_release);
+EXPORT_SYMBOL_NS_GPL(iio_dma_buffer_release, IIO_DMA_BUFFER);
 
 MODULE_AUTHOR("Lars-Peter Clausen <lars@metafoo.de>");
 MODULE_DESCRIPTION("DMA buffer for the IIO framework");
diff --git a/drivers/iio/buffer/industrialio-buffer-dmaengine.c b/drivers/iio/buffer/industrialio-buffer-dmaengine.c
index 12aa1412dfa0..a2246826c11e 100644
--- a/drivers/iio/buffer/industrialio-buffer-dmaengine.c
+++ b/drivers/iio/buffer/industrialio-buffer-dmaengine.c
@@ -348,3 +348,4 @@ EXPORT_SYMBOL_NS_GPL(devm_iio_dmaengine_buffer_setup_ext, IIO_DMAENGINE_BUFFER);
 MODULE_AUTHOR("Lars-Peter Clausen <lars@metafoo.de>");
 MODULE_DESCRIPTION("DMA buffer for the IIO framework");
 MODULE_LICENSE("GPL");
+MODULE_IMPORT_NS(IIO_DMA_BUFFER);

---
base-commit: 472438c7e0e2261c6737a8321f46ef176eef1c8f
change-id: 20240726-dev-iio-dma-buf-mod-namespace-523e54198484
--

Thanks!
- Nuno Sá

