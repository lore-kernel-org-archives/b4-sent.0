From: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>
Date: Wed, 03 Dec 2025 15:11:38 +0000
Subject: [PATCH 3/6] iio: buffer-dma: Turn iio_dma_buffer_init() void
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20251203-iio-dmabuf-improvs-v1-3-0e4907ce7322@analog.com>
References: <20251203-iio-dmabuf-improvs-v1-0-0e4907ce7322@analog.com>
In-Reply-To: <20251203-iio-dmabuf-improvs-v1-0-0e4907ce7322@analog.com>
To: linux-iio@vger.kernel.org
Cc: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, Andy Shevchenko <andy@kernel.org>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1764774697; l=2345;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=y2MrbcO9+GqoAo7PDN3wtQCQRyiKn0pgHKJogZKJwqk=;
 b=BVwzkiL5ixJvvc3yqk1txmDMJPEx1Ni717V20GIFg0XKd8QU6s+U2WOJ2vCYGI5bVw8iowg6F
 b4ShgHI++5HCOOGIXO8MQ1wi7p4R7yIjbYvDc0pgixBSOGuKudWTmNI
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
index 026b42552a0a..0a6891541ed3 100644
--- a/drivers/iio/buffer/industrialio-buffer-dma.c
+++ b/drivers/iio/buffer/industrialio-buffer-dma.c
@@ -819,8 +819,8 @@ EXPORT_SYMBOL_NS_GPL(iio_dma_buffer_set_length, "IIO_DMA_BUFFER");
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
@@ -832,8 +832,6 @@ int iio_dma_buffer_init(struct iio_dma_buffer_queue *queue,
 
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

