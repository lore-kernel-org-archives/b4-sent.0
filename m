From: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>
Date: Fri, 19 Dec 2025 15:28:14 +0000
Subject: [PATCH v2 3/6] iio: buffer-dma: Turn iio_dma_buffer_init() void
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20251219-iio-dmabuf-improvs-v2-3-caa76de6e873@analog.com>
References: <20251219-iio-dmabuf-improvs-v2-0-caa76de6e873@analog.com>
In-Reply-To: <20251219-iio-dmabuf-improvs-v2-0-caa76de6e873@analog.com>
To: linux-iio@vger.kernel.org
Cc: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, Andy Shevchenko <andy@kernel.org>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1766158092; l=2345;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=i2mR17oBuj0z0WQHcCbOUfOiriuyh4DEJuWWhy3zyw0=;
 b=5vk0DRlwJYEXk6O/qk1Ym1blSy2VQzmyc27nAAePAi4VOf/m8j8M846eR9o/RRXhOFoMxyN/F
 DVWk4S0SQGmDa0v2D8sE585DHhJ5kRWwjspEffO/O+D6zvY14VHgAsV
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

iio_dma_buffer_init() always return 0. Therefore there's no point in
returning int.

While at it, fix a mismatch between the function declaration and definition
regarding the struct device (dma_dev != dev).

Signed-off-by: Nuno Sá <nuno.sa@analog.com>
---
 drivers/iio/buffer/industrialio-buffer-dma.c | 6 ++----
 include/linux/iio/buffer-dma.h               | 4 ++--
 2 files changed, 4 insertions(+), 6 deletions(-)

diff --git a/drivers/iio/buffer/industrialio-buffer-dma.c b/drivers/iio/buffer/industrialio-buffer-dma.c
index 1f918a3e6b93..3ab1349f9ea5 100644
--- a/drivers/iio/buffer/industrialio-buffer-dma.c
+++ b/drivers/iio/buffer/industrialio-buffer-dma.c
@@ -820,8 +820,8 @@ EXPORT_SYMBOL_NS_GPL(iio_dma_buffer_set_length, "IIO_DMA_BUFFER");
  * should refer to the device that will perform the DMA to ensure that
  * allocations are done from a memory region that can be accessed by the device.
  */
-int iio_dma_buffer_init(struct iio_dma_buffer_queue *queue,
-	struct device *dev, const struct iio_dma_buffer_ops *ops)
+void iio_dma_buffer_init(struct iio_dma_buffer_queue *queue, struct device *dev,
+			 const struct iio_dma_buffer_ops *ops)
 {
 	iio_buffer_init(&queue->buffer);
 	queue->buffer.length = PAGE_SIZE;
@@ -833,8 +833,6 @@ int iio_dma_buffer_init(struct iio_dma_buffer_queue *queue,
 
 	mutex_init(&queue->lock);
 	spin_lock_init(&queue->list_lock);
-
-	return 0;
 }
 EXPORT_SYMBOL_NS_GPL(iio_dma_buffer_init, "IIO_DMA_BUFFER");
 
diff --git a/include/linux/iio/buffer-dma.h b/include/linux/iio/buffer-dma.h
index 5eb66a399002..91f678e5be71 100644
--- a/include/linux/iio/buffer-dma.h
+++ b/include/linux/iio/buffer-dma.h
@@ -157,8 +157,8 @@ int iio_dma_buffer_set_bytes_per_datum(struct iio_buffer *buffer, size_t bpd);
 int iio_dma_buffer_set_length(struct iio_buffer *buffer, unsigned int length);
 int iio_dma_buffer_request_update(struct iio_buffer *buffer);
 
-int iio_dma_buffer_init(struct iio_dma_buffer_queue *queue,
-	struct device *dma_dev, const struct iio_dma_buffer_ops *ops);
+void iio_dma_buffer_init(struct iio_dma_buffer_queue *queue, struct device *dev,
+			 const struct iio_dma_buffer_ops *ops);
 void iio_dma_buffer_exit(struct iio_dma_buffer_queue *queue);
 void iio_dma_buffer_release(struct iio_dma_buffer_queue *queue);
 

-- 
2.52.0

