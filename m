From: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>
Date: Tue, 07 Oct 2025 10:15:21 +0100
Subject: [PATCH v3 1/3] iio: buffer: support getting dma channel from the
 buffer
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20251007-fix-iio-dmabuf-get-dma-device-v3-1-0c73e2c0653b@analog.com>
References: <20251007-fix-iio-dmabuf-get-dma-device-v3-0-0c73e2c0653b@analog.com>
In-Reply-To: <20251007-fix-iio-dmabuf-get-dma-device-v3-0-0c73e2c0653b@analog.com>
To: linux-iio@vger.kernel.org
Cc: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, Andy Shevchenko <andy@kernel.org>, 
 stable@vger.kernel.org
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1759828521; l=5123;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=+7B4M4g0oii5at3ljQ2R7qfIy/Gk+7w2PvcLmO3dnFQ=;
 b=S+OYyfZ4vKAEaGBUvtDa+8sQ+HVdrzhPwoQzPNLaMlmd2e4CbFr5vQNlJnW08EnOifU2qHYn9
 QR4ROsZJrKwD3kylVg6R+3D2quxCIucs0l75zAZxtd0HKcyJV0Oc9JW
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a new buffer accessor .get_dma_dev() in order to get the
struct device responsible for actually providing the dma channel. We
cannot assume that we can use the parent of the IIO device for mapping
the DMA buffer. This becomes important on systems (like the Xilinx/AMD
zynqMP Ultrascale) where memory (or part of it) is mapped above the
32 bit range. On such systems and given that a device by default has
a dma mask of 32 bits we would then need to rely on bounce buffers (to
swiotlb) for mapping memory above the dma mask limit.

In the process, add an iio_buffer_get_dma_dev() helper function to get
the proper DMA device.

Cc: stable@vger.kernel.org
Reviewed-by: David Lechner <dlechner@baylibre.com>
Signed-off-by: Nuno Sá <nuno.sa@analog.com>
---
 drivers/iio/industrialio-buffer.c | 21 ++++++++++++++++-----
 include/linux/iio/buffer_impl.h   |  2 ++
 2 files changed, 18 insertions(+), 5 deletions(-)

diff --git a/drivers/iio/industrialio-buffer.c b/drivers/iio/industrialio-buffer.c
index f1448ae1b843fc577599fc1b9cf6d859bba226f1..bbdc0c4a158795750bc441a9f89e84ba0ed75172 100644
--- a/drivers/iio/industrialio-buffer.c
+++ b/drivers/iio/industrialio-buffer.c
@@ -1623,19 +1623,28 @@ static int iio_dma_resv_lock(struct dma_buf *dmabuf, bool nonblock)
 	return 0;
 }
 
+static struct device *iio_buffer_get_dma_dev(const struct iio_dev *indio_dev,
+					     struct iio_buffer *buffer)
+{
+	if (buffer->access->get_dma_dev)
+		return buffer->access->get_dma_dev(buffer);
+
+	return indio_dev->dev.parent;
+}
+
 static struct dma_buf_attachment *
 iio_buffer_find_attachment(struct iio_dev_buffer_pair *ib,
 			   struct dma_buf *dmabuf, bool nonblock)
 {
-	struct device *dev = ib->indio_dev->dev.parent;
 	struct iio_buffer *buffer = ib->buffer;
+	struct device *dma_dev = iio_buffer_get_dma_dev(ib->indio_dev, buffer);
 	struct dma_buf_attachment *attach = NULL;
 	struct iio_dmabuf_priv *priv;
 
 	guard(mutex)(&buffer->dmabufs_mutex);
 
 	list_for_each_entry(priv, &buffer->dmabufs, entry) {
-		if (priv->attach->dev == dev
+		if (priv->attach->dev == dma_dev
 		    && priv->attach->dmabuf == dmabuf) {
 			attach = priv->attach;
 			break;
@@ -1653,6 +1662,7 @@ static int iio_buffer_attach_dmabuf(struct iio_dev_buffer_pair *ib,
 {
 	struct iio_dev *indio_dev = ib->indio_dev;
 	struct iio_buffer *buffer = ib->buffer;
+	struct device *dma_dev = iio_buffer_get_dma_dev(indio_dev, buffer);
 	struct dma_buf_attachment *attach;
 	struct iio_dmabuf_priv *priv, *each;
 	struct dma_buf *dmabuf;
@@ -1679,7 +1689,7 @@ static int iio_buffer_attach_dmabuf(struct iio_dev_buffer_pair *ib,
 		goto err_free_priv;
 	}
 
-	attach = dma_buf_attach(dmabuf, indio_dev->dev.parent);
+	attach = dma_buf_attach(dmabuf, dma_dev);
 	if (IS_ERR(attach)) {
 		err = PTR_ERR(attach);
 		goto err_dmabuf_put;
@@ -1719,7 +1729,7 @@ static int iio_buffer_attach_dmabuf(struct iio_dev_buffer_pair *ib,
 	 * combo. If we do, refuse to attach.
 	 */
 	list_for_each_entry(each, &buffer->dmabufs, entry) {
-		if (each->attach->dev == indio_dev->dev.parent
+		if (each->attach->dev == dma_dev
 		    && each->attach->dmabuf == dmabuf) {
 			/*
 			 * We unlocked the reservation object, so going through
@@ -1758,6 +1768,7 @@ static int iio_buffer_detach_dmabuf(struct iio_dev_buffer_pair *ib,
 {
 	struct iio_buffer *buffer = ib->buffer;
 	struct iio_dev *indio_dev = ib->indio_dev;
+	struct device *dma_dev = iio_buffer_get_dma_dev(indio_dev, buffer);
 	struct iio_dmabuf_priv *priv;
 	struct dma_buf *dmabuf;
 	int dmabuf_fd, ret = -EPERM;
@@ -1772,7 +1783,7 @@ static int iio_buffer_detach_dmabuf(struct iio_dev_buffer_pair *ib,
 	guard(mutex)(&buffer->dmabufs_mutex);
 
 	list_for_each_entry(priv, &buffer->dmabufs, entry) {
-		if (priv->attach->dev == indio_dev->dev.parent
+		if (priv->attach->dev == dma_dev
 		    && priv->attach->dmabuf == dmabuf) {
 			list_del(&priv->entry);
 
diff --git a/include/linux/iio/buffer_impl.h b/include/linux/iio/buffer_impl.h
index 0daff9ff20ce49de67fa0f2ac6191882de2f4a67..c0b0e0992a85b2813a126c1a61f13f1ed0b498dd 100644
--- a/include/linux/iio/buffer_impl.h
+++ b/include/linux/iio/buffer_impl.h
@@ -51,6 +51,7 @@ struct sg_table;
  * @enqueue_dmabuf:	called from userspace via ioctl to queue this DMABUF
  *			object to this buffer. Requires a valid DMABUF fd, that
  *			was previouly attached to this buffer.
+ * @get_dma_dev:	called to get the DMA channel associated with this buffer.
  * @lock_queue:		called when the core needs to lock the buffer queue;
  *                      it is used when enqueueing DMABUF objects.
  * @unlock_queue:       used to unlock a previously locked buffer queue
@@ -91,6 +92,7 @@ struct iio_buffer_access_funcs {
 			      struct iio_dma_buffer_block *block,
 			      struct dma_fence *fence, struct sg_table *sgt,
 			      size_t size, bool cyclic);
+	struct device * (*get_dma_dev)(struct iio_buffer *buffer);
 	void (*lock_queue)(struct iio_buffer *buffer);
 	void (*unlock_queue)(struct iio_buffer *buffer);
 

-- 
2.51.0

